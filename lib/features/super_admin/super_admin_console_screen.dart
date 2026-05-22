import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../data/models/bey_part.dart';
import '../../data/repositories/auth_repository.dart';

final superAdminMetricsProvider = StreamProvider<SuperAdminMetrics>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.users)
      .limit(1000)
      .snapshots()
      .asyncMap(
    (users) async {
      final tournaments = await firestore
          .collection(FirestorePaths.tournaments)
          .limit(500)
          .get();
      final communities = await firestore
          .collection(FirestorePaths.communities)
          .limit(500)
          .get();
      final components = await firestore
          .collection(FirestorePaths.componentStats)
          .limit(500)
          .get();
      final pendingApplications = await firestore
          .collection(FirestorePaths.communityApplications)
          .where('status', isEqualTo: 'pending')
          .limit(100)
          .get();
      final payments = await firestore
          .collectionGroup(FirestorePaths.payments)
          .limit(500)
          .get();
      final withdrawals = await firestore
          .collectionGroup(FirestorePaths.withdrawals)
          .limit(500)
          .get();
      final grossRevenue = payments.docs
          .where((doc) => (doc.data()['status'] ?? '').toString() == 'paid')
          .fold<int>(
            0,
            (total, doc) => total + _intFrom(doc.data()['amount']),
          );
      final platformRevenue = payments.docs
          .where((doc) => (doc.data()['status'] ?? '').toString() == 'paid')
          .fold<int>(
            0,
            (total, doc) => total + _intFrom(doc.data()['platformFee']),
          );
      final activeWithdrawals = withdrawals.docs
          .where((doc) => ['processing', 'queued', 'requested', 'pending']
              .contains((doc.data()['status'] ?? '').toString().toLowerCase()))
          .fold<int>(
            0,
            (total, doc) => total + _intFrom(doc.data()['amount']),
          );
      return SuperAdminMetrics(
        activeUsers:
            users.docs.where((doc) => doc.data()['isActive'] != false).length,
        bannedUsers:
            users.docs.where((doc) => doc.data()['isActive'] == false).length,
        judges: users.docs
            .where((doc) => _rolesFromData(doc.data()).contains('judge'))
            .length,
        communityAdmins: users.docs
            .where(
                (doc) => _rolesFromData(doc.data()).contains('community_admin'))
            .length,
        communities: communities.docs.length,
        pendingApprovals: pendingApplications.docs.length,
        tournaments: tournaments.docs.length,
        runningTournaments: tournaments.docs
            .where(
                (doc) => (doc.data()['status'] ?? '').toString() == 'running')
            .length,
        componentStats: components.docs.length,
        grossRevenue: grossRevenue,
        platformRevenue: platformRevenue,
        paymentCount: payments.docs.length,
        activeWithdrawals: activeWithdrawals,
      );
    },
  );
});

final componentStatsReviewProvider =
    StreamProvider<List<ComponentStatSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.componentStats)
      .orderBy('appearances', descending: true)
      .limit(25)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ComponentStatSummary.fromFirestore(doc))
          .toList());
});

final weeklyComponentReleaseProvider =
    StreamProvider<WeeklyComponentRelease>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .doc(FirestorePaths.weeklyComponentReleaseDoc('current'))
      .snapshots()
      .map(WeeklyComponentRelease.fromFirestore);
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
      final stat =
          await firestore.doc(FirestorePaths.componentStatDoc(doc.id)).get();
      rows.add(AdminComponentSummary.fromFirestore(
        component: doc,
        stat: stat,
      ));
    }
    return rows;
  });
});

final superAdminUsersProvider = StreamProvider<List<AdminUserSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection(FirestorePaths.users).limit(1000).snapshots().map(
    (snap) {
      final rows = snap.docs.map(AdminUserSummary.fromFirestore).toList();
      rows.sort((a, b) {
        final role = a.roleLabel.compareTo(b.roleLabel);
        if (role != 0) return role;
        return a.displayName.compareTo(b.displayName);
      });
      return rows;
    },
  );
});

final pendingApplicationsPreviewProvider =
    StreamProvider<List<PendingApplicationSummary>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.communityApplications)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: false)
      .limit(5)
      .snapshots()
      .map((snap) =>
          snap.docs.map(PendingApplicationSummary.fromFirestore).toList());
});

enum SuperAdminSection {
  reports,
  components,
  componentStats,
  users,
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
                              size: 10, color: HDTColors.accentHover)),
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
      case SuperAdminSection.users:
        return const _UsersManagement();
    }
  }
}

