import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth_errors.dart';
import '../theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_shell.dart';
import '../widgets/gradient_button.dart';
import '../widgets/shake.dart';
import 'login_page.dart';

/// PAGE 1 — Registration
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _shake = GlobalKey<ShakeState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  static const _strengthLabels = ['Too short', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _strengthColors = [
    AppColors.danger,
    AppColors.danger,
    AppColors.gold,
    AppColors.lilac,
    AppColors.mint,
  ];

  @override
  void initState() {
    super.initState();
    _pass.addListener(() => setState(() {})); // live strength meter
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _strength {
    final p = _pass.text;
    if (p.length < 6) return 0;
    var s = 1;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      _shake.currentState?.shake();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final email = _email.text.trim();
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _pass.text,
      );
      await cred.user!.updateDisplayName(_name.text.trim());
      LoginPage.prefillEmail = email;
      // Requirement: after registering, the user goes to the Login page.
      await FirebaseAuth.instance.signOut();
      navigator.pop(email);
      showAppSnack(messenger, 'Account created! Log in to begin your journey.');
    } on FirebaseAuthException catch (e) {
      _shake.currentState?.shake();
      showAppSnack(messenger, authMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _strengthMeter() {
    final s = _strength;
    final color = _strengthColors[s];
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: _pass.text.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: i < s ? color : Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text(
                      _strengthLabels[s],
                      textAlign: TextAlign.right,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => AuthShell(
        eyebrow: 'Start today',
        title: 'Create your account',
        subtitle: 'A private place to record every win, big or small.',
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?', style: TextStyle(color: AppColors.textMuted)),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Log in')),
          ],
        ),
        child: Shake(
          key: _shake,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your name';
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'At least 6 characters',
                    helperStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _hide ? 'Show password' : 'Hide password',
                      icon: Icon(_hide ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                _strengthMeter(),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _hide,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _pass.text) return 'Passwords do not match';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                FormField<bool>(
                  initialValue: false,
                  validator: (v) => v == true ? null : 'Please accept to continue',
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => field.didChange(!(field.value ?? false)),
                        child: Row(
                          children: [
                            Checkbox(
                              value: field.value ?? false,
                              onChanged: (v) => field.didChange(v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms of Use and Privacy Policy',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            field.errorText!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Create account',
                  icon: Icons.auto_awesome_rounded,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      );
}
