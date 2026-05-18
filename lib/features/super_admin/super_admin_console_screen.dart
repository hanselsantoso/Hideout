import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/models/bey_part.dart';
import '../../data/repositories/auth_repository.dart';

final superAdminMetricsProvider = StreamProvider<SuperAdminMetrics>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection(FirestorePaths.users).limit(1000).snapshots().asyncMap(
    (users) async {
      final tournaments =
          await firestore.collection(FirestorePaths.tournaments).limit(500).get();
      final communities =
          await firestore.collection(FirestorePaths.communities).limit(500).get();
      final components =
          await firestore.collection(FirestorePaths.componentStats).limit(500).get();
      return SuperAdminMetrics(
        activeUsers: users.docs.where((doc) => doc.data()['isActive'] != false).length,
        judges: users.docs.where((doc) => _rolesFromData(doc.data()).contains('judge')).length,
        communityAdmins: users.docs
            .where((doc) => _rolesFromData(doc.data()).contains('community_admin'))
            .length,
        communities: communities.docs.length,
        tournaments: tournaments.docs.length,
        runningTournaments: tournaments.docs
            .where((doc) => (doc.data()['status'] ?? '').toString() == 'running')
            .length,
        componentStats: components.docs.length,
      );
    },
  );
});

final superAdminWithdrawQueueProvider =
    StreamProvider<List<WithdrawRequestSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collectionGroup(FirestorePaths.withdrawals)
      .limit(25)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => WithdrawRequestSummary.fromFirestore(doc))
          .toList());
});

final componentStatsReviewProvider =
    StreamProvider<List<ComponentStatSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.componentStats)
      .orderBy('appearances', descending: true)
      .limit(25)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => ComponentStatSummary.fromFirestore(doc)).toList());
});

final superAdminComponentsProvider =
    StreamProvider<List<AdminComponentSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.components)
      .orderBy('name')
      .limit(500)
      .snapshots()
      .asyncMap((snap) async {
    final rows = <AdminComponentSummary>[];
    for (final doc in snap.docs) {
      final stat = await firestore.doc(FirestorePaths.componentStatDoc(doc.id)).get();
      rows.add(AdminComponentSummary.fromFirestore(
        component: doc,
        stat: stat,
      ));
    }
    return rows;
  });
});

enum SuperAdminSection {
  reports,
  components,
  componentStats,
  newParts,
}

class SuperAdminConsoleScreen extends ConsumerWidget {
  const SuperAdminConsoleScreen({
    super.key,
    required this.section,
  });

  final SuperAdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Text(_sectionTitle(section).toUpperCase(),
                style: HDTText.overline(size: 10)),
          ],
        ),
      ),
      body: profile.when(
        data: (user) {
          if (user == null) return const _SuperAdminNotice.login();
          if (!user.capabilities.contains('super_admin')) {
            return const _SuperAdminNotice.permission();
          }
          return _SuperAdminContent(section: section);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _SuperAdminNotice.backend(),
      ),
    );
  }
}

class _SuperAdminContent extends StatelessWidget {
  const _SuperAdminContent({required this.section});

  final SuperAdminSection section;

  @override
  Widget build(BuildContext context) {
    final overview = _sectionOverview(section);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          padding: const EdgeInsets.all(HDTSpace.xl),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overview.eyebrow,
                          style: HDTText.overline(
                              size: 10, color: HDTColors.warning)),
                      const SizedBox(height: HDTSpace.sm),
                      Text(overview.title, style: HDTText.display(size: 34)),
                      const SizedBox(height: HDTSpace.sm),
                      Text(
                        overview.description,
                        style: HDTText.body(
                          size: 14,
                          color: HDTColors.text2,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: HDTSpace.lg),
                _SectionStatusChip(label: overview.status),
              ],
            ),
            const SizedBox(height: HDTSpace.xl),
            _SectionBody(section: section),
          ],
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final SuperAdminSection section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case SuperAdminSection.reports:
        return const _ReportGrid();
      case SuperAdminSection.components:
        return const _ComponentManagement();
      case SuperAdminSection.componentStats:
        return const _StatsReview();
      case SuperAdminSection.newParts:
        return const _NewPartQueue();
    }
  }
}

