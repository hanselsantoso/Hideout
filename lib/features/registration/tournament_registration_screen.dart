import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/player_deck.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/tournament_repository.dart';

const _registrationSteps = [
  'ELIGIBILITY',
  'CHOOSE DECK',
  'REVIEW & FEE',
  'PAYMENT',
  'CONFIRMED',
];

// Stored for future demo mode; live registration uses Firebase decks only.
// ignore: unused_element
const _deckOptions = [
  _DeckDraft(
    id: 'demo-phantom-reaper',
    name: 'Phantom Reaper',
    type: 'BALANCE',
    combos: ['DranSword 3-60F', 'WizardRod 9-60B', 'PhoenixWing 5-60P'],
    atk: 78,
    def: 64,
    sta: 72,
    eligible: true,
  ),
  _DeckDraft(
    id: 'demo-void-bastion',
    name: 'Void Bastion',
    type: 'DEFENSE',
    combos: ['KnightShield 3-80N', 'WizardArrow 4-60B', 'SharkEdge 5-60LF'],
    atk: 52,
    def: 88,
    sta: 70,
    eligible: true,
  ),
  _DeckDraft(
    id: 'demo-cobalt-rush',
    name: 'Cobalt Rush',
    type: 'ATTACK',
    combos: ['CobaltDragoon 2-60R', 'DranDagger 4-60F', 'HellsChain 5-80O'],
    atk: 91,
    def: 48,
    sta: 54,
    eligible: false,
    reason: 'Banned part: Cobalt Dragoon',
  ),
];

String _orTba(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? 'TBA' : text;
}

String _orDash(Object? value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? '-' : text;
}

String _formatDateArg(Object? value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return 'TBA';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return DateFormat('MMM d, yyyy - HH:mm')
      .format(parsed.toLocal())
      .toUpperCase();
}

List<_DeckDraft> _registrationDecks(List<PlayerDeck>? savedDecks) {
  if (savedDecks == null || savedDecks.isEmpty) return const [];
  return savedDecks.map(_deckFromPlayerDeck).toList();
}

_DeckDraft _deckFromPlayerDeck(PlayerDeck deck) {
  return _DeckDraft(
    id: deck.id,
    name: deck.name,
    type: deck.deckClass,
    combos: deck.combos.map((combo) => combo.compactLabel).toList(),
    atk: deck.stats.attack,
    def: deck.stats.defense,
    sta: deck.stats.stamina,
    eligible: deck.legal,
    reason: deck.issues.isEmpty ? null : deck.issues.first,
    snapshot: deck.toSnapshot(),
  );
}

class TournamentRegistrationScreen extends ConsumerStatefulWidget {
  const TournamentRegistrationScreen({super.key});

