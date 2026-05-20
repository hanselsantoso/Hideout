import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityApplication {
  final String id;
  final String requesterId;
  final String communityName;
  final String city;
  final String leaderUserId;
  final String description;
  final String status;
  final String tag;
  final String type;
  final String region;
  final String website;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final String leaderInstagram;
  final String bankName;
  final String bankHolder;
  final String bankNumber;
  final String bankBranch;
  final bool logoUploaded;
  final bool idUploaded;
  final bool letterUploaded;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewerId;
  final String? rejectionReason;

  const CommunityApplication({
    required this.id,
    required this.requesterId,
    required this.communityName,
    required this.city,
    required this.leaderUserId,
    required this.description,
    required this.status,
    this.tag = '',
    this.type = '',
    this.region = '',
    this.website = '',
    this.leaderName = '',
    this.leaderEmail = '',
    this.leaderPhone = '',
    this.leaderInstagram = '',
    this.bankName = '',
    this.bankHolder = '',
    this.bankNumber = '',
    this.bankBranch = '',
    this.logoUploaded = false,
    this.idUploaded = false,
    this.letterUploaded = false,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewerId,
    this.rejectionReason,
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

    final leader = Map<String, dynamic>.from(data['leader'] as Map? ?? {});
    final finance =
        Map<String, dynamic>.from(data['financeAccount'] as Map? ?? {});
    final documents =
        Map<String, dynamic>.from(data['documents'] as Map? ?? {});

    return CommunityApplication(
      id: doc.id,
      requesterId: (data['requesterId'] ?? '').toString(),
      communityName: (data['communityName'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      leaderUserId: (data['leaderUserId'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      tag: (data['tag'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      region: (data['region'] ?? '').toString(),
      website: (data['website'] ?? '').toString(),
      leaderName: (leader['name'] ?? '').toString(),
      leaderEmail: (leader['email'] ?? '').toString(),
      leaderPhone: (leader['phone'] ?? '').toString(),
      leaderInstagram: (leader['instagram'] ?? '').toString(),
      bankName: (finance['bankName'] ?? '').toString(),
      bankHolder: (finance['holderName'] ?? '').toString(),
      bankNumber: (finance['accountNumber'] ?? '').toString(),
      bankBranch: (finance['branch'] ?? '').toString(),
      logoUploaded: documents['logoUploaded'] == true,
      idUploaded: documents['idUploaded'] == true,
      letterUploaded: documents['letterUploaded'] == true,
      createdAt: readDate('createdAt'),
      reviewedAt: readDate('reviewedAt'),
      reviewerId: data['reviewerId']?.toString(),
      rejectionReason: data['rejectionReason']?.toString(),
    );
  }
}
