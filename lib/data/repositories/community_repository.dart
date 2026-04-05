import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_join_request_model.dart';
import '../models/group_model.dart';
import '../models/group_post_model.dart';
import '../models/post_model.dart';

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
    await _firestore.collection('groupMembers').doc('${doc.id}_${group.createdBy}').set({
      'groupId': doc.id,
      'userId': group.createdBy,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await doc.update({'totalMembers': FieldValue.increment(1)});
    return doc.id;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final batch = _firestore.batch();
    final memberRef = _firestore.collection('groupMembers').doc('${groupId}_$userId');
    batch.set(memberRef, {
      'groupId': groupId,
      'userId': userId,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('groups').doc(groupId), {
      'totalMembers': FieldValue.increment(1),
    });

    await batch.commit();
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupJoinRequestModel.fromMap(doc.data(), doc.id))
            .toList());
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

    await requestRef.update({
      'status': status,
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved' && groupId.isNotEmpty && userId.isNotEmpty) {
      await joinGroup(groupId, userId);
    }
  }

  Future<void> createGroupPost(String groupId, GroupPostModel post) async {
    await _firestore.collection('groupPosts').add(post.toMap());
  }

  Stream<List<GroupPostModel>> getGroupPosts(String groupId) {
    return _firestore
        .collection('groupPosts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupPostModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
