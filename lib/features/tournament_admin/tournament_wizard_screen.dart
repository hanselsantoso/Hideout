import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/tournament_repository.dart';

const _wizardSteps = [
  'BASIC',
  'FORMAT',
  'ELIGIBILITY',
  'PRICING',
  'LOGISTICS',
  'JURI & ARENA',
];

const _tiers = [
  _Tier('casual', 'CASUAL', 'Open to all', HDTColors.success),
  _Tier('standard', 'STANDARD', 'ELO 1800+', HDTColors.info),
  _Tier('premier', 'PREMIER', 'ELO 2500+', HDTColors.accent),
  _Tier('invite', 'INVITE', 'Top 16 only', Color(0xFFF4D03F)),
];

const _stageFormats = [
  'Round Robin',
  'Swiss',
  'Single Elimination',
  'Double Elimination',
];

const _seedingModes = [
  'ELO-based',
  'Win Rate-based',
  'Random',
  'Manual',
];

const _fallbackJuriCandidates = [
  AssignableJudge(uid: 'fallback:bayu', displayName: 'BAYU', role: 'demo'),
  AssignableJudge(uid: 'fallback:nadia', displayName: 'NADIA', role: 'demo'),
  AssignableJudge(
      uid: 'fallback:gerhana', displayName: 'GERHANA', role: 'demo'),
  AssignableJudge(uid: 'fallback:taro', displayName: 'TARO', role: 'demo'),
  AssignableJudge(uid: 'fallback:rama', displayName: 'RAMA', role: 'demo'),
  AssignableJudge(uid: 'fallback:sinta', displayName: 'SINTA', role: 'demo'),
];

class TournamentWizardScreen extends ConsumerStatefulWidget {
  const TournamentWizardScreen({super.key});

  @override
  ConsumerState<TournamentWizardScreen> createState() =>
      _TournamentWizardScreenState();
}