class _ReportGrid extends ConsumerWidget {
  const _ReportGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(superAdminMetricsProvider);
    final data = metrics.valueOrNull ?? SuperAdminMetrics.demo;
    final cards = [
      _MetricCard(
        label: 'Active users',
        value: '${data.activeUsers}',
        note:
            '${data.judges} judges . ${data.communityAdmins} leads . ${data.bannedUsers} banned',
        icon: Icons.people_alt_outlined,
        color: HDTColors.info,
        route: '/super-admin/users',
      ),
      _MetricCard(
        label: 'Pending approval',
        value: '${data.pendingApprovals}',
        note: 'Community proposals waiting for review',
        icon: Icons.fact_check_outlined,
        color:
            data.pendingApprovals > 0 ? HDTColors.warning : HDTColors.success,
        route: '/super-admin/community-approvals',
      ),
      _MetricCard(
        label: 'Tournaments',
        value: '${data.tournaments}',
        note: '${data.runningTournaments} running',
        icon: Icons.emoji_events_outlined,
        color: HDTColors.accentHover,
        route: '/public/tournaments',
      ),
      _MetricCard(
        label: 'Komponen tercatat',
        value: '${data.componentStats}',
        note: 'Part stats from ranked matches',
        icon: Icons.category_outlined,
        color: HDTColors.success,
        route: '/super-admin/component-stats',
      ),
      _MetricCard(
        label: 'Platform revenue',
        value: _formatRp(data.platformRevenue),
        note: '${data.paymentCount} transaksi paid',
        icon: Icons.account_balance_wallet_outlined,
        color: HDTColors.accent,
        route: '/super-admin/reports',
      ),
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
        _PendingApplicationsPanel(
            applications: ref.watch(pendingApplicationsPreviewProvider)),
        const SizedBox(height: HDTSpace.xl),
        _FinanceStatsPanel(data: data),
      ],
    );
  }
}

class _ComponentManagement extends ConsumerStatefulWidget {
  const _ComponentManagement();

  @override
  ConsumerState<_ComponentManagement> createState() =>
      _ComponentManagementState();
}

