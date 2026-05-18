import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

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

class _FinancePolicyPanel extends StatelessWidget {
  const _FinancePolicyPanel({
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  Widget build(BuildContext context) {
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
                Text('FINANCE & WITHDRAW',
                    style:
                        HDTText.overline(size: 10, color: HDTColors.success)),
                const SizedBox(height: HDTSpace.sm),
                Text('Dana pendaftaran diterima utuh oleh komunitas',
                    style: HDTText.display(size: 26)),
                const SizedBox(height: HDTSpace.sm),
                Text(
                  'Platform fee, Midtrans/QRIS fee, dan coverage fee withdraw dibebankan ke user saat checkout, sehingga nominal entry fee net tetap menjadi hak komunitas untuk hadiah dan operasional event.',
                  style: HDTText.body(
                      size: 13, color: HDTColors.text2, height: 1.5),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _WithdrawDialog(
                userId: userId,
                userName: userName,
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('REQUEST WITHDRAW'),
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
  });

  final String userId;
  final String userName;

  @override
  ConsumerState<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends ConsumerState<_WithdrawDialog> {
  final _tournamentId = TextEditingController();
  final _amount = TextEditingController(text: '1500000');
  final _bank = TextEditingController(text: 'BCA');
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  bool _busy = false;
  String? _message;

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
      title: Text('REQUEST WITHDRAW', style: HDTText.display(size: 24)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Admin menerima nominal net. Fee payment dan withdraw sudah ditagihkan ke user di checkout.',
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
            amount: int.tryParse(_amount.text) ?? 0,
            bankName: _bank.text,
            accountNumber: _accountNumber.text,
            accountName: _accountName.text,
          );
      if (!mounted) return;
      setState(() => _message = 'Withdraw diajukan: $id');
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
