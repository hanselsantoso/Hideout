import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/player_deck.dart';
import '../../data/repositories/tournament_repository.dart';

class JudgeScannerScreen extends ConsumerStatefulWidget {
  const JudgeScannerScreen({super.key});

  @override
  ConsumerState<JudgeScannerScreen> createState() => _JudgeScannerScreenState();
}

class _JudgeScannerScreenState extends ConsumerState<JudgeScannerScreen> {
  final _ticketController = TextEditingController();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  var _routeArgsApplied = false;
  bool _matchVerify = false;
  bool _judgeCheckedIn = false;
  bool _cameraOpen = false;
  bool _scanned = false;
  bool _loading = false;
  bool _deckMatches = true;
  bool _bladeOk = true;
  bool _ratchetOk = true;
  bool _bitOk = true;
  String? _error;
  JudgeRegistrationSnapshot? _registration;

  @override
  void dispose() {
    _ticketController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _applyRouteArgs();
    if (!_judgeCheckedIn) {
      return Scaffold(
        backgroundColor: HDTColors.bg,
        appBar: AppBar(title: const Text('SCANNER LOCKED')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(HDTSpace.xl),
              decoration: hdtCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHECK IN REQUIRED',
                      style: HDTText.display(size: 26)),
                  const SizedBox(height: HDTSpace.sm),
                  Text(
                    'Scanner only opens after you check in (absen) for the tournament on the event day. Open Judge Schedule and press CHECK IN first.',
                    style: HDTText.body(
                        color: HDTColors.text2, height: 1.5),
                  ),
                  const SizedBox(height: HDTSpace.lg),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/juri/matches'),
                    child: const Text('GO TO JUDGE SCHEDULE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final allOk = _deckMatches && _bladeOk && _ratchetOk && _bitOk;
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JUDGE CONSOLE', style: HDTText.overline(size: 9)),
            Text(_matchVerify ? 'MATCH DECK CHECK' : 'QR CHECK-IN',
                style: HDTText.display(size: 20)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/juri/matches'),
            icon: const Icon(Icons.assignment_ind_outlined, size: 16),
            label: const Text('MATCHES'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: HDTSpace.md),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.how_to_reg_outlined),
                  label: Text('CHECK-IN'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.fact_check_outlined),
                  label: Text('MATCH'),
                ),
              ],
              selected: {_matchVerify},
              onSelectionChanged: (value) => setState(() {
                _matchVerify = value.first;
                _scanned = false;
              }),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScannerBgPainter())),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.all(HDTSpace.lg),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    return Wrap(
                      spacing: HDTSpace.xl,
                      runSpacing: HDTSpace.xl,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: wide ? 360 : constraints.maxWidth,
                          child: _ScannerPanel(
                            matchVerify: _matchVerify,
                            scanned: _scanned,
                            loading: _loading,
                            controller: _ticketController,
                            error: _error,
                            cameraOpen: _cameraOpen,
                            scannerController: _scannerController,
                            onToggleCamera: _toggleCamera,
                            onDetect: _handleCameraDetect,
                            onScan: _scanRegistration,
                          ),
                        ),
                        SizedBox(
                          width: wide ? 520 : constraints.maxWidth,
                          child: _scanned
                              ? _ResultPanel(
                                  matchVerify: _matchVerify,
                                  allOk: allOk,
                                  registration: _registration!,
                                  deckMatches: _deckMatches,
                                  bladeOk: _bladeOk,
                                  ratchetOk: _ratchetOk,
                                  bitOk: _bitOk,
                                  onDeckChanged: (value) =>
                                      setState(() => _deckMatches = value),
                                  onBladeChanged: (value) =>
                                      setState(() => _bladeOk = value),
                                  onRatchetChanged: (value) =>
                                      setState(() => _ratchetOk = value),
                                  onBitChanged: (value) =>
                                      setState(() => _bitOk = value),
                                  onConfirm: () => _confirm(allOk),
                                  onReset: _reset,
                                )
                              : const _QueuePanel(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRouteArgs() {
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final registrationId = args['registrationId']?.toString();
    if (registrationId != null && registrationId.isNotEmpty) {
      _ticketController.text = registrationId;
    }
    final matchVerify = args['matchVerify'];
    if (matchVerify is bool && matchVerify != _matchVerify) {
      _matchVerify = matchVerify;
    }
    final checkedIn = args['judgeCheckedIn'];
    if (checkedIn is bool) _judgeCheckedIn = checkedIn;
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _loading = false;
      _error = null;
      _registration = null;
      _deckMatches = true;
      _bladeOk = true;
      _ratchetOk = true;
      _bitOk = true;
    });
  }