class _ReportGrid extends ConsumerWidget {
  const _ReportGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(superAdminMetricsProvider);
    final withdraws = ref.watch(superAdminWithdrawQueueProvider);
    final data = metrics.valueOrNull ?? SuperAdminMetrics.demo;
    final cards = [
      _MetricCard('User aktif', '${data.activeUsers}',
          '${data.judges} juri . ${data.communityAdmins} ketua komunitas',
          Icons.people_alt_outlined),
      _MetricCard('Komunitas aktif', '${data.communities}', 'Approved community',
          Icons.groups_2),
      _MetricCard('Turnamen', '${data.tournaments}',
          '${data.runningTournaments} sedang berjalan', Icons.emoji_events),
      _MetricCard('Komponen tercatat', '${data.componentStats}',
          'Stat part dari deck match', Icons.category),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          children: [
            for (final card in cards) SizedBox(width: 270, child: card),
          ],
        ),
        const SizedBox(height: HDTSpace.xl),
        _WithdrawQueuePanel(withdraws: withdraws),
      ],
    );
  }
}

class _ComponentManagement extends ConsumerWidget {
  const _ComponentManagement();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final components = ref.watch(superAdminComponentsProvider);
    final rows = components.valueOrNull ?? const <AdminComponentSummary>[];
    return _DataPanel(
      title: 'MASTER DATA KOMPONEN',
      icon: Icons.category_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Part tambahan dari super admin akan ikut muncul di deck builder user. Stat A/D/S/X/Burst dipakai langsung untuk perhitungan deck, sedangkan performa otomatis tetap dihitung dari match.',
                style: HDTText.body(size: 12, color: HDTColors.text2),
              ),
            ),
            const SizedBox(width: HDTSpace.md),
            ElevatedButton.icon(
              onPressed: () => _openComponentDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADD PART'),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.md),
        components.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(HDTSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ManagementRow(
            item: _DataRowItem(
              'Komponen belum terbaca',
              'RETRY',
              'Data komponen dari Firebase belum bisa dibaca. Coba muat ulang halaman.',
            ),
          ),
          data: (_) => rows.isEmpty
              ? const _ManagementRow(
                  item: _DataRowItem(
                    'Belum ada part custom',
                    'EMPTY',
                    'Klik Add Part untuk membuat komponen baru di luar data BeyBrew bawaan.',
                  ),
                )
              : Column(
                  children: [
                    for (final row in rows) _ComponentAdminRow(item: row),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openComponentDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminComponentSummary? item,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ComponentEditorDialog(item: item),
    );
  }
}

class _ComponentAdminRow extends ConsumerStatefulWidget {
  const _ComponentAdminRow({required this.item});

  final AdminComponentSummary item;

  @override
  ConsumerState<_ComponentAdminRow> createState() => _ComponentAdminRowState();
}

class _ComponentAdminRowState extends ConsumerState<_ComponentAdminRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(
          color: item.active ? HDTColors.s2 : HDTColors.danger.withValues(alpha: .45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.s2),
            ),
            child: Text(item.shortCode, style: HDTText.overline(size: 11)),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: HDTText.display(size: 15)),
                const SizedBox(height: 4),
                Text(
                  '${_categoryLabel(item.category)} . ${item.type} . ${item.line.isEmpty ? 'No line' : item.line} . A${item.stats.attack} D${item.stats.defense} S${item.stats.stamina} X${item.stats.xDash} B${item.stats.burstResistance}',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
                const SizedBox(height: 3),
                Text(
                  'Auto ${item.autoAppearances} played / ${item.autoWins}W ${item.autoLosses}L. Manual adj ${item.manualAppearances} / ${item.manualWins}W ${item.manualLosses}L. Effective ${item.effectiveWinRate.toStringAsFixed(0)}%.',
                  style: HDTText.mono(size: 10, color: HDTColors.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Text(item.active ? 'ACTIVE' : 'HIDDEN',
              style: HDTText.overline(
                size: 9,
                color: item.active ? HDTColors.success : HDTColors.danger,
              )),
          const SizedBox(width: HDTSpace.sm),
          IconButton(
            tooltip: 'Edit part',
            onPressed: _busy
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (_) => _ComponentEditorDialog(item: item),
                    ),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Delete part',
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete component?'),
        content: Text(
          '${widget.item.name} akan dihapus dari master komponen. Statistik match historis tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.componentDoc(widget.item.id))
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komponen sudah dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komponen belum bisa dihapus. Coba ulangi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ComponentEditorDialog extends ConsumerStatefulWidget {
  const _ComponentEditorDialog({this.item});

  final AdminComponentSummary? item;

  @override
  ConsumerState<_ComponentEditorDialog> createState() =>
      _ComponentEditorDialogState();
}

class _ComponentEditorDialogState extends ConsumerState<_ComponentEditorDialog> {
  final _name = TextEditingController();
  final _alias = TextEditingController();
  final _line = TextEditingController();
  final _image = TextEditingController();
  final _integrated = TextEditingController();
  final _description = TextEditingController();
  final _attack = TextEditingController();
  final _defense = TextEditingController();
  final _stamina = TextEditingController();
  final _xDash = TextEditingController();
  final _burst = TextEditingController();
  final _manualAppearances = TextEditingController();
  final _manualWins = TextEditingController();
  final _manualLosses = TextEditingController();

  String _category = 'blades';
  String _type = 'balance';
  bool _active = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _name.text = item.name;
    _alias.text = item.alias ?? '';
    _line.text = item.line;
    _image.text = item.image ?? '';
    _integrated.text = item.integratedRatchet ?? '';
    _description.text = item.description ?? '';
    _attack.text = item.stats.attack.toString();
    _defense.text = item.stats.defense.toString();
    _stamina.text = item.stats.stamina.toString();
    _xDash.text = item.stats.xDash.toString();
    _burst.text = item.stats.burstResistance.toString();
    _manualAppearances.text = item.manualAppearances.toString();
    _manualWins.text = item.manualWins.toString();
    _manualLosses.text = item.manualLosses.toString();
    _category = item.category;
    _type = item.type;
    _active = item.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _alias.dispose();
    _line.dispose();
    _image.dispose();
    _integrated.dispose();
    _description.dispose();
    _attack.dispose();
    _defense.dispose();
    _stamina.dispose();
    _xDash.dispose();
    _burst.dispose();
    _manualAppearances.dispose();
    _manualWins.dispose();
    _manualLosses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return AlertDialog(
      title: Text(editing ? 'Edit Component' : 'Create Component'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _textField(_name, 'Name')),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(child: _textField(_alias, 'Alias / short code')),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final item in _categoryOptions.entries)
                          DropdownMenuItem(value: item.key, child: Text(item.value)),
                      ],
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'blades'),
                    ),
                  ),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'attack', child: Text('Attack')),
                        DropdownMenuItem(value: 'defense', child: Text('Defense')),
                        DropdownMenuItem(value: 'stamina', child: Text('Stamina')),
                        DropdownMenuItem(value: 'balance', child: Text('Balance')),
                      ],
                      onChanged: (value) =>
                          setState(() => _type = value ?? 'balance'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              Row(
                children: [
                  Expanded(child: _textField(_line, 'Line, contoh: BX / UX / CX')),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(child: _textField(_image, 'Image filename')),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              _textField(
                _integrated,
                'Integrated ratchet, jika ada',
              ),
              const SizedBox(height: HDTSpace.md),
              _textField(_description, 'Description'),
              const SizedBox(height: HDTSpace.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Deck Stats', style: HDTText.overline(size: 10)),
              ),
              const SizedBox(height: HDTSpace.sm),
              Row(
                children: [
                  Expanded(child: _numberField(_attack, 'Attack')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_defense, 'Defense')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_stamina, 'Stamina')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_xDash, 'X Dash')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_burst, 'Burst')),
                ],
              ),
              const SizedBox(height: HDTSpace.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Manual Performance Adjustment',
                    style: HDTText.overline(size: 10)),
              ),
              const SizedBox(height: HDTSpace.sm),
              Row(
                children: [
                  Expanded(child: _numberField(_manualAppearances, 'Played +/-')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_manualWins, 'Wins +/-')),
                  const SizedBox(width: HDTSpace.sm),
                  Expanded(child: _numberField(_manualLosses, 'Losses +/-')),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: const Text('Active in deck builder'),
              ),
              if (_error != null) ...[
                const SizedBox(height: HDTSpace.sm),
                Text(_error!, style: HDTText.body(size: 12, color: HDTColors.danger)),
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
          onPressed: _busy ? null : _save,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(_busy ? 'SAVING...' : 'SAVE'),
        ),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama komponen wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = widget.item?.id ?? '${_category}_${_slug(name)}';
    final payload = {
      'id': id,
      'name': name,
      'alias': _nullIfEmpty(_alias.text),
      'category': _category,
      'type': _type,
      'line': _line.text.trim(),
      'image': _nullIfEmpty(_image.text),
      'integratedRatchet': _nullIfEmpty(_integrated.text),
      'description': _nullIfEmpty(_description.text),
      'source': ['Super Admin'],
      'active': _active,
      'stats': PartStats(
        attack: _intOf(_attack),
        defense: _intOf(_defense),
        stamina: _intOf(_stamina),
        xDash: _intOf(_xDash),
        burstResistance: _intOf(_burst),
      ).toMap(),
      'manualPerformance': {
        'appearances': _intOf(_manualAppearances),
        'wins': _intOf(_manualWins),
        'losses': _intOf(_manualLosses),
      },
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.item == null) 'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.componentDoc(id))
          .set(payload, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name tersimpan.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Komponen belum tersimpan. Coba ulangi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _StatsReview extends ConsumerWidget {
  const _StatsReview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(componentStatsReviewProvider);
    final liveRows = live.valueOrNull ?? const <ComponentStatSummary>[];
    if (liveRows.isNotEmpty) {
      return _DataPanel(
        title: 'REVIEW STATISTIK PART',
        icon: Icons.analytics_outlined,
        children: [
          for (final row in liveRows) _ComponentStatReviewRow(stat: row),
        ],
      );
    }
    const rows = [
      _DataRowItem('Wizard Rod 5-70B', '72% win rate',
          'Perlu review karena sample besar dan meta dominan'),
      _DataRowItem('Dran Buster 1-60A', '58% win rate',
          'Performa attack stabil di stage final'),
      _DataRowItem('Phoenix Wing 9-60R', '64% win rate',
          'Banyak dipakai di round robin group A'),
    ];
    return _DataPanel(
      title: 'REVIEW STATISTIK PART',
      icon: Icons.analytics_outlined,
      children: [for (final row in rows) _ManagementRow(item: row)],
    );
  }
}

