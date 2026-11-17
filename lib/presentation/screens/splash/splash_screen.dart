// lib/presentation/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../../core/utils/logger.dart';

/// Écran de chargement / Splash Screen
/// Vérifie l'état d'authentification avant de rediriger
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // ============================================
  // VARIABLES D'ÉTAT
  // ============================================

  bool _isInitialized = false;
  String _statusMessage = 'Chargement...';

  // ============================================
  // CYCLE DE VIE
  // ============================================

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ============================================
  // INITIALISATION
  // ============================================

  /// Initialise l'application et vérifie l'authentification
  Future<void> _initializeApp() async {
    try {
      _updateStatus('Vérification de l\'authentification...');

      // Attendre que l'état d'authentification soit résolu
      await Future.delayed(const Duration(milliseconds: 500));

      // Récupérer l'état d'authentification
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final user = ref.read(currentUserProvider);

      if (!mounted) return;

      _updateStatus(
        isAuthenticated
            ? 'Bienvenue ${user?.prenom ?? ''} !'
            : 'Prêt pour la connexion...',
      );

      // Petit délai pour l'effet visuel
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Rediriger vers la page appropriée
      _navigateToAppropriateScreen();
    } catch (e) {
      Logger.error('❌ Erreur lors de l\'initialisation: $e');
      if (mounted) {
        _updateStatus('Erreur de chargement');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          // En cas d'erreur, aller vers l'écran de connexion
          context.go('/login'); // ✅ Redirection vers /login
        }
      }
    }
  }

  /// Met à jour le message de statut
  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _isInitialized = true;
      });
    }
  }

  /// Redirige vers l'écran approprié selon l'état de l'utilisateur
  void _navigateToAppropriateScreen() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final user = ref.read(currentUserProvider);

    if (!mounted) return;

    if (!isAuthenticated) {
      Logger.info('👤 Utilisateur non authentifié → /login');
      context.go('/login'); // ✅ Redirection vers l'écran de login (PIN)
      return;
    }

    // Utilisateur authentifié
    Logger.info('👤 Utilisateur authentifié: ${user?.prenom}');

    // Vérifier l'onboarding
    if (user?.onboardingVu == false) {
      Logger.info('🔄 Onboarding nécessaire → /onboarding');
      context.go('/onboarding');
      return;
    }

    // Vérifier le PIN
    final hasPin = ref.read(hasPinProvider);
    if (!hasPin) {
      Logger.info('🔐 PIN nécessaire → /pin-setup');
      context.go('/pin-setup');
      return;
    }

    // Vérifier l'accès (essai ou premium)
    final canAccess = ref.read(canAccessAppProvider);
    if (!canAccess) {
      Logger.info('🔒 Activation nécessaire → /activation');
      context.go('/activation');
      return;
    }

    // Tout est ok → Accueil
    Logger.info('🏠 Accès validé → /home');
    context.go('/home');
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ============================================
            // LOGO / ICÔNE
            // ============================================
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

            const SizedBox(height: 20),

            // ============================================
            // TITRE DE L'APPLICATION
            // ============================================
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'TAPA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.gold,
                    ),
                  ),
                  TextSpan(
                    text: ' Invest',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: TAPAColors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ============================================
            // SOUS-TITRE
            // ============================================
            const Text(
              'Le budget simple pour tous.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 48),

            // ============================================
            // STATUT DE CHARGEMENT
            // ============================================
            if (_isInitialized) ...[
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ============================================
            // INDICATEUR DE PROGRÈS
            // ============================================
            const CircularProgressIndicator(
              color: TAPAColors.gold,
              strokeWidth: 2,
            ),

            // ============================================
            // VERSION DE L'APPLICATION
            // ============================================
            const SizedBox(height: 48),
            const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
