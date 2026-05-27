import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final Set<String> roles;
  final int eloRating;
  final int totalWins;
  final int totalLosses;
  final int totalMatches;
  final bool isActive;
  final bool isQrActivated;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.roles = const {},
    required this.eloRating,
    required this.totalWins,
    required this.totalLosses,
    required this.totalMatches,
    required this.isActive,
    required this.isQrActivated,
  });

  Set<String> get capabilities {
    final normalized = roles.isEmpty ? {_normalizeRole(role)} : roles;
    if (normalized.contains('super_admin') || normalized.contains('admin')) {
      return {'super_admin'};
    }
    return {
      'player',
      if (normalized.contains('community_admin')) 'community_admin',
      if (normalized.contains('judge')) 'judge',
    };
  }

  bool get isAdminCompatible => capabilities.contains('super_admin');
  bool get isCommunityAdminCompatible =>
      capabilities.contains('community_admin');
  bool get isJudgeCompatible => capabilities.contains('judge');

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      displayName: (data['displayName'] ?? data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'player').toString(),
      roles: _rolesFromData(data),
      eloRating: (data['eloRating'] as num?)?.round() ?? 1000,
      totalWins: (data['totalWins'] as num?)?.round() ?? 0,
      totalLosses: (data['totalLosses'] as num?)?.round() ?? 0,
      totalMatches: (data['totalMatches'] as num?)?.round() ??
          (((data['totalWins'] as num?)?.round() ?? 0) +
              ((data['totalLosses'] as num?)?.round() ?? 0)),
      isActive: data['isActive'] != false,
      isQrActivated: data['isQrActivated'] == true,
    );
  }
}

Set<String> _rolesFromData(Map<String, dynamic> data) {
  final roles = <String>{_normalizeRole((data['role'] ?? 'player').toString())};
  for (final key in ['roles', 'roleClaims', 'capabilities']) {
    final value = data[key];
    if (value is Iterable) {
      roles.addAll(value.map((item) => _normalizeRole(item.toString())));
    }
  }
  roles.removeWhere((role) => role.isEmpty);
  return roles.isEmpty ? {'player'} : roles;
}

String _normalizeRole(String role) {
  final value = role.trim().toLowerCase();
  if (value == 'superadmin') return 'super_admin';
  if (value == 'communityadmin') return 'community_admin';
  if (value == 'juri') return 'judge';
  return value;
}
