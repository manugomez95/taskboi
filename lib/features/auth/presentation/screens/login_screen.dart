import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/icons/app_icon.jpg',
                          width: 64,
                          height: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appName,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tagline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterEmail;
                        }
                        if (!value.contains('@')) {
                          return l10n.pleaseEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterPassword;
                        }
                        if (value.length < 6) {
                          return l10n.passwordMinLength;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleEmailSignIn(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _handleEmailSignIn,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.signIn),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.or,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(l10n.continueWithGoogle),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.dontHaveAccount),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(l10n.signUp),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LinkButton(
                          label: l10n.privacyPolicy,
                          url:
                              'https://taskboi.netlify.app/privacy-policy.html',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\u2022',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 8),
                        _LinkButton(
                          label: l10n.termsOfService,
                          url:
                              'https://taskboi.netlify.app/terms-of-service.html',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;

  const _LinkButton({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          // Ignore errors
        }
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
