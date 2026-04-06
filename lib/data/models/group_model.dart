import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String description;
  final int totalMembers;
  final String category;
  final DateTime createdAt;
  final String ownerId;
  final bool isPrivate;
  final bool requiresApproval;
  final String locationCode;
  final String? allowedCountry;
  final String? allowedCity;
  final String? allowedLanguage;
  final int? minChildAge;
  final int? maxChildAge;
  final List<String> allowedConditions;
  final List<String> instructions;
  final List<String> joinInstructions;

  const GroupModel({
    required this.groupId,
    required this.groupName,
    required this.description,
    this.totalMembers = 0,
    required this.category,
    required this.createdAt,
    required this.ownerId,
    required this.isPrivate,
    required this.requiresApproval,
    required this.locationCode,
    this.allowedCountry,
    this.allowedCity,
    this.allowedLanguage,
    required this.minChildAge,
    required this.maxChildAge,
    required this.allowedConditions,
    required this.instructions,
    this.joinInstructions = const [],
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
      ownerId: (map['ownerId'] ?? map['createdBy'] ?? '').toString(),
      isPrivate: map['isPrivate'] ?? false,
      requiresApproval: map['requiresApproval'] ?? false,
      locationCode: (map['locationCode'] ?? 'GLOBAL').toString().toUpperCase(),
      allowedCountry: (map['allowedCountry'] as String?)?.trim(),
      allowedCity: (map['allowedCity'] as String?)?.trim(),
      allowedLanguage: (map['allowedLanguage'] as String?)?.trim(),
      minChildAge: map['minChildAge'],
      maxChildAge: map['maxChildAge'],
      allowedConditions: List<String>.from(map['allowedConditions'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      joinInstructions: List<String>.from(map['joinInstructions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'description': description,
      'totalMembers': totalMembers,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
      'createdBy': ownerId,
      'isPrivate': isPrivate,
      'requiresApproval': requiresApproval,
      'locationCode': locationCode,
      'allowedCountry': allowedCountry,
      'allowedCity': allowedCity,
      'allowedLanguage': allowedLanguage,
      'minChildAge': minChildAge,
      'maxChildAge': maxChildAge,
      'allowedConditions': allowedConditions,
      'instructions': instructions,
      'joinInstructions': joinInstructions,
    };
  }
}