class _WithdrawQueuePanel extends StatelessWidget {
  const _WithdrawQueuePanel({required this.withdraws});

  final AsyncValue<List<WithdrawRequestSummary>> withdraws;

  @override
  Widget build(BuildContext context) {
    final rows = withdraws.valueOrNull ?? const <WithdrawRequestSummary>[];
    return _DataPanel(
      title: 'WITHDRAW REQUESTS',
      icon: Icons.account_balance_wallet_outlined,
      children: rows.isEmpty
          ? const [
              _ManagementRow(
                item: _DataRowItem(
                  'Belum ada request withdraw',
                  'CLEAR',
                  'Setiap request dari ketua komunitas akan tampil di sini untuk direview super admin.',
                ),
              ),
            ]
          : [for (final row in rows) _WithdrawRequestRow(item: row)],
    );
  }
}

class _WithdrawRequestRow extends ConsumerStatefulWidget {
  const _WithdrawRequestRow({required this.item});

  final WithdrawRequestSummary item;

  @override
  ConsumerState<_WithdrawRequestRow> createState() => _WithdrawRequestRowState();
}

class _WithdrawRequestRowState extends ConsumerState<_WithdrawRequestRow> {
  bool _busy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.requesterName,
                    style: HDTText.display(size: 15)),
              ),
              Text(item.status.toUpperCase(),
                  style: HDTText.overline(size: 9, color: HDTColors.warning)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatRp(item.amount)} ke ${item.bankName} ${item.accountNumber}. Admin menerima nominal net, fee dibebankan ke user.',
            style: HDTText.body(size: 12, color: HDTColors.text2),
          ),
          if (_message != null) ...[
            const SizedBox(height: HDTSpace.sm),
            Text(_message!, style: HDTText.body(size: 11, color: HDTColors.text3)),
          ],
          const SizedBox(height: HDTSpace.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _review('rejected'),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('REJECT'),
              ),
              const SizedBox(width: HDTSpace.sm),
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _review('approved'),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 14),
                label: Text(_busy ? 'SAVING...' : 'APPROVE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(String status) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(firestoreProvider).doc(widget.item.path).set({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _message = 'Withdraw ditandai $status.');
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _message = 'Review withdraw belum tersimpan. Coba ulangi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ComponentStatReviewRow extends StatelessWidget {
  const _ComponentStatReviewRow({required this.stat});

  final ComponentStatSummary stat;

  @override
  Widget build(BuildContext context) {
    return _ManagementRow(
      item: _DataRowItem(
        stat.name,
        '${stat.winRate.toStringAsFixed(0)}% win rate',
        '${stat.appearances} appearance . ${stat.wins}W/${stat.losses}L . ${stat.category} ${stat.line}',
      ),
    );
  }
}

