import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/community_repository.dart';

class CommunityJudgesScreen extends ConsumerStatefulWidget {
  const CommunityJudgesScreen({super.key});

  @override
  ConsumerState<CommunityJudgesScreen> createState() =>
      _CommunityJudgesScreenState();
}

class _CommunityJudgesScreenState extends ConsumerState<CommunityJudgesScreen> {
  final _search = TextEditingController();
  final Set<String> _busyUsers = {};
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMMUNITY ADMIN', style: HDTText.overline(size: 9)),
            Text('JURI & MEMBERS', style: HDTText.display(size: 20)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/admin/tournaments/new'),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('NEW TOURNEY'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _PermissionNotice(
          text: 'Belum bisa membaca sesi admin. Coba muat ulang halaman.',
        ),
        data: (user) {
          if (user == null) {
            return _LoginRequired(
              onLogin: () => Navigator.pushNamed(context, '/signin'),
            );
          }
          if (!user.isCommunityAdminCompatible) {
            return _PermissionNotice(
              text:
                  'Role akun ini ${user.role}. Pengaturan juri hanya untuk admin komunitas atau admin platform.',
            );
          }
          return _content(user);
        },
      ),
    );
  }

  Widget _content(AppUser user) {
    final candidates = ref.watch(communityJudgeCandidatesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      children: [
        _HeaderCard(
          onCreateTournament: () =>
              Navigator.pushNamed(context, '/admin/tournaments/new'),
        ),
        const SizedBox(height: HDTSpace.lg),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Cari nama, email, region, atau HDT id',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: HDTSpace.md),
          _Notice(text: _error!, color: HDTColors.danger),
        ],
        const SizedBox(height: HDTSpace.lg),
        candidates.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _Notice(
            color: HDTColors.warning,
            text: 'Belum bisa membaca kandidat juri. Coba muat ulang halaman.',
          ),
          data: (items) {
            final filtered = _filter(items);
            if (filtered.isEmpty) {
              return const _EmptyState();
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 980 ? 2 : 1;
                final width =
                    (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) / cols;
                return Wrap(
                  spacing: HDTSpace.md,
                  runSpacing: HDTSpace.md,
                  children: [
                    for (final candidate in filtered)
                      SizedBox(
                        width: width,
                        child: _CandidateCard(
                          candidate: candidate,
                          busy: _busyUsers.contains(candidate.uid),
                          onAssign: () => _assign(candidate, user.uid),
                          onRevoke: () => _revoke(candidate, user.uid),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  List<CommunityJudgeCandidate> _filter(
    List<CommunityJudgeCandidate> candidates,
  ) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return candidates;
    return [
      for (final candidate in candidates)
        if (candidate.uid.toLowerCase().contains(q) ||
            candidate.displayName.toLowerCase().contains(q) ||
            candidate.email.toLowerCase().contains(q) ||
            candidate.region.toLowerCase().contains(q))
          candidate,
    ];
  }

  Future<void> _assign(
    CommunityJudgeCandidate candidate,
    String adminUid,
  ) async {
    await _runRoleAction(
      candidate.uid,
      () => ref.read(communityRepositoryProvider).assignJudge(
            targetUid: candidate.uid,
            assignedBy: adminUid,
          ),
      '${candidate.displayName} sekarang menjadi juri.',
    );
  }

  Future<void> _revoke(
    CommunityJudgeCandidate candidate,
    String adminUid,
  ) async {
    await _runRoleAction(
      candidate.uid,
      () => ref.read(communityRepositoryProvider).revokeJudge(
            targetUid: candidate.uid,
            revokedBy: adminUid,
          ),
      '${candidate.displayName} dikembalikan menjadi pemain.',
    );
  }

  Future<void> _runRoleAction(
    String uid,
    Future<void> Function() run,
    String message,
  ) async {
    setState(() {
      _error = null;
      _busyUsers.add(uid);
    });
    try {
      await run();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Belum bisa mengubah role juri. Coba ulangi.';
      });
    } finally {
      if (mounted) {
        setState(() => _busyUsers.remove(uid));
      }
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onCreateTournament});

  final VoidCallback onCreateTournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration:
          hdtAccentCard(accentColor: HDTColors.accent, highlighted: true),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.s2),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: HDTColors.accentHover,
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASSIGN JURI', style: HDTText.display(size: 26)),
                Text(
                  'Pilih pemain aktif untuk menjadi juri. Setelah role berubah, nama mereka muncul di wizard tournament bagian arena.',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          ElevatedButton.icon(
            onPressed: onCreateTournament,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('BUAT TOURNEY'),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.busy,
    required this.onAssign,
    required this.onRevoke,
  });

  final CommunityJudgeCandidate candidate;
  final bool busy;
  final VoidCallback onAssign;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final isJudge = candidate.isJudge;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: isJudge ? HDTColors.success : HDTColors.accent,
        highlighted: isJudge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: HDTColors.s2,
                  borderRadius: HDTR.md,
                ),
                child: Text(
                  candidate.displayName.isEmpty
                      ? '?'
                      : candidate.displayName[0].toUpperCase(),
                  style: HDTText.display(size: 18),
                ),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.display(size: 20),
                    ),
                    Text(
                      candidate.email.isEmpty ? candidate.uid : candidate.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HDTText.mono(size: 11, color: HDTColors.text3),
                    ),
                  ],
                ),
              ),
              _RolePill(candidate.roleLabel),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          hdtDivider(),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              _MiniMetric('REGION', candidate.region.toUpperCase()),
              const SizedBox(width: HDTSpace.lg),
              _MiniMetric('ELO', candidate.eloRating.toString()),
              const SizedBox(width: HDTSpace.lg),
              _MiniMetric('MATCH', candidate.totalMatches.toString()),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          SizedBox(
            width: double.infinity,
            child: isJudge
                ? OutlinedButton.icon(
                    onPressed: busy ? null : onRevoke,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_outlined, size: 16),
                    label: Text(busy ? 'UPDATING...' : 'REVOKE JURI'),
                  )
                : ElevatedButton.icon(
                    onPressed: busy ? null : onAssign,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gavel_outlined, size: 16),
                    label: Text(busy ? 'UPDATING...' : 'ASSIGN AS JURI'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isJudge = label == 'JUDGE';
    final color = isJudge ? HDTColors.success : HDTColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: HDTR.sm,
        border: Border.all(color: color),
      ),
      child: Text(label, style: HDTText.overline(size: 8, color: color)),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HDTText.overline(size: 8)),
          const SizedBox(height: HDTSpace.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HDTText.mono(size: 12, color: HDTColors.text),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtAccentCard(accentColor: color),
      child: Text(text, style: HDTText.body(size: 12, color: HDTColors.text2)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(),
      child: Column(
        children: [
          const Icon(Icons.search_off_outlined, size: 38),
          const SizedBox(height: HDTSpace.md),
          Text('TIDAK ADA KANDIDAT', style: HDTText.display(size: 22)),
          const SizedBox(height: HDTSpace.xs),
          Text(
            'Belum ada player aktif yang cocok dengan pencarian.',
            textAlign: TextAlign.center,
            style: HDTText.body(size: 12, color: HDTColors.text2),
          ),
        ],
      ),
    );
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

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
