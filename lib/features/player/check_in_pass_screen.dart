import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';

class CheckInPassScreen extends StatefulWidget {
  const CheckInPassScreen({super.key});

  @override
  State<CheckInPassScreen> createState() => _CheckInPassScreenState();
}

class _CheckInPassScreenState extends State<CheckInPassScreen> {
  String _status = 'CHECKED IN';
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final ticket = _Ticket.fromArgs(ModalRoute.of(context)?.settings.arguments);
    final meta = _statusMeta(_status);

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.maybePop(context),
              onHome: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 90),
                    children: [
                      _StatusBanner(
                        status: _status,
                        meta: meta,
                        onStatus: (value) => setState(() => _status = value),
                      ),
                      const SizedBox(height: 20),
                      _TicketCard(
                        ticket: ticket,
                        copied: _copied,
                        onCopy: () {
                          setState(() => _copied = true);
                          Future.delayed(const Duration(milliseconds: 1100),
                              () {
                            if (mounted) setState(() => _copied = false);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const _RulesCard(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/tournaments/detail'),
                              icon: const Icon(Icons.emoji_events_outlined),
                              label: const Text('VIEW BRACKET'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/me/decks'),
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text('MY DECK'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const _TopBar({required this.onBack, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xEA0F1115),
        border: Border(bottom: BorderSide(color: HDTColors.s2)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: HDTR.md,
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: HDTR.md,
                border: Border.all(color: HDTColors.s2),
              ),
              child: const Icon(Icons.chevron_left,
                  size: 18, color: HDTColors.text2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHECK-IN', style: HDTText.display(size: 28)),
                Text('Your QR pass for tournament day',
                    style: HDTText.mono(size: 11, color: HDTColors.text3)),
              ],
            ),
          ),
          IconButton(
            onPressed: onHome,
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final _StatusMeta meta;
  final ValueChanged<String> onStatus;

  const _StatusBanner({
    required this.status,
    required this.meta,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: hdtCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: meta.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: meta.color, blurRadius: 12)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.label,
                        style: HDTText.overline(size: 11, color: meta.color)),
                    const SizedBox(height: 2),
                    Text(meta.description,
                        style: HDTText.body(size: 12, color: HDTColors.text2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in const [
                    'PENDING',
                    'CHECKED IN',
                    'ON DECK',
                    'CALLED',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: InkWell(
                        borderRadius: HDTR.sm,
                        onTap: () => onStatus(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: status == item
                                ? _statusMeta(item).color
                                : Colors.transparent,
                            borderRadius: HDTR.sm,
                            border: Border.all(color: HDTColors.s2),
                          ),
                          child: Text(
                            item,
                            style: HDTText.overline(
                              size: 8,
                              color: status == item
                                  ? HDTColors.bg
                                  : HDTColors.text3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _Ticket ticket;
  final bool copied;
  final VoidCallback onCopy;

  const _TicketCard({
    required this.ticket,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HDTColors.accent.withValues(alpha: .18),
                  Colors.transparent,
                ],
              ),
              border: const Border(bottom: BorderSide(color: HDTColors.s2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OFFICIAL ENTRY',
                          style: HDTText.overline(
                              size: 10, color: HDTColors.accentHover)),
                      const SizedBox(height: 4),
                      Text(ticket.tournamentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HDTText.display(size: 23)),
                    ],
                  ),
                ),
                const Icon(Icons.shield_outlined,
                    size: 30, color: HDTColors.accentHover),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final qrPanel = _QrPanel(
                ticket: ticket,
                copied: copied,
                onCopy: onCopy,
              );
              final details = _TicketDetails(ticket: ticket);
              if (!wide) {
                return Column(children: [qrPanel, hdtDivider(), details]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 292, child: qrPanel),
                  Container(width: 1, color: HDTColors.s2),
                  Expanded(child: details),
                ],
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: HDTColors.s2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Show this QR at the judge table when called',
                    style: HDTText.mono(size: 10, color: HDTColors.text3),
                  ),
                ),
                Text('v1 . HIDEOUT PASS',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  final _Ticket ticket;
  final bool copied;
  final VoidCallback onCopy;

  const _QrPanel({
    required this.ticket,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: HDTR.lg,
            ),
            child: SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: _QrPainter(seed: ticket.ticketId.hashCode),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(ticket.ticketId,
              style: HDTText.mono(size: 11, color: HDTColors.text3)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: Icon(copied ? Icons.check : Icons.copy, size: 13),
            label: Text(copied ? 'COPIED' : 'COPY ID'),
          ),
        ],
      ),
    );
  }
}

class _TicketDetails extends StatelessWidget {
  final _Ticket ticket;

  const _TicketDetails({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 420 ? 2 : 1;
              final fields = [
                _Field('PLAYER', ticket.player),
                _Field('BJX ID', ticket.bjxId),
                _Field('REGION', 'JKT-PUSAT'),
                _Field('ARENA', 'ARENA 02'),
                _Field('DATE', _shortDate(ticket.date)),
                const _Field('MATCH START', '14:30'),
              ];
              return Wrap(
                spacing: 20,
                runSpacing: 18,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: (constraints.maxWidth - ((cols - 1) * 20)) / cols,
                      child: field,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: hdtCard(bg: HDTColors.bg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text('STARTS IN', style: HDTText.overline(size: 10)),
                    ),
                    const Icon(Icons.schedule,
                        size: 14, color: HDTColors.text3),
                  ],
                ),
                const SizedBox(height: 4),
                Text('01:18:42',
                    style: HDTText.display(
                        size: 36, color: HDTColors.accentHover)),
                const SizedBox(height: 2),
                Text('Bracket announced at 15:00',
                    style: HDTText.mono(size: 11, color: HDTColors.text3)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Quick(
                  icon: Icons.wifi,
                  label: 'ARENA WIFI',
                  value: 'HDT-PUBLIC',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Quick(
                  icon: Icons.location_on_outlined,
                  label: 'VENUE',
                  value: ticket.venue.toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _Quick(
                  icon: Icons.verified_user_outlined,
                  label: 'JUDGE',
                  value: 'VERIFIED',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 10)),
        const SizedBox(height: 5),
        Text(value, style: HDTText.mono(size: 14, color: HDTColors.text)),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Quick({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: HDTColors.text3),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HDTText.overline(size: 8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HDTText.mono(size: 10, color: HDTColors.text2)),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    const rules = [
      'Arrive at least 30 minutes before match start. More than 5 minutes late = walkover.',
      'Decks are locked after check-in. Part changes must be reported to a judge.',
      'Banned parts are announced on the arena board. Check again before starting.',
      'Disputes are resolved by the head judge, and the decision is final.',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOUSE RULES', style: HDTText.overline(size: 11)),
          const SizedBox(height: 12),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ',
                      style: TextStyle(color: HDTColors.text2, height: 1.5)),
                  Expanded(
                    child: Text(rule,
                        style: HDTText.body(
                            size: 13, color: HDTColors.text2, height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Ticket {
  final String ticketId;
  final String tournamentName;
  final String community;
  final String player;
  final String bjxId;
  final String deck;
  final String venue;
  final String city;
  final DateTime date;

  const _Ticket({
    required this.ticketId,
    required this.tournamentName,
    required this.community,
    required this.player,
    required this.bjxId,
    required this.deck,
    required this.venue,
    required this.city,
    required this.date,
  });

  factory _Ticket.fromArgs(Object? args) {
    final raw = args is Map ? args : const {};
    final rawDate = raw['date'];
    return _Ticket(
      ticketId: (raw['ticketId'] ?? 'HDT-CUP-4-0042').toString(),
      tournamentName:
          (raw['tournamentName'] ?? 'HIDEOUT Cup #4. Summer Open').toString(),
      community: (raw['community'] ?? 'JKT Wolves').toString(),
      player: (raw['player'] ?? 'HANSEL').toString(),
      bjxId: (raw['bjxId'] ?? 'HDT-202').toString(),
      deck: (raw['deck'] ?? 'Phantom Reaper').toString(),
      venue: (raw['venue'] ?? 'GBK Senayan').toString(),
      city: (raw['city'] ?? 'Jakarta').toString(),
      date: rawDate is String
          ? DateTime.tryParse(rawDate) ?? DateTime(2026, 6, 14)
          : DateTime(2026, 6, 14),
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final String description;

  const _StatusMeta(this.label, this.color, this.description);
}

_StatusMeta _statusMeta(String status) {
  return switch (status) {
    'PENDING' => const _StatusMeta(
        'PENDING CHECK-IN',
        HDTColors.text3,
        'Show this QR at the registration desk.',
      ),
    'ON DECK' => const _StatusMeta(
        'ON DECK',
        HDTColors.warning,
        'Get ready. Your next match is up.',
      ),
    'CALLED' => const _StatusMeta(
        'CALLED. GO TO ARENA',
        HDTColors.accent,
        'Head to the arena now.',
      ),
    _ => const _StatusMeta(
        'CHECKED IN',
        HDTColors.success,
        'Stay in the arena area. Wait for the call.',
      ),
  };
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HDTColors.s1;
    final cell = size.width / 25;
    for (var r = 0; r < 25; r++) {
      for (var c = 0; c < 25; c++) {
        final finder =
            (r < 7 && c < 7) || (r < 7 && c >= 18) || (r >= 18 && c < 7);
        final on = finder
            ? (r == 0 ||
                r == 6 ||
                c == 0 ||
                c == 6 ||
                (r >= 2 && r <= 4 && c >= 2 && c <= 4) ||
                (r >= 2 && r <= 4 && c >= 20 && c <= 22) ||
                (r >= 20 && r <= 22 && c >= 2 && c <= 4))
            : ((r * 31 + c * 17 + seed) % 7 > 2);
        if (on) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell * .86, cell * .86),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