  @override
  ConsumerState<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends ConsumerState<TournamentRegistrationScreen> {
  int _step = 0;
  String _selectedDeck = 'Phantom Reaper';
  bool _accepted = false;
  bool _busy = false;
  bool _breakdownOpen = true;
  String? _registrationId;
  String? _paymentSessionId;
  String? _paymentLinkUrl;
  String? _paymentStatus;
  String? _paymentMessage;
  String? _qrisReferenceId;
  String? _qrisQrImageDataUrl;
  String? _qrisQrString;
  String? _error;
  bool _routeArgsApplied = false;
  Timer? _syncTimer;
  String _tournamentId = '';
  TournamentFeePolicy? _feePolicy;
  String _community = '';
  String _dateLabel = 'TBA';
  String _locationLabel = 'TBA';
  String _formatLabel = 'TBA';
  String _tierLabel = '-';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _tournamentId = (args['tournamentId'] ?? '').toString();
    _community = (args['community'] ?? '').toString().trim();
    _dateLabel = _formatDateArg(args['date']);
    final venue = (args['venue'] ?? '').toString().trim();
    final city = (args['city'] ?? '').toString().trim();
    _locationLabel = [venue, city].where((part) => part.isNotEmpty).join(', ');
    if (_locationLabel.isEmpty) _locationLabel = 'TBA';
    _formatLabel = _orTba(args['format']);
    _tierLabel = _orDash(args['tier']);
    final policyTournamentId = (args['tournamentId'] ?? '').toString();
    if (policyTournamentId.isNotEmpty &&
        !policyTournamentId.startsWith('demo-')) {
      final fallbackFee = _parseFee((args['fee'] ?? 'Rp 75.000').toString());
      ref
          .read(tournamentRepositoryProvider)
          .fetchFeePolicy(
            tournamentId: policyTournamentId,
            fallbackNetFee: fallbackFee,
          )
          .then((policy) {
        if (mounted) setState(() => _feePolicy = policy);
      });
    }
    final registrationId = (args['registrationId'] ?? '').toString();
    if (registrationId.isNotEmpty) {
      _registrationId = registrationId;
    }
    final deckName = (args['deckName'] ?? args['deck']).toString();
    if (deckName.trim().isNotEmpty && deckName != 'null') {
      _selectedDeck = deckName;
    }
    final requestedStep = args['initialStep'];
    if (requestedStep is int) {
      _step = requestedStep.clamp(0, _registrationSteps.length - 2);
    }
    if (args['resumePayment'] == true) {
      _step = 3;
      _paymentMessage =
          'Payment is still pending. Create or reload the QRIS code, then check the payment status after paying.';
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final tournamentId = (args['tournamentId'] ?? '').toString();
    final tournamentName = (args['name'] ?? 'Hideout Cup #04').toString();
    final feeLabel = (args['fee'] ?? 'Rp 75.000').toString();
    final fee = _parseFee(feeLabel);
    final policy = _feePolicy ?? TournamentFeePolicy.defaultsForNetFee(fee);
    final firebaseDecks = ref.watch(userDecksProvider).valueOrNull;
    final deckOptions = _registrationDecks(firebaseDecks);

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
            Text(
              _community.isEmpty
                  ? 'REGISTRATION'
                  : '${_community.toUpperCase()} - REGISTRATION',
              style: HDTText.overline(size: 10),
            ),
            Text(tournamentName, style: HDTText.display(size: 22)),
          ],
        ),
        actions: [
          Center(
            child: Text('STEP ${_step + 1} / ${_registrationSteps.length}',
                style: HDTText.overline(size: 10)),
          ),
          const SizedBox(width: HDTSpace.lg),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                HDTSpace.lg, HDTSpace.xl, HDTSpace.lg, 130),
            children: [
              _Stepper(step: _step, labels: _registrationSteps),
              const SizedBox(height: HDTSpace.xxl),
              _currentStep(tournamentName, policy, deckOptions),
              if (_error != null) ...[
                const SizedBox(height: HDTSpace.lg),
                _Notice(
                    color: HDTColors.danger,
                    icon: Icons.error_outline,
                    text: _error!),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _step == _registrationSteps.length - 1
          ? null
          : _BottomBar(
              busy: _busy,
              canBack: _step > 0,
              nextEnabled: _canProceed(deckOptions),
              nextLabel:
                  _step == 3 ? _paymentActionLabel(policy) : 'CONTINUE',
              onBack: _back,
              onNext: () => _next(tournamentId),
            ),
    );
  }

  Widget _currentStep(
    String tournamentName,
    TournamentFeePolicy policy,
    List<_DeckDraft> deckOptions,
  ) {
    return switch (_step) {
      0 => _eligibilityStep(),
      1 => _deckStep(deckOptions),
      2 => _reviewStep(tournamentName, policy, deckOptions),
      3 => _paymentStep(policy),
      _ => _ticketStep(tournamentName, deckOptions),
    };
  }

