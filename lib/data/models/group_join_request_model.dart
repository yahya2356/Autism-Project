import 'package:cloud_firestore/cloud_firestore.dart';

class GroupJoinRequestModel {
  final String id;
  final String groupId;
  final String userId;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const GroupJoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.status,
    this.note,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isPending => status == 'pending';

  factory GroupJoinRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupJoinRequestModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'pending',
      note: map['note'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'status': status,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }
}
