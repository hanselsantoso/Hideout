import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/community_application.dart';
import 'auth_repository.dart';
import 'tournament_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(functionsProvider),
  );
});

final pendingCommunityApplicationsProvider =
    StreamProvider<List<CommunityApplication>>((ref) {
  return ref.watch(communityRepositoryProvider).watchPendingApplications();
});

final communityJudgeCandidatesProvider =
    StreamProvider<List<CommunityJudgeCandidate>>((ref) {
  return ref.watch(communityRepositoryProvider).watchJudgeCandidates();
});

class CommunityRepository {
  CommunityRepository({required this.firestore, required this.functions});

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  Stream<List<CommunityApplication>> watchPendingApplications() {
    return firestore
        .collection(FirestorePaths.communityApplications)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CommunityApplication.fromFirestore).toList());
  }

  Stream<List<CommunityJudgeCandidate>> watchJudgeCandidates() {
    return firestore
        .collection(FirestorePaths.users)
        .limit(100)
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .map(CommunityJudgeCandidate.fromFirestore)
          .where((user) => !user.isSuperAdmin)
          .toList();
      users.sort((a, b) {
        final role = a.roleLabel.compareTo(b.roleLabel);
        if (role != 0) return role;
        return a.displayName.compareTo(b.displayName);
      });
      return users;
    });
  }

  Future<void> assignJudge({
    required String targetUid,
    required String assignedBy,
  }) async {
    try {
      final callable = functions.httpsCallable('assignJudge');
      await callable.call({
        'targetUid': targetUid,
        'assignedBy': assignedBy,
      });
    } catch (_) {
      final userRef = firestore.doc(FirestorePaths.userDoc(targetUid));
      final userSnap = await userRef.get();
      final roles = _rolesFromUserData(userSnap.data())
        ..add('player')
        ..add('judge');
      await firestore.doc(FirestorePaths.userDoc(targetUid)).set({
        'role': _primaryRole(roles),
        'roles': roles.toList()..sort(),
        'judgeAssignedBy': assignedBy,
        'judgeAssignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> revokeJudge({
    required String targetUid,
    required String revokedBy,
  }) async {
    final userRef = firestore.doc(FirestorePaths.userDoc(targetUid));
    final userSnap = await userRef.get();
    final roles = _rolesFromUserData(userSnap.data())..remove('judge');
    if (roles.isEmpty) roles.add('player');
    await firestore.doc(FirestorePaths.userDoc(targetUid)).set({
      'role': _primaryRole(roles),
      'roles': roles.toList()..sort(),
      'judgeRevokedBy': revokedBy,
      'judgeRevokedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> submitApplication({
    required String requesterId,
    required String communityName,
    required String city,
    required String leaderUserId,
    required String description,
  }) async {
    try {
      final callable = functions.httpsCallable('submitCommunityApplication');
      final result = await callable.call({
        'communityName': communityName.trim(),
        'city': city.trim(),
        'leaderUserId': leaderUserId.trim(),
        'description': description.trim(),
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return (data['applicationId'] ?? '').toString();
    } catch (_) {
      final ref =
          firestore.collection(FirestorePaths.communityApplications).doc();
      await ref.set({
        'requesterId': requesterId,
        'communityName': communityName.trim(),
        'city': city.trim(),
        'leaderUserId': leaderUserId.trim(),
        'description': description.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
  }

  Future<String> approveApplication({
    required CommunityApplication application,
    required String reviewerId,
  }) async {
    try {
      final callable = functions.httpsCallable('reviewCommunityApplication');
      final result = await callable.call({
        'applicationId': application.id,
        'decision': 'approved',
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return (data['communityId'] ?? '').toString();
    } catch (_) {
      final communityRef =
          firestore.collection(FirestorePaths.communities).doc();
      final applicationRef = firestore
          .collection(FirestorePaths.communityApplications)
          .doc(application.id);
      await firestore.runTransaction((tx) async {
        final leaderRef =
            firestore.doc(FirestorePaths.userDoc(application.leaderUserId));
        final leaderSnap = await tx.get(leaderRef);
        final roles = _rolesFromUserData(leaderSnap.data())
          ..add('player')
          ..add('community_admin');
        tx.set(communityRef, {
          'name': application.communityName,
          'city': application.city,
          'description': application.description,
          'leaderUserId': application.leaderUserId,
          'adminIds': [application.leaderUserId],
          'status': 'active',
          'sourceApplicationId': application.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.set(
            applicationRef,
            {
              'status': 'approved',
              'reviewerId': reviewerId,
              'communityId': communityRef.id,
              'reviewedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
        tx.set(
          leaderRef,
          {
            'role': _primaryRole(roles),
            'roles': roles.toList()..sort(),
            'communityIds': FieldValue.arrayUnion([communityRef.id]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      return communityRef.id;
    }
  }

  Future<void> rejectApplication({
    required CommunityApplication application,
    required String reviewerId,
    String reason = '',
  }) async {
    try {
      final callable = functions.httpsCallable('reviewCommunityApplication');
      await callable.call({
        'applicationId': application.id,
        'decision': 'rejected',
        'reason': reason,
      });
    } catch (_) {
      await firestore
          .collection(FirestorePaths.communityApplications)
          .doc(application.id)
          .set({
        'status': 'rejected',
        'reviewerId': reviewerId,
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}

class CommunityJudgeCandidate {
  final String uid;
  final String displayName;
  final String email;
  final String region;
  final String role;
  final Set<String> roles;
  final int eloRating;
  final int totalMatches;

  const CommunityJudgeCandidate({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.region,
    required this.role,
    required this.roles,
    required this.eloRating,
    required this.totalMatches,
  });

  bool get isJudge => roles.contains('judge');
  bool get isSuperAdmin => roles.contains('super_admin');

  String get roleLabel {
    if (roles.contains('community_admin') && roles.contains('judge')) {
      return 'PLAYER / KETUA / JURI';
    }
    if (roles.contains('community_admin')) return 'PLAYER / KETUA';
    if (roles.contains('judge')) return 'PLAYER / JURI';
    return 'PLAYER';
  }

  factory CommunityJudgeCandidate.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final roles = _rolesFromUserData(data);
    return CommunityJudgeCandidate(
      uid: doc.id,
      displayName: (data['displayName'] ?? data['name'] ?? 'Player').toString(),
      email: (data['email'] ?? '').toString(),
      region: (data['region'] ?? '-').toString(),
      role: (data['role'] ?? 'player').toString(),
      roles: roles,
      eloRating: (data['eloRating'] as num?)?.round() ?? 1000,
      totalMatches: (data['totalMatches'] as num?)?.round() ?? 0,
    );
  }
}

Set<String> _rolesFromUserData(Map<String, dynamic>? data) {
  final roles = <String>{};
  final role = data?['role']?.toString();
  if (role != null && role.trim().isNotEmpty) roles.add(_normalizeRole(role));
  for (final key in ['roles', 'roleClaims', 'capabilities']) {
    final value = data?[key];
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

String _primaryRole(Set<String> roles) {
  if (roles.contains('super_admin')) return 'super_admin';
  if (roles.contains('community_admin')) return 'community_admin';
  if (roles.contains('judge')) return 'judge';
  return 'player';
}