  Widget _eligibilityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 1', 'ELIGIBILITY CHECK'),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Automatic verification before registration. Every requirement must PASS to continue.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        const SizedBox(height: HDTSpace.lg),
        Container(
          decoration: hdtCard(),
          child: const Column(
            children: [
              _EligibilityRow(
                ok: true,
                label: 'ELO Range',
                detail: 'Required 2200-3000 - You: 2680',
              ),
              _EligibilityRow(
                ok: true,
                label: 'Region',
                detail: 'JAKARTA - Open to all regions',
              ),
              _EligibilityRow(
                ok: true,
                label: 'Account Verified',
                detail: 'Email confirmed',
              ),
              _EligibilityRow(
                ok: true,
                label: 'Profile Complete',
                detail: 'HDT-202 - HANSEL',
              ),
            ],
          ),
        ),
        const SizedBox(height: HDTSpace.lg),
        const _ResponsiveGrid(children: [
          _StatCard(
              Icons.calendar_today_outlined, 'DATE', 'MAY 22, 2026 - 14:00'),
          _StatCard(
              Icons.location_on_outlined, 'LOCATION', 'Gear Sports Arena'),
          _StatCard(Icons.groups_outlined, 'CAPACITY', '24 / 32'),
          _StatCard(Icons.emoji_events_outlined, 'PRIZE POOL', 'Rp 2.4M'),
        ]),
      ],
    );
  }

  Widget _deckStep(List<_DeckDraft> deckOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('STEP 2', 'CHOOSE DECK')),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/me/decks/new'),
              icon: const Icon(Icons.add),
              label: const Text('BUILD NEW DECK'),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Choose the deck you will use. Decks are locked after on-site check-in.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        const SizedBox(height: HDTSpace.lg),
        const _Notice(
          color: HDTColors.warning,
          icon: Icons.shield_outlined,
          text:
              'Deck Restrictions: banned parts Cobalt Dragoon, required 3 combos, ELO 2200-3000.',
        ),
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 920
                ? 3
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
            final width =
                (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) / cols;
            return Wrap(
              spacing: HDTSpace.md,
              runSpacing: HDTSpace.md,
              children: [
                if (deckOptions.isEmpty)
                  SizedBox(
                    width: constraints.maxWidth,
                    child: const _Notice(
                      color: HDTColors.info,
                      icon: Icons.inventory_2_outlined,
                      text:
                          'No saved deck was found in Firebase. Build and save a deck first before joining a beta tournament.',
                    ),
                  ),
                for (final deck in deckOptions)
                  SizedBox(
                    width: width,
                    child: _DeckCard(
                      deck: deck,
                      selected: _selectedDeck == deck.name,
                      onTap: deck.eligible
                          ? () => setState(() => _selectedDeck = deck.name)
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _reviewStep(
    String tournamentName,
    TournamentFeePolicy policy,
    List<_DeckDraft> deckOptions,
  ) {
    final deck = _selectedDeckDraft(deckOptions);
    final fee = policy.netFee;
    final platform = policy.platformFee;
    final gateway = policy.gatewayFee;
    final total = policy.userPayable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 3', 'REVIEW & FEE'),
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.lg,
              children: [
                SizedBox(
                  width:
                      wide ? constraints.maxWidth - 380 : constraints.maxWidth,
                  child: Container(
                    padding: const EdgeInsets.all(HDTSpace.lg),
                    decoration: hdtCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOURNAMENT', style: HDTText.overline(size: 10)),
                        const SizedBox(height: HDTSpace.xs),
                        Text(tournamentName, style: HDTText.display(size: 24)),
                        Text(_community.isEmpty ? '-' : _community.toUpperCase(),
                            style: HDTText.mono(size: 11)),
                        const SizedBox(height: HDTSpace.lg),
                        hdtDivider(),
                        const SizedBox(height: HDTSpace.lg),
                        _ResponsiveGrid(children: [
                          _Mini('DATE', _dateLabel),
                          _Mini('LOCATION', _locationLabel),
                          _Mini('FORMAT', _formatLabel),
                          _Mini('ELO RANGE', _tierLabel),
                        ]),
                        const SizedBox(height: HDTSpace.lg),
                        hdtDivider(),
                        const SizedBox(height: HDTSpace.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text('YOUR DECK',
                                  style: HDTText.overline(size: 10)),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _step = 1),
                              child: const Text('CHANGE'),
                            ),
                          ],
                        ),
                        _DeckSummary(deck: deck),
                        const SizedBox(height: HDTSpace.lg),
                        hdtDivider(),
                        const SizedBox(height: HDTSpace.md),
                        CheckboxListTile(
                          value: _accepted,
                          onChanged: (value) =>
                              setState(() => _accepted = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'I agree to the tournament rules and refund policy, and my deck will not be changed after check-in.',
                            style: HDTText.body(color: HDTColors.text2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: wide ? 360 : constraints.maxWidth,
                  child: _FeeBreakdown(
                    total: total,
                    fee: fee,
                    platform: platform,
                    gateway: gateway,
                    withdraw: policy.withdrawFeeCoverage,
                    community: _community,
                    open: _breakdownOpen,
                    onToggle: () =>
                        setState(() => _breakdownOpen = !_breakdownOpen),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _paymentStep(TournamentFeePolicy policy) {
    final total = policy.userPayable;
    if (total <= 0) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('STEP 4', 'FREE ENTRY'),
          SizedBox(height: HDTSpace.md),
          _Notice(
            color: HDTColors.success,
            icon: Icons.verified_outlined,
            text:
                'This tournament is free to join — no payment required. Press CONFIRM FREE ENTRY to activate your registration immediately.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 4', 'QRIS PAYMENT'),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Create a QRIS code, scan it with your bank or e-wallet app, then check the payment status here.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        if (_paymentMessage != null) ...[
          const SizedBox(height: HDTSpace.md),
          _Notice(
            color: HDTColors.info,
            icon: Icons.info_outline,
            text: _paymentMessage!,
          ),
        ],
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.lg,
              children: [
                SizedBox(
                  width: wide ? 330 : constraints.maxWidth,
                  child: _XenditCheckoutPanel(
                    total: total,
                    paymentSessionId: _paymentSessionId,
                    paymentLinkUrl: _paymentLinkUrl,
                    qrisQrImageDataUrl: _qrisQrImageDataUrl,
                    qrisQrString: _qrisQrString,
                    status: _paymentStatus,
                    onOpen: _openPaymentLink,
                  ),
                ),
                SizedBox(
                  width:
                      wide ? constraints.maxWidth - 350 : constraints.maxWidth,
                  child:
                      _PaymentInstructions(hasLink: _paymentSessionId != null),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.md),
        Text(
          'Payment status is checked automatically every 10 seconds while the QRIS code is active.',
          style: HDTText.body(size: 11, color: HDTColors.text3),
        ),
      ],
    );
  }

  Widget _ticketStep(String tournamentName, List<_DeckDraft> deckOptions) {
    final deck = _selectedDeckDraft(deckOptions);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: HDTColors.accentDim,
                shape: BoxShape.circle,
                border: Border.all(color: HDTColors.accent),
              ),
              child: const Icon(Icons.check, size: 36, color: Colors.white),
            ),
            const SizedBox(height: HDTSpace.xl),
            Text('REGISTERED.',
                style: HDTText.display(size: 54).copyWith(height: 1)),
            const SizedBox(height: HDTSpace.sm),
            Text('See you on the bracket.',
                style: HDTText.body(color: HDTColors.text2)),
            const SizedBox(height: HDTSpace.xxl),
            _TicketCard(
              tournamentName: tournamentName,
              deck: deck,
              registrationId: _registrationId ?? 'DEMO-QR-TICKET',
            ),
            const SizedBox(height: HDTSpace.lg),
            const _Notice(
              color: HDTColors.info,
              icon: Icons.mail_outline,
              text:
                  'Ticket and registration details will be sent to email. This QR is used during check-in and when a judge calls the match.',
            ),
            const SizedBox(height: HDTSpace.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/me/tournaments'),
                icon: const Icon(Icons.chevron_right),
                label: const Text('MY TOURNAMENTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed(List<_DeckDraft> deckOptions) {
    return switch (_step) {
      0 => true,
      1 => deckOptions.isNotEmpty && _selectedDeckDraft(deckOptions).eligible,
      2 => _accepted,
      3 => true,
      _ => true,
    };
  }

  String _paymentActionLabel(TournamentFeePolicy policy) {
    if (policy.userPayable <= 0) {
      return 'CONFIRM FREE ENTRY';
    }
    if (_paymentSessionId == null) {
      return 'CREATE QRIS';
    }
    return 'CHECK PAYMENT STATUS';
  }

  void _back() {
    setState(() {
      _error = null;
      if (_step > 0) _step--;
    });
  }

  Future<void> _next(String tournamentId) async {
    if (_step == 4) {
      Navigator.pop(context);
      return;
    }
    if (_step != 3) {
      setState(() => _step++);
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      Navigator.pushNamed(context, '/signup');
      return;
    }

    if (tournamentId.isEmpty || tournamentId.startsWith('demo-')) {
      setState(() {
        _registrationId = 'DEMO-${DateTime.now().millisecondsSinceEpoch}';
        _paymentSessionId = 'DEMO-CHECKOUT';
        _paymentStatus = 'COMPLETED';
        _paymentMessage = 'Demo tournament registration has been confirmed.';
        _step++;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final selectedDeck = _selectedDeckDraft(
        _registrationDecks(ref.read(userDecksProvider).valueOrNull),
      );
      final registrationId = _registrationId ??
          await repo.createRegistration(
            tournamentId: tournamentId,
            playerId: user.uid,
            playerName: user.displayName ?? user.email ?? 'Player',
            deckId: selectedDeck.id,
            deckName: selectedDeck.name,
            deckSnapshot:
                selectedDeck.snapshot.isEmpty ? null : selectedDeck.snapshot,
          );
      if (_registrationId == null && mounted) {
        setState(() => _registrationId = registrationId);
      }

      final XenditPaymentSessionResult payment;
      if (_paymentSessionId == null) {
        payment = await repo.createXenditQrisPayment(
          tournamentId: tournamentId,
          registrationId: registrationId,
        );
      } else {
        payment = await repo.syncXenditQrisPayment(
          tournamentId: tournamentId,
          registrationId: registrationId,
          qrisReferenceId: _qrisReferenceId,
        );
      }
      if (!mounted) return;
      _applyPaymentResult(payment);
      if (payment.paid) {
        setState(() => _step++);
        return;
      }
      if (payment.expired) {
        setState(() {
          _paymentSessionId = null;
          _paymentLinkUrl = null;
          _qrisReferenceId = null;
          _qrisQrImageDataUrl = null;
          _qrisQrString = null;
          _paymentMessage =
              'The previous QRIS code expired. Create a new QRIS payment to continue.';
        });
        return;
      }
      setState(() {
        _paymentMessage =
            'QRIS is ready. Scan it with your QRIS-enabled app, then press Check Payment Status.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _paymentErrorMessage(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyPaymentResult(XenditPaymentSessionResult payment) {
    setState(() {
      _paymentSessionId = payment.paymentSessionId.isEmpty
          ? _paymentSessionId
          : payment.paymentSessionId;
      _paymentLinkUrl = payment.paymentLinkUrl ?? _paymentLinkUrl;
      _qrisReferenceId = payment.qrisReferenceId ?? _qrisReferenceId;
      _qrisQrImageDataUrl = payment.qrisQrImageDataUrl ?? _qrisQrImageDataUrl;
      _qrisQrString = payment.qrisQrString ?? _qrisQrString;
      _paymentStatus = payment.status;
      _paymentMessage = payment.message;
    });
    _scheduleAutoSync();
  }

  void _scheduleAutoSync() {
    _syncTimer?.cancel();
    final registrationId = _registrationId;
    final referenceId = _qrisReferenceId;
    if (registrationId == null || referenceId == null) return;
    if (_tournamentId.isEmpty || _tournamentId.startsWith('demo-')) return;
    if ((_paymentStatus ?? '').toUpperCase() == 'COMPLETED') return;
    _syncTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _autoSync(),
    );
  }

  Future<void> _autoSync() async {
    if (_busy || !mounted) return;
    final registrationId = _registrationId;
    final referenceId = _qrisReferenceId;
    if (registrationId == null || referenceId == null) return;
    try {
      final payment = await ref
          .read(tournamentRepositoryProvider)
          .syncXenditQrisPayment(
            tournamentId: _tournamentId,
            registrationId: registrationId,
            qrisReferenceId: referenceId,
          );
      if (!mounted) return;
      _applyPaymentResult(payment);
      if (payment.paid) {
        _syncTimer?.cancel();
        setState(() => _step = _registrationSteps.length - 1);
      } else if (payment.expired) {
        _syncTimer?.cancel();
      }
    } catch (_) {
      // Best-effort background sync; manual check stays available.
    }
  }

  String _paymentErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message;
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      return 'Payment setup failed (${error.code}).';
    }
    return 'Payment setup failed. The registration may already be pending payment; reopen this tournament from My Tournaments and try checking payment status.';
  }

  Future<void> _openPaymentLink() async {
    final link = _paymentLinkUrl;
    final uri = link == null ? null : Uri.tryParse(link);
    if (uri == null) return;
    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!opened && mounted) {
      setState(() {
        _paymentMessage =
            'Checkout link is ready, but the browser blocked the new tab. Copy the link from the checkout panel.';
      });
    }
  }

  _DeckDraft _selectedDeckDraft(List<_DeckDraft> deckOptions) {
    if (deckOptions.isEmpty) {
      return const _DeckDraft(
        id: '',
        name: 'No saved deck',
        type: 'BALANCE',
        combos: [],
        atk: 0,
        def: 0,
        sta: 0,
        eligible: false,
      );
    }
    return deckOptions.firstWhere(
      (deck) => deck.name == _selectedDeck,
      orElse: () => deckOptions.first,
    );
  }
}

class _DeckDraft {
  const _DeckDraft({
    required this.id,
    required this.name,
    required this.type,
    required this.combos,
    required this.atk,
    required this.def,
    required this.sta,
    required this.eligible,
    this.snapshot = const {},
    this.reason,
  });
  final String id;
  final String name;
  final String type;
  final List<String> combos;
  final int atk;
  final int def;
  final int sta;
  final bool eligible;
  final Map<String, dynamic> snapshot;
  final String? reason;
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == step
                  ? HDTColors.accent
                  : i < step
                      ? HDTColors.success.withValues(alpha: 0.16)
                      : HDTColors.bg,
              border: Border.all(
                color: i == step
                    ? HDTColors.accent
                    : i < step
                        ? HDTColors.success
                        : HDTColors.s2,
              ),
            ),
            child: Center(
              child: i < step
                  ? const Icon(Icons.check, size: 14, color: HDTColors.success)
                  : Text('${i + 1}',
                      style: HDTText.display(
                          size: 13,
                          color: i == step ? Colors.white : HDTColors.text3)),
            ),
          ),
          const SizedBox(height: HDTSpace.xs),
          Text(labels[i],
              style: HDTText.overline(
                  size: 9,
                  color: i == step ? HDTColors.text : HDTColors.text3)),
        ]),
        if (i < labels.length - 1)
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(
                  left: HDTSpace.sm, right: HDTSpace.sm, bottom: 20),
              color: i < step ? HDTColors.success : HDTColors.s2,
            ),
          ),
      ],
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.kicker, this.title);
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(kicker, style: HDTText.overline(size: 10)),
      const SizedBox(height: HDTSpace.xs),
      Text(title, style: HDTText.display(size: 32)),
    ]);
  }
}

