import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_join_request_model.dart';
import '../models/group_model.dart';
import '../models/group_post_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost(PostModel post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toMap());
  }

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('likes').add({
      'postId': postId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('totalMembers', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> createGroup(GroupModel group) async {
    final doc = _firestore.collection('groups').doc();
    await doc.set(group.toMap());
    await _firestore.collection('groupMembers').doc('${doc.id}_${group.ownerId}').set({
      'groupId': doc.id,
      'userId': group.ownerId,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await doc.update({'totalMembers': FieldValue.increment(1)});
    return doc.id;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final memberRef = _firestore.collection('groupMembers').doc('${groupId}_$userId');
    final groupRef = _firestore.collection('groups').doc(groupId);
    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) return;

      transaction.set(memberRef, {
        'groupId': groupId,
        'userId': userId,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(groupRef, {
        'totalMembers': FieldValue.increment(1),
      });
    });
  }

  Future<void> requestJoinGroup({
    required String groupId,
    required String userId,
    String note = '',
  }) {
    return upsertJoinRequest(
      groupId: groupId,
      userId: userId,
      note: note,
      status: 'pending',
    );
  }

  Future<bool> isUserMember(String groupId, String userId) async {
    final doc = await _firestore.collection('groupMembers').doc('${groupId}_$userId').get();
    return doc.exists;
  }

  Stream<List<String>> getUserGroupIds(String userId) {
    return _firestore
        .collection('groupMembers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data()['groupId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList());
  }

  Future<void> upsertJoinRequest({
    required String groupId,
    required String userId,
    required String note,
    required String status,
  }) async {
    final requestId = '${groupId}_$userId';
    await _firestore.collection('groupJoinRequests').doc(requestId).set({
      'groupId': groupId,
      'userId': userId,
      'note': note,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
    }, SetOptions(merge: true));
  }

  Stream<List<GroupJoinRequestModel>> getUserJoinRequests(String userId) {
    return _firestore
        .collection('groupJoinRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupJoinRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<GroupJoinRequestModel>> getGroupJoinRequests(String groupId) {
    return _firestore
        .collection('groupJoinRequests')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupJoinRequestModel.fromMap(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> reviewJoinRequest({
    required String requestId,
    required String reviewerId,
    required String status,
  }) async {
    final requestRef = _firestore.collection('groupJoinRequests').doc(requestId);
    final requestSnapshot = await requestRef.get();
    if (!requestSnapshot.exists) return;

    final requestData = requestSnapshot.data()!;
    final groupId = requestData['groupId'] as String? ?? '';
    final userId = requestData['userId'] as String? ?? '';

    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupSnapshot = await groupRef.get();
    final ownerId = (groupSnapshot.data()?['ownerId'] ?? groupSnapshot.data()?['createdBy'] ?? '')
        .toString();
    if (ownerId.isEmpty || ownerId != reviewerId) {
      throw Exception('Only group owner can review join requests.');
    }

    await requestRef.update({
      'status': status,
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved' && groupId.isNotEmpty && userId.isNotEmpty) {
      await joinGroup(groupId, userId);
    }
  }

  Stream<List<GroupJoinRequestModel>> getPendingJoinRequestsForOwner(String ownerId) {
    return _firestore.collection('groups').snapshots().asyncMap((groupsSnapshot) async {
      final groupIds = groupsSnapshot.docs
          .where((doc) {
            final data = doc.data();
            final resolvedOwnerId = (data['ownerId'] ?? data['createdBy'] ?? '').toString();
            return resolvedOwnerId == ownerId;
          })
          .map((doc) => doc.id)
          .toList();

      if (groupIds.isEmpty) return <GroupJoinRequestModel>[];

      final List<GroupJoinRequestModel> requests = [];
      for (final groupId in groupIds) {
        final snapshot = await _firestore
            .collection('groupJoinRequests')
            .where('groupId', isEqualTo: groupId)
            .where('status', isEqualTo: 'pending')
            .get();
        requests.addAll(snapshot.docs.map((doc) => GroupJoinRequestModel.fromMap(doc.data(), doc.id)));
      }

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Future<bool> canJoinGroup(GroupModel group, UserModel? user) async {
    if (user == null) return false;
    final userLocation = (user.locationCode ?? '').toString().toUpperCase();
    final countryRule = (group.allowedCountry ?? '').trim().toUpperCase();
    final cityRule = (group.allowedCity ?? '').trim().toUpperCase();
    final languageRule = (group.allowedLanguage ?? '').trim().toLowerCase();

    if (countryRule.isNotEmpty && countryRule != 'GLOBAL' && userLocation != countryRule) {
      return false;
    }
    if (cityRule.isNotEmpty && cityRule != 'GLOBAL' && userLocation != cityRule) {
      return false;
    }

    final childDob = user.childDob;
    if (childDob != null) {
      final now = DateTime.now();
      final age = now.year - childDob.year -
          ((now.month < childDob.month || (now.month == childDob.month && now.day < childDob.day))
              ? 1
              : 0);
      if (group.minChildAge != null && age < group.minChildAge!) return false;
      if (group.maxChildAge != null && age > group.maxChildAge!) return false;
    }

    final diagnosis = (user.diagnosis ?? '').toString().toLowerCase().trim();
    if (group.allowedConditions.isNotEmpty &&
        !group.allowedConditions.map((e) => e.toLowerCase()).contains(diagnosis)) {
      return false;
    }

    final userLanguage = (user.preferredTextSize ?? '').toString().toLowerCase().trim();
    if (languageRule.isNotEmpty && userLanguage.isNotEmpty && languageRule != userLanguage) {
      return false;
    }
    return true;
  }

  Future<void> createGroupPost(String groupId, GroupPostModel post) async {
    final payload = post.toMap();
    payload['groupId'] = groupId;
    await _firestore.collection('groupPosts').add(payload);
  }

  Stream<List<GroupPostModel>> getGroupPosts(String groupId) {
    return _firestore
        .collection('groupPosts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupPostModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