  void _toggleCamera() {
    setState(() {
      _cameraOpen = !_cameraOpen;
      _error = null;
    });
  }

  void _handleCameraDetect(BarcodeCapture capture) {
    if (_loading || _scanned) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null || raw.trim().isEmpty) return;
    _ticketController.text = _ticketFromQr(raw.trim());
    setState(() => _cameraOpen = false);
    _scanRegistration();
  }

  String _ticketFromQr(String raw) {
    final uri = Uri.tryParse(raw);
    final queryId = uri?.queryParameters['registrationId'] ??
        uri?.queryParameters['ticket'] ??
        uri?.queryParameters['id'];
    if (queryId != null && queryId.trim().isNotEmpty) return queryId.trim();
    return raw;
  }

  Future<void> _scanRegistration() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final registration =
          await ref.read(tournamentRepositoryProvider).findRegistrationForJudge(
                registrationId: _ticketController.text,
              );
      if (!mounted) return;
      if (registration == null) {
        setState(() {
          _registration = null;
          _scanned = false;
          _error =
              'Ticket not found in live data. Make sure the registration ID is correct or scan the QR of a registered participant.';
        });
        return;
      }
      setState(() {
        _registration = registration;
        _scanned = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _registration = null;
        _scanned = false;
        _error =
            'Ticket could not be read from Firebase. Check the connection and scan again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(bool allOk) async {
    final registration = _registration;
    if (registration == null) {
      _reset();
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(tournamentRepositoryProvider).markRegistrationCheckIn(
        registration: registration,
        accepted: allOk,
        matchVerification: _matchVerify,
        checks: {
          'deckMatches': _deckMatches,
          'bladeOk': _bladeOk,
          'ratchetOk': _ratchetOk,
          'bitOk': _bitOk,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_matchVerify
              ? (allOk ? 'Deck verified.' : 'Deck rejected.')
              : (allOk ? 'Participant checked in.' : 'Check-in rejected.')),
        ),
      );
      _reset();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Judge action was not saved. Check the connection or try again in a moment.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ScannerPanel extends StatelessWidget {
  const _ScannerPanel({
    required this.matchVerify,
    required this.scanned,
    required this.loading,
    required this.controller,
    required this.error,
    required this.cameraOpen,
    required this.scannerController,
    required this.onToggleCamera,
    required this.onDetect,
    required this.onScan,
  });
  final bool matchVerify;
  final bool scanned;
  final bool loading;
  final TextEditingController controller;
  final String? error;
  final bool cameraOpen;
  final MobileScannerController scannerController;
  final VoidCallback onToggleCamera;
  final void Function(BarcodeCapture capture) onDetect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(bg: HDTColors.bg.withValues(alpha: 0.72)),
      child: Column(children: [
        Text(matchVerify ? 'SCAN MATCH QR' : 'SCAN CHECK-IN QR',
            style: HDTText.overline(size: 10, color: HDTColors.accentHover)),
        const SizedBox(height: HDTSpace.lg),
        _CameraScannerBox(
          open: cameraOpen,
          scanned: scanned,
          matchVerify: matchVerify,
          controller: scannerController,
          onDetect: onDetect,
        ),
        const SizedBox(height: HDTSpace.lg),
        Text(
          matchVerify
              ? 'When a player is called, scan the QR ticket to match the deck.'
              : 'Scan participant QR on arrival to activate check-in.',
          textAlign: TextAlign.center,
          style: HDTText.body(color: HDTColors.text2, height: 1.5),
        ),
        const SizedBox(height: HDTSpace.lg),
        TextField(
          controller: controller,
          style: HDTText.body(size: 13),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.confirmation_number_outlined, size: 16),
            hintText: 'Registration / ticket ID',
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: HDTSpace.sm),
          Text(error!, style: HDTText.body(size: 11, color: HDTColors.warning)),
        ],
        const SizedBox(height: HDTSpace.lg),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: loading ? null : onToggleCamera,
            icon: Icon(cameraOpen
                ? Icons.videocam_off_outlined
                : Icons.photo_camera_outlined),
            label: Text(cameraOpen ? 'CLOSE CAMERA' : 'OPEN DEVICE CAMERA'),
          ),
        ),
        const SizedBox(height: HDTSpace.sm),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onScan,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner),
            label: Text(matchVerify ? 'SCAN MATCH TICKET' : 'SCAN CHECK-IN QR'),
          ),
        ),
      ]),
    );
  }
}

class _CameraScannerBox extends StatelessWidget {
  const _CameraScannerBox({
    required this.open,
    required this.scanned,
    required this.matchVerify,
    required this.controller,
    required this.onDetect,
  });