class _EligibilityRow extends StatelessWidget {
  const _EligibilityRow({
    required this.ok,
    required this.label,
    required this.detail,
  });
  final bool ok;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HDTColors.s2))),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (ok ? HDTColors.success : HDTColors.danger)
                .withValues(alpha: 0.15),
            border:
                Border.all(color: ok ? HDTColors.success : HDTColors.danger),
          ),
          child: Icon(ok ? Icons.check : Icons.lock,
              size: 14, color: ok ? HDTColors.success : HDTColors.danger),
        ),
        const SizedBox(width: HDTSpace.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: HDTText.body(size: 13)),
            Text(detail, style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ]),
        ),
        Text(ok ? 'PASS' : 'FAIL',
            style: HDTText.overline(
                size: 9, color: ok ? HDTColors.success : HDTColors.danger)),
      ]),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard(
      {required this.deck, required this.selected, required this.onTap});
  final _DeckDraft deck;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _deckColor(deck.type);
    return InkWell(
      onTap: onTap,
      borderRadius: HDTR.lg,
      child: Opacity(
        opacity: deck.eligible ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(HDTSpace.lg),
          decoration: hdtCard(
            borderColor: selected ? HDTColors.accent : HDTColors.s2,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
                decoration: BoxDecoration(color: color, borderRadius: HDTR.sm),
                child: Text(deck.type,
                    style: HDTText.overline(size: 9, color: Colors.white)),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle,
                    size: 20, color: HDTColors.accentHover),
            ]),
            const SizedBox(height: HDTSpace.md),
            Text(deck.name, style: HDTText.display(size: 18)),
            const SizedBox(height: HDTSpace.lg),
            for (var i = 0; i < deck.combos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: HDTSpace.xs),
                child: Text('#${i + 1} ${deck.combos[i]}',
                    style: HDTText.mono(size: 10, color: HDTColors.text3)),
              ),
            const SizedBox(height: HDTSpace.md),
            hdtDivider(),
            const SizedBox(height: HDTSpace.md),
            Row(children: [
              Expanded(child: _Mini('ATK', '${deck.atk}')),
              Expanded(child: _Mini('DEF', '${deck.def}')),
              Expanded(child: _Mini('STA', '${deck.sta}')),
            ]),
            if (!deck.eligible && deck.reason != null) ...[
              const SizedBox(height: HDTSpace.md),
              Container(
                padding: const EdgeInsets.all(HDTSpace.sm),
                decoration: BoxDecoration(
                  color: HDTColors.danger.withValues(alpha: 0.1),
                  borderRadius: HDTR.sm,
                  border: Border.all(
                      color: HDTColors.danger.withValues(alpha: 0.3)),
                ),
                child: Text(deck.reason!,
                    style: HDTText.mono(size: 10, color: HDTColors.danger)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _DeckSummary extends StatelessWidget {
  const _DeckSummary({required this.deck});
  final _DeckDraft deck;

  @override
  Widget build(BuildContext context) {
    final color = _deckColor(deck.type);
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: HDTR.md,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(deck.type[0],
                style: HDTText.display(size: 16, color: color)),
          ),
        ),
        const SizedBox(width: HDTSpace.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(deck.name, style: HDTText.body(size: 14)),
            Text('${deck.type} - ${deck.combos.length}/3 combos',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ]),
        ),
      ]),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  const _FeeBreakdown({
    required this.total,
    required this.fee,
    required this.platform,
    required this.gateway,
    required this.withdraw,
    this.community = '',
    required this.open,
    required this.onToggle,
  });

  final int total;
  final int fee;
  final int platform;
  final int gateway;
  final int withdraw;
  final String community;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOTAL PAYABLE', style: HDTText.overline(size: 10)),
        const SizedBox(height: HDTSpace.xs),
        Text(_formatRp(total),
            style: HDTText.display(size: 36, color: HDTColors.accentHover)),
        TextButton(
          onPressed: onToggle,
          child: Text(open ? 'HIDE BREAKDOWN' : 'SHOW BREAKDOWN'),
        ),
        if (open) ...[
          hdtDivider(),
          const SizedBox(height: HDTSpace.md),
          _FeeLine('Entry fee', fee),
          _FeeLine('Platform fee', platform, muted: true),
          _FeeLine('Payment gateway fee', gateway, muted: true),
          _FeeLine('Withdrawal coverage', withdraw, muted: true),
        ],
        const SizedBox(height: HDTSpace.md),
        Container(
          padding: const EdgeInsets.all(HDTSpace.md),
          decoration: hdtCard(bg: HDTColors.bg),
          child: Text(
            community.isEmpty
                ? 'The community receives the full ${_formatRp(fee)}.'
                : '$community community receives the full ${_formatRp(fee)}.',
            style: HDTText.body(size: 11, color: HDTColors.text2),
          ),
        ),
      ]),
    );
  }
}

