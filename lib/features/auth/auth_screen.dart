import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _loading = false;
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _nameCtrl   = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim(), _nameCtrl.text.trim());
      } else {
        await auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAnonymously() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInAnonymously();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.pink.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 32),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 28),
                  Text(
                    _isSignUp ? 'Create account' : 'Welcome back',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'Share what you\'re listening to'
                        : 'See what your friends are playing',
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 40),

                  // Form
                  if (_isSignUp) ...[
                    _field(controller: _nameCtrl, hint: 'Display name', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                  ],
                  _field(controller: _emailCtrl, hint: 'Email', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _field(controller: _passCtrl, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: true),
                  const SizedBox(height: 6),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: _isSignUp ? 'Create Account' : 'Sign In',
                      loading: _loading,
                      onTap: _submit,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _continueAnonymously,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Continue as Guest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          children: [
                            TextSpan(text: _isSignUp ? 'Already have an account? ' : 'New here? '),
                            TextSpan(
                              text: _isSignUp ? 'Sign in' : 'Create account',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
      ),
    );
  }
}