class _TournamentWizardScreenState
    extends ConsumerState<TournamentWizardScreen> {
  int _step = 0;
  bool _busy = false;
  bool _seedingMatches = false;
  String? _error;
  String? _createdId;
  int? _seededMatchCount;

  final _name = TextEditingController(text: 'Hideout Cup #04');
  final _tagline =
      TextEditingController(text: 'Spring Showdown - Single Elim Championship');
  final _description = TextEditingController(
      text:
          'Turnamen Beyblade X bulanan untuk komunitas Jakarta. Bracket terbuka, 64 slot.');
  final _venue = TextEditingController(text: 'GBK Arena 02 - Senayan');
  final _city = TextEditingController(text: 'Jakarta');
  final _capacity = TextEditingController(text: '64');
  final _entryFee = TextEditingController(text: '75000');
  final _platformRate = TextEditingController(text: '10');
  final _gatewayRate = TextEditingController(text: '3');
  final _minElo = TextEditingController(text: '1200');
  final _maxElo = TextEditingController(text: '3000');
  final _startDate = TextEditingController(text: '2026-05-22');
  final _startTime = TextEditingController(text: '14:00');
  final _checkInOpen = TextEditingController(text: '12:30');
  final _checkInClose = TextEditingController(text: '13:45');
  final _address = TextEditingController(text: 'GBK Senayan, Hall C, Jakarta');
  final _streamUrl = TextEditingController();
  final _firstPrize = TextEditingController(text: 'Rp 1.500.000 + trophy');
  final _secondPrize = TextEditingController(text: 'Rp 750.000');
  final _thirdPrize = TextEditingController(text: 'Rp 350.000');
  final _bannedDraft = TextEditingController(text: 'Cobalt Dragoon');

  String _tier = 'standard';
  Color _bannerColor = HDTColors.accent;
  String _seeding = 'ELO-based';
  String _deckSize = '3';
  bool _allowDraws = false;
  bool _lockedDeck = true;
  bool _verifiedOnly = true;
  final List<_Stage> _stages = [
    _Stage(
      format: 'Round Robin',
      bestOf: 'BO3',
      advance: '16',
      groupCount: '4',
      advancePerGroup: '4',
    ),
    _Stage(format: 'Double Elimination', bestOf: 'BO5', advance: '0'),
  ];
  final Set<String> _bannedParts = {'Cobalt Dragoon'};
  final List<_ArenaDraft> _arenas = [
    _ArenaDraft(name: 'ARENA 01', juri: {'fallback:bayu'}),
    _ArenaDraft(name: 'ARENA 02', juri: {'fallback:nadia'}),
  ];

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    _venue.dispose();
    _city.dispose();
    _capacity.dispose();
    _entryFee.dispose();
    _platformRate.dispose();
    _gatewayRate.dispose();
    _minElo.dispose();
    _maxElo.dispose();
    _startDate.dispose();
    _startTime.dispose();
    _checkInOpen.dispose();
    _checkInClose.dispose();
    _address.dispose();
    _streamUrl.dispose();
    _firstPrize.dispose();
    _secondPrize.dispose();
    _thirdPrize.dispose();
    _bannedDraft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final gate = profile.valueOrNull;

    if (profile.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (gate == null) return const _LoginRequired();
    if (!gate.isCommunityAdminCompatible) {
      return _PermissionNotice(role: gate.role);
    }

    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                HDTSpace.lg, HDTSpace.xxl, HDTSpace.lg, 120),
            children: [
              _breadcrumb(),
              const SizedBox(height: HDTSpace.md),
              _header(),
              const SizedBox(height: HDTSpace.xxl),
              _Stepper(step: _step, labels: _wizardSteps, onTap: _setStep),
              const SizedBox(height: HDTSpace.xxl),
              _currentStep(),
              if (_createdId != null) ...[
                const SizedBox(height: HDTSpace.lg),
                _Notice(
                  color: HDTColors.success,
                  icon: Icons.check_circle_outline,
                  text: 'Tournament created: $_createdId',
                ),
                const SizedBox(height: HDTSpace.md),
                _MatchSeedActions(
                  tournamentId: _createdId!,
                  seededMatchCount: _seededMatchCount,
                  busy: _seedingMatches,
                  onSeed: _seedMatches,
                ),
              ],
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
      bottomNavigationBar: _BottomBar(
        canBack: _step > 0,
        busy: _busy,
        backLabel: _step == 0 ? 'CANCEL' : 'BACK TO ${_wizardSteps[_step - 1]}',
        nextLabel: _step == _wizardSteps.length - 1
            ? 'PUBLISH TOURNAMENT'
            : 'CONTINUE TO ${_wizardSteps[_step + 1]}',
        onBack: _step == 0 ? () => Navigator.maybePop(context) : _back,
        onNext: _busy ? null : _next,
      ),
    );
  }

  Widget _breadcrumb() {
    return Row(
      children: [
        Text('JKT WOLVES', style: HDTText.overline(size: 10)),
        const SizedBox(width: HDTSpace.xs),
        const Icon(Icons.chevron_right, size: 12, color: HDTColors.text3),
        const SizedBox(width: HDTSpace.xs),
        Text('NEW TOURNAMENT', style: HDTText.overline(size: 10)),
      ],
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _name.text.trim().isEmpty
              ? 'UNTITLED TOURNAMENT'
              : _name.text.trim().toUpperCase(),
          style: HDTText.display(size: 40).copyWith(height: 1.05),
        ),
        const SizedBox(height: HDTSpace.xs),
        Text('DRAFT - LAST SAVED 12 SEC AGO',
            style: HDTText.mono(size: 12, color: HDTColors.text3)),
      ],
    );
  }

  Widget _currentStep() {
    return switch (_step) {
      0 => _basicStep(),
      1 => _formatStep(),
      2 => _eligibilityStep(),
      3 => _pricingStep(),
      4 => _logisticsStep(),
      _ => _juriStep(),
    };
  }

  Widget _basicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('SECTION A', 'BANNER PREVIEW'),
        const SizedBox(height: HDTSpace.lg),
        _BannerPreview(
          color: _bannerColor,
          tier: _tiers.firstWhere((t) => t.id == _tier).label,
          name: _name.text,
          tagline: _tagline.text,
          startDate: _startDate.text,
          startTime: _startTime.text,
          city: _city.text,
          capacity: _capacity.text,
        ),
        const SizedBox(height: HDTSpace.lg),
        _ColorPicker(
          value: _bannerColor,
          onChanged: (value) => setState(() => _bannerColor = value),
        ),
        const SizedBox(height: HDTSpace.xxl),
        const _SectionTitle('SECTION B', 'NAME & DESCRIPTION'),
        const SizedBox(height: HDTSpace.lg),
        _Field(label: 'TOURNAMENT NAME', controller: _name, maxLength: 48),
        const SizedBox(height: HDTSpace.md),
        _Field(label: 'TAGLINE', controller: _tagline, maxLength: 80),
        const SizedBox(height: HDTSpace.md),
        _Field(
          label: 'DESCRIPTION',
          controller: _description,
          minLines: 4,
          maxLines: 5,
          maxLength: 400,
        ),
        const SizedBox(height: HDTSpace.xxl),
        const _SectionTitle('SECTION C', 'TIER'),
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 720
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: HDTSpace.md,
              runSpacing: HDTSpace.md,
              children: [
                for (final tier in _tiers)
                  SizedBox(
                    width: cardWidth,
                    child: _TierCard(
                      tier: tier,
                      active: _tier == tier.id,
                      onTap: () => setState(() => _tier = tier.id),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.xxl),
        const _SectionTitle('SECTION D', 'SCHEDULE & VENUE'),
        const SizedBox(height: HDTSpace.lg),
        _ResponsiveGrid(
          children: [
            _Field(label: 'START DATE', controller: _startDate),
            _Field(label: 'START TIME', controller: _startTime),
            _Field(
                label: 'CAPACITY',
                controller: _capacity,
                keyboardType: TextInputType.number),
            _Field(label: 'CITY', controller: _city),
            _Field(label: 'VENUE', controller: _venue),
          ],
        ),
        const SizedBox(height: HDTSpace.lg),
        const _Notice(
          color: HDTColors.accentHover,
          icon: Icons.info_outline,
          text:
              'Banner color dan tier akan diturunkan ke halaman registrasi dan bracket.',
        ),
      ],
    );
  }

  Widget _formatStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
                child: _SectionTitle('SECTION A', 'TOURNAMENT FORMAT')),
            Text('${_stages.length} / 4 STAGES',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ],
        ),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Default event memakai 2 stage: round robin group untuk semua peserta, lalu top cut double elimination.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        const SizedBox(height: HDTSpace.lg),
        for (var i = 0; i < _stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: HDTSpace.md),
            child: _StageCard(
              index: i,
              stage: _stages[i],
              canDelete: _stages.length > 1,
              onDelete: () => setState(() => _stages.removeAt(i)),
              onChanged: () => setState(() {}),
            ),
          ),
        if (_stages.length < 4)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _stages.add(_Stage())),
              icon: const Icon(Icons.add),
              label: const Text('ADD STAGE'),
            ),
          ),
        const SizedBox(height: HDTSpace.xxl),
        const _SectionTitle('SECTION B', 'BRACKET SEEDING'),
        const SizedBox(height: HDTSpace.lg),
        _ResponsiveGrid(
          children: [
            for (final mode in _seedingModes)
              _OptionCard(
                active: _seeding == mode,
                title: mode,
                subtitle: _seedingTip(mode),
                onTap: () => setState(() => _seeding = mode),
              ),
          ],
        ),
        const SizedBox(height: HDTSpace.xxl),
        const _SectionTitle('SECTION C', 'MATCH RULES'),
        const SizedBox(height: HDTSpace.lg),
        _SettingsPanel(
          rows: [
            _ToggleRow(
              title: 'Allow Draws',
              subtitle: 'Draw count sebagai 0.5 point per side.',
              value: _allowDraws,
              onChanged: (value) => setState(() => _allowDraws = value),
            ),
            const _InfoRow(
              title: 'Time Limit Per Round',
              value: '5 min',
              subtitle: 'Round auto-resolves jika melewati batas waktu.',
            ),
            const _InfoRow(
              title: 'Tiebreaker',
              value: 'Sudden Death',
              subtitle: 'Cara menentukan pemenang saat skor seri.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _eligibilityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 3', 'ELIGIBILITY & DECK RULES'),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Rule ini muncul di registration flow dan dipakai juri saat verifikasi deck.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        const SizedBox(height: HDTSpace.lg),
        _ResponsiveGrid(
          children: [
            _Field(
                label: 'MIN ELO',
                controller: _minElo,
                keyboardType: TextInputType.number),
            _Field(
                label: 'MAX ELO',
                controller: _maxElo,
                keyboardType: TextInputType.number),
            _SelectBox(
              label: 'DECK SIZE',
              value: _deckSize,
              values: const ['1', '2', '3'],
              onChanged: (value) => setState(() => _deckSize = value),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.lg),
        _SettingsPanel(
          rows: [
            _ToggleRow(
              title: 'Deck locked after check-in',
              subtitle: 'Juri membandingkan QR peserta dengan deck terdaftar.',
              value: _lockedDeck,
              onChanged: (value) => setState(() => _lockedDeck = value),
            ),
            _ToggleRow(
              title: 'Verified account only',
              subtitle: 'Email terverifikasi wajib sebelum pembayaran.',
              value: _verifiedOnly,
              onChanged: (value) => setState(() => _verifiedOnly = value),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.lg),
        _BannedPartsEditor(
          draft: _bannedDraft,
          parts: _bannedParts,
          onAdd: _addBannedPart,
          onRemove: (part) => setState(() => _bannedParts.remove(part)),
        ),
        const SizedBox(height: HDTSpace.lg),
        const _Notice(
          color: HDTColors.warning,
          icon: Icons.shield_outlined,
          text:
              'Default poin match: Spin +1, Burst +2, Over +2, Xtreme +3. Admin komunitas masih bisa menulis override di rules.',
        ),
      ],
    );
  }

  Widget _pricingStep() {
    final fee = int.tryParse(_entryFee.text) ?? 0;
    final platform = int.tryParse(_platformRate.text) ?? 10;
    final gateway = int.tryParse(_gatewayRate.text) ?? 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 4', 'PRICING & PRIZES'),
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.lg,
              children: [
                SizedBox(
                  width:
                      wide ? constraints.maxWidth - 340 : constraints.maxWidth,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(HDTSpace.lg),
                        decoration: hdtCard(),
                        child: _ResponsiveGrid(
                          children: [
                            _Field(
                                label: 'ENTRY FEE NET',
                                controller: _entryFee,
                                keyboardType: TextInputType.number),
                            _Field(
                                label: 'PLATFORM FEE % (DIBAYAR USER)',
                                controller: _platformRate,
                                keyboardType: TextInputType.number),
                            _Field(
                                label: 'MIDTRANS / QRIS EST. % (DIBAYAR USER)',
                                controller: _gatewayRate,
                                keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(height: HDTSpace.lg),
                      Container(
                        padding: const EdgeInsets.all(HDTSpace.lg),
                        decoration: hdtCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRIZE LIST',
                                style: HDTText.overline(size: 10)),
                            const SizedBox(height: HDTSpace.md),
                            _Field(label: '1ST PLACE', controller: _firstPrize),
                            const SizedBox(height: HDTSpace.md),
                            _Field(
                                label: '2ND PLACE', controller: _secondPrize),
                            const SizedBox(height: HDTSpace.md),
                            _Field(label: '3RD PLACE', controller: _thirdPrize),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: wide ? 320 : constraints.maxWidth,
                  child: _MoneyPreview(
                    fee: fee,
                    platformRate: platform,
                    gatewayRate: gateway,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _logisticsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('STEP 5', 'LOGISTICS'),
        const SizedBox(height: HDTSpace.lg),
        _ResponsiveGrid(
          children: [
            _Field(label: 'CHECK-IN OPENS', controller: _checkInOpen),
            _Field(label: 'CHECK-IN CLOSES', controller: _checkInClose),
            _Field(label: 'LIVESTREAM URL', controller: _streamUrl),
          ],
        ),
        const SizedBox(height: HDTSpace.lg),
        _Field(
          label: 'FULL ADDRESS',
          controller: _address,
          minLines: 3,
          maxLines: 4,
        ),
        const SizedBox(height: HDTSpace.lg),
        const _Notice(
          color: HDTColors.accentHover,
          icon: Icons.qr_code_2,
          text:
              'Peserta scan QR untuk check-in. Saat match dipanggil, juri scan lagi untuk validasi deck terkunci.',
        ),
      ],
    );
  }

  Widget _juriStep() {
    final judges = ref.watch(assignableJudgesProvider);
    final liveJudges = judges.valueOrNull ?? const <AssignableJudge>[];
    final candidates =
        liveJudges.isEmpty ? _fallbackJuriCandidates : liveJudges;
    final totalJuri =
        _arenas.fold<int>(0, (sum, arena) => sum + arena.juri.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('STEP 6', 'JURI & ARENA')),
            ElevatedButton.icon(
              onPressed: () => setState(() => _arenas.add(_ArenaDraft(
                    name:
                        'ARENA ${(_arenas.length + 1).toString().padLeft(2, '0')}',
                  ))),
              icon: const Icon(Icons.add),
              label: const Text('ADD ARENA'),
            ),
          ],
        ),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Assign juri dari pool komunitas ke arena fisik. Satu arena bisa punya lebih dari satu juri.',
          style: HDTText.body(color: HDTColors.text2),
        ),
        if (liveJudges.isEmpty) ...[
          const SizedBox(height: HDTSpace.md),
          _Notice(
            color: judges.hasError ? HDTColors.warning : HDTColors.accentHover,
            icon: judges.hasError
                ? Icons.warning_amber_outlined
                : Icons.manage_accounts_outlined,
            text: judges.hasError
                ? 'Belum bisa membaca akun juri dari Firebase. Chip demo tetap tampil untuk layout, tapi generate match butuh akun juri live.'
                : 'Belum ada akun dengan role judge. Tambahkan/promosikan pemain menjadi juri agar match live bisa di-assign ke akun mereka.',
          ),
        ],
        const SizedBox(height: HDTSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 720
                ? (constraints.maxWidth - HDTSpace.lg) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.lg,
              children: [
                for (var i = 0; i < _arenas.length; i++)
                  SizedBox(
                    width: width,
                    child: _ArenaCard(
                      arena: _arenas[i],
                      candidates: candidates,
                      onChanged: () => setState(() {}),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: HDTSpace.lg),
        Container(
          padding: const EdgeInsets.all(HDTSpace.lg),
          decoration: hdtAccentCard(accentColor: HDTColors.accent),
          child: _ResponsiveGrid(
            children: [
              _MiniStat('FORMAT',
                  _stages.map((stage) => _abbr(stage.format)).join(' -> ')),
              _MiniStat('FEE', _formatRp(_grossFee)),
              _MiniStat(
                  'CHECK-IN', '${_checkInOpen.text} - ${_checkInClose.text}'),
              _MiniStat('JURI', '$totalJuri assigned'),
            ],
          ),
        ),
      ],
    );
  }

  void _setStep(int value) {
    setState(() {
      _error = null;
      _step = value;
    });
  }

  void _back() => _setStep((_step - 1).clamp(0, _wizardSteps.length - 1));

  Future<void> _next() async {
    if (_step < _wizardSteps.length - 1) {
      _setStep(_step + 1);
      return;
    }
    await _publish();
  }

  Future<void> _publish() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      Navigator.pushNamed(context, '/signup');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _createdId = null;
      _seededMatchCount = null;
    });
    try {
      final now = DateTime.now();
      final id = await ref.read(tournamentRepositoryProvider).createTournament(
            name: _name.text,
            location: _venue.text,
            registrationFee: int.tryParse(_entryFee.text) ?? 0,
            maxParticipants: int.tryParse(_capacity.text) ?? 32,
            bracketType: _backendBracketType(_stages.last.format),
            matchPointTarget: 4,
            startDate: now.add(const Duration(days: 14)),
            registrationDeadline: now.add(const Duration(days: 13)),
            maxDecksPerPlayer: int.tryParse(_deckSize) ?? 3,
            prizes: [_firstPrize.text, _secondPrize.text, _thirdPrize.text],
            organizerId: user.uid,
            stagePlan: [
              for (var i = 0; i < _stages.length; i++) _stages[i].toPayload(i),
            ],
          );
      if (!mounted) return;
      setState(() => _createdId = id.isEmpty ? 'created' : id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament tersimpan di Firebase.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Belum bisa membuat tournament. Pastikan akun ini punya role admin komunitas dan coba ulangi.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _seedMatches() async {
    final tournamentId = _createdId;
    if (tournamentId == null || tournamentId.isEmpty) return;
    setState(() {
      _seedingMatches = true;
      _error = null;
      _seededMatchCount = null;
    });
    try {
      final count = await ref
          .read(tournamentRepositoryProvider)
          .generateFirstRoundMatches(
            tournamentId: tournamentId,
            arenas: _arenaAssignments(),
            matchPointTarget: 4,
          );
      if (!mounted) return;
      setState(() => _seededMatchCount = count);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count match siap untuk juri.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Belum bisa generate match. Pastikan ada akun juri live dan minimal 2 peserta sudah paid active.';
      });
    } finally {
      if (mounted) setState(() => _seedingMatches = false);
    }
  }

  List<JudgeArenaAssignment> _arenaAssignments() {
    final liveJudges = ref.read(assignableJudgesProvider).valueOrNull ??
        const <AssignableJudge>[];
    final namesById = {
      for (final judge in _fallbackJuriCandidates) judge.uid: judge.displayName,
      for (final judge in liveJudges) judge.uid: judge.displayName,
    };
    return [
      for (final arena in _arenas)
        JudgeArenaAssignment(
          name: arena.name,
          judgeIds: arena.juri.toList(),
          judgeNames: [for (final id in arena.juri) namesById[id] ?? 'Judge'],
        ),
    ];
  }

  void _addBannedPart() {
    final part = _bannedDraft.text.trim();
    if (part.isEmpty) return;
    setState(() {
      _bannedParts.add(part);
      _bannedDraft.clear();
    });
  }

  int get _grossFee {
    final fee = int.tryParse(_entryFee.text) ?? 0;
    final platform = int.tryParse(_platformRate.text) ?? 10;
    final gateway = int.tryParse(_gatewayRate.text) ?? 3;
    return fee + (fee * platform / 100).round() + (fee * gateway / 100).round();
  }

  String _backendBracketType(String value) {
    return switch (value) {
      'Double Elimination' => 'doubleElimination',
      'Swiss' => 'swiss',
      'Round Robin' => 'roundRobin',
      _ => 'singleElimination',
    };
  }
}

class _Tier {
  const _Tier(this.id, this.label, this.sub, this.color);
  final String id;
  final String label;
  final String sub;
  final Color color;
}

class _Stage {
  _Stage({
    this.format = 'Single Elimination',
    this.bestOf = 'BO5',
    this.advance = '0',
    this.groupCount = '4',
    this.advancePerGroup = '4',
  });
  String format;
  String bestOf;
  String advance;
  String groupCount;
  String advancePerGroup;

  Map<String, dynamic> toPayload(int index) {
    final isGroup = format == 'Round Robin';
    return {
      'index': index + 1,
      'name': 'Stage ${index + 1}',
      'format': _backendFormat(format),
      'bestOf': bestOf,
      'advanceTotal': int.tryParse(advance) ?? 0,
      if (isGroup) ...{
        'groupCount': int.tryParse(groupCount) ?? 4,
        'advancePerGroup': int.tryParse(advancePerGroup) ?? 4,
        'pairing': 'roundRobinAllPlayAll',
        'pointRule': {
          'win': 3,
          'draw': 1,
          'loss': 0,
        },
        'tiebreakers': [
          'matchWinRate',
          'pointDifference',
          'headToHead',
          'suddenDeath',
        ],
      },
      if (format == 'Double Elimination') ...{
        'upperBracket': true,
        'lowerBracket': true,
        'grandFinal': true,
        'bracketReset': true,
        'eliminationAfterLosses': 2,
      },
      'publicVisibility': {
        'standings': true,
        'schedule': true,
        'results': true,
        'nextCall': true,
        'rules': true,
      },
    };
  }

  String _backendFormat(String value) {
    return switch (value) {
      'Double Elimination' => 'doubleElimination',
      'Swiss' => 'swiss',
      'Round Robin' => 'roundRobin',
      _ => 'singleElimination',
    };
  }
}

class _ArenaDraft {
  _ArenaDraft({required this.name, Set<String>? juri}) : juri = juri ?? {};
  String name;
  Set<String> juri;
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUAT TURNAMEN')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          child: const Text('LOGIN ADMIN KOMUNITAS'),
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BUAT TURNAMEN')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(HDTSpace.lg),
          padding: const EdgeInsets.all(HDTSpace.xl),
          decoration: hdtCard(),
          child: Text(
            'Role akun ini `$role`. Buat tournament hanya untuk admin komunitas atau super admin.',
            textAlign: TextAlign.center,
            style: HDTText.body(color: HDTColors.text2, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.step, required this.labels, required this.onTap});
  final int step;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          InkWell(
            onTap: () => onTap(i),
            borderRadius: HDTR.full,
            child: Column(
              children: [
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
                        ? const Icon(Icons.check,
                            size: 14, color: HDTColors.success)
                        : Text('${i + 1}',
                            style: HDTText.display(
                                size: 13,
                                color: i == step
                                    ? Colors.white
                                    : HDTColors.text3)),
                  ),
                ),
                const SizedBox(height: HDTSpace.xs),
                Text(labels[i],
                    style: HDTText.overline(
                        size: 9,
                        color: i == step ? HDTColors.text : HDTColors.text3)),
              ],
            ),
          ),
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
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.kicker, this.title);
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: HDTText.overline(size: 10)),
        const SizedBox(height: HDTSpace.xs),
        Text(title, style: HDTText.display(size: 28)),
      ],
    );
  }
}

