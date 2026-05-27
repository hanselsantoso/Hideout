import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import 'auth_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: ref.watch(firestoreProvider));
});

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream<List<AppNotification>>.value(const []);
  }
  return ref.watch(notificationRepositoryProvider).watchUserNotifications(
        user.uid,
      );
});

class NotificationRepository {
  const NotificationRepository({required this.firestore});

  final FirebaseFirestore firestore;

  Stream<List<AppNotification>> watchUserNotifications(String uid) {
    return firestore
        .collection(FirestorePaths.notifications)
        .where('recipientId', isEqualTo: uid)
        .limit(80)
        .snapshots()
        .map((snap) {
      final rows = snap.docs.map(AppNotification.fromFirestore).toList();
      rows.sort((a, b) {
        final pinned = b.pinned.toString().compareTo(a.pinned.toString());
        if (pinned != 0) return pinned;
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rows;
    });
  }

  Future<void> markRead(String id) {
    return firestore
        .collection(FirestorePaths.notifications)
        .doc(id)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markAllRead(List<AppNotification> notifications) async {
    final batch = firestore.batch();
    for (final item in notifications.where((item) => !item.read)) {
      batch.set(
        firestore.collection(FirestorePaths.notifications).doc(item.id),
        {'isRead': true},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.pinned,
    this.actorName,
    this.ctaLabel,
    this.ctaRoute,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final bool pinned;
  final String? actorName;
  final String? ctaLabel;
  final String? ctaRoute;
  final DateTime? createdAt;

  factory AppNotification.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    DateTime? readDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AppNotification(
      id: doc.id,
      title: (data['title'] ?? 'Notification').toString(),
      body: (data['body'] ?? '').toString(),
      type: (data['type'] ?? 'system').toString(),
      read: data['isRead'] == true || data['read'] == true,
      pinned: data['pinned'] == true,
      actorName: data['actorName']?.toString(),
      ctaLabel: data['ctaLabel']?.toString(),
      ctaRoute: data['ctaRoute']?.toString(),
      createdAt: readDate(data['createdAt']),
    );
  }
}
