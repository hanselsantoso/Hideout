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
            Text('COMMUNITY APPROVALS', style: HDTText.overline(size: 10)),
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
          final reviewed = ref.watch(reviewedCommunityApplicationsProvider);
          return applications.when(
            data: (items) => _ApprovalContent(
              items: items,
              reviewedItems:
                  reviewed.valueOrNull ?? const <CommunityApplication>[],
              historyLoading: reviewed.isLoading,
              message: _message,
              busyId: _busyId,
              onApprove: (item) => _approve(item, user.uid),
              onReject: (item, reason) => _reject(item, user.uid, reason),
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

  Future<void> _reject(
    CommunityApplication application,
    String reviewerId,
    String reason,
  ) {
    return _review(
      application: application,
      action: 'rejected',
      run: () => ref.read(communityRepositoryProvider).rejectApplication(
            application: application,
            reviewerId: reviewerId,
            reason: reason,
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
      setState(() => _message = 'Review failed. Try again in a moment.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _ApprovalContent extends StatelessWidget {
  const _ApprovalContent({
    required this.items,
    required this.reviewedItems,
    required this.historyLoading,
    required this.message,
    required this.busyId,
    required this.onApprove,
    required this.onReject,
  });

  final List<CommunityApplication> items;
  final List<CommunityApplication> reviewedItems;
  final bool historyLoading;
  final String? message;
  final String? busyId;
  final ValueChanged<CommunityApplication> onApprove;
  final void Function(CommunityApplication application, String reason) onReject;

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
                      Text('NEW COMMUNITY APPLICATIONS',
                          style: HDTText.display(size: 32)),
                      const SizedBox(height: HDTSpace.xs),
                      Text(
                        'Every community that applies from the Open Community page enters this queue. When approved, the community lead automatically receives community admin access.',
                        style: HDTText.body(color: HDTColors.text2),
                      ),
                      const SizedBox(height: HDTSpace.md),
                      const Wrap(
                        spacing: HDTSpace.sm,
                        runSpacing: HDTSpace.sm,
                        children: [
                          _MetaChip(Icons.groups_outlined,
                              'SOURCE: COMMUNITY REGISTRATION'),
                          _MetaChip(Icons.admin_panel_settings_outlined,
                              'ROLE: COMMUNITY LEAD'),
                          _MetaChip(Icons.account_balance_wallet_outlined,
                              'WITHDRAW: DI HALAMAN LEAD'),
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
                        onReject: (reason) => onReject(item, reason),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: HDTSpace.xl),
            _ReviewHistoryPanel(
              items: reviewedItems,
              loading: historyLoading,
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
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    final created = application.createdAt;
    final submittedAt = created == null
        ? 'Date not available'
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
                onPressed: busy
                    ? null
                    : () async {
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (_) =>
                              _RejectReasonDialog(application: application),
                        );
                        if (reason != null && reason.trim().isNotEmpty) {
                          onReject(reason.trim());
                        }
                      },
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
    return first.isEmpty ? 'No community description.' : first;
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
                _detailText(application),
                style: HDTText.body(color: HDTColors.text2, height: 1.6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  static String _detailText(CommunityApplication application) {
    final rows = [
      if (application.description.isNotEmpty) application.description,
      if (application.tag.isNotEmpty) 'Tag: ${application.tag}',
      if (application.type.isNotEmpty) 'Type: ${application.type}',
      if (application.region.isNotEmpty) 'Region: ${application.region}',
      if (application.website.isNotEmpty) 'Website: ${application.website}',
      if (application.leaderName.isNotEmpty)
        'Lead: ${application.leaderName} (${application.leaderEmail})',
      if (application.leaderInstagram.isNotEmpty)
        'Instagram: ${application.leaderInstagram}',
      if (application.bankName.isNotEmpty)
        'Bank account: ${application.bankName} - ${application.bankHolder} (${application.bankNumber})',
      'Dokumen: KTP ${application.idUploaded ? 'OK' : 'review'}, Surat ${application.letterUploaded ? 'OK' : 'opsional'}, Logo ${application.logoUploaded ? 'OK' : 'opsional'}',
    ];
    return rows.isEmpty ? 'No additional details.' : rows.join('\n\n');
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog({required this.application});

  final CommunityApplication application;

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _reason = TextEditingController(
    text: 'Documents or community data are incomplete.',
  );

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: HDTColors.s1,
      title: Text('Reject Application', style: HDTText.display(size: 22)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.application.communityName,
              style: HDTText.body(color: HDTColors.text2),
            ),
            const SizedBox(height: HDTSpace.md),
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, _reason.text),
          icon: const Icon(Icons.cancel_outlined, size: 16),
          label: const Text('TOLAK'),
        ),
      ],
    );
  }
}

class _ReviewHistoryPanel extends StatelessWidget {
  const _ReviewHistoryPanel({
    required this.items,
    required this.loading,
  });

  final List<CommunityApplication> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('HISTORI REVIEW', style: HDTText.overline(size: 10)),
              const Spacer(),
              if (loading)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          if (items.isEmpty)
            Text(
              'No community approval or rejection history yet.',
              style: HDTText.body(size: 12, color: HDTColors.text2),
            )
          else
            for (final item in items) _ReviewHistoryRow(application: item),
        ],
      ),
    );
  }
}

class _ReviewHistoryRow extends StatelessWidget {
  const _ReviewHistoryRow({required this.application});

  final CommunityApplication application;

  @override
  Widget build(BuildContext context) {
    final approved = application.status == 'approved';
    final color = approved ? HDTColors.success : HDTColors.danger;
    final reviewed = application.reviewedAt;
    final date = reviewed == null
        ? 'Review date not available yet'
        : '${reviewed.year}-${reviewed.month.toString().padLeft(2, '0')}-${reviewed.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Row(
        children: [
          Icon(
            approved ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.communityName,
                    style: HDTText.display(size: 14)),
                const SizedBox(height: 3),
                Text(
                  application.rejectionReason?.isNotEmpty == true
                      ? application.rejectionReason!
                      : '${application.city} - $date',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HDTText.body(size: 11, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          Text(application.status.toUpperCase(),
              style: HDTText.overline(size: 8, color: color)),
        ],
      ),
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
          'This account role is `$role`. Community approval is only for super admin.',
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
              Text('BACKEND NOT READABLE', style: HDTText.display(size: 24)),
              const SizedBox(height: HDTSpace.sm),
              Text(
                'Pending approvals cannot be read right now. Try again in a moment.',
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
          Text('No new communities are waiting for approval.',
              style: HDTText.body(color: HDTColors.text2)),
        ],
      ),
    );
  }
}
