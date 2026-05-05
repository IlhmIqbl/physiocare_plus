import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String userType;
  final List<String> bodyFocusAreas;
  final int painSeverity;
  final DateTime createdAt;
  final String? therapistId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.userType,
    required this.bodyFocusAreas,
    required this.painSeverity,
    required this.createdAt,
    this.therapistId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      userType: map['userType'] as String,
      bodyFocusAreas: List<String>.from(map['bodyFocusAreas'] ?? []),
      painSeverity: map['painSeverity'] as int,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      therapistId: map['therapistId'] as String?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'userType': userType,
      'bodyFocusAreas': bodyFocusAreas,
      'painSeverity': painSeverity,
      'createdAt': Timestamp.fromDate(createdAt),
      'therapistId': therapistId,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? userType,
    List<String>? bodyFocusAreas,
    int? painSeverity,
    DateTime? createdAt,
    String? therapistId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      bodyFocusAreas: bodyFocusAreas ?? this.bodyFocusAreas,
      painSeverity: painSeverity ?? this.painSeverity,
      createdAt: createdAt ?? this.createdAt,
      therapistId: therapistId ?? this.therapistId,
    );
  }
}