  final bool open;
  final bool scanned;
  final bool matchVerify;
  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      padding: const EdgeInsets.all(HDTSpace.sm),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.xl,
        border: Border.all(
          color: scanned ? HDTColors.success : HDTColors.accent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (scanned ? HDTColors.success : HDTColors.accent)
                .withValues(alpha: 0.22),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: HDTR.lg,
        child: open
            ? Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: onDetect,
                  ),
                  CustomPaint(painter: _ScannerFramePainter()),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(HDTSpace.md),
                child: CustomPaint(
                  painter: _MockQrPainter(seed: matchVerify ? 8 : 3),
                ),
              ),
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JUDGE SCAN GUIDE', style: HDTText.display(size: 24)),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Use this screen only for live check-in and assigned match deck verification. Enter or scan a registered participant ticket, compare the registered deck with the physical deck, then save the result.',
          style: HDTText.body(color: HDTColors.text2, height: 1.45),
        ),
        const SizedBox(height: HDTSpace.lg),
        const _GuideLine(
          icon: Icons.assignment_ind_outlined,
          title: 'Open assigned match',
          body:
              'Start from Match Assignments when this judge has active matches.',
        ),
        const SizedBox(height: HDTSpace.sm),
        const _GuideLine(
          icon: Icons.qr_code_scanner,
          title: 'Scan participant ticket',
          body:
              'Use CHECK-IN for arrivals or MATCH for deck verification before a battle.',
        ),
        const SizedBox(height: HDTSpace.sm),
        const _GuideLine(
          icon: Icons.fact_check_outlined,
          title: 'Reject mismatches',
          body:
              'Turn off any failed deck check and save the rejection so the lead can resolve it.',
        ),
      ]),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.matchVerify,
    required this.allOk,
    required this.registration,
    required this.deckMatches,
    required this.bladeOk,
    required this.ratchetOk,
    required this.bitOk,
    required this.onDeckChanged,
    required this.onBladeChanged,
    required this.onRatchetChanged,
    required this.onBitChanged,
    required this.onConfirm,
    required this.onReset,
  });

  final bool matchVerify;
  final bool allOk;
  final JudgeRegistrationSnapshot registration;
  final bool deckMatches;
  final bool bladeOk;
  final bool ratchetOk;
  final bool bitOk;
  final ValueChanged<bool> onDeckChanged;
  final ValueChanged<bool> onBladeChanged;
  final ValueChanged<bool> onRatchetChanged;
  final ValueChanged<bool> onBitChanged;
  final VoidCallback onConfirm;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final data = registration;
    final deck = data.deckSnapshot;
    final playerInitial = data.playerName.isEmpty ? '?' : data.playerName[0];
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtAccentCard(
        accentColor: allOk ? HDTColors.success : HDTColors.danger,
        highlighted: true,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: HDTColors.info, borderRadius: HDTR.md),
            child: Center(
                child: Text(playerInitial.toUpperCase(),
                    style: HDTText.display(size: 22, color: Colors.white))),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.playerName.toUpperCase(),
                  style: HDTText.display(size: 22)),
              Text(
                  '${data.id} - ${data.paymentStatus.toUpperCase()} - ${matchVerify ? 'MATCH VERIFY' : 'CHECK-IN'}',
                  style: HDTText.mono(size: 11, color: HDTColors.text3)),
            ]),
          ),
          _StatusPill(allOk ? 'VALID' : 'REJECT'),
        ]),
        const SizedBox(height: HDTSpace.lg),
        hdtDivider(),
        const SizedBox(height: HDTSpace.lg),
        Text('REGISTERED DECK', style: HDTText.overline(size: 10)),
        const SizedBox(height: HDTSpace.sm),
        if (deck == null) ...[
          _DeckLine(data.deckName, 'Deck snapshot is not available yet'),
        ] else ...[
          _DeckHeader(deck: deck),
          const SizedBox(height: HDTSpace.sm),
          for (var i = 0; i < deck.combos.length; i++)
            _DeckComboLine(number: i + 1, combo: deck.combos[i]),
        ],
        if (matchVerify) ...[
          const SizedBox(height: HDTSpace.lg),
          Text('DECK VERIFICATION', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.sm),
          _VerifyToggle(
              label: 'Deck QR matches the player ticket',
              value: deckMatches,
              onChanged: onDeckChanged),
          _VerifyToggle(
              label: 'Blade matches registration list',
              value: bladeOk,
              onChanged: onBladeChanged),
          _VerifyToggle(
              label: 'Ratchet matches registration list',
              value: ratchetOk,
              onChanged: onRatchetChanged),
          _VerifyToggle(
              label: 'Bit matches registration list',
              value: bitOk,
              onChanged: onBitChanged),
        ],
        const SizedBox(height: HDTSpace.lg),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.close),
              label: const Text('SCAN AGAIN'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: HDTColors.text2,
                  side: const BorderSide(color: HDTColors.s2)),
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: Icon(matchVerify ? Icons.fact_check : Icons.how_to_reg),
              label: Text(allOk
                  ? (matchVerify ? 'VERIFY DECK' : 'CHECK-IN')
                  : 'SAVE REJECTION'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: const BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.md,
        border: Border.fromBorderSide(BorderSide(color: HDTColors.s2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: HDTColors.info),
        const SizedBox(width: HDTSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: HDTText.overline(size: 9)),
              const SizedBox(height: HDTSpace.xs),
              Text(body,
                  style: HDTText.body(
                    size: 12,
                    color: HDTColors.text2,
                    height: 1.35,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DeckLine extends StatelessWidget {
  const _DeckLine(this.name, this.combo);
  final String name;
  final String combo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HDTSpace.sm),
      child: Row(children: [
        Expanded(child: Text(name, style: HDTText.body(size: 13))),
        Text(combo, style: HDTText.mono(size: 11, color: HDTColors.text3)),
      ]),
    );
  }
}

class _DeckHeader extends StatelessWidget {
  final PlayerDeck deck;

  const _DeckHeader({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(deck.name, style: HDTText.display(size: 18)),
              Text('${deck.tier} - ${deck.deckClass}',
                  style: HDTText.mono(size: 10, color: HDTColors.text3)),
            ],
          ),
        ),
        _StatusPill(deck.legal ? 'VALID' : 'REJECT'),
      ]),
    );
  }
}

