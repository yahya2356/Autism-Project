import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String description;
  final int totalMembers;
  final String category;
  final DateTime createdAt;
  final String createdBy;
  final bool isPrivate;
  final bool requiresApproval;
  final String locationCode;
  final int? minChildAge;
  final int? maxChildAge;
  final List<String> allowedConditions;
  final List<String> instructions;

  const GroupModel({
    required this.groupId,
    required this.groupName,
    required this.description,
    this.totalMembers = 0,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    required this.isPrivate,
    required this.requiresApproval,
    required this.locationCode,
    required this.minChildAge,
    required this.maxChildAge,
    required this.allowedConditions,
    required this.instructions,
  });

  String get visibilityLabel => isPrivate ? 'Private' : 'Public';

  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      groupId: documentId,
      groupName: map['groupName'] ?? '',
      description: map['description'] ?? '',
      totalMembers: map['totalMembers'] ?? 0,
      category: map['category'] ?? 'General',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      isPrivate: map['isPrivate'] ?? false,
      requiresApproval: map['requiresApproval'] ?? false,
      locationCode: (map['locationCode'] ?? 'GLOBAL').toString().toUpperCase(),
      minChildAge: map['minChildAge'],
      maxChildAge: map['maxChildAge'],
      allowedConditions: List<String>.from(map['allowedConditions'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'description': description,
      'totalMembers': totalMembers,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isPrivate': isPrivate,
      'requiresApproval': requiresApproval,
      'locationCode': locationCode,
      'minChildAge': minChildAge,
      'maxChildAge': maxChildAge,
      'allowedConditions': allowedConditions,
      'instructions': instructions,
    };
  }
}
