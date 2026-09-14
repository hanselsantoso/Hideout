import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';
import '../../data/models/tournament_summary.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

final staffTournamentsProvider =
    StreamProvider<List<TournamentSummary>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<TournamentSummary>>.value(const []);
  return ref.watch(tournamentRepositoryProvider).watchStaffTournaments(user.uid);
});

class StaffDeskScreen extends ConsumerStatefulWidget {
  const StaffDeskScreen({super.key});

  @override
  ConsumerState<StaffDeskScreen> createState() => _StaffDeskScreenState();
}

class _StaffDeskScreenState extends ConsumerState<StaffDeskScreen> {
  String? _selectedTournament;
  final Set<String> _busy = {};

  Future<void> _runAction(
    String action,
    String registrationId,
    String tournamentId,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy.add(registrationId));
    try {
      await ref.read(tournamentRepositoryProvider).runRegistrationOps(
            tournamentId: tournamentId,
            registrationId: registrationId,
            action: action,
            actorId: user.uid,
            actorName: user.displayName ?? '',
          );
      if (!mounted) return;
      final label = switch (action) {
        'markPaid' => 'Payment marked as PAID.',
        'checkIn' => 'Player checked in.',
        'undoCheckIn' => 'Check-in undone.',
        'walkOut' => 'Player walked out.',
        _ => 'Done.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again in a moment.')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(registrationId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(staffTournamentsProvider);

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PANITIA', style: HDTText.overline(size: 9)),
            Text('REGISTRATION DESK', style: HDTText.display(size: 20)),
          ],
        ),
      ),
      body: SafeArea(
        child: assignments.when(
          data: (tournaments) {
            if (tournaments.isEmpty) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(HDTSpace.xl),
                    decoration: hdtCard(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NO STAFF ASSIGNMENTS',
                            style: HDTText.overline(size: 10)),
                        const SizedBox(height: HDTSpace.sm),
                        Text('You are not staff yet',
                            style: HDTText.display(size: 26)),
                        const SizedBox(height: HDTSpace.sm),
                        Text(
                          'The community lead assigns staff per tournament in the tournament wizard. Once assigned, the tournament appears here on every device you sign in with.',
                          style: HDTText.body(
                              color: HDTColors.text2, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final selectedId = _selectedTournament ??= tournaments.first.id;
            final registrations = ref
                .watch(tournamentRegistrationsProvider(selectedId));
            final roster =
                registrations.valueOrNull ?? const <TournamentRegistrationSummary>[];
            final paid =
                roster.where((row) => row.paymentStatus == 'paid').length;
            final checkedIn =
                roster.where((row) => row.checkInStatus == 'checkedIn').length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                // Assignment selector
                Text('ASSIGNED TO (${tournaments.length})',
                    style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tournament in tournaments)
                      ChoiceChip(
                        label: Text(tournament.name.toUpperCase(),
                            style: HDTText.overline(size: 9)),
                        selected: selectedTournamentId == tournament.id,
                        onSelected: (_) =>
                            setState(() => _selectedTournament = tournament.id),
                        backgroundColor: HDTColors.s1,
                        selectedColor:
                            HDTColors.accent.withValues(alpha: .25),
                        side: BorderSide(
                          color: selectedTournamentId == tournament.id
                              ? HDTColors.accent
                              : HDTColors.s2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: HDTSpace.lg),
                Container(
                  padding: const EdgeInsets.all(HDTSpace.lg),
                  decoration: hdtCard(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('REGISTRATION DESK',
                                style: HDTText.overline(size: 10)),
                            Text(
                              roster.isEmpty
                                  ? 'Roster empty'
                                  : '${roster.length} registrations',
                              style: HDTText.display(size: 24),
                            ),
                            Text(
                              '$paid paid . $checkedIn checked-in',
                              style:
                                  HDTText.mono(size: 11, color: HDTColors.text3),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/tournaments/detail',
                          arguments: {
                            'tournamentId': selectedTournamentId,
                            'name': tournaments
                                .firstWhere((t) => t.id == selectedTournamentId)
                                .name,
                            'initialTab': 'bracket',
                          },
                        ),
                        icon: const Icon(Icons.account_tree_outlined, size: 14),
                        label: const Text('BRACKET'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HDTSpace.md),
                Text(
                  'MARK PAID = offline/cash payment confirmed by you (recorded with your name). CHECK-IN = player present at venue. WALK OUT = player left without playing.',
                  style: HDTText.body(size: 11, color: HDTColors.text3),
                ),
                const SizedBox(height: HDTSpace.md),
                for (final row in roster) ...[
                  _RosterRow(
                    row: row,
                    busy: _busy.contains(row.id),
                    onPaid: () => _runAction(
                        'markPaid', row.id, selectedTournamentId),
                    onCheckIn: () => _runAction(
                        row.checkInStatus == 'checkedIn'
                            ? 'undoCheckIn'
                            : 'checkIn',
                        row.id,
                        selectedTournamentId),
                    onWalkOut: () =>
                        _runAction('walkOut', row.id, selectedTournamentId),
                  ),
                  const SizedBox(height: HDTSpace.sm),
                ],
                if (roster.isEmpty)
                  const HDTEmptyState(
                    icon: Icons.people_outline,
                    title: 'NO REGISTRATIONS YET',
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: HDTEmptyState(
              icon: Icons.error_outline,
              title: 'COULD NOT READ ASSIGNMENTS',
              subtitle: 'Try again in a moment.',
            ),
          ),
        ),
      ),
    );
  }

  String get selectedTournamentId => _selectedTournament ?? '';
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.row,
    required this.busy,
    required this.onPaid,
    required this.onCheckIn,
    required this.onWalkOut,
  });

  final TournamentRegistrationSummary row;
  final bool busy;
  final VoidCallback onPaid;
  final VoidCallback onCheckIn;
  final VoidCallback onWalkOut;

  @override
  Widget build(BuildContext context) {
    final paid = row.paymentStatus == 'paid';
    final checkedIn = row.checkInStatus == 'checkedIn';
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.playerName.isEmpty ? row.id : row.playerName,
                    style: HDTText.display(size: 14)),
                const SizedBox(height: 3),
                Text('DECK: ${row.deckName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: _StatusPill(
              label: paid ? 'PAID' : 'UNPAID',
              color: paid ? HDTColors.success : HDTColors.warning,
            ),
          ),
          const SizedBox(width: HDTSpace.xs),
          SizedBox(
            width: 110,
            child: OutlinedButton(
              onPressed: paid || busy ? null : onPaid,
              child: const Text('MARK PAID',
                  style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: HDTSpace.xs),
          SizedBox(
            width: 104,
            child: OutlinedButton(
              onPressed: busy ? null : onCheckIn,
              child: Text(checkedIn ? 'UNDO' : 'CHECK-IN',
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(width: HDTSpace.xs),
          IconButton(
            tooltip: 'Walk out',
            onPressed: busy ? null : onWalkOut,
            icon: Icon(Icons.directions_walk,
                size: 16, color: HDTColors.danger),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(label, style: HDTText.overline(size: 8, color: color)),
    );
  }
}