class _BannerPreview extends StatelessWidget {
  const _BannerPreview({
    required this.color,
    required this.tier,
    required this.name,
    required this.tagline,
    required this.startDate,
    required this.startTime,
    required this.city,
    required this.capacity,
  });

  final Color color;
  final String tier;
  final String name;
  final String tagline;
  final String startDate;
  final String startTime;
  final String city;
  final String capacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: HDTR.lg,
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 28)
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.38), HDTColors.bg],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
              decoration: BoxDecoration(color: color, borderRadius: HDTR.sm),
              child: Text(tier,
                  style: HDTText.overline(size: 10, color: Colors.white)),
            ),
            const SizedBox(height: HDTSpace.md),
            Text(name.isEmpty ? 'UNTITLED' : name.toUpperCase(),
                style: HDTText.display(size: 40).copyWith(height: 1.05)),
            const SizedBox(height: HDTSpace.xs),
            Text(tagline.isEmpty ? '-' : tagline,
                style: HDTText.body(size: 14, color: HDTColors.text2)),
            const SizedBox(height: HDTSpace.lg),
            Wrap(
              spacing: HDTSpace.lg,
              runSpacing: HDTSpace.sm,
              children: [
                _InlineMeta(
                    Icons.calendar_today_outlined, '$startDate $startTime'),
                _InlineMeta(Icons.location_on_outlined, city),
                _InlineMeta(Icons.groups_outlined, '$capacity slot'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.value, required this.onChanged});
  final Color value;
  final ValueChanged<Color> onChanged;

  static const colors = [
    HDTColors.accent,
    Color(0xFFE67E22),
    HDTColors.info,
    HDTColors.success,
    Color(0xFFF4D03F),
    HDTColors.danger,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BANNER COLOR', style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.sm),
        Wrap(
          spacing: HDTSpace.sm,
          runSpacing: HDTSpace.sm,
          children: [
            for (final color in colors)
              InkWell(
                onTap: () => onChanged(color),
                borderRadius: HDTR.full,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color == value ? HDTColors.text : HDTColors.s2,
                        width: 2),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload, size: 13),
              label: const Text('UPLOAD IMAGE'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard(
      {required this.tier, required this.active, required this.onTap});
  final _Tier tier;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: HDTR.lg,
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.md),
        decoration: hdtCard(
          bg: active ? tier.color.withValues(alpha: 0.12) : HDTColors.s1,
          borderColor: active ? tier.color : HDTColors.s2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration:
                  BoxDecoration(color: tier.color, borderRadius: HDTR.sm),
              child: const Icon(Icons.shield_outlined,
                  size: 15, color: Colors.black),
            ),
            const SizedBox(height: HDTSpace.md),
            Text(tier.label, style: HDTText.display(size: 16)),
            Text(tier.sub, style: HDTText.mono(size: 10)),
          ],
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.index,
    required this.stage,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  final int index;
  final _Stage stage;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

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
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: HDTColors.s2, borderRadius: HDTR.sm),
                child: Center(
                    child:
                        Text('${index + 1}', style: HDTText.display(size: 13))),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Text('STAGE ${index + 1}',
                    style: HDTText.display(size: 18)),
              ),
              IconButton(
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          _ResponsiveGrid(
            children: [
              _SelectBox(
                label: 'FORMAT',
                value: stage.format,
                values: _stageFormats,
                onChanged: (value) {
                  stage.format = value;
                  onChanged();
                },
              ),
              _SelectBox(
                label: 'BEST OF',
                value: stage.bestOf,
                values: const ['BO1', 'BO3', 'BO5', 'BO7'],
                onChanged: (value) {
                  stage.bestOf = value;
                  onChanged();
                },
              ),
              _SelectBox(
                label: 'ADVANCE',
                value: stage.advance,
                values: const ['0', '4', '8', '16', '32'],
                onChanged: (value) {
                  stage.advance = value;
                  onChanged();
                },
              ),
            ],
          ),
          if (stage.format == 'Round Robin') ...[
            const SizedBox(height: HDTSpace.md),
            _ResponsiveGrid(
              children: [
                _SelectBox(
                  label: 'GROUPS',
                  value: stage.groupCount,
                  values: const ['2', '4', '8', '16'],
                  onChanged: (value) {
                    stage.groupCount = value;
                    final groups = int.tryParse(stage.groupCount) ?? 4;
                    final top = int.tryParse(stage.advancePerGroup) ?? 4;
                    stage.advance = (groups * top).toString();
                    onChanged();
                  },
                ),
                _SelectBox(
                  label: 'TOP / GROUP',
                  value: stage.advancePerGroup,
                  values: const ['1', '2', '3', '4'],
                  onChanged: (value) {
                    stage.advancePerGroup = value;
                    final groups = int.tryParse(stage.groupCount) ?? 4;
                    final top = int.tryParse(stage.advancePerGroup) ?? 4;
                    stage.advance = (groups * top).toString();
                    onChanged();
                  },
                ),
                const _InfoRow(
                  title: 'Round-robin pairing',
                  value: 'All-play-all',
                  subtitle:
                      'Setiap pemain di grup akan bertemu semua lawan satu kali.',
                ),
              ],
            ),
            const SizedBox(height: HDTSpace.md),
            const _Notice(
              color: HDTColors.info,
              icon: Icons.visibility_outlined,
              text:
                  'Standings, hasil match, next call, rules, dan tiebreaker stage ini akan tampil transparan untuk pemain.',
            ),
          ],
          if (stage.format == 'Double Elimination') ...[
            const SizedBox(height: HDTSpace.md),
            const _SettingsPanel(
              rows: [
                _InfoRow(
                  title: 'Bracket structure',
                  value: 'Upper + Lower',
                  subtitle:
                      'Pemain yang kalah di upper turun ke lower bracket. Eliminasi terjadi setelah kalah kedua.',
                ),
                _InfoRow(
                  title: 'Grand final',
                  value: 'Reset ON',
                  subtitle:
                      'Jika winner lower mengalahkan winner upper di grand final pertama, bracket reset match akan dimainkan.',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ArenaCard extends StatelessWidget {
  const _ArenaCard({
    required this.arena,
    required this.candidates,
    required this.onChanged,
  });
  final _ArenaDraft arena;
  final List<AssignableJudge> candidates;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineEdit(
            label: 'ARENA NAME',
            value: arena.name,
            onChanged: (value) {
              arena.name = value.toUpperCase();
              onChanged();
            },
          ),
          const SizedBox(height: HDTSpace.lg),
          Text('ASSIGNED JURI', style: HDTText.overline(size: 9)),
          const SizedBox(height: HDTSpace.sm),
          Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              for (final judge in candidates)
                FilterChip(
                  selected: arena.juri.contains(judge.uid),
                  label: Text(judge.displayName.toUpperCase()),
                  avatar: judge.role == 'demo'
                      ? const Icon(Icons.visibility_off_outlined, size: 14)
                      : const Icon(Icons.verified_user_outlined, size: 14),
                  onSelected: (selected) {
                    selected
                        ? arena.juri.add(judge.uid)
                        : arena.juri.remove(judge.uid);
                    onChanged();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannedPartsEditor extends StatelessWidget {
  const _BannedPartsEditor({
    required this.draft,
    required this.parts,
    required this.onAdd,
    required this.onRemove,
  });
  final TextEditingController draft;
  final Set<String> parts;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BANNED PARTS', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.md),
          Wrap(
            spacing: HDTSpace.sm,
            runSpacing: HDTSpace.sm,
            children: [
              for (final part in parts)
                InputChip(
                  label: Text(part),
                  onDeleted: () => onRemove(part),
                  deleteIconColor: HDTColors.danger,
                ),
            ],
          ),
          const SizedBox(height: HDTSpace.md),
          Row(
            children: [
              Expanded(child: _Field(label: 'ADD PART', controller: draft)),
              const SizedBox(width: HDTSpace.md),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyPreview extends StatelessWidget {
  const _MoneyPreview({
    required this.fee,
    required this.platformRate,
    required this.gatewayRate,
  });
  final int fee;
  final int platformRate;
  final int gatewayRate;

  @override
  Widget build(BuildContext context) {
    final platform = (fee * platformRate / 100).round();
    final gateway = (fee * gatewayRate / 100).round();
    final gross = fee + platform + gateway;
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtAccentCard(accentColor: HDTColors.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLAYER PAYS', style: HDTText.overline(size: 10)),
          const SizedBox(height: HDTSpace.xs),
          Text(_formatRp(gross),
              style: HDTText.display(size: 34, color: HDTColors.accentHover)),
          const SizedBox(height: HDTSpace.lg),
          _FeeRow('Community net', fee, strong: true),
          _FeeRow('Platform fee ($platformRate%)', platform),
          _FeeRow('Gateway est. ($gatewayRate%)', gateway),
          const SizedBox(height: HDTSpace.md),
          Container(
            padding: const EdgeInsets.all(HDTSpace.md),
            decoration: hdtCard(bg: HDTColors.bg),
            child: Text(
              'Midtrans/QRIS dipasang nanti. MVP ini menganggap payment lunas setelah konfirmasi.',
              style:
                  HDTText.body(size: 11, color: HDTColors.text2, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hdtCard(),
      child: Column(children: rows),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelRow(
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _PanelRow(
      title: title,
      subtitle: subtitle,
      trailing: Text(value, style: HDTText.mono(size: 12)),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HDTColors.s2))),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: HDTText.body(size: 14)),
              const SizedBox(height: HDTSpace.xs),
              Text(subtitle,
                  style: HDTText.body(size: 11, color: HDTColors.text3)),
            ]),
          ),
          const SizedBox(width: HDTSpace.md),
          trailing,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool active;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: HDTR.lg,
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.lg),
        decoration: hdtCard(
          bg: active ? HDTColors.accentDim : HDTColors.s1,
          borderColor: active ? HDTColors.accent : HDTColors.s2,
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: active ? HDTColors.accentHover : HDTColors.s3,
                    width: 2),
              ),
              child: active
                  ? Center(
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: HDTColors.accentHover)),
                    )
                  : null,
            ),
            const SizedBox(width: HDTSpace.md),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HDTText.body(size: 14)),
                    const SizedBox(height: HDTSpace.xs),
                    Text(subtitle,
                        style: HDTText.body(size: 11, color: HDTColors.text3)),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 760
          ? 3
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        TextField(
          controller: controller,
          maxLength: maxLength,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: HDTText.body(size: 13),
          decoration: const InputDecoration(counterText: ''),
        ),
      ],
    );
  }
}

class _InlineEdit extends StatelessWidget {
  const _InlineEdit({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: HDTText.body(size: 13),
        ),
      ],
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: HDTColors.s1,
          items: [
            for (final option in values)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: HDTColors.text2),
      const SizedBox(width: HDTSpace.xs),
      Text(text, style: HDTText.mono(size: 12, color: HDTColors.text2)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
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

class _FeeRow extends StatelessWidget {
  const _FeeRow(this.label, this.value, {this.strong = false});
  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HDTSpace.sm),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: HDTText.body(
                      size: 12,
                      color: strong ? HDTColors.text : HDTColors.text3))),
          Text(_formatRp(value), style: HDTText.mono(size: 12)),
        ],
      ),
    );
  }
}