class _XenditCheckoutPanel extends StatelessWidget {
  const _XenditCheckoutPanel({
    required this.total,
    required this.paymentSessionId,
    required this.paymentLinkUrl,
    required this.qrisQrImageDataUrl,
    required this.qrisQrString,
    required this.status,
    required this.onOpen,
  });

  final int total;
  final String? paymentSessionId;
  final String? paymentLinkUrl;
  final String? qrisQrImageDataUrl;
  final String? qrisQrString;
  final String? status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final currentStatus = (status ?? 'NOT CREATED').toUpperCase();
    final hasQris =
        qrisQrImageDataUrl != null && qrisQrImageDataUrl!.isNotEmpty;
    final active =
        hasQris || (paymentLinkUrl != null && paymentLinkUrl!.isNotEmpty);
    final qrisBytes = hasQris ? _decodeDataUrl(qrisQrImageDataUrl!) : null;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MERCHANT', style: HDTText.overline(size: 8)),
              Text('TURNEY.ID', style: HDTText.display(size: 14)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
            decoration: BoxDecoration(
              color: (active ? HDTColors.success : HDTColors.info)
                  .withValues(alpha: 0.15),
              borderRadius: HDTR.sm,
              border: Border.all(
                  color: (active ? HDTColors.success : HDTColors.info)
                      .withValues(alpha: 0.35)),
            ),
            child: Text(
              currentStatus,
              style: HDTText.overline(
                size: 8,
                color: active ? HDTColors.success : HDTColors.info,
              ),
            ),
          ),
        ]),
        const SizedBox(height: HDTSpace.lg),
        Container(
          width: 220,
          height: 220,
          padding: EdgeInsets.all(hasQris ? HDTSpace.sm : HDTSpace.lg),
          decoration: BoxDecoration(
            color: hasQris ? Colors.white : HDTColors.bg,
            borderRadius: HDTR.lg,
            border: Border.all(color: HDTColors.s2),
          ),
          child: qrisBytes != null
              ? Image.memory(qrisBytes, fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 56, color: HDTColors.accentHover),
                    const SizedBox(height: HDTSpace.md),
                    Text('QRIS', style: HDTText.display(size: 28)),
                    const SizedBox(height: HDTSpace.xs),
                    Text(
                      active ? 'QRIS READY' : 'WAITING TO CREATE',
                      textAlign: TextAlign.center,
                      style: HDTText.overline(size: 9, color: HDTColors.text3),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: HDTSpace.lg),
        Text('TOTAL PAYMENT', style: HDTText.overline(size: 9)),
        Text(_formatRp(total),
            style: HDTText.display(size: 28, color: HDTColors.accentHover)),
        const SizedBox(height: HDTSpace.lg),
        Text('PAYMENT ID', style: HDTText.overline(size: 9)),
        Text(
          paymentSessionId == null
              ? 'NOT CREATED'
              : _shortId(paymentSessionId!),
          style: HDTText.mono(size: 12, color: HDTColors.text2),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: HDTSpace.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: paymentLinkUrl != null && paymentLinkUrl!.isNotEmpty
                ? onOpen
                : null,
            icon: const Icon(Icons.open_in_new),
            label: const Text('OPEN FALLBACK CHECKOUT'),
          ),
        ),
        if (hasQris) ...[
          const SizedBox(height: HDTSpace.sm),
          Text(
            'Scan with any QRIS-enabled bank or e-wallet app, then press Check Payment Status.',
            textAlign: TextAlign.center,
            style: HDTText.body(size: 11, color: HDTColors.text2),
          ),
        ],
        if (paymentLinkUrl != null) ...[
          const SizedBox(height: HDTSpace.sm),
          SelectableText(
            paymentLinkUrl!,
            textAlign: TextAlign.center,
            style: HDTText.mono(size: 10, color: HDTColors.text3),
          ),
        ],
      ]),
    );
  }
}