class _NewPartQueue extends StatelessWidget {
  const _NewPartQueue();

  @override
  Widget build(BuildContext context) {
    const rows = [
      _DataRowItem('Samurai Saber', 'Menunggu validasi',
          'Butuh foto, kategori part, dan legalitas format'),
      _DataRowItem('CX Assist Blade sample', 'Draft',
          'Lengkapi hubungan assist blade dan lock chip'),
      _DataRowItem('Integrated line import', 'Siap review',
          'Pastikan part tidak bisa dipisah di deck builder'),
    ];
    return _DataPanel(
      title: 'ANTRIAN PART BARU',
      icon: Icons.new_releases_outlined,
      children: [for (final row in rows) _ManagementRow(item: row)],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.note, this.icon);

  final String label;
  final String value;
  final String note;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(
        accentColor: HDTColors.warning,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HDTColors.warning, size: 22),
          const SizedBox(height: HDTSpace.md),
          Text(label.toUpperCase(),
              style: HDTText.overline(size: 9, color: HDTColors.text3)),
          const SizedBox(height: HDTSpace.xs),
          Text(value, style: HDTText.display(size: 30)),
          const SizedBox(height: HDTSpace.xs),
          Text(note, style: HDTText.body(size: 12, color: HDTColors.text2)),
        ],
      ),
    );
  }
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
              Icon(icon, color: HDTColors.warning, size: 18),
              const SizedBox(width: HDTSpace.sm),
              Text(title, style: HDTText.overline(size: 10)),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          ...children,
        ],
      ),
    );
  }
}

