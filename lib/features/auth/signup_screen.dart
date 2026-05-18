import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/repositories/auth_repository.dart';

const _regions = [
  'Jakarta',
  'Surabaya',
  'Bandung',
  'Yogyakarta',
  'Medan',
  'Bali',
  'Makassar',
  'Lainnya',
];

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _playerId =
      'HDT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 11)}';

  int _step = 1;
  String _region = '';
  bool _agree = false;
  bool _showPassword = false;
  bool _busy = false;
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthHeader(
            title: 'DAFTAR AKUN',
            subtitle: 'Sudah punya akun?',
            actionLabel: 'Masuk',
            actionRoute: '/signin',
          ),
          const SizedBox(height: HDTSpace.lg),
          _StepIndicator(step: _step),
          const SizedBox(height: HDTSpace.lg),
          Container(
            padding: const EdgeInsets.all(HDTSpace.xl),
            decoration: hdtCard(bg: HDTColors.s1),
            child: _step == 1 ? _accountStep() : _profileStep(),
          ),
          if (_errors['api'] != null) ...[
            const SizedBox(height: HDTSpace.md),
            AuthErrorBox(_errors['api']!),
          ],
        ],
      ),
    );
  }

  Widget _accountStep() {
    return Column(
      children: [
        AuthField(
          label: 'NAMA TAMPILAN',
          controller: _name,
          hint: 'BILLY',
          error: _errors['displayName'],
        ),
        const SizedBox(height: HDTSpace.md),
        AuthField(
          label: 'EMAIL',
          controller: _email,
          hint: 'kamu@email.com',
          keyboardType: TextInputType.emailAddress,
          error: _errors['email'],
        ),
        const SizedBox(height: HDTSpace.md),
        AuthField(
          label: 'PASSWORD',
          controller: _password,
          hint: 'Min. 8 karakter',
          obscure: !_showPassword,
          error: _errors['password'],
          suffix: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
              color: HDTColors.text3,
            ),
          ),
        ),
        const SizedBox(height: HDTSpace.md),
        AuthField(
          label: 'KONFIRMASI PASSWORD',
          controller: _confirm,
          hint: 'Ulangi password',
          obscure: !_showPassword,
          error: _errors['confirm'],
        ),
        const SizedBox(height: HDTSpace.xl),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _continueToProfile,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('LANJUT'),
          ),
        ),
      ],
    );
  }

  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: HDTSpace.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: HDTColors.s2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akun untuk',
                  style: HDTText.body(size: 12, color: HDTColors.text3)),
              Text(_name.text.trim().isEmpty ? 'PLAYER' : _name.text.trim(),
                  style: HDTText.display(size: 18)),
              Text(_email.text.trim(),
                  style: HDTText.body(size: 12, color: HDTColors.text3)),
            ],
          ),
        ),
        const SizedBox(height: HDTSpace.lg),
        Text('REGION',
            style: HDTText.overline(size: 10, color: HDTColors.text3)),
        const SizedBox(height: HDTSpace.sm),
        DropdownButtonFormField<String>(
          initialValue: _region.isEmpty ? null : _region,
          decoration: InputDecoration(
            hintText: 'Pilih region...',
            errorText: _errors['region'],
          ),
          items: [
            for (final region in _regions)
              DropdownMenuItem(value: region, child: Text(region)),
          ],
          onChanged: (value) => setState(() => _region = value ?? ''),
        ),
        const SizedBox(height: HDTSpace.xs),
        Text(
          'Digunakan untuk regional leaderboard dan rekomendasi komunitas.',
          style: HDTText.body(size: 11, color: HDTColors.text3),
        ),
        const SizedBox(height: HDTSpace.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(HDTSpace.md),
          decoration: hdtCard(bg: HDTColors.bg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAYER ID (AUTO-ASSIGN)',
                  style: HDTText.overline(size: 10)),
              const SizedBox(height: HDTSpace.xs),
              Text(_playerId,
                  style: HDTText.mono(size: 14, color: HDTColors.accentHover)),
              const SizedBox(height: HDTSpace.xs),
              Text('ID unik untuk bracket dan leaderboard.',
                  style: HDTText.body(size: 11, color: HDTColors.text3)),
            ],
          ),
        ),
        const SizedBox(height: HDTSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agree,
              onChanged: (value) => setState(() => _agree = value ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Saya setuju dengan Terms of Service dan Privacy Policy HIDEOUT.',
                  style: HDTText.body(size: 12, color: HDTColors.text2),
                ),
              ),
            ),
          ],
        ),
        if (_errors['terms'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(_errors['terms']!,
                style: HDTText.body(size: 11, color: HDTColors.danger)),
          ),
        const SizedBox(height: HDTSpace.lg),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => setState(() => _step = 1),
                  child: const Text('KEMBALI'),
                ),
              ),
            ),
            const SizedBox(width: HDTSpace.md),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_busy ? 'MEMBUAT...' : 'DAFTAR'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _continueToProfile() {
    final next = <String, String>{};
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty) {
      next['displayName'] = 'Nama tampilan wajib diisi.';
    } else if (name.length < 3) {
      next['displayName'] = 'Minimal 3 karakter.';
    }
    if (email.isEmpty) {
      next['email'] = 'Email wajib diisi.';
    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      next['email'] = 'Format email tidak valid.';
    }
    if (_password.text.isEmpty) {
      next['password'] = 'Password wajib diisi.';
    } else if (_password.text.length < 8) {
      next['password'] = 'Minimal 8 karakter.';
    }
    if (_password.text != _confirm.text) {
      next['confirm'] = 'Password tidak cocok.';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(next);
      if (next.isEmpty) _step = 2;
    });
  }

  Future<void> _submit() async {
    final next = <String, String>{};
    if (_region.isEmpty) next['region'] = 'Pilih region kamu.';
    if (!_agree) next['terms'] = 'Kamu harus menyetujui syarat & ketentuan.';
    setState(() {
      _errors
        ..clear()
        ..addAll(next);
    });
    if (next.isNotEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            region: _region,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errors['api'] =
            'Pendaftaran belum berhasil. Periksa data akun lalu coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HDTColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AuthBgPainter())),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(HDTSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final String actionRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (_) => false,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: HDTColors.accent, borderRadius: HDTR.md),
                child: const Icon(Icons.sports_martial_arts,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: HDTSpace.sm),
              Text('HIDEOUT', style: HDTText.display(size: 28)),
            ],
          ),
        ),
        const SizedBox(height: HDTSpace.xl),
        Text(title, style: HDTText.display(size: 24)),
        const SizedBox(height: HDTSpace.xs),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text('$subtitle ',
                style: HDTText.body(size: 13, color: HDTColors.text3)),
            InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, actionRoute),
              child: Text(actionLabel,
                  style: HDTText.body(size: 13, color: HDTColors.accentHover)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(active: step == 1, done: step > 1, label: 'AKUN', index: 1),
        Expanded(
          child: Container(
            height: 1,
            color: step > 1 ? HDTColors.accentDim : HDTColors.s2,
          ),
        ),
        _StepDot(active: step == 2, done: false, label: 'PROFIL', index: 2),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.active,
    required this.done,
    required this.label,
    required this.index,
  });

  final bool active;
  final bool done;
  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: active
                ? HDTColors.accent
                : done
                    ? HDTColors.accentDim
                    : HDTColors.s2,
            shape: BoxShape.circle,
            border: done ? Border.all(color: HDTColors.accent) : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check,
                    size: 13, color: HDTColors.accentHover)
                : Text('$index',
                    style: HDTText.mono(
                        size: 11,
                        color: active ? Colors.white : HDTColors.text3)),
          ),
        ),
        const SizedBox(width: HDTSpace.sm),
        Text(label,
            style: HDTText.overline(
                size: 9, color: active ? HDTColors.text : HDTColors.text3)),
        const SizedBox(width: HDTSpace.sm),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.error,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HDTText.overline(size: 10, color: HDTColors.text3)),
        const SizedBox(height: HDTSpace.sm),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: HDTText.body(size: 14),
            decoration: InputDecoration(
              hintText: hint,
              errorText: null,
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: HDTSpace.md),
              enabledBorder: OutlineInputBorder(
                borderRadius: HDTR.md,
                borderSide: BorderSide(
                    color: error == null ? HDTColors.s2 : HDTColors.danger),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: HDTR.md,
                borderSide: BorderSide(color: HDTColors.accent),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: HDTSpace.xs),
          Text(error!, style: HDTText.body(size: 11, color: HDTColors.danger)),
        ],
      ],
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: BoxDecoration(
        color: HDTColors.danger.withValues(alpha: 0.1),
        borderRadius: HDTR.md,
        border: Border.all(color: HDTColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: HDTColors.danger),
          const SizedBox(width: HDTSpace.sm),
          Expanded(
              child: Text(message,
                  style: HDTText.body(size: 12, color: HDTColors.danger))),
        ],
      ),
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -1.15),
        radius: 0.9,
        colors: [
          HDTColors.accent.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
