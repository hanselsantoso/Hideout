import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import 'signup_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthHeader(
            title: 'MASUK KE ARENA',
            subtitle: 'Belum punya akun?',
            actionLabel: 'Daftar sekarang',
            actionRoute: '/signup',
          ),
          const SizedBox(height: HDTSpace.xl),
          Container(
            padding: const EdgeInsets.all(HDTSpace.xl),
            decoration: hdtCard(bg: HDTColors.s1),
            child: Column(
              children: [
                if (_error != null) ...[
                  AuthErrorBox(_error!),
                  const SizedBox(height: HDTSpace.md),
                ],
                AuthField(
                  label: 'EMAIL',
                  controller: _email,
                  hint: 'kamu@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: HDTSpace.md),
                AuthField(
                  label: 'PASSWORD',
                  controller: _password,
                  hint: '********',
                  obscure: !_showPassword,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: HDTColors.text3,
                    ),
                  ),
                ),
                const SizedBox(height: HDTSpace.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_busy ? 'AUTHENTICATING...' : 'MASUK'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HDTSpace.lg),
          Row(
            children: [
              Expanded(child: hdtDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HDTSpace.md),
                child: Text('ATAU', style: HDTText.overline(size: 10)),
              ),
              Expanded(child: hdtDivider()),
            ],
          ),
          const SizedBox(height: HDTSpace.lg),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/signup'),
              child: const Text('BUAT AKUN BARU'),
            ),
          ),
          const SizedBox(height: HDTSpace.lg),
          Text(
            'Dengan masuk, kamu setuju dengan Terms of Service dan Privacy Policy HIDEOUT.',
            textAlign: TextAlign.center,
            style: HDTText.body(size: 11, color: HDTColors.text3),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      final uid = credential.user?.uid;
      final profile = uid == null
          ? null
          : await ref.read(authRepositoryProvider).getUser(uid);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, _homeRouteFor(profile));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Login belum berhasil. Periksa email dan password kamu.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

String _homeRouteFor(AppUser? user) {
  final capabilities = user?.capabilities ?? const <String>{};
  if (capabilities.contains('super_admin')) return '/super-admin/reports';
  return '/dashboard';
}
