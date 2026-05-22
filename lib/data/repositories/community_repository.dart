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

final reviewedCommunityApplicationsProvider =
    StreamProvider<List<CommunityApplication>>((ref) {
  return ref.watch(communityRepositoryProvider).watchRecentApplications();
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

  Stream<List<CommunityApplication>> watchRecentApplications() {
    return firestore
        .collection(FirestorePaths.communityApplications)
        .limit(80)
        .snapshots()
        .map((snap) {
      final applications =
          snap.docs.map(CommunityApplication.fromFirestore).toList();
      applications.sort((a, b) {
        final aDate = a.reviewedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.reviewedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return applications
          .where((application) => application.status != 'pending')
          .take(12)
          .toList();
    });
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
    String tag = '',
    String type = '',
    String region = '',
    String website = '',
    Map<String, Object?> leader = const {},
    Map<String, Object?> financeAccount = const {},
    Map<String, Object?> documents = const {},
  }) async {
    try {
      final callable = functions.httpsCallable('submitCommunityApplication');
      final result = await callable.call({
        'communityName': communityName.trim(),
        'city': city.trim(),
        'leaderUserId': leaderUserId.trim(),
        'description': description.trim(),
        'tag': tag.trim(),
        'type': type.trim(),
        'region': region.trim(),
        'website': website.trim(),
        'leader': leader,
        'financeAccount': financeAccount,
        'documents': documents,
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
        'tag': tag.trim(),
        'type': type.trim(),
        'region': region.trim(),
        'website': website.trim(),
        'leader': leader,
        'financeAccount': financeAccount,
        'documents': documents,
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
      final communityId = (data['communityId'] ?? '').toString();
      await _recordApplicationReview(
        application: application,
        reviewerId: reviewerId,
        status: 'approved',
        communityId: communityId,
      );
      return communityId;
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
          'tag': application.tag,
          'type': application.type,
          'city': application.city,
          'region': application.region,
          'website': application.website,
          'description': application.description,
          'leaderUserId': application.leaderUserId,
          'leader': _leaderPayload(application),
          'financeAccount': _financePayload(application),
          'documents': _documentPayload(application),
          'adminIds': [application.leaderUserId],
          'memberCount': 1,
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
              'reviewEvents': FieldValue.arrayUnion([
                _reviewEvent(
                  status: 'approved',
                  reviewerId: reviewerId,
                  communityId: communityRef.id,
                ),
              ]),
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
      await _writeReviewNotification(
        application: application,
        status: 'approved',
        communityId: communityRef.id,
      );
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
      await _recordApplicationReview(
        application: application,
        reviewerId: reviewerId,
        status: 'rejected',
        reason: reason,
      );
    } catch (_) {
      await firestore
          .collection(FirestorePaths.communityApplications)
          .doc(application.id)
          .set({
        'status': 'rejected',
        'reviewerId': reviewerId,
        'rejectionReason': reason,
        'reviewEvents': FieldValue.arrayUnion([
          _reviewEvent(
            status: 'rejected',
            reviewerId: reviewerId,
            reason: reason,
          ),
        ]),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _writeReviewNotification(
        application: application,
        status: 'rejected',
        reason: reason,
      );
    }
  }

  Future<void> _recordApplicationReview({
    required CommunityApplication application,
    required String reviewerId,
    required String status,
    String communityId = '',
    String reason = '',
  }) async {
    await firestore
        .collection(FirestorePaths.communityApplications)
        .doc(application.id)
        .set({
      'status': status,
      'reviewerId': reviewerId,
      if (communityId.isNotEmpty) 'communityId': communityId,
      if (reason.isNotEmpty) 'rejectionReason': reason,
      'reviewEvents': FieldValue.arrayUnion([
        _reviewEvent(
          status: status,
          reviewerId: reviewerId,
          communityId: communityId,
          reason: reason,
        ),
      ]),
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _writeReviewNotification(
      application: application,
      status: status,
      communityId: communityId,
      reason: reason,
    );
  }

  Future<void> _writeReviewNotification({
    required CommunityApplication application,
    required String status,
    String communityId = '',
    String reason = '',
  }) async {
    final recipients = <String>{
      application.requesterId,
      application.leaderUserId,
    }..removeWhere((uid) => uid.trim().isEmpty);
    final title = status == 'approved'
        ? 'Community approved'
        : 'Community application rejected';
    final body = status == 'approved'
        ? '${application.communityName} is now active. The community lead can open the community dashboard.'
        : '${application.communityName} has not been approved. ${reason.isEmpty ? 'Please complete the data and resubmit.' : reason}';
    for (final uid in recipients) {
      await firestore.collection(FirestorePaths.notifications).add({
        'recipientId': uid,
        'type': 'communityApplication',
        'title': title,
        'body': body,
        'sourceApplicationId': application.id,
        if (communityId.isNotEmpty) 'communityId': communityId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

Map<String, Object?> _reviewEvent({
  required String status,
  required String reviewerId,
  String communityId = '',
  String reason = '',
}) {
  return {
    'status': status,
    'reviewerId': reviewerId,
    if (communityId.isNotEmpty) 'communityId': communityId,
    if (reason.isNotEmpty) 'reason': reason,
    'at': DateTime.now().toUtc().toIso8601String(),
  };
}

Map<String, Object?> _leaderPayload(CommunityApplication application) {
  return {
    'name': application.leaderName,
    'email': application.leaderEmail,
    'phone': application.leaderPhone,
    'instagram': application.leaderInstagram,
    'userId': application.leaderUserId,
  };
}

Map<String, Object?> _financePayload(CommunityApplication application) {
  return {
    'bankName': application.bankName,
    'holderName': application.bankHolder,
    'accountNumber': application.bankNumber,
    'branch': application.bankBranch,
    'withdrawMode': 'community_admin_auto',
  };
}

Map<String, Object?> _documentPayload(CommunityApplication application) {
  return {
    'logoUploaded': application.logoUploaded,
    'idUploaded': application.idUploaded,
    'letterUploaded': application.letterUploaded,
  };
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
      return 'PLAYER / LEAD / JUDGE';
    }
    if (roles.contains('community_admin')) return 'PLAYER / LEAD';
    if (roles.contains('judge')) return 'PLAYER / JUDGE';
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
