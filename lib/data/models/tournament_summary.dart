import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentSummary {
  final String id;
  final String name;
  final String description;
  final String status;
  final String bracketType;
  final String location;
  final int registrationFee;
  final int maxParticipants;
  final int currentParticipantCount;
  final DateTime? startDate;
  final DateTime? registrationDeadline;
  final String? winnerName;
  final String? winnerDeckName;

  const TournamentSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.bracketType,
    required this.location,
    required this.registrationFee,
    required this.maxParticipants,
    required this.currentParticipantCount,
    required this.startDate,
    required this.registrationDeadline,
    this.winnerName,
    this.winnerDeckName,
  });

  bool get registrationOpen => status == 'registrationOpen';
  double get fillPct {
    if (maxParticipants <= 0) return 0;
    return (currentParticipantCount / maxParticipants).clamp(0, 1).toDouble();
  }

  factory TournamentSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? dateOf(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TournamentSummary(
      id: doc.id,
      name: (data['name'] ?? 'Untitled Tournament').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'draft').toString(),
      bracketType: (data['bracketType'] ?? 'singleElimination').toString(),
      location: (data['location'] ?? data['venue'] ?? '').toString(),
      registrationFee: (data['registrationFee'] as num?)?.round() ?? 0,
      maxParticipants: (data['maxParticipants'] as num?)?.round() ?? 32,
      currentParticipantCount:
          (data['currentParticipantCount'] as num?)?.round() ??
              (data['participantCount'] as num?)?.round() ??
              0,
      startDate: dateOf('startDate'),
      registrationDeadline: dateOf('registrationDeadline'),
      winnerName: data['winnerName']?.toString(),
      winnerDeckName: data['winnerDeckName']?.toString(),
    );
  }
}