class _ManagementRow extends StatelessWidget {
  const _ManagementRow({required this.item});

  final _DataRowItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: HDTText.display(size: 15)),
                const SizedBox(height: 4),
                Text(item.description,
                    style: HDTText.body(size: 12, color: HDTColors.text2)),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Text(item.status,
              textAlign: TextAlign.right,
              style: HDTText.overline(size: 9, color: HDTColors.warning)),
        ],
      ),
    );
  }
}

class _SectionStatusChip extends StatelessWidget {
  const _SectionStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.md,
        vertical: HDTSpace.sm,
      ),
      decoration: BoxDecoration(
        color: HDTColors.warning.withValues(alpha: .14),
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.warning.withValues(alpha: .34)),
      ),
      child: Text(label.toUpperCase(),
          style: HDTText.overline(size: 9, color: HDTColors.warning)),
    );
  }
}

class _SuperAdminNotice extends StatelessWidget {
  const _SuperAdminNotice.login()
      : title = 'Login diperlukan',
        message = 'Masuk sebagai super admin untuk membuka console platform.';

  const _SuperAdminNotice.permission()
      : title = 'Akses terbatas',
        message = 'Halaman ini khusus untuk super admin platform.';

  const _SuperAdminNotice.backend()
      : title = 'Data belum tersedia',
        message =
            'Console super admin belum bisa membaca data saat ini. Coba kembali beberapa saat lagi.';

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: hdtAccentCard(accentColor: HDTColors.warning),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: HDTText.display(size: 24)),
            const SizedBox(height: HDTSpace.sm),
            Text(message, style: HDTText.body(color: HDTColors.text2)),
          ],
        ),
      ),
    );
  }
}