class _PaymentInstructions extends StatelessWidget {
  const _PaymentInstructions({required this.hasLink});

  final bool hasLink;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '01',
        'Create QRIS',
        'Turney creates a QRIS code from the server.'
      ),
      (
        '02',
        'Scan QR',
        'The QRIS code appears here so the participant does not need a new checkout tab.'
      ),
      (
        '03',
        'Complete payment',
        'Pay using any QRIS-enabled bank or e-wallet app.'
      ),
      (
        '04',
        'Sync status',
        hasLink
            ? 'Return here and press Check Payment Status.'
            : 'After QRIS is created, the button changes into status sync.'
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT GUIDE', style: HDTText.overline(size: 10)),
        const SizedBox(height: HDTSpace.md),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: HDTSpace.md),
            child: Container(
              padding: const EdgeInsets.all(HDTSpace.md),
              decoration: hdtCard(),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: HDTColors.s2, borderRadius: HDTR.sm),
                  child: Center(
                      child: Text(item.$1, style: HDTText.display(size: 11))),
                ),
                const SizedBox(width: HDTSpace.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: HDTText.body(size: 13)),
                        const SizedBox(height: HDTSpace.xs),
                        Text(item.$3,
                            style: HDTText.body(
                                size: 12, color: HDTColors.text2, height: 1.5)),
                      ]),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

