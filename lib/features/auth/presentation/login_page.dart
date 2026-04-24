import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:palavra_viva/core/constants/app_colors.dart';
import 'package:palavra_viva/shared/branding/palavra_viva_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onLogin,
    this.onForgotPassword,
    this.onCreateAccount,
    this.onGoogleSignIn,
  });

  final Future<void> Function(String email, String password)? onLogin;
  final VoidCallback? onForgotPassword;
  final Future<void> Function(String email, String password)? onCreateAccount;
  final Future<void> Function()? onGoogleSignIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (createAccount && widget.onCreateAccount != null) {
        await widget.onCreateAccount!(email, password);
      } else if (!createAccount && widget.onLogin != null) {
        await widget.onLogin!(email, password);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Não encontramos uma conta com esse e-mail. Você pode criar uma conta agora.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha não conferem. Revise os dados e tente novamente.';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado. Tente entrar com sua senha.';
        case 'weak-password':
          return 'Escolha uma senha um pouco mais forte, com pelo menos 6 caracteres.';
        case 'invalid-email':
          return 'Esse e-mail parece inválido. Confira e tente novamente.';
        case 'network-request-failed':
          return 'Não conseguimos falar com o servidor agora. Verifique sua conexão e tente de novo.';
        case 'popup-closed-by-user':
          return 'Entrada com Google cancelada.';
      }
    }

    final raw = error.toString();
    if (raw.contains('user-not-found')) {
      return 'Não encontramos uma conta com esse e-mail. Você pode criar uma conta agora.';
    }
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'E-mail ou senha não conferem. Revise os dados e tente novamente.';
    }
    if (raw.contains('network-request-failed') ||
        raw.contains('Failed host lookup')) {
      return 'Não conseguimos falar com o servidor agora. Verifique sua conexão e tente de novo.';
    }
    if (raw.contains('popup-closed-by-user') ||
        raw.contains('sign_in_canceled') ||
        raw.contains('cancelled')) {
      return 'Entrada com Google cancelada.';
    }
    return 'Algo não saiu como esperado. Tente novamente em instantes.';
  }

  @override
  Widget build(BuildContext context) {
    final loginFieldTheme = Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.74),
        ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.78),
        ),
        floatingLabelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
        prefixIconColor: Colors.white.withValues(alpha: 0.82),
        suffixIconColor: Colors.white.withValues(alpha: 0.82),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB9CAF2), width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.8),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFB3A9), width: 1.4),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFD2CB), width: 1.8),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Color(0x66FFFFFF),
        selectionHandleColor: Colors.white,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFEFD), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: PalavraVivaLogo(size: 68, showTitle: true),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Theme(
                            data: loginFieldTheme,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                    hintText: 'contato@email.com',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu e-mail.';
                                    }
                                    if (!value.contains('@')) {
                                      return 'E-mail inválido.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'A senha deve ter ao menos 6 caracteres.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: widget.onForgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                    child: const Text('Esqueci minha senha'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFA8BDF2),
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () => _submit(createAccount: false),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Entrar'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    onPressed: _isLoading ||
                                            widget.onGoogleSignIn == null
                                        ? null
                                        : () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            setState(() => _isLoading = true);
                                            try {
                                              await widget.onGoogleSignIn!();
                                            } catch (error) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _friendlyErrorMessage(
                                                      error,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _isLoading = false,
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.g_mobiledata_rounded),
                                    label: const Text('Entrar com Google'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () => _submit(createAccount: true),
                                    child: const Text('Criar conta'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.secondary),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entre com calma e constância',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Seu estudo, suas revisões e sua caminhada espiritual continuam daqui.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            const Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _FeatureChip(
                                  icon: Icons.auto_stories_outlined,
                                  label: 'Estudo guiado',
                                ),
                                _FeatureChip(
                                  icon: Icons.style_outlined,
                                  label: 'Cards bíblicos',
                                ),
                                _FeatureChip(
                                  icon: Icons.forum_outlined,
                                  label: 'Chat com o texto',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Pequenos passos, todos os dias, formam uma vida de constância.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
