import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final name = profile.maybeWhen(
      data: (user) {
        if (user == null) return 'BLADE RUNNER';
        if (user.displayName.trim().isNotEmpty) {
          return user.displayName.trim().toUpperCase();
        }
        return user.email.split('@').first.toUpperCase();
      },
      orElse: () => 'BLADE RUNNER',
    );

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 80),
          children: [
            _Header(name: name),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1040;
                if (!wide) {
                  return const Column(
                    children: [
                      _NextUpCard(),
                      SizedBox(height: 16),
                      _RankCard(),
                      SizedBox(height: 16),
                      _FormCard(),
                      SizedBox(height: 16),
                      _DecksCard(),
                      SizedBox(height: 16),
                      _ActiveTournamentsCard(),
                      SizedBox(height: 16),
                      _NotificationsCard(),
                      SizedBox(height: 16),
                      _RecommendedCard(),
                      SizedBox(height: 16),
                      _GoalCard(),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _NextUpCard(),
                          SizedBox(height: 16),
                          _RankCard(),
                          SizedBox(height: 16),
                          _FormCard(),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _DecksCard(),
                          SizedBox(height: 16),
                          _ActiveTournamentsCard(),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _NotificationsCard(),
                          SizedBox(height: 16),
                          _RecommendedCard(),
                          SizedBox(height: 16),
                          _GoalCard(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WELCOME BACK', style: HDTText.overline(size: 11)),
            const SizedBox(height: 4),
            Text(name, style: HDTText.display(size: 40)),
            const SizedBox(height: 4),
            Text(
              'HDT-202 . JAKARTA . ELO 2,680',
              style: HDTText.mono(size: 12, color: HDTColors.text3),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/juri/matches'),
              icon: const Icon(Icons.sports_martial_arts_outlined, size: 16),
              label: const Text('JUDGE MATCHES'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 42),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/community/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
              label: const Text('ADMIN KOMUNITAS'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(174, 42),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin/tournaments/ops'),
              icon: const Icon(Icons.account_tree_outlined, size: 16),
              label: const Text('TOURNEY OPS'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(148, 42),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/me/decks/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('BUILD DECK'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(148, 42),
                backgroundColor: HDTColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'NEXT UP',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: HDTColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('ACTIVE', style: HDTText.overline(color: HDTColors.accentHover)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('JKT WOLVES', style: HDTText.overline(size: 10)),
          const SizedBox(height: 8),
          Text('Hideout Cup #03', style: HDTText.display(size: 32)),
          const SizedBox(height: 2),
          Text(
            'BO5 . Single Elim . 32 PLAYERS',
            style: HDTText.mono(size: 12, color: HDTColors.text3),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: _CountdownTile(label: 'DAYS', value: '01')),
              SizedBox(width: 8),
              Expanded(child: _CountdownTile(label: 'HRS', value: '18')),
              SizedBox(width: 8),
              Expanded(child: _CountdownTile(label: 'MIN', value: '42')),
              SizedBox(width: 8),
              Expanded(child: _CountdownTile(label: 'SEC', value: '17')),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Gear Sports Arena, Jakarta',
            style: HDTText.body(size: 12, color: HDTColors.text2),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/tournaments/detail',
                    arguments: {
                      'tournamentId': 'bjx-cup-3',
                      'name': 'HIDEOUT Cup #3. Spring Showdown',
                      'community': 'JKT Wolves',
                      'status': 'LIVE',
                      'format': 'BO5 . Single Elim',
                      'tier': 'PREMIER',
                      'city': 'Jakarta',
                      'venue': 'Gear Sports Arena',
                      'fee': 'Rp 100.000',
                      'date': DateTime(2026, 5, 9).toIso8601String(),
                      'registered': 32,
                      'capacity': 32,
                    },
                  ),
                  child: const Text('VIEW BRACKET'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/me/qr'),
                  child: const Text('QR PASS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownTile extends StatelessWidget {
  final String label;
  final String value;

  const _CountdownTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: HDTText.display(size: 28, color: HDTColors.accentHover)),
          const SizedBox(height: 4),
          Text(label, style: HDTText.overline(size: 9)),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'MY RANK',
      action: Text('SEASON 3',
          style: HDTText.mono(size: 11, color: HDTColors.text3)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('2,680', style: HDTText.display(size: 54)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up,
                              size: 14, color: HDTColors.success),
                          const SizedBox(width: 3),
                          Text('+45',
                              style: HDTText.mono(
                                  size: 13, color: HDTColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
                Text('ELO . LAST 7 DAYS', style: HDTText.overline(size: 10)),
                const SizedBox(height: 16),
                const _RankLine(
                    label: 'GLOBAL #5', total: '/ 12,450', value: .92),
                const SizedBox(height: 12),
                const _RankLine(
                    label: 'JAKARTA #2', total: '/ 4,120', value: .96),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const SizedBox(
            width: 136,
            height: 80,
            child: _Sparkline(
              data: [
                2520,
                2550,
                2540,
                2580,
                2600,
                2595,
                2620,
                2640,
                2635,
                2660,
                2680
              ],
              color: HDTColors.accentHover,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankLine extends StatelessWidget {
  final String label;
  final String total;
  final double value;

  const _RankLine(
      {required this.label, required this.total, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: HDTText.mono(size: 11, color: HDTColors.text2),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                  text: total,
                  style: HDTText.mono(size: 11, color: HDTColors.text3)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: HDTR.full,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: HDTColors.bg,
            valueColor: const AlwaysStoppedAnimation(HDTColors.accent),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard();

  @override
  Widget build(BuildContext context) {
    const form = ['W', 'W', 'L', 'W', 'W', 'W', 'L', 'W', 'W', 'W'];
    return _Panel(
      title: 'RECENT FORM',
      action: Text('8W-2L LAST 10',
          style: HDTText.mono(size: 11, color: HDTColors.text2)),
      child: Row(
        children: [
          for (final item in form) ...[
            Expanded(child: _FormTile(result: item)),
            if (item != form.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  final String result;

  const _FormTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final win = result == 'W';
    final color = win ? HDTColors.success : HDTColors.danger;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: HDTR.md,
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Text(result, style: HDTText.display(size: 14, color: color)),
      ),
    );
  }
}

class _DecksCard extends StatelessWidget {
  const _DecksCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'MY DECKS',
      action: InkWell(
        onTap: () => Navigator.pushNamed(context, '/me/decks/new'),
        child: Text('BUILD NEW',
            style: HDTText.overline(color: HDTColors.accentHover)),
      ),
      padding: EdgeInsets.zero,
      child: const Column(
        children: [
          _DeckRow(
              name: 'Phantom Reaper',
              record: '12W-3L . 15 matches',
              wr: '80%',
              color: HDTColors.success),
          _DeckRow(
              name: 'Void Bastion',
              record: '8W-4L . 12 matches',
              wr: '67%',
              color: HDTColors.accentHover),
          _DeckRow(
              name: 'Shrike Mk.II',
              record: '7W-5L . 12 matches',
              wr: '58%',
              color: HDTColors.text),
        ],
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  final String name;
  final String record;
  final String wr;
  final Color color;

  const _DeckRow({
    required this.name,
    required this.record,
    required this.wr,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HDTColors.bg,
              borderRadius: HDTR.md,
              border: Border.all(color: HDTColors.s2),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 17, color: HDTColors.accentHover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(record,
                    style: HDTText.mono(size: 11, color: HDTColors.text3)),
              ],
            ),
          ),
          Text(wr, style: HDTText.display(size: 22, color: color)),
        ],
      ),
    );
  }
}

class _ActiveTournamentsCard extends StatelessWidget {
  const _ActiveTournamentsCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'ACTIVE TOURNAMENTS',
      action: Text('4', style: HDTText.mono(size: 11, color: HDTColors.text3)),
      padding: EdgeInsets.zero,
      child: const Column(
        children: [
          _TournamentMiniRow(
              status: 'LIVE',
              name: 'Friday Night Burst',
              date: 'TODAY . 19:00',
              paid: true),
          _TournamentMiniRow(
              status: 'UPCOMING',
              name: 'Hideout Cup #03',
              date: 'TOMORROW . 14:00',
              paid: true),
          _TournamentMiniRow(
              status: 'UPCOMING',
              name: 'Highland Open',
              date: 'MAY 15 . 10:00',
              paid: true),
          _TournamentMiniRow(
              status: 'UPCOMING',
              name: 'Sultanate Series',
              date: 'MAY 22 . 13:00',
              paid: false),
        ],
      ),
    );
  }
}

class _TournamentMiniRow extends StatelessWidget {
  final String status;
  final String name;
  final String date;
  final bool paid;

  const _TournamentMiniRow({
    required this.status,
    required this.name,
    required this.date,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    final live = status == 'LIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: live ? HDTColors.accent : Colors.transparent,
              borderRadius: HDTR.sm,
              border: live ? null : Border.all(color: HDTColors.s2),
            ),
            child: Text(
              status,
              style: HDTText.overline(
                size: 9,
                color: live ? Colors.white : HDTColors.text2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.body(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(date,
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
          Text(
            paid ? 'PAID' : 'PENDING',
            style: HDTText.overline(
              size: 9,
              color: paid ? HDTColors.success : HDTColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'NOTIFICATIONS',
      action: Icon(Icons.notifications_none, size: 15, color: HDTColors.text3),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _NotificationRow(
              unread: true,
              time: '5m',
              text: 'Match vs BJX-077 NIRO scheduled in 2 hours'),
          _NotificationRow(
              unread: true,
              time: '1h',
              text: 'JKT Wolves opened registration for Hideout #04'),
          _NotificationRow(
              unread: false,
              time: '4h',
              text: 'Your ELO updated: +12 vs BJX-091 AVI'),
          _NotificationRow(
              unread: false, time: '1d', text: 'Withdrawal Rp 75.000 received'),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final bool unread;
  final String time;
  final String text;

  const _NotificationRow({
    required this.unread,
    required this.time,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: unread ? HDTColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: HDTText.body(
                    size: 12,
                    color: unread ? HDTColors.text : HDTColors.text2,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$time ago',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      title: 'RECOMMENDED',
      action: Icon(Icons.auto_awesome, size: 15, color: HDTColors.accentHover),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _RecommendedRow(
              name: 'East Coast Showdown',
              community: 'SBY SPIN',
              date: 'MAY 18',
              fee: 'Rp 85.000',
              elo: '2400-2900'),
          _RecommendedRow(
              name: 'Highland Open',
              community: 'BDG GRINDERS',
              date: 'MAY 15',
              fee: 'Rp 65.000',
              elo: '2200+'),
          _RecommendedRow(
              name: 'Sultanate Series',
              community: 'YOGYA META',
              date: 'MAY 22',
              fee: 'Rp 50.000',
              elo: 'OPEN'),
        ],
      ),
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  final String name;
  final String community;
  final String date;
  final String fee;
  final String elo;

  const _RecommendedRow({
    required this.name,
    required this.community,
    required this.date,
    required this.fee,
    required this.elo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(community, style: HDTText.overline(size: 9))),
              Text(date, style: HDTText.mono(size: 10, color: HDTColors.text3)),
            ],
          ),
          const SizedBox(height: 5),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.body(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(fee, style: HDTText.mono(size: 11, color: HDTColors.text2)),
              const Spacer(),
              Text('ELO $elo',
                  style:
                      HDTText.overline(size: 9, color: HDTColors.accentHover)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_outlined,
              size: 22, color: HDTColors.accentHover),
          const SizedBox(height: 14),
          Text('2 WINS\nFROM TOP 4',
              style: HDTText.display(size: 24, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Next 2 ranked wins put you in JKT top 4 this season.',
            style: HDTText.body(size: 12, color: HDTColors.text2, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsets padding;

  const _Panel({
    required this.title,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Expanded(child: Text(title, style: HDTText.overline(size: 10))),
                if (action != null) action!,
              ],
            ),
          ),
          hdtDivider(),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklinePainter(data: data, color: color));
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1 : max - min;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * (i / (data.length - 1));
      final y = size.height - ((data[i] - min) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