class _ComponentManagementState extends ConsumerState<_ComponentManagement> {
  final _search = TextEditingController();
  String _category = 'all';
  String _sort = 'name_asc';
  int _page = 0;
  static const _pageSize = 8;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final components = ref.watch(superAdminComponentsProvider);
    final rows = components.valueOrNull ?? const <AdminComponentSummary>[];
    final filteredRows = _filteredRows(rows);
    final totalPages =
        filteredRows.isEmpty ? 1 : (filteredRows.length / _pageSize).ceil();
    final currentPage = _page.clamp(0, totalPages - 1).toInt();
    final start = currentPage * _pageSize;
    final end = start + _pageSize > filteredRows.length
        ? filteredRows.length
        : start + _pageSize;
    final visibleRows = filteredRows.isEmpty
        ? const <AdminComponentSummary>[]
        : filteredRows.sublist(start, end);
    return _DataPanel(
      title: 'COMPONENT MASTER DATA',
      icon: Icons.category_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Additional parts from super admin will appear in the user deck builder. A/D/S/X/Burst stats are used directly for deck calculations, while performance is still calculated automatically from matches.',
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
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() => _page = 0),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search part...',
                ),
              ),
            ),
            _SmallSelect(
              value: _category,
              width: 180,
              items: const {
                'all': 'All categories',
                'blades': 'Blade',
                'assist_blades': 'Assist Blade',
                'over_blades': 'Over Blade',
                'lock_chips': 'Lock Chip',
                'ratchets': 'Ratchet',
                'bits': 'Bit',
              },
              onChanged: (value) => setState(() {
                _category = value;
                _page = 0;
              }),
            ),
            _SmallSelect(
              value: _sort,
              width: 220,
              items: const {
                'name_asc': 'Name A-Z',
                'category_asc': 'Category',
                'win_rate_desc': 'Highest win rate',
                'played_desc': 'Most played',
              },
              onChanged: (value) => setState(() {
                _sort = value;
                _page = 0;
              }),
            ),
            Text('${filteredRows.length} parts',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
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
              'Components not readable',
              'RETRY',
              'Component data from Firebase could not be read. Try refreshing the page.',
            ),
          ),
          data: (_) => rows.isEmpty
              ? const _ManagementRow(
                  item: _DataRowItem(
                    'No custom parts yet',
                    'EMPTY',
                    'Click Add Part to create a new component outside the built-in BeyBrew data.',
                  ),
                )
              : Column(
                  children: [
                    _PaginationBar(
                      start: filteredRows.isEmpty ? 0 : start + 1,
                      end: end,
                      total: filteredRows.length,
                      page: currentPage,
                      totalPages: totalPages,
                      onPage: (next) => setState(() => _page = next),
                    ),
                    const SizedBox(height: HDTSpace.md),
                    for (final row in visibleRows)
                      _ComponentAdminRow(item: row),
                    const SizedBox(height: HDTSpace.sm),
                    _PaginationBar(
                      start: filteredRows.isEmpty ? 0 : start + 1,
                      end: end,
                      total: filteredRows.length,
                      page: currentPage,
                      totalPages: totalPages,
                      onPage: (next) => setState(() => _page = next),
                      compact: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  List<AdminComponentSummary> _filteredRows(List<AdminComponentSummary> rows) {
    final query = _search.text.trim().toLowerCase();
    final filtered = rows.where((row) {
      final matchesQuery = query.isEmpty ||
          row.name.toLowerCase().contains(query) ||
          row.shortCode.toLowerCase().contains(query) ||
          row.line.toLowerCase().contains(query);
      final matchesCategory = _category == 'all' || row.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();
    filtered.sort((a, b) => _compareAdminComponents(a, b, _sort));
    return filtered;
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
          color: item.active
              ? HDTColors.s2
              : HDTColors.danger.withValues(alpha: .45),
        ),
      ),
      child: Row(
        children: [
          _ComponentThumb(item: item, size: 52),
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
          '${widget.item.name} will be deleted from the component master. Historical match statistics remain stored.',
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
        const SnackBar(content: Text('Component deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Component could not be deleted. Try again.')),
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

class _ComponentEditorDialogState
    extends ConsumerState<_ComponentEditorDialog> {
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
    _name.addListener(_refreshPreview);
    _alias.addListener(_refreshPreview);
    _image.addListener(_refreshPreview);
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
    _name.removeListener(_refreshPreview);
    _alias.removeListener(_refreshPreview);
    _image.removeListener(_refreshPreview);
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

  void _refreshPreview() {
    if (mounted) setState(() {});
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
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final item in _categoryOptions.entries)
                          DropdownMenuItem(
                              value: item.key, child: Text(item.value)),
                      ],
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'blades'),
                    ),
                  ),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'attack', child: Text('Attack')),
                        DropdownMenuItem(
                            value: 'defense', child: Text('Defense')),
                        DropdownMenuItem(
                            value: 'stamina', child: Text('Stamina')),
                        DropdownMenuItem(
                            value: 'balance', child: Text('Balance')),
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
                  Expanded(
                      child: _textField(_line, 'Line, contoh: BX / UX / CX')),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(child: _textField(_image, 'Image filename / URL')),
                ],
              ),
              const SizedBox(height: HDTSpace.md),
              Row(
                children: [
                  _ComponentImagePreview(
                    image: _image.text,
                    shortCode: _alias.text.trim().isEmpty
                        ? _slug(_name.text)
                            .split('_')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : _alias.text.trim(),
                    category: _category,
                  ),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(
                    child: Text(
                      'Upload stores the file in Firebase Storage, then fills the image URL for this part.',
                      style: HDTText.body(
                        size: 12,
                        color: HDTColors.text2,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: HDTSpace.md),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _uploadImage,
                    icon: const Icon(Icons.upload_file_outlined, size: 16),
                    label: const Text('UPLOAD IMAGE'),
                  ),
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
                  Expanded(
                      child: _numberField(_manualAppearances, 'Played +/-')),
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
                Text(_error!,
                    style: HDTText.body(size: 12, color: HDTColors.danger)),
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

  Future<void> _uploadImage() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
          () => _error = 'Enter the component name before uploading an image.');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Image file could not be read.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = widget.item?.id ?? '${_category}_${_slug(name)}';
      final safeName = file.name
          .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final ref = FirebaseStorage.instance.ref(
        'components/$id/${DateTime.now().millisecondsSinceEpoch}_$safeName',
      );
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(file)),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      _image.text = url;
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'Image upload failed. Make sure the super admin account and Storage are active.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Component name is required.');
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
        SnackBar(content: Text('$name saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Component was not saved. Try again.');
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
    final release = ref.watch(weeklyComponentReleaseProvider);
    final liveRows = live.valueOrNull ?? const <ComponentStatSummary>[];
    final releaseData = release.valueOrNull ?? WeeklyComponentRelease.empty;
    return _DataPanel(
      title: 'REVIEW STATISTIK PART',
      icon: Icons.analytics_outlined,
      children: [
        _WeeklyReleasePanel(
          release: releaseData,
          topRows: liveRows,
        ),
        const SizedBox(height: HDTSpace.md),
        live.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(HDTSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ManagementRow(
            item: _DataRowItem(
              'Stats not readable',
              'RETRY',
              'componentStats data could not be read. Try refreshing the page.',
            ),
          ),
          data: (_) => liveRows.isEmpty
              ? const _ManagementRow(
                  item: _DataRowItem(
                    'No stats yet',
                    'EMPTY',
                    'Component stats will be filled from matches or demo seed data.',
                  ),
                )
              : Column(
                  children: [
                    for (final row in liveRows)
                      _ComponentStatReviewRow(
                        stat: row,
                        selected: releaseData.selectedIds.contains(row.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ComponentStatReviewRow extends ConsumerStatefulWidget {
  const _ComponentStatReviewRow({
    required this.stat,
    required this.selected,
  });

  final ComponentStatSummary stat;
  final bool selected;

  @override
  ConsumerState<_ComponentStatReviewRow> createState() =>
      _ComponentStatReviewRowState();
}

class _ComponentStatReviewRowState
    extends ConsumerState<_ComponentStatReviewRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(
          color: widget.selected
              ? HDTColors.accentHover.withValues(alpha: .55)
              : HDTColors.s2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.selected
                  ? HDTColors.accent.withValues(alpha: .18)
                  : HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(
                color: widget.selected ? HDTColors.accentHover : HDTColors.s2,
              ),
            ),
            child: Text(
              '${stat.winRate.toStringAsFixed(0)}%',
              style: HDTText.display(
                size: 13,
                color: widget.selected ? HDTColors.accentHover : HDTColors.text,
              ),
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.name, style: HDTText.display(size: 15)),
                const SizedBox(height: 4),
                Text(
                  '${stat.appearances} appearance . ${stat.wins}W/${stat.losses}L . ${stat.category} ${stat.line}',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Text(
            widget.selected ? 'FEATURED' : 'AUTO POOL',
            style: HDTText.overline(
              size: 9,
              color: widget.selected ? HDTColors.accentHover : HDTColors.text3,
            ),
          ),
          const SizedBox(width: HDTSpace.sm),
          IconButton(
            tooltip: widget.selected ? 'Remove featured' : 'Feature this week',
            onPressed: _busy ? null : _toggleFeatured,
            icon: Icon(
              widget.selected ? Icons.star : Icons.star_border,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'Edit statistic',
            onPressed: _busy ? null : _editStat,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFeatured() async {
    setState(() => _busy = true);
    try {
      final doc = ref
          .read(firestoreProvider)
          .doc(FirestorePaths.weeklyComponentReleaseDoc('current'));
      final snap = await doc.get();
      final release = WeeklyComponentRelease.fromFirestore(snap);
      final selected = [...release.selectedIds];
      if (selected.contains(widget.stat.id)) {
        selected.remove(widget.stat.id);
      } else {
        selected.add(widget.stat.id);
      }
      await doc.set({
        'id': 'current',
        'weekLabel': _currentWeekLabel(),
        'source': selected.isEmpty ? 'auto' : 'manual',
        'selectedIds': selected.take(4).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editStat() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ComponentStatEditorDialog(stat: widget.stat),
    );
  }
}

class _UsersManagement extends ConsumerStatefulWidget {
  const _UsersManagement();

  @override
  ConsumerState<_UsersManagement> createState() => _UsersManagementState();
}

class _UsersManagementState extends ConsumerState<_UsersManagement> {
  final _search = TextEditingController();
  String _status = 'all';
  String _role = 'all';
  int _page = 0;
  static const _pageSize = 10;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(superAdminUsersProvider);
    final rows = users.valueOrNull ?? const <AdminUserSummary>[];
    final filtered = _filteredRows(rows);
    final totalPages =
        filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final currentPage = _page.clamp(0, totalPages - 1).toInt();
    final start = currentPage * _pageSize;
    final end = start + _pageSize > filtered.length
        ? filtered.length
        : start + _pageSize;
    final visible = filtered.isEmpty
        ? const <AdminUserSummary>[]
        : filtered.sublist(start, end);
    return _DataPanel(
      title: 'SEMUA USER & ROLE',
      icon: Icons.manage_accounts_outlined,
      children: [
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() => _page = 0),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search name, email, UID...',
                ),
              ),
            ),
            _SmallSelect(
              value: _status,
              width: 150,
              items: const {
                'all': 'All status',
                'active': 'Active',
                'banned': 'Banned',
              },
              onChanged: (value) => setState(() {
                _status = value;
                _page = 0;
              }),
            ),
            _SmallSelect(
              value: _role,
              width: 190,
              items: const {
                'all': 'All roles',
                'player': 'Player',
                'judge': 'Judge',
                'community_admin': 'Community lead',
                'mixed': 'Lead + Judge',
              },
              onChanged: (value) => setState(() {
                _role = value;
                _page = 0;
              }),
            ),
            Text('${filtered.length} users',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ],
        ),
        const SizedBox(height: HDTSpace.md),
        users.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(HDTSpace.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ManagementRow(
            item: _DataRowItem(
              'Users not readable',
              'RETRY',
              'Users data from Firebase could not be read.',
            ),
          ),
          data: (_) => Column(
            children: [
              _PaginationBar(
                start: filtered.isEmpty ? 0 : start + 1,
                end: end,
                total: filtered.length,
                page: currentPage,
                totalPages: totalPages,
                onPage: (next) => setState(() => _page = next),
              ),
              const SizedBox(height: HDTSpace.md),
              if (visible.isEmpty)
                const _ManagementRow(
                  item: _DataRowItem(
                    'No users',
                    'EMPTY',
                    'No users match the current filter.',
                  ),
                )
              else
                for (final row in visible) _AdminUserRow(user: row),
              const SizedBox(height: HDTSpace.sm),
              _PaginationBar(
                start: filtered.isEmpty ? 0 : start + 1,
                end: end,
                total: filtered.length,
                page: currentPage,
                totalPages: totalPages,
                onPage: (next) => setState(() => _page = next),
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<AdminUserSummary> _filteredRows(List<AdminUserSummary> rows) {
    final query = _search.text.trim().toLowerCase();
    return rows.where((user) {
      final matchesQuery = query.isEmpty ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.uid.toLowerCase().contains(query);
      final matchesStatus = _status == 'all' ||
          (_status == 'active' && user.active) ||
          (_status == 'banned' && !user.active);
      final matchesRole = switch (_role) {
        'judge' => user.roles.contains('judge') &&
            !user.roles.contains('community_admin'),
        'community_admin' => user.roles.contains('community_admin') &&
            !user.roles.contains('judge'),
        'mixed' => user.roles.contains('community_admin') &&
            user.roles.contains('judge'),
        'player' => !user.roles.contains('judge') &&
            !user.roles.contains('community_admin') &&
            !user.roles.contains('super_admin'),
        _ => true,
      };
      return matchesQuery && matchesStatus && matchesRole;
    }).toList();
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: () {
        final current = ModalRoute.of(context)?.settings.name;
        if (current != route) Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 154),
        padding: const EdgeInsets.all(HDTSpace.lg),
        decoration: BoxDecoration(
          color: HDTColors.s1,
          borderRadius: HDTR.lg,
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 21),
                const Spacer(),
                Icon(Icons.chevron_right, color: color, size: 18),
              ],
            ),
            const Spacer(),
            Text(label.toUpperCase(),
                style: HDTText.overline(size: 9, color: HDTColors.text3)),
            const SizedBox(height: HDTSpace.xs),
            Text(value, style: HDTText.display(size: 28)),
            const SizedBox(height: HDTSpace.xs),
            Text(note, style: HDTText.body(size: 12, color: HDTColors.text2)),
          ],
        ),
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
              Icon(icon, color: HDTColors.accentHover, size: 18),
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

class _SmallSelect extends StatelessWidget {
  const _SmallSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 180,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(),
        items: [
          for (final item in items.entries)
            DropdownMenuItem(value: item.key, child: Text(item.value)),
        ],
        onChanged: (next) => onChanged(next ?? value),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onPage,
    this.compact = false,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: HDTSpace.md,
      runSpacing: HDTSpace.sm,
      children: [
        SizedBox(
          width: compact ? 260 : 340,
          child: Text(
            total == 0 ? 'No matching data.' : 'Showing $start-$end of $total',
            style: HDTText.mono(size: 11, color: HDTColors.text3),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'First page',
              onPressed: page <= 0 ? null : () => onPage(0),
              icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: page <= 0 ? null : () => onPage(page - 1),
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Container(
              width: 88,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HDTColors.bg,
                borderRadius: HDTR.sm,
                border: Border.all(color: HDTColors.s2),
              ),
              child: Text(
                '${page + 1} / $totalPages',
                style: HDTText.mono(size: 11, color: HDTColors.text2),
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: page >= totalPages - 1 ? null : () => onPage(page + 1),
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
            IconButton(
              tooltip: 'Last page',
              onPressed:
                  page >= totalPages - 1 ? null : () => onPage(totalPages - 1),
              icon: const Icon(Icons.keyboard_double_arrow_right, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComponentThumb extends StatelessWidget {
  const _ComponentThumb({required this.item, this.size = 46});

  final AdminComponentSummary item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _ImageBox(
      image: item.image,
      shortCode: item.shortCode,
      category: item.category,
      size: size,
    );
  }
}

class _ComponentImagePreview extends StatelessWidget {
  const _ComponentImagePreview({
    required this.image,
    required this.shortCode,
    required this.category,
  });

  final String image;
  final String shortCode;
  final String category;

  @override
  Widget build(BuildContext context) {
    return _ImageBox(
      image: image,
      shortCode: shortCode.isEmpty ? '?' : shortCode,
      category: category,
      size: 72,
    );
  }
}

class _ImageBox extends StatelessWidget {
  const _ImageBox({
    required this.image,
    required this.shortCode,
    required this.category,
    required this.size,
  });

  final String? image;
  final String shortCode;
  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = image?.trim();
    final Widget child;
    if (value == null || value.isEmpty) {
      child = _ImageFallback(shortCode: shortCode, category: category);
    } else if (_isNetworkImage(value)) {
      child = Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(shortCode: shortCode, category: category),
      );
    } else {
      child = Image.asset(
        'assets/beybrew/parts/$value',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(shortCode: shortCode, category: category),
      );
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: child,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.shortCode, required this.category});

  final String shortCode;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_categoryIcon(category), color: HDTColors.text3, size: 18),
        const SizedBox(height: 3),
        Text(shortCode, style: HDTText.overline(size: 9)),
      ],
    );
  }
}

class _WeeklyReleasePanel extends ConsumerStatefulWidget {
  const _WeeklyReleasePanel({
    required this.release,
    required this.topRows,
  });

  final WeeklyComponentRelease release;
  final List<ComponentStatSummary> topRows;

  @override
  ConsumerState<_WeeklyReleasePanel> createState() =>
      _WeeklyReleasePanelState();
}

class _WeeklyReleasePanelState extends ConsumerState<_WeeklyReleasePanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final manual = widget.release.selectedIds.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Wrap(
        spacing: HDTSpace.lg,
        runSpacing: HDTSpace.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEEKLY FRONT PAGE RELEASE',
                    style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.xs),
                Text(
                  manual
                      ? '${widget.release.selectedIds.length} components manually selected for ${widget.release.weekLabel}.'
                      : 'Homepage automatically uses the highest top win rate when no manual choice is set.',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: manual ? 'MANUAL' : 'AUTO TOP WR',
            color: manual ? HDTColors.accentHover : HDTColors.success,
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _setAuto,
            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
            label: const Text('AUTO TOP WIN RATE'),
          ),
          ElevatedButton.icon(
            onPressed: _busy ? null : _publishTopFour,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_outlined, size: 16),
            label: const Text('PUBLISH TOP 4'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAuto() {
    return _writeRelease(const <String>[], 'auto');
  }

  Future<void> _publishTopFour() {
    final rows = [...widget.topRows]..sort((a, b) {
        final rate = b.winRate.compareTo(a.winRate);
        if (rate != 0) return rate;
        return b.appearances.compareTo(a.appearances);
      });
    return _writeRelease(rows.take(4).map((row) => row.id).toList(), 'manual');
  }

  Future<void> _writeRelease(List<String> selectedIds, String source) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.weeklyComponentReleaseDoc('current'))
          .set({
        'id': 'current',
        'weekLabel': _currentWeekLabel(),
        'source': source,
        'selectedIds': selectedIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HDTSpace.sm,
        vertical: HDTSpace.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: HDTR.sm,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(label, style: HDTText.overline(size: 8, color: color)),
    );
  }
}

class _ComponentStatEditorDialog extends ConsumerStatefulWidget {
  const _ComponentStatEditorDialog({required this.stat});

  final ComponentStatSummary stat;

  @override
  ConsumerState<_ComponentStatEditorDialog> createState() =>
      _ComponentStatEditorDialogState();
}

class _ComponentStatEditorDialogState
    extends ConsumerState<_ComponentStatEditorDialog> {
  late final TextEditingController _appearances;
  late final TextEditingController _wins;
  late final TextEditingController _losses;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _appearances =
        TextEditingController(text: widget.stat.appearances.toString());
    _wins = TextEditingController(text: widget.stat.wins.toString());
    _losses = TextEditingController(text: widget.stat.losses.toString());
  }

  @override
  void dispose() {
    _appearances.dispose();
    _wins.dispose();
    _losses.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Statistik ${widget.stat.name}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _numberField(_appearances, 'Appearances')),
                const SizedBox(width: HDTSpace.sm),
                Expanded(child: _numberField(_wins, 'Wins')),
                const SizedBox(width: HDTSpace.sm),
                Expanded(child: _numberField(_losses, 'Losses')),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: HDTSpace.md),
              Text(_error!, style: HDTText.body(color: HDTColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: Text(_busy ? 'SAVING...' : 'SAVE'),
        ),
      ],
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.componentStatDoc(widget.stat.id))
          .set({
        'partId': widget.stat.id,
        'name': widget.stat.name,
        'category': widget.stat.category,
        'line': widget.stat.line,
        'appearances': _intOf(_appearances),
        'wins': _intOf(_wins),
        'losses': _intOf(_losses),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = 'Stats were not saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PendingApplicationsPanel extends StatelessWidget {
  const _PendingApplicationsPanel({required this.applications});

  final AsyncValue<List<PendingApplicationSummary>> applications;

  @override
  Widget build(BuildContext context) {
    final rows =
        applications.valueOrNull ?? const <PendingApplicationSummary>[];
    return _DataPanel(
      title: 'NEW COMMUNITY APPLICATIONS',
      icon: Icons.fact_check_outlined,
      children: [
        if (rows.isEmpty)
          const _ManagementRow(
            item: _DataRowItem(
              'No pending communities',
              'CLEAR',
              'Every community that registers from the public page enters this queue.',
            ),
          )
        else
          for (final row in rows.take(3))
            _ManagementRow(
              item: _DataRowItem(
                row.communityName,
                row.city.toUpperCase(),
                'Diajukan oleh ${row.leaderUserId}. ${row.description}',
              ),
            ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/super-admin/community-approvals',
            ),
            icon: const Icon(Icons.chevron_right, size: 16),
            label: const Text('OPEN APPROVAL QUEUE'),
          ),
        ),
      ],
    );
  }
}

class _FinanceStatsPanel extends StatelessWidget {
  const _FinanceStatsPanel({
    required this.data,
  });

  final SuperAdminMetrics data;

  @override
  Widget build(BuildContext context) {
    return _DataPanel(
      title: 'STATISTIK KEUANGAN',
      icon: Icons.payments_outlined,
      children: [
        Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          children: [
            _FinanceTile(
              label: 'GMV',
              value: _formatRp(data.grossRevenue),
              color: HDTColors.success,
            ),
            _FinanceTile(
              label: 'Platform revenue',
              value: _formatRp(data.platformRevenue),
              color: HDTColors.accentHover,
            ),
            _FinanceTile(
              label: 'Withdrawals processing',
              value: _formatRp(data.activeWithdrawals),
              color: HDTColors.warning,
            ),
            _FinanceTile(
              label: 'Transaksi paid',
              value: '${data.paymentCount}',
              color: HDTColors.info,
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.md),
        Text(
          'Withdrawals are created and tracked from the Community Lead page; Super Admin only sees platform finance aggregates.',
          style: HDTText.body(size: 12, color: HDTColors.text2),
        ),
      ],
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: HDTText.overline(size: 9, color: HDTColors.text3)),
          const SizedBox(height: HDTSpace.xs),
          Text(value, style: HDTText.display(size: 21, color: color)),
        ],
      ),
    );
  }
}

class _AdminUserRow extends ConsumerStatefulWidget {
  const _AdminUserRow({required this.user});

  final AdminUserSummary user;

  @override
  ConsumerState<_AdminUserRow> createState() => _AdminUserRowState();
}

class _AdminUserRowState extends ConsumerState<_AdminUserRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final locked = user.roles.contains('super_admin');
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.all(
          color: user.active
              ? HDTColors.s2
              : HDTColors.danger.withValues(alpha: .45),
        ),
      ),
      child: Row(
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: HDTText.display(size: 14)),
                const SizedBox(height: 3),
                Text(user.uid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HDTText.body(size: 12, color: HDTColors.text2)),
          ),
          SizedBox(
            width: 138,
            child: _StatusPill(
              label: user.roleLabel,
              color: user.roleColor,
            ),
          ),
          SizedBox(
            width: 74,
            child: Text('${user.eloRating}',
                style: HDTText.mono(size: 12, color: HDTColors.text2)),
          ),
          SizedBox(
            width: 76,
            child: _StatusPill(
              label: user.active ? 'ACTIVE' : 'BANNED',
              color: user.active ? HDTColors.success : HDTColors.danger,
            ),
          ),
          const SizedBox(width: HDTSpace.sm),
          PopupMenuButton<String>(
            tooltip: 'Set role',
            enabled: !_busy && !locked,
            onSelected: _setRole,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'player', child: Text('Player')),
              PopupMenuItem(value: 'judge', child: Text('Judge')),
              PopupMenuItem(
                  value: 'community_admin', child: Text('Community lead')),
              PopupMenuItem(value: 'mixed', child: Text('Lead + Judge')),
            ],
            child: Icon(
              Icons.admin_panel_settings_outlined,
              size: 19,
              color: locked ? HDTColors.text3 : HDTColors.text2,
            ),
          ),
          IconButton(
            tooltip: user.active ? 'Ban user' : 'Unban user',
            onPressed: _busy || locked ? null : _toggleBan,
            icon: Icon(
              user.active ? Icons.block : Icons.check_circle_outline,
              size: 18,
              color: user.active ? HDTColors.danger : HDTColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBan() async {
    setState(() => _busy = true);
    try {
      final actor = ref.read(firebaseAuthProvider).currentUser?.uid;
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.userDoc(widget.user.uid))
          .set({
        'isActive': !widget.user.active,
        if (widget.user.active) 'bannedAt': FieldValue.serverTimestamp(),
        if (widget.user.active) 'bannedBy': actor,
        if (!widget.user.active) 'unbannedAt': FieldValue.serverTimestamp(),
        if (!widget.user.active) 'unbannedBy': actor,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setRole(String value) async {
    setState(() => _busy = true);
    try {
      final roles = <String>{'player'};
      if (value == 'judge' || value == 'mixed') roles.add('judge');
      if (value == 'community_admin' || value == 'mixed') {
        roles.add('community_admin');
      }
      await ref
          .read(firestoreProvider)
          .doc(FirestorePaths.userDoc(widget.user.uid))
          .set({
        'role': _primaryRole(roles),
        'roles': roles.toList()..sort(),
        'roleUpdatedAt': FieldValue.serverTimestamp(),
        'roleUpdatedBy': ref.read(firebaseAuthProvider).currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    final initial =
        user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase();
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: user.roleColor.withValues(alpha: .28),
        borderRadius: HDTR.md,
        border: Border.all(color: user.roleColor.withValues(alpha: .45)),
      ),
      child: Text(initial, style: HDTText.display(size: 14)),
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
        color: HDTColors.accent.withValues(alpha: .12),
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.accentHover.withValues(alpha: .32)),
      ),
      child: Text(label.toUpperCase(),
          style: HDTText.overline(size: 9, color: HDTColors.accentHover)),
    );
  }
}

class _SuperAdminNotice extends StatelessWidget {
  const _SuperAdminNotice.login()
      : title = 'Login required',
        message = 'Sign in as super admin to open the platform console.';

  const _SuperAdminNotice.permission()
      : title = 'Restricted access',
        message = 'This page is only for platform super admins.';

  const _SuperAdminNotice.backend()
      : title = 'Data not available yet',
        message =
            'The super admin console cannot read data right now. Try again in a moment.';

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
    required this.bannedUsers,
    required this.judges,
    required this.communityAdmins,
    required this.communities,
    required this.pendingApprovals,
    required this.tournaments,
    required this.runningTournaments,
    required this.componentStats,
    required this.grossRevenue,
    required this.platformRevenue,
    required this.paymentCount,
    required this.activeWithdrawals,
  });

  final int activeUsers;
  final int bannedUsers;
  final int judges;
  final int communityAdmins;
  final int communities;
  final int pendingApprovals;
  final int tournaments;
  final int runningTournaments;
  final int componentStats;
  final int grossRevenue;
  final int platformRevenue;
  final int paymentCount;
  final int activeWithdrawals;

  static const demo = SuperAdminMetrics(
    activeUsers: 524,
    bannedUsers: 3,
    judges: 32,
    communityAdmins: 18,
    communities: 18,
    pendingApprovals: 2,
    tournaments: 42,
    runningTournaments: 2,
    componentStats: 316,
    grossRevenue: 428500000,
    platformRevenue: 42850000,
    paymentCount: 1482,
    activeWithdrawals: 8300000,
  );
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
    final manual = Map<String, dynamic>.from(
        data['manualPerformance'] as Map? ?? const {});
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

class WeeklyComponentRelease {
  const WeeklyComponentRelease({
    required this.id,
    required this.weekLabel,
    required this.source,
    required this.selectedIds,
  });

  final String id;
  final String weekLabel;
  final String source;
  final List<String> selectedIds;

  static const empty = WeeklyComponentRelease(
    id: 'current',
    weekLabel: 'auto',
    source: 'auto',
    selectedIds: [],
  );

  factory WeeklyComponentRelease.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return WeeklyComponentRelease(
      id: doc.id,
      weekLabel: (data['weekLabel'] ?? _currentWeekLabel()).toString(),
      source: (data['source'] ?? 'auto').toString(),
      selectedIds: ((data['selectedIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.region,
    required this.roles,
    required this.active,
    required this.eloRating,
    required this.totalMatches,
  });

  final String uid;
  final String displayName;
  final String email;
  final String region;
  final Set<String> roles;
  final bool active;
  final int eloRating;
  final int totalMatches;

  String get roleLabel {
    if (roles.contains('super_admin')) return 'SUPER ADMIN';
    if (roles.contains('community_admin') && roles.contains('judge')) {
      return 'LEAD / JUDGE';
    }
    if (roles.contains('community_admin')) return 'LEAD';
    if (roles.contains('judge')) return 'JUDGE';
    return 'PLAYER';
  }

  Color get roleColor {
    if (roles.contains('super_admin')) return HDTColors.accentHover;
    if (roles.contains('community_admin') && roles.contains('judge')) {
      return HDTColors.info;
    }
    if (roles.contains('community_admin')) return HDTColors.success;
    if (roles.contains('judge')) return HDTColors.accent;
    return HDTColors.text3;
  }

  factory AdminUserSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AdminUserSummary(
      uid: doc.id,
      displayName: (data['displayName'] ?? data['name'] ?? doc.id).toString(),
      email: (data['email'] ?? '').toString(),
      region: (data['region'] ?? '-').toString(),
      roles: _rolesFromData(data),
      active: data['isActive'] != false,
      eloRating: _intFrom(data['eloRating']),
      totalMatches: _intFrom(data['totalMatches']),
    );
  }
}

class PendingApplicationSummary {
  const PendingApplicationSummary({
    required this.id,
    required this.communityName,
    required this.city,
    required this.leaderUserId,
    required this.description,
  });

  final String id;
  final String communityName;
  final String city;
  final String leaderUserId;
  final String description;

  factory PendingApplicationSummary.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PendingApplicationSummary(
      id: doc.id,
      communityName: (data['communityName'] ?? doc.id).toString(),
      city: (data['city'] ?? '-').toString(),
      leaderUserId: (data['leaderUserId'] ?? '-').toString(),
      description: (data['description'] ?? '').toString(),
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

String _primaryRole(Set<String> roles) {
  if (roles.contains('super_admin')) return 'super_admin';
  if (roles.contains('community_admin')) return 'community_admin';
  if (roles.contains('judge')) return 'judge';
  return 'player';
}

int _compareAdminComponents(
  AdminComponentSummary a,
  AdminComponentSummary b,
  String sort,
) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return switch (sort) {
    'category_asc' =>
      a.category == b.category ? byName : a.category.compareTo(b.category),
    'win_rate_desc' => b.effectiveWinRate.compareTo(a.effectiveWinRate) == 0
        ? byName
        : b.effectiveWinRate.compareTo(a.effectiveWinRate),
    'played_desc' => b.effectiveAppearances == a.effectiveAppearances
        ? byName
        : b.effectiveAppearances.compareTo(a.effectiveAppearances),
    _ => byName,
  };
}

IconData _categoryIcon(String value) {
  return switch (value) {
    'assist_blades' => Icons.extension_outlined,
    'over_blades' => Icons.layers_outlined,
    'lock_chips' => Icons.lock_outline,
    'ratchets' => Icons.adjust,
    'bits' => Icons.radio_button_checked,
    _ => Icons.hexagon_outlined,
  };
}

String _contentTypeFor(PlatformFile file) {
  return switch (file.extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/png',
  };
}

String _currentWeekLabel() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
  final week = ((dayOfYear - now.weekday + 10) / 7).floor();
  return '${now.year}-W${week.toString().padLeft(2, '0')}';
}

bool _isNetworkImage(String value) {
  final lower = value.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
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
    case SuperAdminSection.users:
      return 'Users & Roles';
  }
}

_SectionOverview _sectionOverview(SuperAdminSection section) {
  switch (section) {
    case SuperAdminSection.reports:
      return const _SectionOverview(
        eyebrow: 'PLATFORM REPORTS',
        title: 'Laporan Operasional BeyTourney',
        description:
            'Summary of communities, tournaments, matches, payments, and platform activity for super admin monitoring.',
        status: 'overview',
      );
    case SuperAdminSection.components:
      return const _SectionOverview(
        eyebrow: 'COMPONENT MASTER',
        title: 'Manajemen Komponen Beyblade',
        description:
            'A place for super admins to manage core part data, CX categories, assist blades, lock chips, and integrated parts.',
        status: 'master data',
      );
    case SuperAdminSection.componentStats:
      return const _SectionOverview(
        eyebrow: 'PERFORMANCE REVIEW',
        title: 'Review Statistik Komponen',
        description:
            'Monitor win rate, sample size, deck usage, and part performance before data is published to players.',
        status: 'review',
      );
    case SuperAdminSection.users:
      return const _SectionOverview(
        eyebrow: 'USER MANAGEMENT',
        title: 'User and Role Management',
        description:
            'View every account, active/banned status, and manage roles as player, judge, community lead, or both.',
        status: 'role control',
      );
  }
}
