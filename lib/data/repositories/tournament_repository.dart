import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/player_deck.dart';
import '../models/tournament_summary.dart';
import 'auth_repository.dart';

final functionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'asia-southeast1');
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(functionsProvider),
  );
});

final liveTournamentsProvider = StreamProvider<List<TournamentSummary>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchTournaments();
});

final assignedJudgeMatchesProvider =
    StreamProvider<List<JudgeMatchSummary>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<JudgeMatchSummary>>.value(const []);
  return ref.watch(tournamentRepositoryProvider).watchAssignedJudgeMatches(
        judgeId: user.uid,
      );
});

final assignableJudgesProvider = StreamProvider<List<AssignableJudge>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAssignableJudges();
});

final tournamentRegistrationsProvider =
    StreamProvider.family<List<TournamentRegistrationSummary>, String>(
  (ref, tournamentId) {
    if (tournamentId.isEmpty) {
      return Stream<List<TournamentRegistrationSummary>>.value(const []);
    }
    return ref
        .watch(tournamentRepositoryProvider)
        .watchTournamentRegistrations(tournamentId);
  },
);

final tournamentBracketProvider =
    StreamProvider.family<List<BracketRoundSummary>, String>(
  (ref, tournamentId) {
    if (tournamentId.isEmpty) {
      return Stream<List<BracketRoundSummary>>.value(const []);
    }
    return ref.watch(tournamentRepositoryProvider).watchTournamentBracket(
          tournamentId,
        );
  },
);

class TournamentRepository {
  TournamentRepository({required this.firestore, required this.functions});

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  Stream<List<TournamentSummary>> watchTournaments() {
    return firestore
        .collection(FirestorePaths.tournaments)
        .orderBy('startDate', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(TournamentSummary.fromFirestore).toList());
  }

