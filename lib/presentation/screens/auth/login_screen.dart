// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(); // ✅ CHANGÉ : email
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ✅ AJOUT : Validation d'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _error = 'Veuillez entrer un email valide.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (mounted) {
        // ✅ CHANGÉ : Envoyer l'email
        context.push('/verify-phone', extra: {
          'prenom': 'Utilisateur',
          'telephone': email, // L'email est envoyé comme "telephone" pour compatibilité
          'indicatif': '',
          'codePays': 'CI',
          'monnaie': 'FCFA',
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      Logger.error('❌ Erreur login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 20 : 32,
            vertical: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: TAPAColors.gold.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TAPAColors.gold,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: TAPAColors.gold,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'TAPA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: TAPAColors.gold,
                            ),
                          ),
                          TextSpan(
                            text: ' Invest',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: TAPAColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre coach financier intelligent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Formulaire
              Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: isSmall ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre adresse email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ CHANGÉ : Champ email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                style: const TextStyle(color: TAPAColors.white),
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Adresse Email',
                  hintText: 'Ex: kouassi@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TAPAColors.gold, width: 2),
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(color: TAPAColors.red),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),

              // Bouton connexion
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.gold,
                    foregroundColor: TAPAColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TAPAColors.navy,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lien inscription
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/inscription'),
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(
                          color: TAPAColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}