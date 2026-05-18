import 'package:beytourney_hideout/core/constants/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds tournament registration paths', () {
    expect(
      FirestorePaths.tournamentRegistrationDoc('tourney-1', 'reg-1'),
      'tournaments/tourney-1/registrations/reg-1',
    );
  });

  test('builds user deck paths', () {
    expect(FirestorePaths.userDecks('user-1'), 'users/user-1/decks');
    expect(
      FirestorePaths.userDeckDoc('user-1', 'deck-1'),
      'users/user-1/decks/deck-1',
    );
  });
}