  Stream<List<AssignableJudge>> watchAssignableJudges() {
    return firestore
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: 'judge')
        .limit(100)
        .snapshots()
        .map((snap) {
      final judges = snap.docs
          .map(AssignableJudge.fromFirestore)
          .where((judge) => judge.isJudge)
          .toList();
      judges.sort((a, b) => a.displayName.compareTo(b.displayName));
      return judges;
    });
  }

  Stream<List<TournamentRegistrationSummary>> watchTournamentRegistrations(
    String tournamentId,
  ) {
    return firestore
        .collection(FirestorePaths.tournamentRegistrations(tournamentId))
        .orderBy('registeredAt', descending: false)
        .limit(128)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(TournamentRegistrationSummary.fromFirestore)
          .toList();
    });
  }

  Stream<List<JudgeMatchSummary>> watchAssignedJudgeMatches({
    required String judgeId,
  }) {
    return firestore
        .collectionGroup(FirestorePaths.matches)
        .where('judgeId', isEqualTo: judgeId)
        .limit(50)
        .snapshots()
        .map((snap) {
      final matches = snap.docs.map(JudgeMatchSummary.fromFirestore).toList();
      matches.sort((a, b) {
        final status = a.statusRank.compareTo(b.statusRank);
        if (status != 0) return status;
        return a.matchCode.compareTo(b.matchCode);
      });
      return matches;
    });
  }

  Stream<List<BracketRoundSummary>> watchTournamentBracket(
    String tournamentId,
  ) {
    return firestore
        .collection(FirestorePaths.tournamentRounds(tournamentId))
        .orderBy('index')
        .limit(16)
        .snapshots()
        .asyncMap((roundSnap) async {
      final rounds = <BracketRoundSummary>[];
      for (final roundDoc in roundSnap.docs) {
        final roundData = roundDoc.data();
        final matchSnap = await roundDoc.reference
            .collection(FirestorePaths.matches)
            .orderBy('bracketPosition')
            .limit(128)
            .get();
        final matches = matchSnap.docs
            .map(BracketMatchNode.fromFirestore)
            .toList()
          ..sort((a, b) => a.bracketPosition.compareTo(b.bracketPosition));
        rounds.add(
          BracketRoundSummary(
            id: roundDoc.id,
            index: (roundData['index'] as num?)?.round() ??
                _roundIndexFromId(roundDoc.id),
            matches: matches,
          ),
        );
      }
      rounds.sort((a, b) => a.index.compareTo(b.index));
      return rounds;
    });
  }

  Future<String> createTournament({
    required String name,
    required String location,
    required int registrationFee,
    required int maxParticipants,
    required String bracketType,
    required int matchPointTarget,
    required DateTime startDate,
    required DateTime registrationDeadline,
    required int maxDecksPerPlayer,
    required List<String> prizes,
    String? organizerId,
    List<Map<String, dynamic>> stagePlan = const [],
  }) async {
    final payload = {
      'name': name.trim(),
      'description': 'Created from BeyTourney HIDEOUT',
      if (organizerId != null && organizerId.trim().isNotEmpty)
        'organizerId': organizerId.trim(),
      'location': location.trim(),
      'registrationFee': registrationFee,
      'feePolicy':
          TournamentFeePolicy.defaultsForNetFee(registrationFee).toFirestore(),
      'organizerPayout': {
        'netRegistrationFeePerPlayer': registrationFee,
        'status': 'notRequested',
      },
      'maxParticipants': maxParticipants,
      'bracketType': bracketType,
      'matchPointTarget': matchPointTarget,
      'startDate': startDate.toIso8601String(),
      'endDate': startDate.add(const Duration(hours: 6)).toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'rules': {
        'allowSameComboMultiple': false,
        'maxDecksPerPlayer': maxDecksPerPlayer,
        'penaltyThreshold': 2,
        'publicVisibility': {
          'showRules': true,
          'showBracket': true,
          'showGroupStandings': true,
          'showNextCall': true,
          'showResults': true,
        },
      },
      'stages': stagePlan.isEmpty ? _defaultTwoStagePlan() : stagePlan,
      'prizes': {
        'first': prizes.isNotEmpty ? prizes[0] : '',
        'second': prizes.length > 1 ? prizes[1] : '',
        'third': prizes.length > 2 ? prizes[2] : '',
      },
    };

    try {
      final callable = functions.httpsCallable('createTournament');
      final result = await callable.call(payload);
      final data = Map<String, dynamic>.from(result.data as Map);
      return (data['tournamentId'] ?? data['id'] ?? '').toString();
    } catch (_) {
      final ref = firestore.collection(FirestorePaths.tournaments).doc();
      await ref.set({
        ...payload,
        'status': 'draft',
        'currentParticipantCount': 0,
        'judgeIds': <String>[],
        'stadiumIds': <String>[],
        'stageStatus': {
          'stage1': 'draft',
          'stage2': 'waitingTopCut',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
  }

  Future<String> createRegistration({
    required String tournamentId,
    required String playerId,
    required String playerName,
    required String deckId,
    required String deckName,
    Map<String, dynamic>? deckSnapshot,
  }) async {
    final tournamentSnap =
        await firestore.doc(FirestorePaths.tournamentDoc(tournamentId)).get();
    final fee =
        (tournamentSnap.data()?['registrationFee'] as num?)?.round() ?? 0;
    final feePolicy = TournamentFeePolicy.fromMap(
      Map<String, dynamic>.from(
        tournamentSnap.data()?['feePolicy'] as Map? ?? const {},
      ),
      fallbackNetFee: fee,
    );
    final ref = firestore
        .collection(FirestorePaths.tournamentRegistrations(tournamentId))
        .doc();
    await ref.set({
      'id': ref.id,
      'tournamentId': tournamentId,
      'playerId': playerId,
      'playerName': playerName,
      'deckId': deckId,
      'deckName': deckName,
      if (deckSnapshot != null) 'deckSnapshot': deckSnapshot,
      'feePolicy': feePolicy.toFirestore(),
      'adminNetAmount': feePolicy.netFee,
      'userPayableAmount': feePolicy.userPayable,
      'platformFeeAmount': feePolicy.platformFee,
      'paymentGatewayFeeAmount': feePolicy.gatewayFee,
      'withdrawFeeCoverageAmount': feePolicy.withdrawFeeCoverage,
      'feeBorneBy': 'player',
      'paymentStatus': 'pending',
      'registrationStatus': 'pendingPayment',
      'registeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<int> generateFirstRoundMatches({
    required String tournamentId,
    required List<JudgeArenaAssignment> arenas,
    required int matchPointTarget,
  }) async {
    final liveArenas = arenas
        .where((arena) => arena.judgeIds.isNotEmpty)
        .map((arena) => arena.normalized)
        .where((arena) => arena.judgeIds.isNotEmpty)
        .toList();
    if (liveArenas.isEmpty) {
      throw StateError(
          'Select at least 1 live judge account before generating matches.');
    }

    final tournamentSnap =
        await firestore.doc(FirestorePaths.tournamentDoc(tournamentId)).get();
    final tournamentData = tournamentSnap.data() ?? {};
    final stages = (tournamentData['stages'] as List?) ?? const [];
    final firstStage = stages.isNotEmpty && stages.first is Map
        ? Map<String, dynamic>.from(stages.first as Map)
        : const <String, dynamic>{};
    final firstFormat = (firstStage['format'] ?? '').toString().toLowerCase();
    if (firstFormat.contains('roundrobin') ||
        firstFormat.contains('round_robin') ||
        firstFormat.contains('round robin')) {
      return _generateRoundRobinStage(
        tournamentId: tournamentId,
        arenas: liveArenas,
        matchPointTarget: matchPointTarget,
        stage: firstStage,
      );
    }

    final registrationSnap = await firestore
        .collection(FirestorePaths.tournamentRegistrations(tournamentId))
        .where('paymentStatus', isEqualTo: 'paid')
        .limit(128)
        .get();

    final registrations = registrationSnap.docs
        .where((doc) => doc.data()['registrationStatus'] == 'active')
        .toList()
      ..sort((a, b) {
        final aAt = a.data()['registeredAt'];
        final bAt = b.data()['registeredAt'];
        if (aAt is Timestamp && bAt is Timestamp) {
          return aAt.compareTo(bAt);
        }
        return a.id.compareTo(b.id);
      });

    if (registrations.length < 2) {
      throw StateError(
        'At least 2 participants with paid payment and active status are required.',
      );
    }

    const roundId = 'round-1';
    final bracketSize = _nextPowerOfTwo(registrations.length);
    final roundMatchCount = bracketSize ~/ 2;
    final byeCount = bracketSize - registrations.length;
    final activeMatchCount = roundMatchCount - byeCount;
    final batch = firestore.batch();
    final roundRef =
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              roundId,
            );
    batch.set(
      roundRef,
      {
        'id': roundId,
        'tournamentId': tournamentId,
        'name': 'Round 1',
        'index': 1,
        'format': 'openingRound',
        'status': 'ready',
        'matchCount': roundMatchCount,
        'activeMatchCount': activeMatchCount,
        'byeCount': byeCount,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final nextRoundByeSeeds = <int, Map<String, dynamic>>{};

    for (var i = 0; i < roundMatchCount; i++) {
      final isPlayable = i < activeMatchCount;
      final aIndex =
          isPlayable ? i * 2 : (activeMatchCount * 2) + (i - activeMatchCount);
      final bIndex = aIndex + 1;
      final a = registrations[aIndex];
      final b = isPlayable && bIndex < registrations.length
          ? registrations[bIndex]
          : null;
      final aData = a.data();
      final arena = liveArenas[i % liveArenas.length];
      final judgeIndex = i % arena.judgeIds.length;
      final judgeName = arena.judgeNames.isEmpty
          ? 'Judge'
          : arena.judgeNames[
              judgeIndex.clamp(0, arena.judgeNames.length - 1).toInt()];
      final matchId = 'm-${(i + 1).toString().padLeft(3, '0')}';
      final matchRef = firestore.doc(
        FirestorePaths.tournamentMatchDoc(tournamentId, roundId, matchId),
      );
      batch.set(
        matchRef,
        {
          'id': matchId,
          'tournamentId': tournamentId,
          'roundId': roundId,
          'matchCode': 'M-${(i + 1).toString().padLeft(3, '0')}',
          'status': b == null ? 'completed' : 'ready',
          'arena': arena.name,
          'judgeId': arena.judgeIds[judgeIndex],
          'judgeName': judgeName,
          'matchPointTarget': matchPointTarget,
          'playerAId': (aData['playerId'] ?? '').toString(),
          'playerAName': (aData['playerName'] ?? 'Player A').toString(),
          'playerADeckId': (aData['deckId'] ?? '').toString(),
          'playerADeckName':
              (aData['deckName'] ?? 'Registered Deck').toString(),
          'playerARegistrationId': a.id,
          if (aData['deckSnapshot'] != null)
            'playerADeckSnapshot': aData['deckSnapshot'],
          if (b != null) ...{
            'playerBId': (b.data()['playerId'] ?? '').toString(),
            'playerBName': (b.data()['playerName'] ?? 'Player B').toString(),
            'playerBDeckId': (b.data()['deckId'] ?? '').toString(),
            'playerBDeckName':
                (b.data()['deckName'] ?? 'Registered Deck').toString(),
            'playerBRegistrationId': b.id,
            if (b.data()['deckSnapshot'] != null)
              'playerBDeckSnapshot': b.data()['deckSnapshot'],
          } else ...{
            'playerBId': '',
            'playerBName': 'BYE',
            'playerBDeckId': '',
            'playerBDeckName': '-',
            'winnerId': (aData['playerId'] ?? '').toString(),
            'winnerName': (aData['playerName'] ?? 'Player').toString(),
            'finalScore': 'BYE',
            'bye': true,
          },
          'bracketPosition': i + 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (b == null && roundMatchCount > 1) {
        final advance = _buildAdvanceTarget(
          tournamentId: tournamentId,
          currentRoundId: roundId,
          currentRoundData: {
            'index': 1,
            'matchCount': roundMatchCount,
          },
          currentMatchData: {
            'id': matchId,
            'bracketPosition': i + 1,
          },
        );
        if (advance != null) {
          final target = nextRoundByeSeeds.putIfAbsent(
            advance.nextPosition,
            () => <String, dynamic>{
              'id': advance.nextMatchId,
              'tournamentId': tournamentId,
              'roundId': advance.nextRoundId,
              'matchCode':
                  'R${advance.nextRoundIndex}-M${advance.nextPosition.toString().padLeft(3, '0')}',
              'arena': arena.name,
              'judgeId': arena.judgeIds[judgeIndex],
              'judgeName': judgeName,
              'matchPointTarget': matchPointTarget,
              'bracketPosition': advance.nextPosition,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
          target
            ..['sourceMatch${advance.side}Id'] = matchId
            ..['player${advance.side}Id'] = (aData['playerId'] ?? '').toString()
            ..['player${advance.side}Name'] =
                (aData['playerName'] ?? 'Player').toString()
            ..['player${advance.side}DeckId'] =
                (aData['deckId'] ?? '').toString()
            ..['player${advance.side}DeckName'] =
                (aData['deckName'] ?? 'Registered Deck').toString()
            ..['player${advance.side}RegistrationId'] = a.id
            ..['advanceNext${advance.side}Ready'] = true;
          if (aData['deckSnapshot'] != null) {
            target['player${advance.side}DeckSnapshot'] = aData['deckSnapshot'];
          }
        }
      }
    }

    if (nextRoundByeSeeds.isNotEmpty) {
      final nextMatchCount = (roundMatchCount / 2).ceil();
      final nextRoundRef = firestore
          .collection(FirestorePaths.tournamentRounds(tournamentId))
          .doc('round-2');
      batch.set(
        nextRoundRef,
        {
          'id': 'round-2',
          'tournamentId': tournamentId,
          'name': 'Round 2',
          'index': 2,
          'format': 'singleElimination',
          'status': 'waiting',
          'matchCount': nextMatchCount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      for (final entry in nextRoundByeSeeds.entries) {
        final data = entry.value;
        final hasA = data['advanceNextAReady'] == true;
        final hasB = data['advanceNextBReady'] == true;
        data['status'] = hasA && hasB ? 'ready' : 'waitingOpponent';
        final nextRef = firestore.doc(
          FirestorePaths.tournamentMatchDoc(
            tournamentId,
            'round-2',
            data['id'].toString(),
          ),
        );
        batch.set(nextRef, data, SetOptions(merge: true));
      }
    }

    batch.set(
      firestore.doc(FirestorePaths.tournamentDoc(tournamentId)),
      {
        'status': 'ready',
        'currentRoundId': roundId,
        'bracketSize': bracketSize,
        'seededMatchCount': roundMatchCount,
        'activeMatchCount': activeMatchCount,
        'byeCount': byeCount,
        'matchSeededAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return roundMatchCount;
  }

  Future<void> saveTournamentGroupDraft({
    required String tournamentId,
    required List<TournamentGroupDraft> groups,
  }) async {
    if (groups.isEmpty) {
      throw StateError('Create at least 1 group before saving setup.');
    }
    await firestore.doc(FirestorePaths.tournamentDoc(tournamentId)).set(
      {
        'roundRobin': {
          'groupCount': groups.length,
          'assignmentMode': 'manualDraft',
          'draftGroups': [
            for (var i = 0; i < groups.length; i++)
              groups[i].toFirestore(index: i),
          ],
          'draftUpdatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<int> _generateRoundRobinStage({
    required String tournamentId,
    required List<JudgeArenaAssignment> arenas,
    required int matchPointTarget,
    required Map<String, dynamic> stage,
  }) async {
    final registrationSnap = await firestore
        .collection(FirestorePaths.tournamentRegistrations(tournamentId))
        .where('paymentStatus', isEqualTo: 'paid')
        .limit(256)
        .get();

    final registrations = registrationSnap.docs
        .where((doc) => doc.data()['registrationStatus'] == 'active')
        .toList()
      ..sort((a, b) {
        final aAt = a.data()['registeredAt'];
        final bAt = b.data()['registeredAt'];
        if (aAt is Timestamp && bAt is Timestamp) {
          return aAt.compareTo(bAt);
        }
        return a.id.compareTo(b.id);
      });

    if (registrations.length < 2) {
      throw StateError(
        'At least 2 participants with paid payment and active status are required.',
      );
    }

    final tournamentSnap =
        await firestore.doc(FirestorePaths.tournamentDoc(tournamentId)).get();
    final tournamentData = tournamentSnap.data() ?? const <String, dynamic>{};
    final roundRobinData = Map<String, dynamic>.from(
      tournamentData['roundRobin'] as Map? ?? const <String, dynamic>{},
    );
    final requestedGroups = (roundRobinData['groupCount'] as num?)?.round() ??
        (stage['groupCount'] as num?)?.round() ??
        4;
    final advancePerGroup = ((stage['advancePerGroup'] as num?)?.round() ?? 4)
        .clamp(1, registrations.length)
        .toInt();
    final groups = _manualRoundRobinGroups(
          registrations,
          roundRobinData['draftGroups'],
        ) ??
        _autoRoundRobinGroups(registrations, requestedGroups);

    var matchCounter = 0;
    final batch = firestore.batch();
    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final groupName = groups[groupIndex].name;
      final groupCode = _groupCode(groupIndex);
      final roundId = 'stage-1-group-${groupIndex + 1}';
      final roundRef = firestore
          .collection(FirestorePaths.tournamentRounds(tournamentId))
          .doc(
            roundId,
          );
      final group = groups[groupIndex].registrations;
      final matchCount = group.length * (group.length - 1) ~/ 2;
      batch.set(
        roundRef,
        {
          'id': roundId,
          'tournamentId': tournamentId,
          'name': groupName,
          'index': groupIndex + 1,
          'format': 'roundRobin',
          'stage': 1,
          'status': 'ready',
          'groupName': groupName,
          'matchCount': matchCount,
          'advancePerGroup': advancePerGroup,
          'tiebreaker':
              'Match win percentage, point difference, head-to-head, sudden death',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      var position = 0;
      for (var aIndex = 0; aIndex < group.length; aIndex++) {
        for (var bIndex = aIndex + 1; bIndex < group.length; bIndex++) {
          position++;
          matchCounter++;
          final a = group[aIndex];
          final b = group[bIndex];
          final aData = a.data();
          final bData = b.data();
          final arena = arenas[matchCounter % arenas.length];
          final judgeIndex = matchCounter % arena.judgeIds.length;
          final matchId = 'm-${position.toString().padLeft(3, '0')}';
          batch.set(
            firestore.doc(
              FirestorePaths.tournamentMatchDoc(tournamentId, roundId, matchId),
            ),
            {
              'id': matchId,
              'tournamentId': tournamentId,
              'roundId': roundId,
              'matchCode': '$groupCode-${position.toString().padLeft(3, '0')}',
              'status': position == 1 ? 'ready' : 'queued',
              'stage': 1,
              'format': 'roundRobin',
              'groupName': groupName,
              'arena': arena.name,
              'judgeId': arena.judgeIds[judgeIndex],
              'judgeName': arena.judgeNames.isEmpty
                  ? 'Judge'
                  : arena.judgeNames[
                      judgeIndex.clamp(0, arena.judgeNames.length - 1).toInt()],
              'matchPointTarget': matchPointTarget,
              'playerAId': (aData['playerId'] ?? '').toString(),
              'playerAName': (aData['playerName'] ?? 'Player A').toString(),
              'playerADeckId': (aData['deckId'] ?? '').toString(),
              'playerADeckName':
                  (aData['deckName'] ?? 'Registered Deck').toString(),
              'playerARegistrationId': a.id,
              if (aData['deckSnapshot'] != null)
                'playerADeckSnapshot': aData['deckSnapshot'],
              'playerBId': (bData['playerId'] ?? '').toString(),
              'playerBName': (bData['playerName'] ?? 'Player B').toString(),
              'playerBDeckId': (bData['deckId'] ?? '').toString(),
              'playerBDeckName':
                  (bData['deckName'] ?? 'Registered Deck').toString(),
              'playerBRegistrationId': b.id,
              if (bData['deckSnapshot'] != null)
                'playerBDeckSnapshot': bData['deckSnapshot'],
              'bracketPosition': position,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
    }

    batch.set(
      firestore.doc(FirestorePaths.tournamentDoc(tournamentId)),
      {
        'status': 'running',
        'currentStage': 1,
        'currentRoundId': 'stage-1-group-1',
        'stageStatus': {
          'stage1': 'running',
          'stage2': 'waitingTopCut',
        },
        'roundRobin': {
          ...roundRobinData,
          'groupCount': groups.length,
          'advancePerGroup': advancePerGroup,
          'totalMatches': matchCounter,
          'groupNames': [for (final group in groups) group.name],
        },
        'topCutFormat': 'doubleElimination',
        'matchSeededAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return matchCounter;
  }

  Future<int> generateDoubleEliminationTopCut({
    required String tournamentId,
    required List<JudgeArenaAssignment> arenas,
    required int matchPointTarget,
  }) async {
    final liveArenas = arenas
        .where((arena) => arena.judgeIds.isNotEmpty)
        .map((arena) => arena.normalized)
        .where((arena) => arena.judgeIds.isNotEmpty)
        .toList();
    if (liveArenas.isEmpty) {
      throw StateError('Select at least 1 live judge account.');
    }

    final roundsSnap = await firestore
        .collection(FirestorePaths.tournamentRounds(tournamentId))
        .where('format', isEqualTo: 'roundRobin')
        .get();
    final topCut = <_TopCutPlayer>[];
    for (final round in roundsSnap.docs) {
      final advancePerGroup =
          (round.data()['advancePerGroup'] as num?)?.round() ?? 4;
      final standingSnap = await round.reference
          .collection('standings')
          .orderBy('points', descending: true)
          .orderBy('pointDiff', descending: true)
          .limit(advancePerGroup)
          .get();
      for (final doc in standingSnap.docs) {
        final data = doc.data();
        topCut.add(
          _TopCutPlayer(
            id: (data['playerId'] ?? doc.id).toString(),
            name: (data['playerName'] ?? 'Player').toString(),
            seedScore: (data['points'] as num?)?.round() ?? 0,
          ),
        );
      }
    }

    if (topCut.length < 2) {
      throw StateError(
          'Top cut is not ready yet. Complete the round robin standings.');
    }

    topCut.sort((a, b) {
      final score = b.seedScore.compareTo(a.seedScore);
      if (score != 0) return score;
      return a.name.compareTo(b.name);
    });

    final bracketSize = _nextPowerOfTwo(topCut.length);
    final padded = [
      ...topCut,
      for (var i = topCut.length; i < bracketSize; i++)
        const _TopCutPlayer(id: 'bye', name: 'BYE', seedScore: -1),
    ];
    final matchCount = bracketSize ~/ 2;
    const upperRoundId = 'stage-2-upper-1';
    const lowerRoundId = 'stage-2-lower-1';
    final batch = firestore.batch();
    final upperRoundRef =
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              upperRoundId,
            );
    batch.set(
      upperRoundRef,
      {
        'id': upperRoundId,
        'tournamentId': tournamentId,
        'name': 'Stage 2 Upper Round 1',
        'index': 201,
        'format': 'doubleElimination',
        'bracket': 'upper',
        'stage': 2,
        'status': 'ready',
        'matchCount': matchCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
            lowerRoundId,
          ),
      {
        'id': lowerRoundId,
        'tournamentId': tournamentId,
        'name': 'Stage 2 Lower Round 1',
        'index': 301,
        'format': 'doubleElimination',
        'bracket': 'lower',
        'stage': 2,
        'status': 'waitingLosers',
        'matchCount': matchCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (var i = 0; i < matchCount; i++) {
      final a = padded[i];
      final b = padded[padded.length - 1 - i];
      final arena = liveArenas[i % liveArenas.length];
      final judgeIndex = i % arena.judgeIds.length;
      final matchId = 'u1-${(i + 1).toString().padLeft(3, '0')}';
      batch.set(
        firestore.doc(
          FirestorePaths.tournamentMatchDoc(
            tournamentId,
            upperRoundId,
            matchId,
          ),
        ),
        {
          'id': matchId,
          'tournamentId': tournamentId,
          'roundId': upperRoundId,
          'matchCode': 'U1-${(i + 1).toString().padLeft(3, '0')}',
          'status': b.id == 'bye' ? 'completed' : 'ready',
          'stage': 2,
          'format': 'doubleElimination',
          'bracket': 'upper',
          'arena': arena.name,
          'judgeId': arena.judgeIds[judgeIndex],
          'judgeName': arena.judgeNames.isEmpty
              ? 'Judge'
              : arena.judgeNames[
                  judgeIndex.clamp(0, arena.judgeNames.length - 1).toInt()],
          'matchPointTarget': matchPointTarget,
          'playerAId': a.id,
          'playerAName': a.name,
          'playerADeckName': 'Top cut registered deck',
          'playerBId': b.id == 'bye' ? '' : b.id,
          'playerBName': b.name,
          'playerBDeckName': b.id == 'bye' ? '-' : 'Top cut registered deck',
          if (b.id == 'bye') ...{
            'winnerId': a.id,
            'winnerName': a.name,
            'finalScore': 'BYE',
            'bye': true,
          },
          'bracketPosition': i + 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      firestore.doc(FirestorePaths.tournamentDoc(tournamentId)),
      {
        'status': 'running',
        'currentStage': 2,
        'currentRoundId': upperRoundId,
        'stageStatus': {
          'stage1': 'completed',
          'stage2': 'running',
        },
        'topCut': {
          'format': 'doubleElimination',
          'size': bracketSize,
          'seededPlayers': topCut.length,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return matchCount;
  }

  Future<JudgeRegistrationSnapshot?> findRegistrationForJudge({
    String? registrationId,
  }) async {
    Query<Map<String, dynamic>> query =
        firestore.collectionGroup(FirestorePaths.registrations);
    final trimmed = registrationId?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      final snap = await query.where('id', isEqualTo: trimmed).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return JudgeRegistrationSnapshot.fromFirestore(snap.docs.first);
      }
    }

    final latest =
        await query.orderBy('registeredAt', descending: true).limit(1).get();
    if (latest.docs.isEmpty) return null;
    return JudgeRegistrationSnapshot.fromFirestore(latest.docs.first);
  }

  Future<void> markRegistrationCheckIn({
    required JudgeRegistrationSnapshot registration,
    required bool accepted,
    required bool matchVerification,
    required Map<String, bool> checks,
  }) async {
    await registration.reference.set({
      if (matchVerification)
        'deckVerificationStatus': accepted ? 'verified' : 'rejected'
      else
        'checkInStatus': accepted ? 'checkedIn' : 'rejected',
      'judgeChecks': checks,
      'lastJudgeActionAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> submitMatchScore({
    required String tournamentId,
    required String roundId,
    required String matchId,
    required String judgeId,
    required String playerAId,
    required String playerAName,
    required String playerBId,
    required String playerBName,
    required String winnerId,
    required String winnerName,
    required int scoreA,
    required int scoreB,
    required List<Map<String, dynamic>> rounds,
  }) async {
    final battleRef = firestore
        .collection(FirestorePaths.matchBattles(tournamentId, roundId, matchId))
        .doc();
    final matchRef = firestore.doc(
      FirestorePaths.tournamentMatchDoc(tournamentId, roundId, matchId),
    );
    final roundRef = firestore.doc(
      '${FirestorePaths.tournamentRounds(tournamentId)}/$roundId',
    );
    final tournamentRef =
        firestore.doc(FirestorePaths.tournamentDoc(tournamentId));
    await firestore.runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      final roundSnap = await tx.get(roundRef);
      final tournamentSnap = await tx.get(tournamentRef);
      final matchData = matchSnap.data() ?? {};
      final roundData = roundSnap.data() ?? {};
      final tournamentData = tournamentSnap.data() ?? {};
      final isRoundRobin =
          (roundData['format'] ?? '').toString().toLowerCase() == 'roundrobin';
      final isDoubleElimination =
          (roundData['format'] ?? '').toString().toLowerCase() ==
              'doubleelimination';
      final playerARef = firestore.doc(FirestorePaths.userDoc(playerAId));
      final playerBRef = firestore.doc(FirestorePaths.userDoc(playerBId));
      final playerASnap = await tx.get(playerARef);
      final playerBSnap = await tx.get(playerBRef);
      final advanceTarget = isRoundRobin || isDoubleElimination
          ? null
          : _buildAdvanceTarget(
              tournamentId: tournamentId,
              currentRoundId: roundId,
              currentRoundData: roundData,
              currentMatchData: matchData,
            );
      final nextMatchData = advanceTarget == null
          ? null
          : (await tx.get(advanceTarget.nextMatchRef)).data();
      tx.set(battleRef, {
        'id': battleRef.id,
        'tournamentId': tournamentId,
        'roundId': roundId,
        'matchId': matchId,
        'judgeId': judgeId,
        'playerAId': playerAId,
        'playerAName': playerAName,
        'playerBId': playerBId,
        'playerBName': playerBName,
        'winnerId': winnerId,
        'winnerName': winnerName,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'rounds': rounds,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
          matchRef,
          {
            'status': 'completed',
            'winnerId': winnerId,
            'winnerName': winnerName,
            'finalScore': '$scoreA-$scoreB',
            'lastBattleId': battleRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      tx.set(
        roundRef,
        {'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      _writePerformanceStats(
        tx: tx,
        tournamentId: tournamentId,
        matchData: matchData,
        playerARef: playerARef,
        playerBRef: playerBRef,
        playerAData: playerASnap.data() ?? const {},
        playerBData: playerBSnap.data() ?? const {},
        playerAId: playerAId,
        playerBId: playerBId,
        winnerId: winnerId,
        scoreA: scoreA,
        scoreB: scoreB,
      );
      if (isRoundRobin) {
        _writeRoundRobinStandings(
          tx: tx,
          tournamentId: tournamentId,
          roundId: roundId,
          groupName: (roundData['groupName'] ?? 'Group').toString(),
          playerAId: playerAId,
          playerAName: playerAName,
          playerBId: playerBId,
          playerBName: playerBName,
          winnerId: winnerId,
          scoreA: scoreA,
          scoreB: scoreB,
        );
      }
      _advanceWinnerInTransaction(
        tx: tx,
        tournamentRef: tournamentRef,
        tournamentId: tournamentId,
        tournamentData: tournamentData,
        currentRoundData: roundData,
        currentMatchData: matchData,
        advanceTarget: advanceTarget,
        existingNextMatchData: nextMatchData,
        winnerId: winnerId,
        winnerName: winnerName,
        scoreA: scoreA,
        scoreB: scoreB,
      );
    });
    return battleRef.id;
  }

  void _writePerformanceStats({
    required Transaction tx,
    required String tournamentId,
    required Map<String, dynamic> matchData,
    required DocumentReference<Map<String, dynamic>> playerARef,
    required DocumentReference<Map<String, dynamic>> playerBRef,
    required Map<String, dynamic> playerAData,
    required Map<String, dynamic> playerBData,
    required String playerAId,
    required String playerBId,
    required String winnerId,
    required int scoreA,
    required int scoreB,
  }) {
    if (playerAId.isEmpty || playerBId.isEmpty || playerBId == 'player-b') {
      return;
    }
    final aWon = winnerId == playerAId;
    final aElo = (playerAData['eloRating'] as num?)?.round() ?? 1000;
    final bElo = (playerBData['eloRating'] as num?)?.round() ?? 1000;
    final next = _eloResult(aElo, bElo, aWon);
    tx.set(
      playerARef,
      {
        'eloRating': next.a,
        'totalMatches': FieldValue.increment(1),
        'wins': FieldValue.increment(aWon ? 1 : 0),
        'losses': FieldValue.increment(aWon ? 0 : 1),
        'lastMatchAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    tx.set(
      playerBRef,
      {
        'eloRating': next.b,
        'totalMatches': FieldValue.increment(1),
        'wins': FieldValue.increment(aWon ? 0 : 1),
        'losses': FieldValue.increment(aWon ? 1 : 0),
        'lastMatchAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _writeDeckComponentStats(
      tx: tx,
      tournamentId: tournamentId,
      deckSnapshot: matchData['playerADeckSnapshot'],
      won: aWon,
      scoreFor: scoreA,
      scoreAgainst: scoreB,
    );
    _writeDeckComponentStats(
      tx: tx,
      tournamentId: tournamentId,
      deckSnapshot: matchData['playerBDeckSnapshot'],
      won: !aWon,
      scoreFor: scoreB,
      scoreAgainst: scoreA,
    );
  }

  void _writeRoundRobinStandings({
    required Transaction tx,
    required String tournamentId,
    required String roundId,
    required String groupName,
    required String playerAId,
    required String playerAName,
    required String playerBId,
    required String playerBName,
    required String winnerId,
    required int scoreA,
    required int scoreB,
  }) {
    final aWon = winnerId == playerAId;
    void writeRow({
      required String playerId,
      required String playerName,
      required bool won,
      required int scoreFor,
      required int scoreAgainst,
    }) {
      final ref = firestore
          .collection(
            '${FirestorePaths.tournamentRounds(tournamentId)}/$roundId/standings',
          )
          .doc(playerId);
      tx.set(
        ref,
        {
          'playerId': playerId,
          'playerName': playerName,
          'groupName': groupName,
          'matches': FieldValue.increment(1),
          'wins': FieldValue.increment(won ? 1 : 0),
          'losses': FieldValue.increment(won ? 0 : 1),
          'points': FieldValue.increment(won ? 3 : 0),
          'scoreFor': FieldValue.increment(scoreFor),
          'scoreAgainst': FieldValue.increment(scoreAgainst),
          'pointDiff': FieldValue.increment(scoreFor - scoreAgainst),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    writeRow(
      playerId: playerAId,
      playerName: playerAName,
      won: aWon,
      scoreFor: scoreA,
      scoreAgainst: scoreB,
    );
    writeRow(
      playerId: playerBId,
      playerName: playerBName,
      won: !aWon,
      scoreFor: scoreB,
      scoreAgainst: scoreA,
    );
  }

  void _writeDeckComponentStats({
    required Transaction tx,
    required String tournamentId,
    required Object? deckSnapshot,
    required bool won,
    required int scoreFor,
    required int scoreAgainst,
  }) {
    if (deckSnapshot is! Map) return;
    final parts = _componentPartsFromDeck(Map<String, dynamic>.from(
      deckSnapshot,
    ));
    for (final part in parts) {
      final ref = firestore.doc(FirestorePaths.componentStatDoc(part.id));
      tx.set(
        ref,
        {
          'partId': part.id,
          'name': part.name,
          'category': part.category,
          'line': part.line,
          'appearances': FieldValue.increment(1),
          'wins': FieldValue.increment(won ? 1 : 0),
          'losses': FieldValue.increment(won ? 0 : 1),
          'scoreFor': FieldValue.increment(scoreFor),
          'scoreAgainst': FieldValue.increment(scoreAgainst),
          'tournamentIds': FieldValue.arrayUnion([tournamentId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  _EloPair _eloResult(int a, int b, bool aWon) {
    const k = 32;
    final expectedA = 1 / (1 + mathPow10((b - a) / 400));
    final expectedB = 1 - expectedA;
    final scoreA = aWon ? 1 : 0;
    final scoreB = aWon ? 0 : 1;
    return _EloPair(
      (a + k * (scoreA - expectedA)).round(),
      (b + k * (scoreB - expectedB)).round(),
    );
  }

  void _advanceWinnerInTransaction({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> tournamentRef,
    required String tournamentId,
    required Map<String, dynamic> tournamentData,
    required Map<String, dynamic> currentRoundData,
    required Map<String, dynamic> currentMatchData,
    required _AdvanceTarget? advanceTarget,
    required Map<String, dynamic>? existingNextMatchData,
    required String winnerId,
    required String winnerName,
    required int scoreA,
    required int scoreB,
  }) {
    if ((currentRoundData['format'] ?? '').toString().toLowerCase() ==
        'roundrobin') {
      tx.set(
        tournamentRef,
        {
          'status': 'running',
          'currentStage': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }
    if ((currentRoundData['format'] ?? '').toString().toLowerCase() ==
        'doubleelimination') {
      _advanceDoubleEliminationInTransaction(
        tx: tx,
        tournamentRef: tournamentRef,
        tournamentId: tournamentId,
        tournamentData: tournamentData,
        currentRoundData: currentRoundData,
        currentMatchData: currentMatchData,
        winnerId: winnerId,
        winnerName: winnerName,
        scoreA: scoreA,
        scoreB: scoreB,
      );
      return;
    }
    final currentMatchCount =
        (currentRoundData['matchCount'] as num?)?.round() ?? 1;
    if (currentMatchCount <= 1 || advanceTarget == null) {
      tx.set(
        tournamentRef,
        {
          'status': 'completed',
          'winnerId': winnerId,
          'winnerName': winnerName,
          'finalScore': '$scoreA-$scoreB',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final winnerSide = winnerId == currentMatchData['playerAId'] ? 'A' : 'B';
    final opponentReady = existingNextMatchData?[
            'advanceNext${advanceTarget.opponentSide}Ready'] ==
        true;
    tx.set(
      advanceTarget.nextRoundRef,
      {
        'id': advanceTarget.nextRoundId,
        'tournamentId': tournamentId,
        'name': 'Round ${advanceTarget.nextRoundIndex}',
        'index': advanceTarget.nextRoundIndex,
        'format': 'singleElimination',
        'status': opponentReady ? 'ready' : 'waiting',
        'matchCount': advanceTarget.nextMatchCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    tx.set(
      advanceTarget.nextMatchRef,
      {
        'id': advanceTarget.nextMatchId,
        'tournamentId': tournamentId,
        'roundId': advanceTarget.nextRoundId,
        'matchCode':
            'R${advanceTarget.nextRoundIndex}-M${advanceTarget.nextPosition.toString().padLeft(3, '0')}',
        'status': opponentReady ? 'ready' : 'waitingOpponent',
        'arena': (currentMatchData['arena'] ?? 'Arena').toString(),
        'judgeId': (currentMatchData['judgeId'] ?? '').toString(),
        'judgeName': (currentMatchData['judgeName'] ?? 'Judge').toString(),
        'matchPointTarget': currentMatchData['matchPointTarget'] ?? 4,
        'bracketPosition': advanceTarget.nextPosition,
        'sourceMatch${advanceTarget.side}Id': currentMatchData['id'] ?? '',
        'player${advanceTarget.side}Id': winnerId,
        'player${advanceTarget.side}Name': winnerName,
        'player${advanceTarget.side}DeckId':
            (currentMatchData['player${winnerSide}DeckId'] ?? '').toString(),
        'player${advanceTarget.side}DeckName':
            (currentMatchData['player${winnerSide}DeckName'] ??
                    'Registered Deck')
                .toString(),
        'player${advanceTarget.side}RegistrationId':
            currentMatchData['player${winnerSide}RegistrationId']?.toString(),
        if (currentMatchData['player${winnerSide}DeckSnapshot'] != null)
          'player${advanceTarget.side}DeckSnapshot':
              currentMatchData['player${winnerSide}DeckSnapshot'],
        'advanceNext${advanceTarget.side}Ready': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    tx.set(
      tournamentRef,
      {
        'status': 'running',
        'currentRoundId': advanceTarget.nextRoundId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _advanceDoubleEliminationInTransaction({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> tournamentRef,
    required String tournamentId,
    required Map<String, dynamic> tournamentData,
    required Map<String, dynamic> currentRoundData,
    required Map<String, dynamic> currentMatchData,
    required String winnerId,
    required String winnerName,
    required int scoreA,
    required int scoreB,
  }) {
    final bracket = (currentRoundData['bracket'] ?? 'upper').toString();
    final currentRoundId =
        (currentMatchData['roundId'] ?? currentRoundData['id'] ?? '')
            .toString();
    final roundNo = _doubleRoundNumber(currentRoundId);
    final matchCount = (currentRoundData['matchCount'] as num?)?.round() ?? 1;
    final position =
        (currentMatchData['bracketPosition'] as num?)?.round() ?? 1;
    final winnerSide = winnerId == currentMatchData['playerAId'] ? 'A' : 'B';
    final loserSide = winnerSide == 'A' ? 'B' : 'A';
    final targetSide = position.isOdd ? 'A' : 'B';
    final winnerPayload = _playerPayloadFromMatchSide(
      currentMatchData,
      winnerSide,
      targetSide: targetSide,
    );

    if (bracket == 'grandFinal') {
      tx.set(
        tournamentRef,
        {
          'status': 'completed',
          'currentStage': 2,
          'winnerId': winnerId,
          'winnerName': winnerName,
          'winnerDeckName': (currentMatchData['player${winnerSide}DeckName'] ??
                  'Registered Deck')
              .toString(),
          if (currentMatchData['player${winnerSide}DeckSnapshot'] != null)
            'winnerDeckSnapshot':
                currentMatchData['player${winnerSide}DeckSnapshot'],
          'finalScore': '$scoreA-$scoreB',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }
    final loserPayload = _playerPayloadFromMatchSide(
      currentMatchData,
      loserSide,
      targetSide: targetSide,
    );

    tx.set(
      tournamentRef,
      {
        'status': 'running',
        'currentStage': 2,
        'latestStage2Result': {
          'matchId': currentMatchData['id'] ?? '',
          'roundId': currentRoundId,
          'bracket': bracket,
          'winnerId': winnerId,
          'winnerName': winnerName,
          'winnerDeckName': (currentMatchData['player${winnerSide}DeckName'] ??
                  'Registered Deck')
              .toString(),
          'finalScore': '$scoreA-$scoreB',
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (bracket == 'upper' && matchCount > 1) {
      final nextRoundNo = roundNo + 1;
      final nextRoundId = 'stage-2-upper-$nextRoundNo';
      final nextPosition = ((position + 1) / 2).floor();
      final nextMatchId =
          'u$nextRoundNo-${nextPosition.toString().padLeft(3, '0')}';
      final nextMatchCount = (matchCount / 2).ceil();
      final nextSide = position.isOdd ? 'A' : 'B';
      final status = nextSide == 'B' ? 'ready' : 'waitingOpponent';
      tx.set(
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              nextRoundId,
            ),
        {
          'id': nextRoundId,
          'tournamentId': tournamentId,
          'name': 'Stage 2 Upper Round $nextRoundNo',
          'index': 200 + nextRoundNo,
          'format': 'doubleElimination',
          'bracket': 'upper',
          'stage': 2,
          'status': 'running',
          'matchCount': nextMatchCount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        firestore.doc(
          FirestorePaths.tournamentMatchDoc(
            tournamentId,
            nextRoundId,
            nextMatchId,
          ),
        ),
        {
          'id': nextMatchId,
          'tournamentId': tournamentId,
          'roundId': nextRoundId,
          'matchCode':
              'U$nextRoundNo-${nextPosition.toString().padLeft(3, '0')}',
          'status': status,
          'stage': 2,
          'format': 'doubleElimination',
          'bracket': 'upper',
          'bracketPosition': nextPosition,
          ...winnerPayload,
          'advanceNext${nextSide}Ready': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else if (bracket == 'upper' && matchCount <= 1) {
      final finalist = {
        'winnerId': winnerId,
        'winnerName': winnerName,
        'winnerDeckName': (currentMatchData['player${winnerSide}DeckName'] ??
                'Registered Deck')
            .toString(),
        if (currentMatchData['player${winnerSide}DeckSnapshot'] != null)
          'winnerDeckSnapshot':
              currentMatchData['player${winnerSide}DeckSnapshot'],
      };
      tx.set(
        tournamentRef,
        {
          'grandFinalCandidate': finalist,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      final challenger = tournamentData['grandFinalChallenger'];
      if (challenger is Map) {
        _createGrandFinalInTransaction(
          tx: tx,
          tournamentId: tournamentId,
          candidate: finalist,
          challenger: Map<String, dynamic>.from(challenger),
        );
      }
    }

    if (bracket == 'upper' &&
        (loserPayload['player${targetSide}Id'] ?? '').toString().isNotEmpty) {
      final lowerRoundId = 'stage-2-lower-$roundNo';
      final lowerPosition = position;
      final lowerMatchId =
          'l$roundNo-${lowerPosition.toString().padLeft(3, '0')}';
      tx.set(
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              lowerRoundId,
            ),
        {
          'id': lowerRoundId,
          'tournamentId': tournamentId,
          'name': 'Stage 2 Lower Round $roundNo',
          'index': 300 + roundNo,
          'format': 'doubleElimination',
          'bracket': 'lower',
          'stage': 2,
          'status': 'running',
          'matchCount': matchCount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        firestore.doc(
          FirestorePaths.tournamentMatchDoc(
            tournamentId,
            lowerRoundId,
            lowerMatchId,
          ),
        ),
        {
          'id': lowerMatchId,
          'tournamentId': tournamentId,
          'roundId': lowerRoundId,
          'matchCode': 'L$roundNo-${lowerPosition.toString().padLeft(3, '0')}',
          'status': targetSide == 'B' ? 'ready' : 'waitingOpponent',
          'stage': 2,
          'format': 'doubleElimination',
          'bracket': 'lower',
          'bracketPosition': lowerPosition,
          ...loserPayload,
          'advanceNext${targetSide}Ready': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (bracket == 'lower') {
      if (matchCount <= 1) {
        final challenger = {
          'winnerId': winnerId,
          'winnerName': winnerName,
          'winnerDeckName': (currentMatchData['player${winnerSide}DeckName'] ??
                  'Registered Deck')
              .toString(),
          if (currentMatchData['player${winnerSide}DeckSnapshot'] != null)
            'winnerDeckSnapshot':
                currentMatchData['player${winnerSide}DeckSnapshot'],
        };
        tx.set(
          tournamentRef,
          {
            'grandFinalChallenger': challenger,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        final candidate = tournamentData['grandFinalCandidate'];
        if (candidate is Map) {
          _createGrandFinalInTransaction(
            tx: tx,
            tournamentId: tournamentId,
            candidate: Map<String, dynamic>.from(candidate),
            challenger: challenger,
          );
        }
        return;
      }
      final nextRoundNo = roundNo + 1;
      final nextRoundId = 'stage-2-lower-$nextRoundNo';
      final nextPosition = ((position + 1) / 2).floor();
      final nextMatchId =
          'l$nextRoundNo-${nextPosition.toString().padLeft(3, '0')}';
      final nextMatchCount = (matchCount / 2).ceil();
      tx.set(
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              nextRoundId,
            ),
        {
          'id': nextRoundId,
          'tournamentId': tournamentId,
          'name': 'Stage 2 Lower Round $nextRoundNo',
          'index': 300 + nextRoundNo,
          'format': 'doubleElimination',
          'bracket': 'lower',
          'stage': 2,
          'status': 'running',
          'matchCount': nextMatchCount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        firestore.doc(
          FirestorePaths.tournamentMatchDoc(
            tournamentId,
            nextRoundId,
            nextMatchId,
          ),
        ),
        {
          'id': nextMatchId,
          'tournamentId': tournamentId,
          'roundId': nextRoundId,
          'matchCode':
              'L$nextRoundNo-${nextPosition.toString().padLeft(3, '0')}',
          'status': position.isEven ? 'ready' : 'waitingOpponent',
          'stage': 2,
          'format': 'doubleElimination',
          'bracket': 'lower',
          'bracketPosition': nextPosition,
          ...winnerPayload,
          'advanceNext${position.isOdd ? 'A' : 'B'}Ready': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  void _createGrandFinalInTransaction({
    required Transaction tx,
    required String tournamentId,
    required Map<String, dynamic> candidate,
    required Map<String, dynamic> challenger,
  }) {
    const roundId = 'stage-2-grand-final';
    const matchId = 'grand-final';
    tx.set(
      firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
            roundId,
          ),
      {
        'id': roundId,
        'tournamentId': tournamentId,
        'name': 'Grand Final',
        'index': 999,
        'format': 'doubleElimination',
        'bracket': 'grandFinal',
        'stage': 2,
        'status': 'ready',
        'matchCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    tx.set(
      firestore.doc(
        FirestorePaths.tournamentMatchDoc(tournamentId, roundId, matchId),
      ),
      {
        'id': matchId,
        'tournamentId': tournamentId,
        'roundId': roundId,
        'matchCode': 'GRAND FINAL',
        'status': 'ready',
        'stage': 2,
        'format': 'doubleElimination',
        'bracket': 'grandFinal',
        'bracketPosition': 1,
        'playerAId': (candidate['winnerId'] ?? '').toString(),
        'playerAName': (candidate['winnerName'] ?? 'Upper winner').toString(),
        'playerADeckName':
            (candidate['winnerDeckName'] ?? 'Registered Deck').toString(),
        if (candidate['winnerDeckSnapshot'] != null)
          'playerADeckSnapshot': candidate['winnerDeckSnapshot'],
        'playerBId': (challenger['winnerId'] ?? '').toString(),
        'playerBName': (challenger['winnerName'] ?? 'Lower winner').toString(),
        'playerBDeckName':
            (challenger['winnerDeckName'] ?? 'Registered Deck').toString(),
        if (challenger['winnerDeckSnapshot'] != null)
          'playerBDeckSnapshot': challenger['winnerDeckSnapshot'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    tx.set(
      firestore.doc(FirestorePaths.tournamentDoc(tournamentId)),
      {
        'currentRoundId': roundId,
        'grandFinalReady': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  _AdvanceTarget? _buildAdvanceTarget({
    required String tournamentId,
    required String currentRoundId,
    required Map<String, dynamic> currentRoundData,
    required Map<String, dynamic> currentMatchData,
  }) {
    final currentMatchCount =
        (currentRoundData['matchCount'] as num?)?.round() ?? 1;
    if (currentMatchCount <= 1) return null;
    final currentRoundIndex = (currentRoundData['index'] as num?)?.round() ??
        _roundIndexFromId(currentRoundId);
    final currentPosition =
        (currentMatchData['bracketPosition'] as num?)?.round() ?? 1;
    final nextRoundIndex = currentRoundIndex + 1;
    final nextRoundId = 'round-$nextRoundIndex';
    final nextMatchCount = (currentMatchCount / 2).ceil();
    final nextPosition = ((currentPosition + 1) / 2).floor();
    final nextMatchId = 'm-${nextPosition.toString().padLeft(3, '0')}';
    final side = currentPosition.isOdd ? 'A' : 'B';
    final nextRoundRef =
        firestore.collection(FirestorePaths.tournamentRounds(tournamentId)).doc(
              nextRoundId,
            );
    final nextMatchRef = firestore.doc(
      FirestorePaths.tournamentMatchDoc(
        tournamentId,
        nextRoundId,
        nextMatchId,
      ),
    );
    return _AdvanceTarget(
      nextRoundRef: nextRoundRef,
      nextMatchRef: nextMatchRef,
      nextRoundId: nextRoundId,
      nextMatchId: nextMatchId,
      nextRoundIndex: nextRoundIndex,
      nextMatchCount: nextMatchCount,
      nextPosition: nextPosition,
      side: side,
    );
  }

  int _doubleRoundNumber(String roundId) {
    final match = RegExp(r'stage-2-(?:upper|lower)-(\d+)').firstMatch(roundId);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  Map<String, dynamic> _playerPayloadFromMatchSide(
    Map<String, dynamic> matchData,
    String sourceSide, {
    required String targetSide,
  }) {
    return {
      'player${targetSide}Id':
          (matchData['player${sourceSide}Id'] ?? '').toString(),
      'player${targetSide}Name':
          (matchData['player${sourceSide}Name'] ?? 'Player').toString(),
      'player${targetSide}DeckId':
          (matchData['player${sourceSide}DeckId'] ?? '').toString(),
      'player${targetSide}DeckName':
          (matchData['player${sourceSide}DeckName'] ?? 'Registered Deck')
              .toString(),
      'player${targetSide}RegistrationId':
          matchData['player${sourceSide}RegistrationId']?.toString(),
      if (matchData['player${sourceSide}DeckSnapshot'] != null)
        'player${targetSide}DeckSnapshot':
            matchData['player${sourceSide}DeckSnapshot'],
    };
  }

  int _roundIndexFromId(String roundId) {
    final match = RegExp(r'round-(\d+)').firstMatch(roundId);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  int _nextPowerOfTwo(int value) {
    var power = 1;
    while (power < value) {
      power *= 2;
    }
    return power;
  }

  Future<void> simulatePayment({
    required String tournamentId,
    required String registrationId,
  }) async {
    try {
      final callable = functions.httpsCallable('simulatePayment');
      await callable.call({
        'tournamentId': tournamentId,
        'registrationId': registrationId,
      });
    } catch (_) {
      await firestore
          .doc(FirestorePaths.tournamentRegistrationDoc(
        tournamentId,
        registrationId,
      ))
          .set({
        'paymentStatus': 'paid',
        'registrationStatus': 'active',
        'paymentId': 'AUTO-$registrationId',
        'paidAt': FieldValue.serverTimestamp(),
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<XenditPaymentSessionResult> createXenditPaymentSession({
    required String tournamentId,
    required String registrationId,
    required String appBaseUrl,
  }) async {
    final callable = functions.httpsCallable('createXenditPaymentSession');
    final response = await callable.call<Map<String, dynamic>>({
      'tournamentId': tournamentId,
      'registrationId': registrationId,
      'appBaseUrl': appBaseUrl,
    });
    return XenditPaymentSessionResult.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<XenditPaymentSessionResult> syncXenditPaymentSession({
    required String tournamentId,
    required String registrationId,
    String? paymentSessionId,
  }) async {
    final callable = functions.httpsCallable('syncXenditPaymentSession');
    final response = await callable.call<Map<String, dynamic>>({
      'tournamentId': tournamentId,
      'registrationId': registrationId,
      if (paymentSessionId != null) 'paymentSessionId': paymentSessionId,
    });
    return XenditPaymentSessionResult.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> activateTournamentRegistration({
    required String tournamentId,
    required String registrationId,
  }) async {
    final registrationRef = firestore.doc(
      FirestorePaths.tournamentRegistrationDoc(tournamentId, registrationId),
    );
    final tournamentRef = firestore.doc(FirestorePaths.tournamentDoc(
      tournamentId,
    ));
    await firestore.runTransaction((tx) async {
      final registrationSnap = await tx.get(registrationRef);
      final wasReady = registrationSnap.exists &&
          registrationSnap.data()?['paymentStatus'] == 'paid' &&
          registrationSnap.data()?['registrationStatus'] == 'active';
      tx.set(
        registrationRef,
        {
          'paymentStatus': 'paid',
          'registrationStatus': 'active',
          'paymentId': 'AUTO-$registrationId',
          'paidAt': FieldValue.serverTimestamp(),
          'activatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!wasReady) {
        tx.set(
          tournamentRef,
          {
            'currentParticipantCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> markRegistrationWalkOut({
    required String tournamentId,
    required String registrationId,
  }) async {
    final registrationRef = firestore.doc(
      FirestorePaths.tournamentRegistrationDoc(tournamentId, registrationId),
    );
    final tournamentRef = firestore.doc(FirestorePaths.tournamentDoc(
      tournamentId,
    ));
    await firestore.runTransaction((tx) async {
      final registrationSnap = await tx.get(registrationRef);
      final data = registrationSnap.data() ?? const <String, dynamic>{};
      final wasReady = data['paymentStatus'] == 'paid' &&
          data['registrationStatus'] == 'active';
      final tournamentSnap = await tx.get(tournamentRef);
      final currentCount =
          (tournamentSnap.data()?['currentParticipantCount'] as num?)
                  ?.round() ??
              0;
      tx.set(
        registrationRef,
        {
          'registrationStatus': 'walkOut',
          'walkOutAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (wasReady) {
        tx.set(
          tournamentRef,
          {
            'currentParticipantCount': math.max(0, currentCount - 1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<String> requestTournamentWithdrawal({
    required String tournamentId,
    required String requesterId,
    required String requesterName,
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final ref = firestore
        .collection(FirestorePaths.tournamentWithdrawals(tournamentId))
        .doc();
    await firestore.runTransaction((tx) async {
      final tournamentRef =
          firestore.doc(FirestorePaths.tournamentDoc(tournamentId));
      tx.set(ref, {
        'id': ref.id,
        'tournamentId': tournamentId,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'amount': amount,
        'bankName': bankName.trim(),
        'accountNumber': accountNumber.trim(),
        'accountName': accountName.trim(),
        'status': 'processing',
        'approvalMode': 'community_admin_auto',
        'source': 'community_admin_console',
        'feeBorneBy': 'player',
        'adminReceivesNetAmount': amount,
        'requestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        tournamentRef,
        {
          'organizerPayout': {
            'status': 'processing',
            'requestedAmount': amount,
            'lastWithdrawalId': ref.id,
            'feeBorneBy': 'player',
            'approvalMode': 'community_admin_auto',
            'requestedBy': requesterId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    return ref.id;
  }

  List<Map<String, dynamic>> _defaultTwoStagePlan() {
    return const [
      {
        'index': 0,
        'name': 'Stage 1',
        'format': 'roundRobin',
        'bestOf': 'BO3',
        'advance': 16,
        'groupCount': 4,
        'advancePerGroup': 4,
        'publicVisibility': true,
      },
      {
        'index': 1,
        'name': 'Stage 2',
        'format': 'doubleElimination',
        'bestOf': 'BO5',
        'advance': 0,
        'publicVisibility': true,
      },
    ];
  }
}

Set<String> _rolesFromUserData(Map<String, dynamic> data) {
  final roles = <String>{};
  final role = data['role']?.toString();
  if (role != null && role.trim().isNotEmpty) roles.add(_normalizeRole(role));
  for (final key in ['roles', 'roleClaims', 'capabilities']) {
    final value = data[key];
    if (value is Iterable) {
      roles.addAll(value.map((item) => _normalizeRole(item.toString())));
    }
  }
  roles.removeWhere((role) => role.isEmpty);
  return roles.isEmpty ? {'player'} : roles;
}

List<_ComponentStatPart> _componentPartsFromDeck(Map<String, dynamic> deck) {
  final seen = <String>{};
  final parts = <_ComponentStatPart>[];
  final combos = deck['combos'];
  if (combos is! Iterable) return parts;
  for (final combo in combos) {
    if (combo is! Map) continue;
    for (final key in [
      'blade',
      'assistBlade',
      'overBlade',
      'lockChip',
      'ratchet',
      'bit',
    ]) {
      final raw = combo[key];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final id = (map['partId'] ?? '').toString();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      parts.add(
        _ComponentStatPart(
          id: id,
          name: (map['name'] ?? id).toString(),
          category: (map['category'] ?? key).toString(),
          line: (map['line'] ?? '').toString(),
        ),
      );
    }
  }
  return parts;
}

double mathPow10(double exponent) {
  return math.pow(10, exponent).toDouble();
}

String _normalizeRole(String role) {
  final value = role.trim().toLowerCase();
  if (value == 'superadmin') return 'super_admin';
  if (value == 'communityadmin') return 'community_admin';
  if (value == 'juri') return 'judge';
  return value;
}

String? _winnerDeckName(String? winnerName, Map<String, dynamic> data) {
  if (winnerName == null) return null;
  if (winnerName == data['playerAName']) {
    return data['playerADeckName']?.toString();
  }
  if (winnerName == data['playerBName']) {
    return data['playerBDeckName']?.toString();
  }
  return data['winnerDeckName']?.toString();
}

class _ComponentStatPart {
  const _ComponentStatPart({
    required this.id,
    required this.name,
    required this.category,
    required this.line,
  });

  final String id;
  final String name;
  final String category;
  final String line;
}

class _EloPair {
  const _EloPair(this.a, this.b);

  final int a;
  final int b;
}

class _TopCutPlayer {
  const _TopCutPlayer({
    required this.id,
    required this.name,
    required this.seedScore,
  });

  final String id;
  final String name;
  final int seedScore;
}

class TournamentFeePolicy {
  const TournamentFeePolicy({
    required this.netFee,
    required this.platformFee,
    required this.gatewayFee,
    required this.withdrawFeeCoverage,
  });

  final int netFee;
  final int platformFee;
  final int gatewayFee;
  final int withdrawFeeCoverage;

  int get userPayable =>
      netFee + platformFee + gatewayFee + withdrawFeeCoverage;

  factory TournamentFeePolicy.defaultsForNetFee(int netFee) {
    return TournamentFeePolicy(
      netFee: netFee,
      platformFee: (netFee * .10).round(),
      gatewayFee: (netFee * .03).round(),
      withdrawFeeCoverage: netFee <= 0 ? 0 : 500,
    );
  }

  factory TournamentFeePolicy.fromMap(
    Map<String, dynamic> map, {
    required int fallbackNetFee,
  }) {
    return TournamentFeePolicy(
      netFee: (map['netFee'] as num?)?.round() ?? fallbackNetFee,
      platformFee: (map['platformFee'] as num?)?.round() ??
          (fallbackNetFee * .10).round(),
      gatewayFee: (map['gatewayFee'] as num?)?.round() ??
          (fallbackNetFee * .03).round(),
      withdrawFeeCoverage: (map['withdrawFeeCoverage'] as num?)?.round() ??
          (fallbackNetFee <= 0 ? 0 : 500),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'netFee': netFee,
      'platformFee': platformFee,
      'gatewayFee': gatewayFee,
      'withdrawFeeCoverage': withdrawFeeCoverage,
      'userPayable': userPayable,
      'feeBorneBy': 'player',
      'adminReceives': netFee,
    };
  }
}

class _AdvanceTarget {
  final DocumentReference<Map<String, dynamic>> nextRoundRef;
  final DocumentReference<Map<String, dynamic>> nextMatchRef;
  final String nextRoundId;
  final String nextMatchId;
  final int nextRoundIndex;
  final int nextMatchCount;
  final int nextPosition;
  final String side;

  const _AdvanceTarget({
    required this.nextRoundRef,
    required this.nextMatchRef,
    required this.nextRoundId,
    required this.nextMatchId,
    required this.nextRoundIndex,
    required this.nextMatchCount,
    required this.nextPosition,
    required this.side,
  });

  String get opponentSide => side == 'A' ? 'B' : 'A';
}

class AssignableJudge {
  final String uid;
  final String displayName;
  final String role;
  final Set<String> roles;

  const AssignableJudge({
    required this.uid,
    required this.displayName,
    required this.role,
    this.roles = const {},
  });

  bool get isJudge => roles.contains('judge') || role == 'judge';

  factory AssignableJudge.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final roles = _rolesFromUserData(data);
    return AssignableJudge(
      uid: doc.id,
      displayName: (data['displayName'] ?? data['name'] ?? 'Judge').toString(),
      role: (data['role'] ?? 'judge').toString(),
      roles: roles,
    );
  }
}

class JudgeArenaAssignment {
  final String name;
  final List<String> judgeIds;
  final List<String> judgeNames;

  const JudgeArenaAssignment({
    required this.name,
    required this.judgeIds,
    required this.judgeNames,
  });

  JudgeArenaAssignment get normalized {
    final pairs = <MapEntry<String, String>>[];
    for (var i = 0; i < judgeIds.length; i++) {
      final id = judgeIds[i].trim();
      if (id.isEmpty || id.startsWith('fallback:')) continue;
      final name = i < judgeNames.length ? judgeNames[i].trim() : 'Judge';
      pairs.add(MapEntry(id, name.isEmpty ? 'Judge' : name));
    }
    return JudgeArenaAssignment(
      name: name.trim().isEmpty ? 'Arena' : name.trim(),
      judgeIds: [for (final pair in pairs) pair.key],
      judgeNames: [for (final pair in pairs) pair.value],
    );
  }
}

class TournamentRegistrationSummary {
  final String id;
  final String tournamentId;
  final String playerId;
  final String playerName;
  final String deckId;
  final String deckName;
  final String paymentStatus;
  final String registrationStatus;
  final DateTime? registeredAt;

  const TournamentRegistrationSummary({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.playerName,
    required this.deckId,
    required this.deckName,
    required this.paymentStatus,
    required this.registrationStatus,
    required this.registeredAt,
  });

  bool get readyForBracket =>
      paymentStatus == 'paid' && registrationStatus == 'active';

  factory TournamentRegistrationSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawDate = data['registeredAt'];
    return TournamentRegistrationSummary(
      id: (data['id'] ?? doc.id).toString(),
      tournamentId: (data['tournamentId'] ?? '').toString(),
      playerId: (data['playerId'] ?? '').toString(),
      playerName: (data['playerName'] ?? 'Player').toString(),
      deckId: (data['deckId'] ?? '').toString(),
      deckName: (data['deckName'] ?? 'Registered Deck').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'pending').toString(),
      registrationStatus: (data['registrationStatus'] ?? 'pending').toString(),
      registeredAt: rawDate is Timestamp ? rawDate.toDate() : null,
    );
  }
}

class XenditPaymentSessionResult {
  const XenditPaymentSessionResult({
    required this.paymentSessionId,
    required this.status,
    required this.paid,
    required this.expired,
    this.paymentLinkUrl,
    this.paymentId,
    this.paymentRequestId,
    this.message,
  });

  final String paymentSessionId;
  final String status;
  final bool paid;
  final bool expired;
  final String? paymentLinkUrl;
  final String? paymentId;
  final String? paymentRequestId;
  final String? message;

  bool get canOpenCheckout =>
      paymentLinkUrl != null && paymentLinkUrl!.trim().isNotEmpty;

  factory XenditPaymentSessionResult.fromMap(Map<String, dynamic> data) {
    return XenditPaymentSessionResult(
      paymentSessionId: (data['paymentSessionId'] ?? '').toString(),
      status: (data['status'] ?? 'ACTIVE').toString(),
      paid: data['paid'] == true,
      expired: data['expired'] == true,
      paymentLinkUrl: data['paymentLinkUrl']?.toString(),
      paymentId: data['paymentId']?.toString(),
      paymentRequestId: data['paymentRequestId']?.toString(),
      message: data['message']?.toString(),
    );
  }
}

class TournamentGroupDraft {
  const TournamentGroupDraft({
    required this.name,
    required this.players,
  });

  final String name;
  final List<TournamentRegistrationSummary> players;

  Map<String, dynamic> toFirestore({required int index}) {
    final cleanName = name.trim().isEmpty ? _defaultGroupName(index) : name;
    return {
      'name': cleanName,
      'index': index + 1,
      'playerCount': players.length,
      'players': [
        for (final player in players)
          {
            'registrationId': player.id,
            'playerId': player.playerId,
            'playerName': player.playerName,
            'deckId': player.deckId,
            'deckName': player.deckName,
            'paymentStatus': player.paymentStatus,
            'registrationStatus': player.registrationStatus,
          },
      ],
    };
  }
}

class _RoundRobinGroup {
  const _RoundRobinGroup({
    required this.name,
    required this.registrations,
  });

  final String name;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations;
}

List<_RoundRobinGroup> _autoRoundRobinGroups(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  int requestedGroups,
) {
  final groupCount =
      requestedGroups.clamp(1, math.max(1, registrations.length)).toInt();
  final groups = List.generate(
    groupCount,
    (index) => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
  );
  for (var i = 0; i < registrations.length; i++) {
    groups[i % groupCount].add(registrations[i]);
  }
  return [
    for (var i = 0; i < groups.length; i++)
      _RoundRobinGroup(name: _defaultGroupName(i), registrations: groups[i]),
  ];
}

List<_RoundRobinGroup>? _manualRoundRobinGroups(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> registrations,
  Object? rawDraft,
) {
  if (rawDraft is! Iterable) return null;
  final byRegistrationId = {
    for (final doc in registrations) doc.id: doc,
  };
  final byPlayerId = {
    for (final doc in registrations)
      (doc.data()['playerId'] ?? '').toString(): doc,
  }..remove('');
  final used = <String>{};
  final groups = <_RoundRobinGroup>[];

  var index = 0;
  for (final rawGroup in rawDraft) {
    if (rawGroup is! Map) continue;
    final data = Map<String, dynamic>.from(rawGroup);
    final rawPlayers = data['players'];
    final members = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    if (rawPlayers is Iterable) {
      for (final rawPlayer in rawPlayers) {
        String registrationId = '';
        String playerId = '';
        if (rawPlayer is Map) {
          registrationId = (rawPlayer['registrationId'] ?? '').toString();
          playerId = (rawPlayer['playerId'] ?? '').toString();
        } else {
          registrationId = rawPlayer.toString();
        }
        final doc = byRegistrationId[registrationId] ?? byPlayerId[playerId];
        if (doc == null || !used.add(doc.id)) continue;
        members.add(doc);
      }
    }
    groups.add(
      _RoundRobinGroup(
        name: (data['name'] ?? _defaultGroupName(index)).toString(),
        registrations: members,
      ),
    );
    index++;
  }

  if (groups.isEmpty) return null;
  final leftovers = registrations.where((doc) => !used.contains(doc.id));
  for (final doc in leftovers) {
    var targetIndex = 0;
    for (var i = 1; i < groups.length; i++) {
      if (groups[i].registrations.length <
          groups[targetIndex].registrations.length) {
        targetIndex = i;
      }
    }
    groups[targetIndex].registrations.add(doc);
  }
  return groups;
}

String _defaultGroupName(int index) {
  if (index < 26) return 'Group ${String.fromCharCode(65 + index)}';
  return 'Group ${index + 1}';
}

String _groupCode(int index) {
  if (index < 26) return String.fromCharCode(65 + index);
  return 'G${index + 1}';
}

class BracketRoundSummary {
  final String id;
  final int index;
  final List<BracketMatchNode> matches;

  const BracketRoundSummary({
    required this.id,
    required this.index,
    required this.matches,
  });

  String get label => index == 1 ? 'Round 1' : 'Round $index';
}

class BracketMatchNode {
  final String id;
  final String tournamentId;
  final String roundId;
  final int roundIndex;
  final int bracketPosition;
  final String matchCode;
  final String status;
  final String playerAName;
  final String playerADeckName;
  final String playerBName;
  final String playerBDeckName;
  final String? winnerName;
  final String? winnerDeckName;
  final String? finalScore;
  final bool bye;

  const BracketMatchNode({
    required this.id,
    required this.tournamentId,
    required this.roundId,
    required this.roundIndex,
    required this.bracketPosition,
    required this.matchCode,
    required this.status,
    required this.playerAName,
    this.playerADeckName = '-',
    required this.playerBName,
    this.playerBDeckName = '-',
    required this.winnerName,
    this.winnerDeckName,
    required this.finalScore,
    required this.bye,
  });

  bool get completed => status == 'completed';

  bool get waiting => status == 'waitingOpponent';

  factory BracketMatchNode.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final roundRef = doc.reference.parent.parent;
    final tournamentRef = roundRef?.parent.parent;
    final roundId = (data['roundId'] ?? roundRef?.id ?? '').toString();
    final roundMatch = RegExp(r'round-(\d+)').firstMatch(roundId);
    return BracketMatchNode(
      id: doc.id,
      tournamentId:
          (data['tournamentId'] ?? tournamentRef?.id ?? '').toString(),
      roundId: roundId,
      roundIndex: int.tryParse(roundMatch?.group(1) ?? '') ?? 1,
      bracketPosition: (data['bracketPosition'] as num?)?.round() ?? 1,
      matchCode: (data['matchCode'] ?? doc.id).toString(),
      status: (data['status'] ?? 'waitingOpponent').toString(),
      playerAName: (data['playerAName'] ?? 'TBD').toString(),
      playerADeckName: (data['playerADeckName'] ?? '-').toString(),
      playerBName: (data['playerBName'] ?? 'TBD').toString(),
      playerBDeckName: (data['playerBDeckName'] ?? '-').toString(),
      winnerName: data['winnerName']?.toString(),
      winnerDeckName: _winnerDeckName(data['winnerName']?.toString(), data),
      finalScore: data['finalScore']?.toString(),
      bye: data['bye'] == true,
    );
  }
}

class JudgeRegistrationSnapshot {
  final String id;
  final String tournamentId;
  final String playerId;
  final String playerName;
  final String deckId;
  final String deckName;
  final String paymentStatus;
  final String registrationStatus;
  final String? checkInStatus;
  final String? deckVerificationStatus;
  final PlayerDeck? deckSnapshot;
  final DocumentReference<Map<String, dynamic>> reference;

  const JudgeRegistrationSnapshot({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.playerName,
    required this.deckId,
    required this.deckName,
    required this.paymentStatus,
    required this.registrationStatus,
    required this.reference,
    this.checkInStatus,
    this.deckVerificationStatus,
    this.deckSnapshot,
  });

  factory JudgeRegistrationSnapshot.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawDeck = data['deckSnapshot'];
    final deckMap = rawDeck is Map ? Map<String, dynamic>.from(rawDeck) : null;
    return JudgeRegistrationSnapshot(
      id: (data['id'] ?? doc.id).toString(),
      tournamentId: (data['tournamentId'] ?? '').toString(),
      playerId: (data['playerId'] ?? '').toString(),
      playerName: (data['playerName'] ?? 'Player').toString(),
      deckId: (data['deckId'] ?? '').toString(),
      deckName: (data['deckName'] ?? 'Registered Deck').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'pending').toString(),
      registrationStatus: (data['registrationStatus'] ?? 'pending').toString(),
      checkInStatus: data['checkInStatus']?.toString(),
      deckVerificationStatus: data['deckVerificationStatus']?.toString(),
      deckSnapshot: deckMap == null
          ? null
          : PlayerDeck.fromMap(
              (deckMap['id'] ?? data['deckId'] ?? doc.id).toString(),
              deckMap,
            ),
      reference: doc.reference,
    );
  }
}

class JudgeMatchSummary {
  final String id;
  final String tournamentId;
  final String roundId;
  final String matchCode;
  final String status;
  final String arena;
  final String playerAId;
  final String playerAName;
  final String playerADeck;
  final String? playerARegistrationId;
  final String playerBId;
  final String playerBName;
  final String playerBDeck;
  final String? playerBRegistrationId;
  final String? winnerName;
  final String? finalScore;

  const JudgeMatchSummary({
    required this.id,
    required this.tournamentId,
    required this.roundId,
    required this.matchCode,
    required this.status,
    required this.arena,
    required this.playerAId,
    required this.playerAName,
    required this.playerADeck,
    required this.playerBId,
    required this.playerBName,
    required this.playerBDeck,
    this.playerARegistrationId,
    this.playerBRegistrationId,
    this.winnerName,
    this.finalScore,
  });

  int get statusRank {
    return switch (status) {
      'ready' => 0,
      'inProgress' => 1,
      'assigned' => 2,
      'waitingOpponent' => 3,
      'completed' => 9,
      _ => 4,
    };
  }

  bool get completed => status == 'completed';

  Map<String, dynamic> get scoreArguments {
    return {
      'tournamentId': tournamentId,
      'roundId': roundId,
      'matchId': id,
      'matchCode': matchCode,
      'arena': arena,
      'playerAId': playerAId,
      'playerAName': playerAName,
      'playerADeckName': playerADeck,
      'playerBId': playerBId,
      'playerBName': playerBName,
      'playerBDeckName': playerBDeck,
    };
  }

  Map<String, dynamic> scanArguments(String side) {
    return {
      'matchVerify': true,
      'matchId': id,
      'registrationId':
          side == 'A' ? playerARegistrationId : playerBRegistrationId,
    };
  }

  factory JudgeMatchSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final roundRef = doc.reference.parent.parent;
    final tournamentRef = roundRef?.parent.parent;
    return JudgeMatchSummary(
      id: doc.id,
      tournamentId:
          (data['tournamentId'] ?? tournamentRef?.id ?? '').toString(),
      roundId: (data['roundId'] ?? roundRef?.id ?? '').toString(),
      matchCode: (data['matchCode'] ?? data['code'] ?? doc.id).toString(),
      status: (data['status'] ?? 'assigned').toString(),
      arena: (data['arena'] ?? data['stadiumName'] ?? 'Arena').toString(),
      playerAId:
          (data['playerAId'] ?? data['player1Id'] ?? 'player-a').toString(),
      playerAName:
          (data['playerAName'] ?? data['player1Name'] ?? 'Player A').toString(),
      playerADeck: (data['playerADeckName'] ??
              data['player1DeckName'] ??
              data['deckAName'] ??
              '-')
          .toString(),
      playerARegistrationId:
          (data['playerARegistrationId'] ?? data['registrationAId'])
              ?.toString(),
      playerBId:
          (data['playerBId'] ?? data['player2Id'] ?? 'player-b').toString(),
      playerBName:
          (data['playerBName'] ?? data['player2Name'] ?? 'Player B').toString(),
      playerBDeck: (data['playerBDeckName'] ??
              data['player2DeckName'] ??
              data['deckBName'] ??
              '-')
          .toString(),
      playerBRegistrationId:
          (data['playerBRegistrationId'] ?? data['registrationBId'])
              ?.toString(),
      winnerName: data['winnerName']?.toString(),
      finalScore: data['finalScore']?.toString(),
    );
  }
}
