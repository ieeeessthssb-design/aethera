import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/toast.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signIn = true;
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  bool _watching = false;

  @override
  void dispose() {
    if (_watching) context.auth.removeListener(_onAuth);
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_watching) {
      _watching = true;
      context.auth.addListener(_onAuth);
    }
  }

  void _onAuth() {
    // e.g. Google sign-in finished in the browser and the app was reopened via deep link.
    if (mounted && context.auth.user != null){
      Navigator.of(context).pushReplacementNamed('/radar');}
  }

  Future<void> _submit() async {
    final l = context.l;
    final c = Backend.client;
    if (c == null) {
      showToast(context, 'Backend not configured', kind: ToastKind.error);
      return;
    }
    final email = _email.text.trim();
    if (!email.contains('@') || _pw.text.length < 6) {
      showToast(context, '${l.t('email')} / ${l.t('password')} (min 6)',
          kind: ToastKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signIn) {
        await c.auth.signInWithPassword(email: email, password: _pw.text);
        if (mounted) Navigator.of(context).pushReplacementNamed('/radar');
      } else {
        await c.auth.signUp(
            email: email,
            password: _pw.text,
            emailRedirectTo: AppConfig.oauthRedirect);
        if (mounted){
          showToast(context, l.t('checkEmail'), kind: ToastKind.success);}
      }
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } catch (e) {
      if (mounted) showToast(context, '$e', kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final c = Backend.client;
    if (c == null) return;
    try {
      await c.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: AppConfig.oauthRedirect);
    } catch (e) {
      if (mounted) showToast(context, '$e', kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      backgroundColor: AppColors.muted,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Logo(), LangSwitch()]),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_signIn ? l.t('signIn') : l.t('signUp'),
                                style: display(size: 24)),
                            const SizedBox(height: 16),
                            AppButton(
                                variant: BtnVariant.outline,
                                expand: true,
                                label: l.t('google'),
                                onPressed: _google),
                            const SizedBox(height: 16),
                            FieldLabel(l.t('email'),
                                child: AppTextField(
                                    controller: _email,
                                    height: 44,
                                    keyboardType: TextInputType.emailAddress)),
                            const SizedBox(height: 12),
                            FieldLabel(l.t('password'),
                                child: AppTextField(
                                    controller: _pw,
                                    height: 44,
                                    obscure: true)),
                            const SizedBox(height: 12),
                            AppButton(
                                label: _signIn ? l.t('signIn') : l.t('signUp'),
                                expand: true,
                                loading: _busy,
                                onPressed: _busy ? null : _submit),
                            const SizedBox(height: 12),
                            Center(
                                child: TextLink(
                                    _signIn ? l.t('signUp') : l.t('signIn'),
                                    onTap: () =>
                                        setState(() => _signIn = !_signIn))),
                          ]),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
