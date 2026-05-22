// ============================================================
// NOTIFICATIONS SCREEN  — Riverpod + Pagination
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/hideout_tokens.dart';
import '../../core/widgets/hdt_widgets.dart';

// ─── Model ──────────────────────────────────────────────────
enum NotifType { match, tournament, trophy, community, system }

extension NotifTypeMeta on NotifType {
  String get label {
    switch (this) {
      case NotifType.match:
        return 'MATCH';
      case NotifType.tournament:
        return 'TOURNAMENT';
      case NotifType.trophy:
        return 'TROPHY';
      case NotifType.community:
        return 'COMMUNITY';
      case NotifType.system:
        return 'SYSTEM';
    }
  }

  Color get color {
    switch (this) {
      case NotifType.match:
        return HDTColors.info;
      case NotifType.tournament:
        return HDTColors.accent;
      case NotifType.trophy:
        return HDTColors.warning;
      case NotifType.community:
        return HDTColors.success;
      case NotifType.system:
        return HDTColors.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case NotifType.match:
        return Icons.sports_mma;
      case NotifType.tournament:
        return Icons.emoji_events;
      case NotifType.trophy:
        return Icons.military_tech;
      case NotifType.community:
        return Icons.groups;
      case NotifType.system:
        return Icons.warning_amber;
    }
  }
}

class NotifItem {
  final String id, title, body, ts;
  final NotifType type;
  bool read;
  final bool pinned;
  final String? actorName;
  final Color? actorColor;
  final String? ctaLabel;
  final String? ctaRoute;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.ts,
    required this.type,
    this.read = false,
    this.pinned = false,
    this.actorName,
    this.actorColor,
    this.ctaLabel,
    this.ctaRoute,
  });

  NotifItem copyWith({bool? read}) => NotifItem(
        id: id,
        title: title,
        body: body,
        ts: ts,
        type: type,
        read: read ?? this.read,
        pinned: pinned,
        actorName: actorName,
        actorColor: actorColor,
        ctaLabel: ctaLabel,
        ctaRoute: ctaRoute,
      );
}

// Seed data
List<NotifItem> _seedNotifs() => [
      NotifItem(
          id: 'n1',
          title: 'BJX Cup #4 - Bracket announced',
          body: 'Your first match vs RAYHAN is at Arena 02, 14:30.',
          ts: '2 minutes ago',
          type: NotifType.tournament,
          read: false,
          pinned: true,
          actorName: 'HIDEOUT',
          actorColor: HDTColors.accent,
          ctaLabel: 'VIEW BRACKET'),
      NotifItem(
          id: 'n2',
          title: 'Match starts in 30 minutes',
          body:
              'Make sure your deck is locked. Check the QR pass in your profile.',
          ts: '12 minutes ago',
          type: NotifType.match,
          read: false,
          actorName: 'Arena 02',
          actorColor: HDTColors.info,
          ctaLabel: 'OPEN QR'),
      NotifItem(
          id: 'n3',
          title: 'Trophy unlocked: 5-Match Streak',
          body: 'You won 5 matches in a row. Keep grinding!',
          ts: '1 hour ago',
          type: NotifType.trophy,
          read: false,
          actorName: 'HIDEOUT',
          actorColor: HDTColors.warning),
      NotifItem(
          id: 'n4',
          title: 'KAEDE challenged you',
          body: '"Sparring Saturday at 16:00 in Senayan?"',
          ts: '3 hours ago',
          type: NotifType.community,
          read: true,
          actorName: 'KAEDE',
          actorColor: HDTColors.accent,
          ctaLabel: 'REPLY'),
      NotifItem(
          id: 'n5',
          title: 'Tournament rules update',
          body: 'BJX Cup #4 bans Cobalt Dragoon. Check your deck.',
          ts: '5 hours ago',
          type: NotifType.system,
          read: true,
          actorName: 'Admin',
          actorColor: HDTColors.danger,
          ctaLabel: 'VIEW RULES'),
      NotifItem(
          id: 'n6',
          title: 'Match result verified',
          body: 'Win vs NADIA (3-2) has been counted. ELO +12.',
          ts: '1 day ago',
          type: NotifType.match,
          read: true,
          actorName: 'Judge',
          actorColor: HDTColors.success),
      NotifItem(
          id: 'n7',
          title: 'Senayan Spinners - new event',
          body: '"Weekly Ranked #19" is scheduled for Saturday, 64 slots.',
          ts: '1 day ago',
          type: NotifType.community,
          read: true,
          actorName: 'SS',
          actorColor: HDTColors.accent,
          ctaLabel: 'OPEN CLUB'),
      NotifItem(
          id: 'n8',
          title: 'Promoted to Tier A - Region JKT',
          body: 'Your ELO crossed 2900. Tier S requires 3000+.',
          ts: '2 days ago',
          type: NotifType.trophy,
          read: true,
          actorName: 'HIDEOUT',
          actorColor: HDTColors.warning),
      NotifItem(
          id: 'n9',
          title: 'HIDEOUT Cup #5 registration opened',
          body: '128 limited slots. Open registration now.',
          ts: '3 days ago',
          type: NotifType.tournament,
          read: false,
          actorName: 'HIDEOUT',
          actorColor: HDTColors.accent,
          ctaLabel: 'REGISTER'),
      NotifItem(
          id: 'n10',
          title: 'Your profile was viewed 24x this week',
          body: 'Profile traffic is up 3x compared with last week.',
          ts: '4 days ago',
          type: NotifType.system,
          read: true,
          actorName: 'Stats',
          actorColor: HDTColors.info),
    ];

