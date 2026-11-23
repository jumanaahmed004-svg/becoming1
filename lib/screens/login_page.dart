import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth_errors.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import '../widgets/gradient_button.dart';
import '../widgets/shake.dart';
import '../widgets/transitions.dart';
import 'register_page.dart';

/// PAGE 2 — Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Set by the Registration page so the new email is already filled in.
  static String? prefillEmail;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _shake = GlobalKey<ShakeState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _email.text = LoginPage.prefillEmail ?? '';
    LoginPage.prefillEmail = null;
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      _shake.currentState?.shake();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      // On success, AuthGate (main.dart) swaps this page for the Dashboard.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      _shake.currentState?.shake();
      showAppSnack(messenger, authMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    if (!emailRegex.hasMatch(email)) {
      showAppSnack(messenger, 'Type your email above first, then tap "Forgot password?"', error: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showAppSnack(messenger, 'If $email has an account, a reset link is on its way.');
    } on FirebaseAuthException catch (e) {
      showAppSnack(messenger, authMessage(e), error: true);
    }
  }

  Future<void> _openRegister() async {
    // Registration returns the new email so we can pre-fill it here.
    final email = await Navigator.of(context).push<String>(fadeSlideRoute(const RegisterPage()));
    if (email != null && mounted) {
      _email.text = email;
      _pass.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        eyebrow: 'Welcome back',
        title: 'Continue your journey',
        subtitle: 'Log in to see your achievements and keep growing.',
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('New here?', style: TextStyle(color: AppColors.textMuted)),
            TextButton(onPressed: _openRegister, child: const Text('Create an account')),
          ],
        ),
        child: Shake(
          key: _shake,
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email';
                      if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _hide ? 'Show password' : 'Hide password',
                        icon: Icon(_hide ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
                  ),
                  const SizedBox(height: 6),
                  GradientButton(
                    label: 'Log in',
                    icon: Icons.arrow_forward_rounded,
                    loading: _loading,
                    onPressed: _login,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