class _MatchSeedActions extends StatelessWidget {
  const _MatchSeedActions({
    required this.tournamentId,
    required this.seededMatchCount,
    required this.busy,
    required this.onSeed,
  });

  final String tournamentId;
  final int? seededMatchCount;
  final bool busy;
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.lg),
      decoration: hdtCard(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ROUND 1 MATCH SEED', style: HDTText.overline(size: 10)),
                const SizedBox(height: HDTSpace.xs),
                Text(
                  seededMatchCount == null
                      ? 'Generate match dari registrasi paid dan assign ke juri live.'
                      : '$seededMatchCount match sudah dibuat untuk tournament $tournamentId.',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: HDTSpace.md),
          ElevatedButton.icon(
            onPressed: busy ? null : onSeed,
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_tree_outlined),
            label: Text(busy ? 'GENERATING...' : 'GENERATE MATCHES'),
          ),
        ],
      ),
    );
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
    required this.canBack,
    required this.busy,
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });

  final bool canBack;
  final bool busy;
  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback? onNext;

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
            constraints: const BoxConstraints(maxWidth: 920),
            child: Row(children: [
              TextButton.icon(
                onPressed: onBack,
                icon: Icon(canBack ? Icons.arrow_back : Icons.close),
                label: Text(backLabel),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined),
                label: const Text('SAVE DRAFT'),
              ),
              const SizedBox(width: HDTSpace.md),
              ElevatedButton.icon(
                onPressed: onNext,
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(busy ? 'PUBLISHING...' : nextLabel),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

String _seedingTip(String mode) {
  return switch (mode) {
    'ELO-based' => 'Pemain ranked tinggi dipasangkan dengan ranked rendah.',
    'Win Rate-based' => 'Pairing menggunakan win rate sebagai metrik.',
    'Manual' => 'Atur seeding manual sebelum stage 1 dimulai.',
    _ => 'Shuffle seed otomatis.',
  };
}

String _abbr(String format) {
  return switch (format) {
    'Round Robin' => 'RR',
    'Single Elimination' => 'SE',
    'Double Elimination' => 'DE',
    _ => 'SWISS',
  };
}

String _formatRp(int value) {
  return 'Rp ${value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      )}';
}
