import 'package:flutter/material.dart';

import '../../core/theme/hideout_tokens.dart';

enum _StepId { welcome, role, identity, gear, interests, complete }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;
  final _name = TextEditingController();
  final Set<String> _roles = {'PLAYER'};
  final Set<String> _interests = {};
  String _gear = '';
  Color _color = HDTColors.accent;
  bool _notifications = true;

  static const _steps = [
    _StepId.welcome,
    _StepId.role,
    _StepId.identity,
    _StepId.gear,
    _StepId.interests,
    _StepId.complete,
  ];

  _StepId get _step => _steps[_index];
  double get _progress => (_index + 1) / _steps.length;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: HDTColors.accent, borderRadius: HDTR.sm),
              child: const Icon(Icons.sports_martial_arts,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: HDTSpace.sm),
            Text('HIDEOUT', style: HDTText.display(size: 22)),
          ],
        ),
        actions: [
          Center(
            child: Text('STEP ${_index + 1} / ${_steps.length}',
                style: HDTText.mono(size: 11, color: HDTColors.text3)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/dashboard'),
            child: const Text('SKIP'),
          ),
          const SizedBox(width: HDTSpace.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 2,
            backgroundColor: HDTColors.s1,
            valueColor: const AlwaysStoppedAnimation(HDTColors.accent),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth > 720 ? 720 : constraints.maxWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    HDTSpace.xl, HDTSpace.xxxl, HDTSpace.xl, 120),
                children: [_buildStep()],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _step == _StepId.complete
          ? null
          : _BottomNav(
              onBack: _back,
              onNext: _canNext ? _next : null,
              label: _nextLabel),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _StepId.welcome => _welcomeStep(),
      _StepId.role => _roleStep(),
      _StepId.identity => _identityStep(),
      _StepId.gear => _gearStep(),
      _StepId.interests => _interestsStep(),
      _StepId.complete => _completeStep(),
    };
  }

  Widget _welcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                LinearGradient(colors: [HDTColors.accent, Color(0xFF6E2A78)]),
          ),
          child: const Icon(Icons.sports_martial_arts,
              color: Colors.white, size: 44),
        ),
        const SizedBox(height: HDTSpace.xl),
        Text('WELCOME',
            style: HDTText.overline(size: 11, color: HDTColors.accentHover)),
        const SizedBox(height: HDTSpace.sm),
        Text('READY TO ENTER\nTHE ARENA?',
            textAlign: TextAlign.center,
            style: HDTText.display(size: 44).copyWith(height: 1.1)),
        const SizedBox(height: HDTSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            'HIDEOUT is the home for Indonesia\'s Beyblade X community: ranked tournaments, national leaderboards, and local communities across the country. Let\'s set up your profile in 60 seconds.',
            textAlign: TextAlign.center,
            style: HDTText.body(color: HDTColors.text2, height: 1.6),
          ),
        ),
        const SizedBox(height: HDTSpace.xl),
        const Wrap(
          spacing: HDTSpace.md,
          runSpacing: HDTSpace.md,
          alignment: WrapAlignment.center,
          children: [
            _WelcomeStat(
                icon: Icons.emoji_events_outlined,
                label: '24 active tournaments'),
            _WelcomeStat(icon: Icons.groups_outlined, label: '12K+ blader'),
            _WelcomeStat(
                icon: Icons.location_on_outlined, label: 'Region from signup'),
          ],
        ),
      ],
    );
  }

  Widget _roleStep() {
    return _StepShell(
      title: 'CHOOSE YOUR ROLE',
      subtitle:
          'You can choose more than one. Judge and community lead requests still wait for approval.',
      child: Column(
        children: [
          _RoleCard(
            id: 'PLAYER',
            title: 'PLAYER',
            desc:
                'Register for tournaments, build decks, climb the leaderboard.',
            icon: Icons.person_outline,
            color: HDTColors.accent,
            active: _roles.contains('PLAYER'),
            onTap: () => _toggleRole('PLAYER'),
          ),
          _RoleCard(
            id: 'JUDGE',
            title: 'JUDGE',
            desc: 'Verify arena matches and handle certified scoring.',
            icon: Icons.verified_user_outlined,
            color: HDTColors.info,
            active: _roles.contains('JUDGE'),
            onTap: () => _toggleRole('JUDGE'),
          ),
          _RoleCard(
            id: 'LEAD',
            title: 'COMMUNITY LEAD',
            desc: 'Manage community rosters and host local events.',
            icon: Icons.workspace_premium_outlined,
            color: HDTColors.warning,
            active: _roles.contains('LEAD'),
            onTap: () => _toggleRole('LEAD'),
          ),
          if (_roles.isNotEmpty) ...[
            const SizedBox(height: HDTSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: HDTSpace.sm,
                runSpacing: HDTSpace.sm,
                children: [
                  Text('SELECTED:', style: HDTText.overline(size: 9)),
                  for (final role in _roles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: HDTSpace.sm, vertical: HDTSpace.xs),
                      decoration: BoxDecoration(
                        color: HDTColors.accentDim,
                        borderRadius: HDTR.sm,
                        border: Border.all(color: HDTColors.accent),
                      ),
                      child: Text(role, style: HDTText.overline(size: 9)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _identityStep() {
    return _StepShell(
      title: 'IDENTITY',
      subtitle: 'The name shown on leaderboards and your public profile.',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: _color, borderRadius: HDTR.md),
                child: Center(
                  child: Text(
                      (_name.text.isEmpty ? '?' : _name.text[0]).toUpperCase(),
                      style: HDTText.display(size: 32, color: Colors.white)),
                ),
              ),
              const SizedBox(width: HDTSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DISPLAY NAME', style: HDTText.overline(size: 10)),
                    const SizedBox(height: HDTSpace.sm),
                    TextField(
                      controller: _name,
                      maxLength: 16,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.characters,
                      style: HDTText.display(size: 18),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: 'HARRIS',
                      ),
                    ),
                    const SizedBox(height: HDTSpace.xs),
                    Text('3-16 characters, uppercase letters',
                        style: HDTText.body(size: 11, color: HDTColors.text3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: HDTSpace.xl),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('PERSONAL COLOR', style: HDTText.overline(size: 10))),
          const SizedBox(height: HDTSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: HDTSpace.sm,
              runSpacing: HDTSpace.sm,
              children: [
                for (final color in const [
                  HDTColors.accent,
                  HDTColors.info,
                  HDTColors.warning,
                  HDTColors.success,
                  HDTColors.danger,
                  Color(0xFFF4D03F),
                  Color(0xFF16A085),
                  Color(0xFF8E44AD),
                ])
                  InkWell(
                    borderRadius: HDTR.full,
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color == _color
                                ? Colors.white
                                : Colors.transparent,
                            width: 2),
                      ),
                      child: color == _color
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: HDTSpace.xl),
          Container(
            padding: const EdgeInsets.all(HDTSpace.md),
            decoration: hdtCard(bg: HDTColors.bg),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined,
                    size: 14, color: HDTColors.accentHover),
                const SizedBox(width: HDTSpace.sm),
                Expanded(
                  child: Text(
                    'Your HDT-ID was created during signup and will be used for brackets, QR, and leaderboards.',
                    style: HDTText.body(size: 11, color: HDTColors.text3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gearStep() {
    return _StepShell(
      title: 'GEAR PREFERENCE',
      subtitle:
          'Choose the playstyle that fits you best. This is used for starter deck recommendations.',
      child: Column(
        children: [
          _GearCard(
            id: 'ATTACK',
            title: 'ATTACK',
            desc: 'Smash & burst, high risk high reward.',
            icon: Icons.flash_on_outlined,
            color: HDTColors.warning,
            active: _gear == 'ATTACK',
            onTap: () => setState(() => _gear = 'ATTACK'),
          ),
          _GearCard(
            id: 'DEFENSE',
            title: 'DEFENSE',
            desc: 'Endure & counter, outlast the opponent.',
            icon: Icons.shield_outlined,
            color: HDTColors.info,
            active: _gear == 'DEFENSE',
            onTap: () => setState(() => _gear = 'DEFENSE'),
          ),
          _GearCard(
            id: 'STAMINA',
            title: 'STAMINA',
            desc: 'Spin economy, last bey standing wins.',
            icon: Icons.all_inclusive,
            color: HDTColors.success,
            active: _gear == 'STAMINA',
            onTap: () => setState(() => _gear = 'STAMINA'),
          ),
        ],
      ),
    );
  }

  Widget _interestsStep() {
    final interests = [
      const _Interest('tournaments', 'Tournaments', Icons.emoji_events_outlined),
      const _Interest('casual', 'Casual play', Icons.auto_awesome_outlined),
      const _Interest('community', 'Local communities', Icons.groups_outlined),
      const _Interest('meta', 'Meta & strategy', Icons.track_changes_outlined),
      const _Interest('collection', 'Parts collecting', Icons.card_giftcard_outlined),
      const _Interest('streaming', 'Watch streams', Icons.photo_camera_outlined),
    ];
    return _StepShell(
      title: 'WHAT BRINGS YOU HERE?',
      subtitle: 'Choose every relevant option. Minimum one.',
      child: Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 560 ? 2 : 1;
            final width =
                (constraints.maxWidth - (cols - 1) * HDTSpace.md) / cols;
            return Wrap(
              spacing: HDTSpace.md,
              runSpacing: HDTSpace.md,
              children: [
                for (final item in interests)
                  SizedBox(
                    width: width,
                    child: _InterestCard(
                      item: item,
                      active: _interests.contains(item.id),
                      onTap: () => setState(() {
                        _interests.contains(item.id)
                            ? _interests.remove(item.id)
                            : _interests.add(item.id);
                      }),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: HDTSpace.xl),
          Container(
            padding: const EdgeInsets.all(HDTSpace.md),
            decoration: hdtCard(),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined,
                    size: 18,
                    color: _notifications
                        ? HDTColors.accentHover
                        : HDTColors.text3),
                const SizedBox(width: HDTSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Push notifications', style: HDTText.body(size: 13)),
                      Text(
                          'Match assignments, verification results, schedule changes',
                          style:
                              HDTText.body(size: 11, color: HDTColors.text3)),
                    ],
                  ),
                ),
                Switch(
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeStep() {
    final name =
        _name.text.trim().isEmpty ? 'BLADER' : _name.text.trim().toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: HDTColors.success),
          child: const Icon(Icons.check, color: Colors.black, size: 44),
        ),
        const SizedBox(height: HDTSpace.xl),
        Text('SETUP COMPLETE',
            style: HDTText.overline(size: 11, color: HDTColors.success)),
        const SizedBox(height: HDTSpace.sm),
        Text('WELCOME, $name',
            textAlign: TextAlign.center, style: HDTText.display(size: 36)),
        const SizedBox(height: HDTSpace.sm),
        Text(
          'Your profile is ready. You receive a 100 ELO starter rating and can start registering for tournaments.',
          textAlign: TextAlign.center,
          style: HDTText.body(color: HDTColors.text2),
        ),
        const SizedBox(height: HDTSpace.xl),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.all(HDTSpace.lg),
          decoration: hdtCard(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration:
                        BoxDecoration(color: _color, borderRadius: HDTR.md),
                    child: Center(
                        child: Text(name[0],
                            style: HDTText.display(
                                size: 28, color: Colors.white))),
                  ),
                  const SizedBox(width: HDTSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: HDTText.display(size: 20)),
                        Text('HDT-ID active from signup',
                            style:
                                HDTText.mono(size: 11, color: HDTColors.text3)),
                        Wrap(
                          spacing: HDTSpace.xs,
                          runSpacing: HDTSpace.xs,
                          children: [
                            for (final role in _roles)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: HDTSpace.sm,
                                    vertical: HDTSpace.xs),
                                decoration: BoxDecoration(
                                  color: HDTColors.accentDim,
                                  borderRadius: HDTR.sm,
                                  border: Border.all(color: HDTColors.accent),
                                ),
                                child: Text(role,
                                    style: HDTText.overline(size: 8)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HDTSpace.lg),
              hdtDivider(),
              const SizedBox(height: HDTSpace.md),
              Row(
                children: [
                  const Expanded(child: _Mini(label: 'ELO', value: '100')),
                  Expanded(
                      child: _Mini(
                          label: 'GEAR', value: _gear.isEmpty ? '-' : _gear)),
                  const Expanded(child: _Mini(label: 'ELO STARTER', value: '+0')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: HDTSpace.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('GO TO DASHBOARD'),
                ),
              ),
              const SizedBox(height: HDTSpace.sm),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: const Text('BUILD MY FIRST DECK'),
                ),
              ),
              const SizedBox(height: HDTSpace.sm),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, '/communities/new'),
                  child: const Text('BROWSE COMMUNITIES'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _canNext {
    return switch (_step) {
      _StepId.welcome => true,
      _StepId.role => _roles.isNotEmpty,
      _StepId.identity => _name.text.trim().length >= 2,
      _StepId.gear => _gear.isNotEmpty,
      _StepId.interests => _interests.isNotEmpty,
      _StepId.complete => true,
    };
  }

  String get _nextLabel {
    return switch (_step) {
      _StepId.welcome => 'GET STARTED',
      _StepId.interests => 'FINISH SETUP',
      _ => 'CONTINUE',
    };
  }

  void _next() {
    if (_index < _steps.length - 1) setState(() => _index++);
  }

  void _back() {
    if (_index == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _index--);
    }
  }

  void _toggleRole(String role) {
    setState(() {
      _roles.contains(role) ? _roles.remove(role) : _roles.add(role);
    });
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell(
      {required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: HDTText.display(size: 28)),
        const SizedBox(height: HDTSpace.xs),
        Text(subtitle, style: HDTText.body(color: HDTColors.text3)),
        const SizedBox(height: HDTSpace.xl),
        child,
      ],
    );
  }
}

class _WelcomeStat extends StatelessWidget {
  const _WelcomeStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(),
      child: Column(
        children: [
          Icon(icon, size: 18, color: HDTColors.accentHover),
          const SizedBox(height: HDTSpace.sm),
          Text(label,
              textAlign: TextAlign.center,
              style: HDTText.body(size: 11, color: HDTColors.text2)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HDTSpace.md),
      child: InkWell(
        borderRadius: HDTR.lg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(HDTSpace.lg),
          decoration: hdtCard(
            bg: active ? color.withValues(alpha: 0.08) : HDTColors.s1,
            borderColor: active ? color : HDTColors.s2,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active ? color : HDTColors.bg,
                  borderRadius: HDTR.md,
                  border: Border.all(color: active ? color : HDTColors.s2),
                ),
                child: Icon(icon, color: active ? Colors.white : color),
              ),
              const SizedBox(width: HDTSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: HDTText.display(
                            size: 16, color: active ? color : HDTColors.text)),
                    Text(desc,
                        style: HDTText.body(size: 12, color: HDTColors.text3)),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: active ? color : Colors.transparent,
                  borderRadius: HDTR.sm,
                  border: Border.all(
                      color: active ? color : HDTColors.s2, width: 2),
                ),
                child: active
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GearCard extends StatelessWidget {
  const _GearCard({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoleCard(
      id: id,
      title: title,
      desc: desc,
      icon: icon,
      color: color,
      active: active,
      onTap: onTap,
    );
  }
}

class _Interest {
  const _Interest(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _InterestCard extends StatelessWidget {
  const _InterestCard(
      {required this.item, required this.active, required this.onTap});
  final _Interest item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: HDTR.lg,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(HDTSpace.md),
        decoration: hdtCard(
          bg: active
              ? HDTColors.accentDim.withValues(alpha: 0.35)
              : HDTColors.s1,
          borderColor: active ? HDTColors.accent : HDTColors.s2,
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 17,
                color: active ? HDTColors.accentHover : HDTColors.text3),
            const SizedBox(width: HDTSpace.md),
            Expanded(
                child: Text(item.label,
                    style: HDTText.body(
                        size: 13,
                        color:
                            active ? HDTColors.accentHover : HDTColors.text))),
            if (active)
              const Icon(Icons.check, size: 13, color: HDTColors.accentHover),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav(
      {required this.onBack, required this.onNext, required this.label});
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String label;

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
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('BACK'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 9)),
        const SizedBox(height: HDTSpace.xs),
        Text(value, style: HDTText.mono(size: 13)),
      ],
    );
  }
}