class _SectionOverview {
  const _SectionOverview({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.status,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String status;
}

class _DataRowItem {
  const _DataRowItem(this.title, this.status, this.description);

  final String title;
  final String status;
  final String description;
}

class SuperAdminMetrics {
  const SuperAdminMetrics({
    required this.activeUsers,
    required this.judges,
    required this.communityAdmins,
    required this.communities,
    required this.tournaments,
    required this.runningTournaments,
    required this.componentStats,
  });

  final int activeUsers;
  final int judges;
  final int communityAdmins;
  final int communities;
  final int tournaments;
  final int runningTournaments;
  final int componentStats;

  static const demo = SuperAdminMetrics(
    activeUsers: 524,
    judges: 32,
    communityAdmins: 18,
    communities: 18,
    tournaments: 42,
    runningTournaments: 2,
    componentStats: 316,
  );
}

class WithdrawRequestSummary {
  const WithdrawRequestSummary({
    required this.id,
    required this.tournamentId,
    required this.requesterName,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.status,
    required this.path,
  });

  final String id;
  final String tournamentId;
  final String requesterName;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String status;
  final String path;

  factory WithdrawRequestSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final tournamentRef = doc.reference.parent.parent;
    return WithdrawRequestSummary(
      id: (data['id'] ?? doc.id).toString(),
      tournamentId: (data['tournamentId'] ?? tournamentRef?.id ?? '').toString(),
      requesterName: (data['requesterName'] ?? 'Ketua komunitas').toString(),
      amount: (data['amount'] as num?)?.round() ?? 0,
      bankName: (data['bankName'] ?? '-').toString(),
      accountNumber: (data['accountNumber'] ?? '-').toString(),
      status: (data['status'] ?? 'requested').toString(),
      path: doc.reference.path,
    );
  }
}

class AdminComponentSummary {
  const AdminComponentSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.line,
    required this.stats,
    required this.active,
    required this.autoAppearances,
    required this.autoWins,
    required this.autoLosses,
    required this.manualAppearances,
    required this.manualWins,
    required this.manualLosses,
    this.alias,
    this.image,
    this.integratedRatchet,
    this.description,
  });

  final String id;
  final String name;
  final String category;
  final String type;
  final String line;
  final PartStats stats;
  final bool active;
  final int autoAppearances;
  final int autoWins;
  final int autoLosses;
  final int manualAppearances;
  final int manualWins;
  final int manualLosses;
  final String? alias;
  final String? image;
  final String? integratedRatchet;
  final String? description;

  String get shortCode {
    if (alias != null && alias!.trim().isNotEmpty) return alias!.trim();
    final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.map((word) => word[0]).take(2).join().toUpperCase();
  }

  int get effectiveAppearances => autoAppearances + manualAppearances;
  int get effectiveWins => autoWins + manualWins;
  int get effectiveLosses => autoLosses + manualLosses;

  double get effectiveWinRate {
    final total = effectiveWins + effectiveLosses;
    if (total <= 0) return 0;
    return effectiveWins / total * 100;
  }

  factory AdminComponentSummary.fromFirestore({
    required QueryDocumentSnapshot<Map<String, dynamic>> component,
    required DocumentSnapshot<Map<String, dynamic>> stat,
  }) {
    final data = component.data();
    final statData = stat.data() ?? const <String, dynamic>{};
    final manual =
        Map<String, dynamic>.from(data['manualPerformance'] as Map? ?? const {});
    final stats = Map<String, dynamic>.from(data['stats'] as Map? ?? const {});
    return AdminComponentSummary(
      id: component.id,
      name: (data['name'] ?? component.id).toString(),
      alias: data['alias']?.toString(),
      category: (data['category'] ?? 'blades').toString(),
      type: (data['type'] ?? 'balance').toString(),
      line: (data['line'] ?? '').toString(),
      image: data['image']?.toString(),
      integratedRatchet: data['integratedRatchet']?.toString(),
      description: data['description']?.toString(),
      active: data['active'] != false,
      stats: PartStats(
        attack: _intFrom(stats['attack']),
        defense: _intFrom(stats['defense']),
        stamina: _intFrom(stats['stamina']),
        xDash: _intFrom(stats['xDash']),
        burstResistance: _intFrom(stats['burstResistance']),
      ),
      autoAppearances: _intFrom(statData['appearances']),
      autoWins: _intFrom(statData['wins']),
      autoLosses: _intFrom(statData['losses']),
      manualAppearances: _intFrom(manual['appearances']),
      manualWins: _intFrom(manual['wins']),
      manualLosses: _intFrom(manual['losses']),
    );
  }
}

