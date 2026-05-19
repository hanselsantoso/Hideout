import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

final communityAdminTournamentsProvider =
    StreamProvider.family<List<CommunityFinanceTournament>, String>(
  (ref, userId) {
    if (userId.isEmpty) {
      return Stream.value(const <CommunityFinanceTournament>[]);
    }
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .collection(FirestorePaths.tournaments)
        .where('organizerId', isEqualTo: userId)
        .limit(25)
        .snapshots()
        .map((snapshot) {
      final rows =
          snapshot.docs.map(CommunityFinanceTournament.fromFirestore).toList();
      rows.sort((a, b) {
        final aDate = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rows;
    });
  },
);

final communityWithdrawalsProvider =
    StreamProvider.family<List<CommunityWithdrawSummary>, String>(
  (ref, userId) {
    if (userId.isEmpty) {
      return Stream.value(const <CommunityWithdrawSummary>[]);
    }
    final firestore = ref.watch(firestoreProvider);
    return firestore
        .collectionGroup(FirestorePaths.withdrawals)
        .where('requesterId', isEqualTo: userId)
        .limit(25)
        .snapshots()
        .map((snapshot) {
      final rows =
          snapshot.docs.map(CommunityWithdrawSummary.fromFirestore).toList();
      rows.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rows;
    });
  },
);

class CommunityAdminScreen extends ConsumerWidget {
  const CommunityAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _AdminNotice(
            text: 'Belum bisa membaca sesi admin. Silakan refresh halaman.',
          ),
          data: (user) {
            if (user == null) {
              return _LoginRequired(
                onLogin: () => Navigator.pushNamed(context, '/signin'),
              );
            }
            if (!user.isCommunityAdminCompatible) {
              return _AdminNotice(
                text:
                    'Role akun ini ${user.role}. Menu ini hanya untuk admin komunitas atau super admin.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 96),
              children: [
                _AdminHeader(
                  name: user.displayName.trim().isEmpty
                      ? user.email.split('@').first
                      : user.displayName.trim(),
                ),
                const SizedBox(height: HDTSpace.xl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 1040
                        ? 3
                        : constraints.maxWidth >= 680
                            ? 2
                            : 1;
                    final width =
                        (constraints.maxWidth - ((cols - 1) * HDTSpace.lg)) /
                            cols;
                    return Wrap(
                      spacing: HDTSpace.lg,
                      runSpacing: HDTSpace.lg,
                      children: [
                        for (final item in _adminMenu)
                          SizedBox(
                            width: width,
                            child: _AdminMenuCard(item: item),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: HDTSpace.xl),
                _FinancePolicyPanel(
                  userId: user.uid,
                  userName: user.displayName.trim().isEmpty
                      ? user.email.split('@').first
                      : user.displayName.trim(),
                ),
                const SizedBox(height: HDTSpace.xl),
                const _OperationalNotes(),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _adminMenu = [
  _AdminMenuItem(
    title: 'Tournament Ops',
    subtitle:
        'Control room untuk group stage, round-robin standings, bracket, next call, dan hasil match.',
    route: '/admin/tournaments/ops',
    icon: Icons.account_tree_outlined,
    color: HDTColors.accent,
    primary: true,
  ),
  _AdminMenuItem(
    title: 'Buat Turnamen',
    subtitle:
        'Atur stage, group, top cut, rules, pricing, juri, arena, dan prize pool.',
    route: '/admin/tournaments/new',
    icon: Icons.add_circle_outline,
    color: HDTColors.success,
  ),
  _AdminMenuItem(
    title: 'Manage Juri',
    subtitle:
        'Assign atau revoke role juri dari pemain komunitas yang sudah diverifikasi.',
    route: '/community/judges',
    icon: Icons.verified_user_outlined,
    color: HDTColors.info,
  ),
  _AdminMenuItem(
    title: 'Registrasi Komunitas',
    subtitle:
        'Buat atau lengkapi profil komunitas sebelum diajukan ke super admin.',
    route: '/communities/new',
    icon: Icons.groups_outlined,
    color: HDTColors.warning,
  ),
];

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.color,
    this.primary = false,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color color;
  final bool primary;
}

class CommunityFinanceTournament {
  const CommunityFinanceTournament({
    required this.id,
    required this.name,
    required this.status,
    required this.registrationFee,
    required this.currentParticipantCount,
    required this.maxParticipants,
    required this.netPayoutEstimate,
    required this.payoutStatus,
    this.startDate,
  });

  final String id;
  final String name;
  final String status;
  final int registrationFee;
  final int currentParticipantCount;
  final int maxParticipants;
  final int netPayoutEstimate;
  final String payoutStatus;
  final DateTime? startDate;

  bool get hasPayout => netPayoutEstimate > 0;

  bool get withdrawLocked {
    final normalized = payoutStatus.toLowerCase();
    return normalized == 'processing' ||
        normalized == 'queued' ||
        normalized == 'paid';
  }

  factory CommunityFinanceTournament.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    DateTime? readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final registrationFee = (data['registrationFee'] as num?)?.round() ?? 0;
    final currentParticipantCount =
        (data['currentParticipantCount'] as num?)?.round() ??
            (data['participantCount'] as num?)?.round() ??
            0;
    final organizerPayout =
        Map<String, dynamic>.from(data['organizerPayout'] as Map? ?? {});
    final netPerPlayer =
        (organizerPayout['netRegistrationFeePerPlayer'] as num?)?.round() ??
            (data['netRegistrationFeePerPlayer'] as num?)?.round() ??
            registrationFee;
    final requestedAmount =
        (organizerPayout['requestedAmount'] as num?)?.round();

    return CommunityFinanceTournament(
      id: doc.id,
      name: (data['name'] ?? 'Untitled Tournament').toString(),
      status: (data['status'] ?? 'draft').toString(),
      registrationFee: registrationFee,
      currentParticipantCount: currentParticipantCount,
      maxParticipants: (data['maxParticipants'] as num?)?.round() ?? 0,
      netPayoutEstimate:
          requestedAmount ?? (netPerPlayer * currentParticipantCount),
      payoutStatus: (organizerPayout['status'] ?? 'notRequested').toString(),
      startDate: readDate('startDate'),
    );
  }
}

class CommunityWithdrawSummary {
  const CommunityWithdrawSummary({
    required this.id,
    required this.tournamentId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String tournamentId;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String status;
  final DateTime? createdAt;

  factory CommunityWithdrawSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final tournamentRef = doc.reference.parent.parent;
    DateTime? readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CommunityWithdrawSummary(
      id: (data['id'] ?? doc.id).toString(),
      tournamentId:
          (data['tournamentId'] ?? tournamentRef?.id ?? '').toString(),
      amount: (data['amount'] as num?)?.round() ?? 0,
      bankName: (data['bankName'] ?? '-').toString(),
      accountNumber: (data['accountNumber'] ?? '-').toString(),
      status: (data['status'] ?? 'processing').toString(),
      createdAt: readDate('createdAt') ?? readDate('requestedAt'),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
    case 'approved':
      return HDTColors.success;
    case 'processing':
    case 'queued':
      return HDTColors.info;
    case 'rejected':
    case 'failed':
      return HDTColors.danger;
    default:
      return HDTColors.warning;
  }
}

String _formatRp(int value) {
  final sign = value < 0 ? '-' : '';
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${sign}Rp ${buffer.toString()}';
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.lg,
        border: Border.all(color: HDTColors.accent.withValues(alpha: .5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.lg,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMMUNITY ADMIN', style: HDTText.overline(size: 11)),
                const SizedBox(height: HDTSpace.xs),
                Text(
                  'CONTROL CENTER',
                  style: HDTText.display(size: 42).copyWith(height: 1.02),
                ),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Halo ${name.toUpperCase()}. Semua operasional komunitas ada di sini: event, group stage, juri, bracket, rules, dan live info pemain.',
                  style: HDTText.body(
                    size: 13,
                    color: HDTColors.text2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              _HeaderMetric('LIVE', '2'),
              _HeaderMetric('GROUP', '4'),
              _HeaderMetric('QUEUE', '12'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 8)),
          const SizedBox(height: 2),
          Text(value, style: HDTText.display(size: 24)),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({required this.item});

  final _AdminMenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route),
      borderRadius: HDTR.lg,
      child: Container(
        constraints: BoxConstraints(minHeight: item.primary ? 230 : 190),
        padding: const EdgeInsets.all(HDTSpace.lg),
        decoration: hdtAccentCard(
          accentColor: item.color,
          highlighted: item.primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .18),
                borderRadius: HDTR.md,
                border: Border.all(color: item.color),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const Spacer(),
            Text(item.title.toUpperCase(), style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.sm),
            Text(
              item.subtitle,
              style:
                  HDTText.body(size: 12, color: HDTColors.text2, height: 1.45),
            ),
            const SizedBox(height: HDTSpace.lg),
            Row(
              children: [
                Text('OPEN',
                    style: HDTText.overline(size: 9, color: item.color)),
                const SizedBox(width: HDTSpace.xs),
                Icon(Icons.arrow_forward, size: 14, color: item.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationalNotes extends StatelessWidget {
  const _OperationalNotes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OPERATING PRINCIPLE', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.sm),
          Text(
            'Admin mengatur stage dan rules. Pemain melihat standings, bracket, hasil, arena, dan giliran berikutnya secara transparan dari halaman tournament.',
            style: HDTText.body(size: 13, color: HDTColors.text2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FinancePolicyPanel extends ConsumerWidget {
  const _FinancePolicyPanel({
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(communityAdminTournamentsProvider(userId));
    final withdrawals = ref.watch(communityWithdrawalsProvider(userId));

    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(accentColor: HDTColors.success),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.lg,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FINANCE & AUTO WITHDRAW',
                    style:
                        HDTText.overline(size: 10, color: HDTColors.success)),
                const SizedBox(height: HDTSpace.sm),
                Text('Withdraw komunitas diproses otomatis',
                    style: HDTText.display(size: 26)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Dana pendaftaran tetap menjadi hak komunitas. Ketua komunitas mengajukan payout dari halaman ini, lalu sistem menandainya masuk proses tanpa approval manual di super admin.',
                  style: HDTText.body(
                      size: 13, color: HDTColors.text2, height: 1.5),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openWithdraw(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('AUTO WITHDRAW'),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TURNAMEN KOMUNITAS', style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.sm),
                tournaments.when(
                  loading: () => const _FinanceInlineNotice(
                    icon: Icons.hourglass_empty,
                    text: 'Memuat turnamen komunitas...',
                  ),
                  error: (_, __) => const _FinanceInlineNotice(
                    icon: Icons.info_outline,
                    text:
                        'Turnamen komunitas belum terbaca. Coba refresh halaman.',
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const _FinanceInlineNotice(
                        icon: Icons.event_busy_outlined,
                        text:
                            'Belum ada turnamen yang terhubung ke akun ketua komunitas ini.',
                      );
                    }
                    return Column(
                      children: [
                        for (final item in rows.take(5))
                          _FinanceTournamentRow(
                            item: item,
                            onWithdraw: item.hasPayout && !item.withdrawLocked
                                ? () => _openWithdraw(context, tournament: item)
                                : null,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: HDTSpace.lg),
                Text('RIWAYAT WITHDRAW OTOMATIS',
                    style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.sm),
                withdrawals.when(
                  loading: () => const _FinanceInlineNotice(
                    icon: Icons.hourglass_empty,
                    text: 'Memuat riwayat withdraw...',
                  ),
                  error: (_, __) => const _FinanceInlineNotice(
                    icon: Icons.info_outline,
                    text:
                        'Riwayat withdraw belum terbaca. Coba refresh halaman.',
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const _FinanceInlineNotice(
                        icon: Icons.account_balance_wallet_outlined,
                        text:
                            'Belum ada withdraw. Gunakan tombol di turnamen yang sudah memiliki dana pendaftaran.',
                      );
                    }
                    return Column(
                      children: [
                        for (final item in rows.take(4))
                          _WithdrawHistoryRow(item: item),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openWithdraw(
    BuildContext context, {
    CommunityFinanceTournament? tournament,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _WithdrawDialog(
        userId: userId,
        userName: userName,
        initialTournamentId: tournament?.id,
        initialAmount: tournament == null || !tournament.hasPayout
            ? null
            : tournament.netPayoutEstimate,
      ),
    );
  }
}

class _FinanceTournamentRow extends StatelessWidget {
  const _FinanceTournamentRow({
    required this.item,
    required this.onWithdraw,
  });

  final CommunityFinanceTournament item;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.payoutStatus);
    final buttonLabel = item.withdrawLocked
        ? 'DIPROSES'
        : item.hasPayout
            ? 'WITHDRAW'
            : 'BELUM ADA DANA';
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg.withValues(alpha: 0.72),
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: HDTSpace.md,
        runSpacing: HDTSpace.sm,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HDTColors.success.withValues(alpha: 0.12),
              borderRadius: HDTR.sm,
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: HDTColors.success, size: 19),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: HDTText.display(size: 15)),
                const SizedBox(height: 4),
                Text(
                  '${item.currentParticipantCount}/${item.maxParticipants} pemain - ${item.status}',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatRp(item.netPayoutEstimate),
                    style: HDTText.mono(size: 12, color: HDTColors.text)),
                const SizedBox(height: 4),
                Text(item.payoutStatus.toUpperCase(),
                    style: HDTText.overline(size: 8, color: statusColor)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.send_outlined, size: 14),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _WithdrawHistoryRow extends StatelessWidget {
  const _WithdrawHistoryRow({required this.item});

  final CommunityWithdrawSummary item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg.withValues(alpha: 0.56),
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: HDTSpace.md,
        runSpacing: HDTSpace.sm,
        children: [
          Icon(Icons.receipt_long_outlined, size: 18, color: color),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 520),
            child: Text(
              '${item.tournamentId} - ${item.bankName} ${item.accountNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 12, color: HDTColors.text2),
            ),
          ),
          Text(_formatRp(item.amount),
              style: HDTText.mono(size: 12, color: HDTColors.text)),
          Text(item.status.toUpperCase(),
              style: HDTText.overline(size: 8, color: color)),
        ],
      ),
    );
  }
}

class _FinanceInlineNotice extends StatelessWidget {
  const _FinanceInlineNotice({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg.withValues(alpha: 0.6),
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: HDTColors.text3),
          const SizedBox(width: HDTSpace.sm),
          Expanded(
            child: Text(text,
                style: HDTText.body(size: 12, color: HDTColors.text2)),
          ),
        ],
      ),
    );
  }
}

class _WithdrawDialog extends ConsumerStatefulWidget {
  const _WithdrawDialog({
    required this.userId,
    required this.userName,
    this.initialTournamentId,
    this.initialAmount,
  });

  final String userId;
  final String userName;
  final String? initialTournamentId;
  final int? initialAmount;

  @override
  ConsumerState<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends ConsumerState<_WithdrawDialog> {
  final _tournamentId = TextEditingController();
  final _amount = TextEditingController();
  final _bank = TextEditingController(text: 'BCA');
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tournamentId.text = widget.initialTournamentId ?? '';
    _amount.text = (widget.initialAmount ?? 1500000).toString();
  }

  @override
  void dispose() {
    _tournamentId.dispose();
    _amount.dispose();
    _bank.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: HDTColors.s1,
      title: Text('AUTO WITHDRAW', style: HDTText.display(size: 24)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Withdraw dibuat dari halaman ketua komunitas dan langsung masuk proses payout. Fee payment dan withdraw sudah ditagihkan ke user saat checkout.',
                style: HDTText.body(size: 12, color: HDTColors.text2),
              ),
              const SizedBox(height: HDTSpace.md),
              TextField(
                controller: _tournamentId,
                decoration: const InputDecoration(
                  labelText: 'Tournament ID',
                  prefixIcon: Icon(Icons.emoji_events_outlined),
                ),
              ),
              const SizedBox(height: HDTSpace.md),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal withdraw net',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: HDTSpace.md),
              TextField(
                controller: _bank,
                decoration: const InputDecoration(labelText: 'Bank'),
              ),
              const SizedBox(height: HDTSpace.md),
              TextField(
                controller: _accountNumber,
                decoration: const InputDecoration(labelText: 'Nomor rekening'),
              ),
              const SizedBox(height: HDTSpace.md),
              TextField(
                controller: _accountName,
                decoration: const InputDecoration(labelText: 'Nama rekening'),
              ),
              if (_message != null) ...[
                const SizedBox(height: HDTSpace.md),
                Text(_message!,
                    style: HDTText.body(size: 12, color: HDTColors.text2)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_busy ? 'SENDING...' : 'SUBMIT'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_tournamentId.text.trim().isEmpty) {
      setState(() => _message = 'Isi Tournament ID terlebih dahulu.');
      return;
    }
    final amount = int.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      setState(() => _message = 'Nominal withdraw harus lebih dari 0.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final id = await ref
          .read(tournamentRepositoryProvider)
          .requestTournamentWithdrawal(
            tournamentId: _tournamentId.text.trim(),
            requesterId: widget.userId,
            requesterName: widget.userName,
            amount: amount,
            bankName: _bank.text,
            accountNumber: _accountNumber.text,
            accountName: _accountName.text,
          );
      if (!mounted) return;
      setState(() => _message = 'Withdraw otomatis masuk proses: $id');
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _message = 'Withdraw belum terkirim. Periksa data dan coba ulangi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onLogin,
        child: const Text('LOGIN ADMIN KOMUNITAS'),
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(HDTSpace.lg),
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: HDTText.body(color: HDTColors.text2, height: 1.5),
        ),
      ),
    );
  }
}
