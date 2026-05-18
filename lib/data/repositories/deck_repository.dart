import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/bey_part.dart';
import '../models/player_deck.dart';
import 'auth_repository.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(firestore: ref.watch(firestoreProvider));
});

final userDecksProvider = StreamProvider<List<PlayerDeck>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<PlayerDeck>>.value(const []);
  return ref.watch(deckRepositoryProvider).watchUserDecks(user.uid);
});

class DeckRepository {
  DeckRepository({required this.firestore});

  final FirebaseFirestore firestore;

  Stream<List<PlayerDeck>> watchUserDecks(String uid) {
    return firestore
        .collection(FirestorePaths.userDecks(uid))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PlayerDeck.fromFirestore).toList());
  }

  Future<String> saveDeck({
    required String ownerId,
    required String name,
    required BeyPartsCatalog catalog,
    required List<DeckComboDraft> combos,
    String? deckId,
  }) async {
    final ref = deckId == null
        ? firestore.collection(FirestorePaths.userDecks(ownerId)).doc()
        : firestore.doc(FirestorePaths.userDeckDoc(ownerId, deckId));
    final deck = PlayerDeck.fromDraft(
      id: ref.id,
      ownerId: ownerId,
      name: name,
      catalog: catalog,
      drafts: combos,
    );
    await ref.set({
      ...deck.toFirestore(),
      if (deckId == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteDeck({
    required String ownerId,
    required String deckId,
  }) {
    return firestore.doc(FirestorePaths.userDeckDoc(ownerId, deckId)).delete();
  }
}