Uint8List? _decodeDataUrl(String value) {
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.tournamentName,
    required this.deck,
    required this.registrationId,
  });
  final String tournamentName;
  final _DeckDraft deck;
  final String registrationId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.xl),
      decoration: hdtAccentCard(accentColor: HDTColors.accent),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('JKT WOLVES',
            style: HDTText.overline(size: 10, color: HDTColors.accentHover)),
        const SizedBox(height: HDTSpace.xs),
        Text(tournamentName, style: HDTText.display(size: 28)),
        Text('MAY 22, 2026 - 14:00',
            style: HDTText.mono(size: 12, color: HDTColors.text3)),
        const SizedBox(height: HDTSpace.lg),
        hdtDivider(),
        const SizedBox(height: HDTSpace.lg),
        Row(children: [
          const Expanded(child: _TicketInfo('PLAYER', 'HANSEL\nHDT-202')),
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(HDTSpace.sm),
            decoration:
                const BoxDecoration(color: Colors.white, borderRadius: HDTR.md),
            child:
                CustomPaint(painter: _QrPainter(seed: registrationId.hashCode)),
          ),
          Expanded(
              child: _TicketInfo(
                  'DECK', '${deck.name}\n${deck.combos.length}/3 KOMBO',
                  alignRight: true)),
        ]),
        const SizedBox(height: HDTSpace.lg),
        hdtDivider(),
        const SizedBox(height: HDTSpace.lg),
        const Row(children: [
          Expanded(child: _TicketInfo('LOCATION', 'Gear Sports Arena')),
          _TicketInfo('CHECK-IN', '14:00 - 15:30', alignRight: true),
        ]),
      ]),
    );
  }
}

