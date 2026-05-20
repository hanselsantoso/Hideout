class FirestorePaths {
  static const users = 'users';
  static const tournaments = 'tournaments';
  static const registrations = 'registrations';
  static const payments = 'payments';
  static const rounds = 'rounds';
  static const matches = 'matches';
  static const battles = 'battles';
  static const decks = 'decks';
  static const communities = 'communities';
  static const communityApplications = 'communityApplications';
  static const components = 'components';
  static const componentStats = 'componentStats';
  static const weeklyComponentReleases = 'weeklyComponentReleases';
  static const withdrawals = 'withdrawals';
  static const notifications = 'notifications';

  static String userDoc(String uid) => '$users/$uid';
  static String userDecks(String uid) => '$users/$uid/$decks';
  static String userDeckDoc(String uid, String deckId) =>
      '$users/$uid/$decks/$deckId';
  static String tournamentDoc(String tournamentId) =>
      '$tournaments/$tournamentId';
  static String tournamentRegistrations(String tournamentId) =>
      '$tournaments/$tournamentId/$registrations';
  static String tournamentRegistrationDoc(
    String tournamentId,
    String registrationId,
  ) =>
      '$tournaments/$tournamentId/$registrations/$registrationId';
  static String tournamentPayments(String tournamentId) =>
      '$tournaments/$tournamentId/$payments';
  static String tournamentPaymentDoc(String tournamentId, String paymentId) =>
      '$tournaments/$tournamentId/$payments/$paymentId';
  static String tournamentRounds(String tournamentId) =>
      '$tournaments/$tournamentId/$rounds';
  static String tournamentMatches(String tournamentId, String roundId) =>
      '$tournaments/$tournamentId/$rounds/$roundId/$matches';
  static String tournamentMatchDoc(
    String tournamentId,
    String roundId,
    String matchId,
  ) =>
      '$tournaments/$tournamentId/$rounds/$roundId/$matches/$matchId';
  static String matchBattles(
    String tournamentId,
    String roundId,
    String matchId,
  ) =>
      '$tournaments/$tournamentId/$rounds/$roundId/$matches/$matchId/$battles';

  static String tournamentWithdrawals(String tournamentId) =>
      '$tournaments/$tournamentId/$withdrawals';
  static String componentStatDoc(String componentId) =>
      '$componentStats/$componentId';
  static String componentDoc(String componentId) => '$components/$componentId';
  static String weeklyComponentReleaseDoc(String releaseId) =>
      '$weeklyComponentReleases/$releaseId';
}
