import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/hideout_tokens.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import 'signup_screen.dart';

// Demo accounts make local evaluation fast. They only appear when the build
// enables them: --dart-define=SHOW_DEMO_LOGIN=true (see README).
const showDemoLogin =
    bool.fromEnvironment('SHOW_DEMO_LOGIN', defaultValue: false);
const _demoPassword = 'HideoutDemo123!';
const _demoAccounts = <_DemoAccount>[
  _DemoAccount(
    role: 'PLAYER',
    email: 'hideout.player@example.com',
    icon: Icons.person_outline,
    color: HDTColors.accentHover,
  ),
  _DemoAccount(
    role: 'JUDGE',
    email: 'hideout.judge@example.com',
    icon: Icons.shield_outlined,
    color: HDTColors.info,
  ),
  _DemoAccount(
    role: 'COMMUNITY LEAD',
    email: 'hideout.community@example.com',
    icon: Icons.groups_outlined,
    color: HDTColors.success,
  ),
  _DemoAccount(
    role: 'SUPER ADMIN',
    email: 'hideout.super@example.com',
    icon: Icons.admin_panel_settings_outlined,
    color: HDTColors.warning,
  ),
];

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
            title: 'ENTER THE ARENA',
            subtitle: 'No account yet?',
            actionLabel: 'Register now',
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
                  hint: 'you@email.com',
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
                    label: Text(_busy ? 'AUTHENTICATING...' : 'SIGN IN'),
                  ),
                ),
                const SizedBox(height: HDTSpace.lg),
                if (showDemoLogin)
                  _DemoLoginPanel(
                    busy: _busy,
                    onSelect: _loginDemo,
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
                child: Text('OR', style: HDTText.overline(size: 10)),
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
              child: const Text('CREATE NEW ACCOUNT'),
            ),
          ),
          const SizedBox(height: HDTSpace.lg),
          Text(
            'By signing in, you agree to the HIDEOUT Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: HDTText.body(size: 11, color: HDTColors.text3),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email and password are required.');
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
        _error = 'Sign-in failed. Check your email and password.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginDemo(_DemoAccount account) async {
    if (_busy) return;
    _email.text = account.email;
    _password.text = _demoPassword;
    await _submit();
  }
}

class _DemoLoginPanel extends StatelessWidget {
  const _DemoLoginPanel({
    required this.busy,
    required this.onSelect,
  });

  final bool busy;
  final ValueChanged<_DemoAccount> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HDTSpace.md),
      decoration: hdtCard(bg: HDTColors.bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.key_outlined,
                size: 16,
                color: HDTColors.accentHover,
              ),
              const SizedBox(width: HDTSpace.sm),
              Text('DEMO LOGIN', style: HDTText.overline(size: 10)),
            ],
          ),
          const SizedBox(height: HDTSpace.xs),
          Text(
            'Choose a role to sign in with a demo account.',
            style: HDTText.body(size: 11, color: HDTColors.text3),
          ),
          const SizedBox(height: HDTSpace.md),
          for (final account in _demoAccounts) ...[
            _DemoAccountButton(
              account: account,
              busy: busy,
              onSelect: onSelect,
            ),
            if (account != _demoAccounts.last)
              const SizedBox(height: HDTSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _DemoAccountButton extends StatelessWidget {
  const _DemoAccountButton({
    required this.account,
    required this.busy,
    required this.onSelect,
  });

  final _DemoAccount account;
  final bool busy;
  final ValueChanged<_DemoAccount> onSelect;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : () => onSelect(account),
          borderRadius: HDTR.md,
          child: Ink(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: HDTSpace.md,
              vertical: HDTSpace.sm,
            ),
            decoration: BoxDecoration(
              color: account.color.withValues(alpha: 0.08),
              borderRadius: HDTR.md,
              border: Border.all(color: account.color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: account.color.withValues(alpha: 0.16),
                    borderRadius: HDTR.md,
                  ),
                  child: Icon(account.icon, size: 16, color: account.color),
                ),
                const SizedBox(width: HDTSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HDTText.overline(
                          size: 10,
                          color: HDTColors.text,
                        ),
                      ),
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HDTText.mono(size: 10, color: HDTColors.text2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: HDTSpace.sm),
                Icon(
                  Icons.login_outlined,
                  size: 16,
                  color: busy ? HDTColors.text3 : account.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.role,
    required this.email,
    required this.icon,
    required this.color,
  });

  final String role;
  final String email;
  final IconData icon;
  final Color color;
}

String _homeRouteFor(AppUser? user) {
  final capabilities = user?.capabilities ?? const <String>{};
  if (capabilities.contains('super_admin')) return '/super-admin/reports';
  return '/dashboard';
}