class _TicketInfo extends StatelessWidget {
  const _TicketInfo(this.label, this.value, {this.alignRight = false});
  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        Text(value,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: HDTText.body(size: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: HDTColors.text3),
          const SizedBox(width: HDTSpace.xs),
          Text(label, style: HDTText.overline(size: 9)),
        ]),
        const SizedBox(height: HDTSpace.sm),
        Text(value, style: HDTText.body(size: 13)),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: HDTText.overline(size: 9)),
      const SizedBox(height: HDTSpace.xs),
      Text(value, style: HDTText.mono(size: 12, color: HDTColors.text)),
    ]);
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine(this.label, this.value, {this.muted = false});
  final String label;
  final int value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HDTSpace.sm),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: HDTText.body(
                    size: 12,
                    color: muted ? HDTColors.text3 : HDTColors.text2))),
        Text(_formatRp(value),
            style: HDTText.mono(
                size: 11, color: muted ? HDTColors.text3 : HDTColors.text)),
      ]),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 720
          ? 4
          : constraints.maxWidth >= 520
              ? 2
              : 1;
      final width = (constraints.maxWidth - ((cols - 1) * HDTSpace.md)) / cols;
      return Wrap(
        spacing: HDTSpace.md,
        runSpacing: HDTSpace.md,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    });
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.icon,
    required this.text,
  });
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: HDTR.lg,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: HDTSpace.md),
        Expanded(
            child: Text(text,
                style: HDTText.body(color: HDTColors.text2, height: 1.5))),
      ]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.busy,
    required this.canBack,
    required this.nextEnabled,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });
  final bool busy;
  final bool canBack;
  final bool nextEnabled;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: const BoxDecoration(
        color: HDTColors.bg,
        border: Border(top: BorderSide(color: HDTColors.s2)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Row(children: [
              TextButton.icon(
                onPressed: canBack ? onBack : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('BACK'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: busy || !nextEnabled ? null : onNext,
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(busy ? 'MEMPROSES...' : nextLabel),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HDTColors.s1;
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
            : ((r * 31 + c * 17 + seed) % 5 != 0);
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
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

Color _deckColor(String type) {
  return switch (type) {
    'ATTACK' => HDTColors.warning,
    'DEFENSE' => HDTColors.info,
    'STAMINA' => HDTColors.success,
    _ => HDTColors.accent,
  };
}

int _parseFee(String value) {
  if (value.trim().toUpperCase() == 'FREE') {
    return 0;
  }
  final clean = value.replaceAll(RegExp('[^0-9]'), '');
  return int.tryParse(clean) ?? 75000;
}

String _formatRp(int value) {
  return 'Rp ${value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      )}';
}

String _shortId(String value) {
  if (value.length <= 16) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
}