class _DeckComboLine extends StatelessWidget {
  final int number;
  final DeckComboSnapshot combo;

  const _DeckComboLine({required this.number, required this.combo});

  @override
  Widget build(BuildContext context) {
    final parts = [
      combo.blade,
      combo.assistBlade,
      combo.lockChip,
      combo.ratchet,
      combo.bit,
    ].whereType<DeckPartSnapshot>().toList();
    return Container(
      margin: const EdgeInsets.only(bottom: HDTSpace.sm),
      padding: const EdgeInsets.all(HDTSpace.sm),
      decoration: BoxDecoration(
        color: HDTColors.bg,
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Row(children: [
        Text('#$number', style: HDTText.mono(size: 10)),
        const SizedBox(width: HDTSpace.sm),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final part in parts) _PartChip(part: part),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PartChip extends StatelessWidget {
  final DeckPartSnapshot part;

  const _PartChip({required this.part});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: HDTColors.s1,
        borderRadius: HDTR.sm,
        border: Border.all(color: HDTColors.s2),
      ),
      child: Text(
        part.alias == null ? part.name : '${part.name} (${part.alias})',
        style: HDTText.mono(size: 9, color: HDTColors.text2),
      ),
    );
  }
}

class _VerifyToggle extends StatelessWidget {
  const _VerifyToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (value) => onChanged(value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label, style: HDTText.body(size: 12)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final ok = status == 'VALID';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
      decoration: BoxDecoration(
        color:
            (ok ? HDTColors.success : HDTColors.danger).withValues(alpha: 0.14),
        borderRadius: HDTR.sm,
        border: Border.all(color: ok ? HDTColors.success : HDTColors.danger),
      ),
      child: Text(status,
          style: HDTText.overline(
              size: 9, color: ok ? HDTColors.success : HDTColors.danger)),
    );
  }
}

class _ScannerBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = HDTColors.s2.withValues(alpha: 0.45);
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawCircle(size.center(Offset.zero), 220,
        Paint()..color = HDTColors.accent.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: .18);
    final line = Paint()
      ..color = HDTColors.accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(Offset.zero & size, dim);
    final inset = size.width * .16;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    const corner = 28.0;
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(corner, 0), line);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, corner), line);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(-corner, 0), line);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, corner), line);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(corner, 0), line);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(0, -corner), line);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(-corner, 0), line);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(0, -corner), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockQrPainter extends CustomPainter {
  const _MockQrPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HDTColors.text;
    final cell = size.width / 21;
    for (var r = 0; r < 21; r++) {
      for (var c = 0; c < 21; c++) {
        final finder =
            (r < 7 && c < 7) || (r < 7 && c >= 14) || (r >= 14 && c < 7);
        final on = finder
            ? (r == 0 ||
                r == 6 ||
                c == 0 ||
                c == 6 ||
                (r >= 2 && r <= 4 && c >= 2 && c <= 4))
            : ((r * 11 + c * 7 + seed) % 4 != 0);
        if (on) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cell, r * cell, cell * 0.82, cell * 0.82),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MockQrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