class ComponentStatSummary {
  const ComponentStatSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.line,
    required this.appearances,
    required this.wins,
    required this.losses,
  });

  final String id;
  final String name;
  final String category;
  final String line;
  final int appearances;
  final int wins;
  final int losses;

  double get winRate {
    final total = wins + losses;
    if (total == 0) return 0;
    return wins / total * 100;
  }

  factory ComponentStatSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ComponentStatSummary(
      id: (data['partId'] ?? doc.id).toString(),
      name: (data['name'] ?? doc.id).toString(),
      category: (data['category'] ?? '-').toString(),
      line: (data['line'] ?? '-').toString(),
      appearances: (data['appearances'] as num?)?.round() ?? 0,
      wins: (data['wins'] as num?)?.round() ?? 0,
      losses: (data['losses'] as num?)?.round() ?? 0,
    );
  }
}

Set<String> _rolesFromData(Map<String, dynamic> data) {
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

String _normalizeRole(String role) {
  final value = role.trim().toLowerCase();
  if (value == 'superadmin') return 'super_admin';
  if (value == 'communityadmin') return 'community_admin';
  if (value == 'juri') return 'judge';
  return value;
}

String _formatRp(int value) {
  return 'Rp ${value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      )}';
}

const _categoryOptions = {
  'blades': 'Blade',
  'assist_blades': 'Assist Blade',
  'over_blades': 'Over Blade',
  'lock_chips': 'Lock Chip',
  'ratchets': 'Ratchet',
  'bits': 'Bit',
};

String _categoryLabel(String value) {
  return _categoryOptions[value] ?? value;
}

int _intFrom(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _intOf(TextEditingController controller) {
  return int.tryParse(controller.text.trim()) ?? 0;
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _sectionTitle(SuperAdminSection section) {
  switch (section) {
    case SuperAdminSection.reports:
      return 'Laporan Platform';
    case SuperAdminSection.components:
      return 'Manajemen Komponen';
    case SuperAdminSection.componentStats:
      return 'Review Statistik';
    case SuperAdminSection.newParts:
      return 'Part Baru';
  }
}

_SectionOverview _sectionOverview(SuperAdminSection section) {
  switch (section) {
    case SuperAdminSection.reports:
      return const _SectionOverview(
        eyebrow: 'PLATFORM REPORTS',
        title: 'Laporan Operasional BeyTourney',
        description:
            'Ringkasan komunitas, turnamen, match, pembayaran, dan aktivitas platform untuk dipantau oleh super admin.',
        status: 'overview',
      );
    case SuperAdminSection.components:
      return const _SectionOverview(
        eyebrow: 'COMPONENT MASTER',
        title: 'Manajemen Komponen Beyblade',
        description:
            'Tempat super admin mengelola data part utama, kategori CX, assist blade, lock chip, dan part integrated.',
        status: 'master data',
      );
    case SuperAdminSection.componentStats:
      return const _SectionOverview(
        eyebrow: 'PERFORMANCE REVIEW',
        title: 'Review Statistik Komponen',
        description:
            'Pantau win rate, sample size, deck usage, dan performa part sebelum data dipublikasikan ke pemain.',
        status: 'review',
      );
    case SuperAdminSection.newParts:
      return const _SectionOverview(
        eyebrow: 'NEW PARTS',
        title: 'Validasi Part Baru',
        description:
            'Antrian part baru untuk dilengkapi metadata, gambar, legalitas format, dan relasi komponen khusus.',
        status: 'queue',
      );
  }
}
