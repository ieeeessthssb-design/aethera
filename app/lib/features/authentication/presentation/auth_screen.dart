
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../expert/presentation/expert_home_screen.dart';
import '../../expert/presentation/expert_access_screen.dart';
import '../../admin/presentation/admin_home_screen.dart';
import '../data/auth_api_service.dart';
import '../data/auth_providers.dart';
import '../../farmer/presentation/farmer_app_shell.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthApiService get _authApi => ref.read(authApiServiceProvider);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  String _selectedRole = 'farmer';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _awaitingEmailVerification = false;

  static const forestGreen = Color(0xFF205C40);
  static const lightMint = Color(0xFFEAF4EC);
  static const inputTextColor = Color(0xFF26352B);

  bool get isSignUp => _mode == AuthMode.signUp;

  String get language {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'fr' || code == 'ar') return code;
    return 'en';
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String? idToken;

      if (kIsWeb) {
        final result = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );

        idToken = await result.user?.getIdToken();
      } else {
        await GoogleSignIn.instance.initialize();

        final googleUser =
            await GoogleSignIn.instance.authenticate();

        final googleAuth = googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final result =
            await FirebaseAuth.instance.signInWithCredential(credential);

        idToken = await result.user?.getIdToken();
      }

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an authentication token.');
      }

      final response = await _authApi.signInWithGoogle(
        idToken: idToken,
      );

      await _openDashboard(response);
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Google authentication failed.');
    } on DioException catch (error) {
      final data = error.response?.data;

      _showMessage(
        data is Map
            ? data['detail']?.toString() ?? 'Google sign-in failed.'
            : 'Google sign-in failed.',
      );
    } catch (error) {
      _showMessage(AppLocalizations.of(context)!.authGoogleError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = isSignUp ? AuthMode.signIn : AuthMode.signUp;
      _awaitingEmailVerification = false;
      _acceptedTerms = false;
      _selectedRole = 'farmer';
      _codeController.clear();
    });
  }

  Future<void> _openDashboard(Map<String, dynamic> response) async {
    final userData = response['user'];

    if (userData is! Map) {
      throw const FormatException('Invalid user information.');
    }

    final user = Map<String, dynamic>.from(userData);
    final role = user['role']?.toString();
    final approval =
        user['expert_approval_status']?.toString() ?? 'pending';

    late final Widget destination;

    switch (role) {
      case 'farmer':
        destination = const FarmerAppShell();
        break;
      case 'expert':
        destination = approval == 'approved'
            ? const ExpertHomeScreen()
            : ExpertAccessScreen(status: approval);
        break;
      case 'admin':
        destination = const AdminHomeScreen();
        break;
      default:
        throw const FormatException('Unknown account role.');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (isSignUp &&
        !_awaitingEmailVerification &&
        !_acceptedTerms) {
      _showMessage(AppLocalizations.of(context)!.authAcceptTerms);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_awaitingEmailVerification) {
        await _authApi.verifyEmail(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _awaitingEmailVerification = false;
          _mode = AuthMode.signIn;
          _passwordController.clear();
          _codeController.clear();
        });

        _showMessage(AppLocalizations.of(context)!.authEmailVerified);
        return;
      }

      if (isSignUp) {
        await _authApi.signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          preferredLanguage: language,
          role: _selectedRole,
        );

        if (!mounted) return;

        setState(() => _awaitingEmailVerification = true);
        _showMessage(AppLocalizations.of(context)!.authCodeSent);
      } else {
        final response = await _authApi.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await _openDashboard(response);
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      final message =
          data is Map ? data['detail']?.toString() : null;

      _showMessage(
        message ?? 'Unable to connect. Please try again.',
      );
    } catch (error) {
      _showMessage(
        error is FormatException
            ? error.message
            : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/farm_hero.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: forestGreen.withValues(alpha: 0.78),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFFB6DC70),
                        size: 55,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'AETHERA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightMint,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _awaitingEmailVerification
                  ? 'Verify your email'
                  : isSignUp
                      ? 'Create your account'
                      : 'Welcome back',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: forestGreen,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _awaitingEmailVerification
                  ? 'Enter the six-digit code sent to your email.'
                  : 'Your smart agriculture platform.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF65736A),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),

            if (_awaitingEmailVerification) ...[
              _field(
                controller: _codeController,
                label: 'Verification code',
                icon: Icons.verified_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                    return 'Enter the six-digit code.';
                  }
                  return null;
                },
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);

                        try {
                          await _authApi.resendVerification(
                            email: _emailController.text.trim(),
                          );

                          _showMessage(AppLocalizations.of(context)!.authNewCodeSent);
                        } on DioException catch (error) {
                          final data = error.response?.data;

                          _showMessage(
                            data is Map
                                ? data['detail']?.toString() ??
                                    'Unable to resend the code.'
                                : 'Unable to resend the code.',
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                child: const Text(
                  'Resend verification code',
                  style: TextStyle(color: forestGreen),
                ),
              ),
            ] else ...[
              if (isSignUp) ...[
                _field(
                  controller: _nameController,
                  label: 'Full name',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter your full name.'
                          : null,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Account type',
                  style: TextStyle(
                    color: forestGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
DropdownButtonFormField<String>(
  initialValue: _selectedRole,
  dropdownColor: Colors.white,
  borderRadius: BorderRadius.circular(13),
  menuMaxHeight: 200,
  style: const TextStyle(
    color: inputTextColor,
    fontSize: 16,
  ),
  decoration: _inputDecoration(
    label: 'Choose account type',
    icon: Icons.badge_outlined,
  ),
  items: const [
    DropdownMenuItem(
      value: 'farmer',
      child: Text(
        'Farmer',
        style: TextStyle(color: inputTextColor),
      ),
    ),
    DropdownMenuItem(
      value: 'expert',
      child: Text(
        'Expert',
        style: TextStyle(color: inputTextColor),
      ),
    ),
  ],
  onChanged: (value) {
    if (value != null) {
      setState(() => _selectedRole = value);
    }
  },
),
                const SizedBox(height: 15),
              ],
              _field(
                controller: _emailController,
                label: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                          .hasMatch(value.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _field(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: forestGreen,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password.';
                  }
                  if (isSignUp && value.length < 12) {
                    return 'Use at least 12 characters.';
                  }
                  return null;
                },
              ),
              if (isSignUp)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptedTerms,
                  activeColor: forestGreen,
                  title: const Text(
                    'I agree to the terms and privacy policy.',
                    style: TextStyle(
                      fontSize: 12,
                      color: inputTextColor,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: forestGreen,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _awaitingEmailVerification
                            ? 'VERIFY EMAIL'
                            : isSignUp
                                ? 'CREATE ACCOUNT'
                                : 'SIGN IN',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),

            if (!isSignUp && !_awaitingEmailVerification) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(
                  Icons.g_mobiledata,
                  size: 30,
                  color: Colors.black,
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: inputTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFFD5E0D7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 15),

            TextButton(
              onPressed: _isLoading || _awaitingEmailVerification
                  ? null
                  : _switchMode,
              child: Text(
                isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New to AETHERA? Create an account',
                style: const TextStyle(
                  color: forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF65736A),
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: forestGreen,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: forestGreen),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFD5E0D7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFD5E0D7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: forestGreen,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: forestGreen,
      style: const TextStyle(
        color: inputTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        suffix: suffix,
      ),
    );
  }
}
