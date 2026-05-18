import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityApplication {
  final String id;
  final String requesterId;
  final String communityName;
  final String city;
  final String leaderUserId;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewerId;

  const CommunityApplication({
    required this.id,
    required this.requesterId,
    required this.communityName,
    required this.city,
    required this.leaderUserId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewerId,
  });

  factory CommunityApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CommunityApplication(
      id: doc.id,
      requesterId: (data['requesterId'] ?? '').toString(),
      communityName: (data['communityName'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      leaderUserId: (data['leaderUserId'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: readDate('createdAt'),
      reviewedAt: readDate('reviewedAt'),
      reviewerId: data['reviewerId']?.toString(),
    );
  }
}