// State & notifier
class NotificationState {
  final List<NotifItem> items;
  final String
      filter; // ALL | UNREAD | match | tournament | trophy | community | system
  final int page;

  const NotificationState({
    required this.items,
    this.filter = 'ALL',
    this.page = 0,
  });

  NotificationState copyWith(
          {List<NotifItem>? items, String? filter, int? page}) =>
      NotificationState(
          items: items ?? this.items,
          filter: filter ?? this.filter,
          page: page ?? this.page);

  int get unreadCount => items.where((n) => !n.read).length;

  List<NotifItem> get filteredList => items.where((n) {
        if (filter == 'UNREAD') return !n.read;
        if (filter != 'ALL') return n.type.label == filter;
        return true;
      }).toList();
}

class NotificationNotifier extends Notifier<NotificationState> {
  static const perPage = 6;

  @override
  NotificationState build() => NotificationState(items: _seedNotifs());

  void setFilter(String f) => state = state.copyWith(filter: f, page: 0);
  void setPage(int p) => state = state.copyWith(page: p);

  void markRead(String id) {
    final items = state.items
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    state = state.copyWith(items: items);
  }

  void markAll() {
    final items = state.items.map((n) => n.copyWith(read: true)).toList();
    state = state.copyWith(items: items);
  }

  void remove(String id) {
    final items = state.items.where((n) => n.id != id).toList();
    state = state.copyWith(items: items);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);

// ─── Screen ──────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _perPage = 6;
  static const _filterTabs = [
    ('ALL', 'SEMUA'),
    ('UNREAD', 'UNREAD'),
    ('MATCH', 'MATCH'),
    ('TOURNAMENT', 'TOURNAMENT'),
    ('TROPHY', 'TROPHY'),
    ('COMMUNITY', 'COMMUNITY'),
    ('SYSTEM', 'SYSTEM'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final list = state.filteredList;
    final pinned = list.where((n) => n.pinned).toList();
    final rest = list.where((n) => !n.pinned).toList();
    final paginatedRest =
        rest.skip(state.page * _perPage).take(_perPage).toList();

    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Row(children: [
          const Text('NOTIFICATIONS'),
          if (state.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: HDTColors.accent, borderRadius: HDTR.full),
              child: Text('${state.unreadCount}',
                  style: HDTText.mono(size: 11, color: Colors.white)),
            ),
          ],
        ]),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: notifier.markAll,
              icon: const Icon(Icons.done_all, size: 14),
              label: const Text('MARK ALL'),
              style: TextButton.styleFrom(foregroundColor: HDTColors.text2),
            ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1), child: hdtDivider()),
      ),
      body: Column(children: [
        // ── Filter tabs ────────────────────────────────────
        Container(
          color: const Color(0xEB0F1115),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: HDTSpace.lg, vertical: HDTSpace.sm),
            child: Row(
              children: _filterTabs.map((tab) {
                final key = tab.$1;
                final count = key == 'ALL'
                    ? state.items.length
                    : key == 'UNREAD'
                        ? state.unreadCount
                        : state.items.where((n) => n.type.label == key).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: HDTFilterChip(
                    label: '${tab.$2} $count',
                    selected: state.filter == key,
                    onTap: () => notifier.setFilter(key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? HDTEmptyState(
                  icon: Icons.notifications_none,
                  title: 'ALL CAUGHT UP',
                  subtitle: 'No notifications in this filter.')
              : ListView(
                  padding: const EdgeInsets.all(HDTSpace.lg),
                  children: [
                    // Pinned
                    if (pinned.isNotEmpty) ...[
                      Row(children: [
                        const Icon(Icons.push_pin,
                            size: 12, color: HDTColors.accent),
                        const SizedBox(width: 4),
                        HDTOverlineLabel('PINNED',
                            color: HDTColors.accentHover),
                      ]),
                      const SizedBox(height: HDTSpace.sm),
                      ...pinned.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: HDTSpace.sm),
                            child: _NotifCard(
                                item: n,
                                onRead: () => notifier.markRead(n.id),
                                onDelete: () => notifier.remove(n.id)),
                          )),
                      const SizedBox(height: HDTSpace.sm),
                      hdtDivider(
                          margin: const EdgeInsets.only(bottom: HDTSpace.md)),
                    ],

                    // Rest
                    ...paginatedRest.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: HDTSpace.sm),
                          child: _NotifCard(
                              item: n,
                              onRead: () => notifier.markRead(n.id),
                              onDelete: () => notifier.remove(n.id)),
                        )),

                    const SizedBox(height: HDTSpace.lg),
                    HDTPagination(
                      total: rest.length,
                      page: state.page,
                      perPage: _perPage,
                      label: 'notifikasi',
                      onPage: notifier.setPage,
                    ),
                    const SizedBox(height: HDTSpace.xxl),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotifItem item;
  final VoidCallback onRead;
  final VoidCallback onDelete;

  const _NotifCard(
      {required this.item, required this.onRead, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final n = item;
    final meta = n.type;
    return Container(
      decoration: BoxDecoration(
        gradient: n.read
            ? null
            : LinearGradient(
                colors: [meta.color.withOpacity(0.1), HDTColors.s1],
                stops: const [0, 0.5]),
        color: n.read ? HDTColors.s1 : null,
        borderRadius: HDTR.lg,
        border: Border.all(
            color: n.read ? HDTColors.s2 : meta.color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Padding(
            padding: const EdgeInsets.all(HDTSpace.md),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.15),
                borderRadius: HDTR.md,
                border: Border.all(color: meta.color.withOpacity(0.3)),
              ),
              child: Icon(meta.icon, size: 18, color: meta.color),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: HDTSpace.md, bottom: HDTSpace.md, right: HDTSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // badges row
                  Wrap(spacing: 4, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: meta.color, borderRadius: HDTR.sm),
                      child: Text(meta.label,
                          style:
                              HDTText.overline(size: 8, color: Colors.white)),
                    ),
                    if (n.actorName != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: n.actorColor, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(n.actorName!, style: HDTText.mono(size: 10)),
                      ]),
                    Text('· ${n.ts}',
                        style: HDTText.mono(size: 10, color: HDTColors.text3)),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.title, style: HDTText.display(size: 15)),
                  const SizedBox(height: 2),
                  Text(n.body,
                      style: HDTText.body(
                          size: 12, color: HDTColors.text2, height: 1.5)),
                  if (n.ctaLabel != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        onRead();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: meta.color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: HDTText.overline(size: 9),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(n.ctaLabel!),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 12),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          Column(
            children: [
              if (!n.read)
                IconButton(
                  icon: const Icon(Icons.check, size: 14),
                  color: HDTColors.text3,
                  onPressed: onRead,
                  tooltip: 'Mark as read',
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                color: HDTColors.text3,
                onPressed: onDelete,
                tooltip: 'Dismiss',
              ),
              if (!n.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: meta.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: meta.color.withOpacity(0.5), blurRadius: 6)
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
