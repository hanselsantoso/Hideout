import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/app_user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream<AppUser?>.value(null);
  return ref.watch(authRepositoryProvider).watchUser(auth.uid);
});

class AuthRepository {
  AuthRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Stream<User?> authStateChanges() => auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String region,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await firestore.doc(FirestorePaths.userDoc(user.uid)).set({
        'uid': user.uid,
        'displayName': name.trim(),
        'email': email.trim(),
        'region': region,
        'role': 'player',
        'eloRating': 1000,
        'totalWins': 0,
        'totalLosses': 0,
        'totalMatches': 0,
        'isQrActivated': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => auth.signOut();

  Future<AppUser?> getUser(String uid) async {
    final snap = await firestore.doc(FirestorePaths.userDoc(uid)).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  Stream<AppUser?> watchUser(String uid) {
    return firestore.doc(FirestorePaths.userDoc(uid)).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }
}
