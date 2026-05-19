import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/community_application.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';

class CommunityApprovalsScreen extends ConsumerStatefulWidget {
  const CommunityApprovalsScreen({super.key});

  @override
  ConsumerState<CommunityApprovalsScreen> createState() =>
      _CommunityApprovalsScreenState();
}

class _CommunityApprovalsScreenState
    extends ConsumerState<CommunityApprovalsScreen> {
  String? _busyId;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text('SUPER ADMIN', style: HDTText.overline(size: 10)),
            const SizedBox(width: HDTSpace.sm),
            const Icon(Icons.chevron_right, size: 14, color: HDTColors.text3),
            const SizedBox(width: HDTSpace.sm),
            Text('PERSETUJUAN KOMUNITAS', style: HDTText.overline(size: 10)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/super-admin/reports'),
            child: const Text('CONSOLE'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
      ),
      body: profile.when(
        data: (user) {
          if (user == null) return const _LoginRequired();
          if (!user.isAdminCompatible) {
            return _PermissionNotice(role: user.role);
          }

          final applications = ref.watch(pendingCommunityApplicationsProvider);
          return applications.when(
            data: (items) => _ApprovalContent(
              items: items,
              message: _message,
              busyId: _busyId,
              onApprove: (item) => _approve(item, user.uid),
              onReject: (item) => _reject(item, user.uid),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const _BackendNotice(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _BackendNotice(),
      ),
    );
  }

  Future<void> _approve(CommunityApplication application, String reviewerId) {
    return _review(
      application: application,
      action: 'approved',
      run: () => ref.read(communityRepositoryProvider).approveApplication(
            application: application,
            reviewerId: reviewerId,
          ),
    );
  }

  Future<void> _reject(CommunityApplication application, String reviewerId) {
    return _review(
      application: application,
      action: 'rejected',
      run: () => ref.read(communityRepositoryProvider).rejectApplication(
            application: application,
            reviewerId: reviewerId,
            reason: 'Rejected from HIDEOUT super admin console',
          ),
    );
  }

  Future<void> _review({
    required CommunityApplication application,
    required String action,
    required Future<Object?> Function() run,
  }) async {
    setState(() {
      _busyId = application.id;
      _message = null;
    });
    try {
      final result = await run();
      if (!mounted) return;
      setState(() {
        _message =
            '${application.communityName} $action. ${result == null ? '' : 'Community ID: $result'}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _message = 'Review gagal. Coba ulangi beberapa saat lagi.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _ApprovalContent extends StatelessWidget {
  const _ApprovalContent({
    required this.items,
    required this.message,
    required this.busyId,
    required this.onApprove,
    required this.onReject,
  });

  final List<CommunityApplication> items;
  final String? message;
  final String? busyId;
  final ValueChanged<CommunityApplication> onApprove;
  final ValueChanged<CommunityApplication> onReject;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.all(HDTSpace.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PENGAJUAN KOMUNITAS BARU',
                          style: HDTText.display(size: 32)),
                      const SizedBox(height: HDTSpace.xs),
                      Text(
                        'Setiap komunitas yang mendaftar dari halaman Buka Komunitas masuk ke queue ini. Saat disetujui, ketua komunitas otomatis mendapat akses admin komunitas.',
                        style: HDTText.body(color: HDTColors.text2),
                      ),
                      const SizedBox(height: HDTSpace.md),
                      const Wrap(
                        spacing: HDTSpace.sm,
                        runSpacing: HDTSpace.sm,
                        children: [
                          _MetaChip(Icons.groups_outlined,
                              'SOURCE: REGISTRASI KOMUNITAS'),
                          _MetaChip(Icons.admin_panel_settings_outlined,
                              'ROLE: KETUA KOMUNITAS'),
                          _MetaChip(Icons.account_balance_wallet_outlined,
                              'WITHDRAW: DI HALAMAN KETUA'),
                        ],
                      ),
                    ],
                  ),
                ),
                _PendingBadge(count: items.length),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: HDTSpace.lg),
              _StatusNotice(message: message!),
            ],
            const SizedBox(height: HDTSpace.xl),
            if (items.isEmpty)
              const _EmptyApprovals()
            else
              Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HDTSpace.lg),
                      child: _ApplicationCard(
                        application: item,
                        busy: busyId == item.id,
                        onApprove: () => onApprove(item),
                        onReject: () => onReject(item),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.md, vertical: HDTSpace.sm),
      decoration: BoxDecoration(
        color: HDTColors.warning.withValues(alpha: 0.14),
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text('$count PENDING',
          style: HDTText.overline(size: 9, color: HDTColors.warning)),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CommunityApplication application;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final created = application.createdAt;
    final submittedAt = created == null
        ? 'Tanggal tidak tersedia'
        : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _colorFor(application.communityName),
                  borderRadius: HDTR.md,
                ),
                child: Center(
                  child: Text(
                    application.communityName.isEmpty
                        ? '?'
                        : application.communityName[0].toUpperCase(),
                    style: HDTText.display(size: 19, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.communityName,
                        style: HDTText.display(size: 20)),
                    const SizedBox(height: HDTSpace.xs),
                    Text(
                      '${application.city} - Diajukan oleh ${application.leaderUserId} - $submittedAt',
                      style: HDTText.body(size: 12, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
              _DocBadge(description: application.description),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          Text(
            _firstParagraph(application.description),
            style: HDTText.body(size: 13, color: HDTColors.text2, height: 1.6),
          ),
          const SizedBox(height: HDTSpace.lg),
          Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              _MetaChip(Icons.location_on_outlined, application.city),
              _MetaChip(Icons.person_outline, application.leaderUserId),
              _MetaChip(Icons.pending_actions_outlined,
                  application.status.toUpperCase()),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          Wrap(
            spacing: HDTSpace.md,
            runSpacing: HDTSpace.sm,
            children: [
              _ActionButton(
                label: busy ? 'PROCESSING...' : 'SETUJUI',
                icon: Icons.check_circle_outline,
                color: HDTColors.success,
                onPressed: busy ? null : onApprove,
                filled: true,
              ),
              _ActionButton(
                label: 'TOLAK',
                icon: Icons.cancel_outlined,
                color: HDTColors.danger,
                onPressed: busy ? null : onReject,
              ),
              _ActionButton(
                label: 'LIHAT DETAIL',
                icon: Icons.visibility_outlined,
                color: HDTColors.text2,
                onPressed: () => _showDetails(context, application),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _firstParagraph(String value) {
    final first = value.split('\n').first.trim();
    return first.isEmpty ? 'Tidak ada deskripsi komunitas.' : first;
  }

  static Color _colorFor(String value) {
    const colors = [
      HDTColors.accent,
      HDTColors.info,
      HDTColors.warning,
      HDTColors.success,
      Color(0xFFE67E22),
      Color(0xFF16A085),
    ];
    if (value.isEmpty) return HDTColors.accent;
    return colors[value.codeUnitAt(0) % colors.length];
  }

  static void _showDetails(
      BuildContext context, CommunityApplication application) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(application.communityName, style: HDTText.display(size: 22)),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Text(
                application.description.isEmpty
                    ? 'Tidak ada detail tambahan.'
                    : application.description,
                style: HDTText.body(color: HDTColors.text2, height: 1.6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('TUTUP'),
            ),
          ],
        );
      },
    );
  }
}

class _DocBadge extends StatelessWidget {
  const _DocBadge({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    final ok = description.toLowerCase().contains('ktp ok');
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
      decoration: BoxDecoration(
        color: (ok ? HDTColors.success : HDTColors.warning)
            .withValues(alpha: 0.12),
        borderRadius: HDTR.sm,
        border: Border.all(
          color: (ok ? HDTColors.success : HDTColors.warning)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Text(ok ? 'DOCS OK' : 'DOCS REVIEW',
          style: HDTText.overline(
              size: 8, color: ok ? HDTColors.success : HDTColors.warning)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: HDTColors.text3),
          const SizedBox(width: HDTSpace.xs),
          Text(label.isEmpty ? '-' : label,
              style: HDTText.mono(size: 10, color: HDTColors.text2)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.16),
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.35)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.65)),
          );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: HDTSpace.sm),
        Text(label),
      ],
    );
    return filled
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child:
          Text(message, style: HDTText.mono(size: 11, color: HDTColors.text2)),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/signup'),
        child: const Text('LOGIN SEBAGAI SUPER ADMIN'),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(HDTSpace.lg),
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtCard(),
        child: Text(
          'Role akun ini `$role`. Approval komunitas hanya untuk super admin.',
          textAlign: TextAlign.center,
          style: HDTText.body(color: HDTColors.text2, height: 1.5),
        ),
      ),
    );
  }
}

class _BackendNotice extends StatelessWidget {
  const _BackendNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.all(HDTSpace.lg),
          padding: const EdgeInsets.all(HDTSpace.xl),
          decoration: hdtCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  color: HDTColors.warning, size: 44),
              const SizedBox(height: HDTSpace.md),
              Text('BACKEND BELUM TERBACA', style: HDTText.display(size: 24)),
              const SizedBox(height: HDTSpace.sm),
              Text(
                'Belum bisa membaca pending approval saat ini. Coba kembali beberapa saat lagi.',
                textAlign: TextAlign.center,
                style: HDTText.body(color: HDTColors.text2, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  const _EmptyApprovals();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.xl, vertical: HDTSpace.xxxl),
      decoration: hdtCard(),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined,
              color: HDTColors.success, size: 42),
          const SizedBox(height: HDTSpace.md),
          Text('QUEUE KOSONG', style: HDTText.display(size: 24)),
          const SizedBox(height: HDTSpace.sm),
          Text('Belum ada komunitas baru yang menunggu persetujuan.',
              style: HDTText.body(color: HDTColors.text2)),
        ],
      ),
    );
  }
}
