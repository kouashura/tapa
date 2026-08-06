// lib/presentation/routes/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/db_service_mysql.dart';
import '../../core/utils/logger.dart';

// ============================================
// IMPORTS DES ÉCRANS
// ============================================
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/inscription_screen.dart';
import '../../screens/auth/pin_screen.dart';
import '../../screens/auth/verify_phone_screen.dart';
import '../../screens/auth/activation_screen.dart';
import '../../screens/auth/setup_wallets_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/wallets/wallets_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/categories_screen.dart';
import '../../screens/profile/change_pin_screen.dart';
import '../../screens/profile/abonnement_screen.dart';
import '../../screens/transactions/add_transaction_screen.dart';
import '../../screens/transactions/history_screen.dart';
import '../../screens/transactions/voice_transaction_screen.dart';
import '../../screens/transactions/scanner_screen.dart';
import '../../screens/savings/savings_screen.dart';
import '../../screens/savings/add_goal_screen.dart';
import '../../screens/savings/epargne_programmee_screen.dart';
import '../../screens/savings/creer_epargne_screen.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/dettes/dettes_screen.dart';
import '../../screens/rapports/rapports_screen.dart';
import '../../screens/score/score_screen.dart';
import '../../screens/analyse/analyse_screen.dart';
import '../../screens/coach/coach_screen.dart';
import '../../screens/guide/guide_screen.dart';
import '../../screens/transfer/transfer_screen.dart';
import '../../screens/echeances/echeances_screen.dart';
import '../../screens/echeances/ajouter_echeance_screen.dart';
import '../../screens/investir/investir_screen.dart';
import '../../screens/investir/fcp_screen.dart';
import '../../screens/investir/produit_detail_screen.dart';
import '../../screens/investir/portefeuille_screen.dart';
import '../../screens/investir/assurance_screen.dart';
import '../../screens/investir/assurance_detail_screen.dart';
import '../../screens/investir/devis_auto_screen.dart';
import '../../screens/migration/migration_page.dart';

class AppRouter {
  final GoRouter router;

  AppRouter(WidgetRef ref) : router = _buildRouter(ref);

  static GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) async {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final user = ref.read(currentUserProvider);
        final location = state.matchedLocation;

        final isOnboardingScreen = location == '/onboarding';
        final isPinScreen = location == '/pin-setup' || location == '/pin-login';
        final isActivationScreen = location == '/activation';
        final isAuthScreen = location == '/inscription' ||
            location == '/pin-login' ||
            location == '/verify-phone' ||
            location == '/splash';

        // ---- Utilisateur NON connecté ----
        if (!isAuthenticated) {
          if (location == '/splash' || isAuthScreen) {
            return null;
          }
          return '/inscription';
        }

        // ---- Utilisateur connecté ----
        final needsOnboarding = !(user?.onboardingVu ?? false);
        final needsPin = (user?.pinCode ?? '').isEmpty;

        // ✅ ÉTAPE 1 : ONBOARDING (priorité absolue)
        if (needsOnboarding) {
          Logger.info('🔄 Redirection: Onboarding nécessaire');
          return isOnboardingScreen ? null : '/onboarding';
        }

        // ✅ ÉTAPE 2 : PIN (après onboarding)
        if (needsPin) {
          Logger.info('🔄 Redirection: PIN nécessaire');
          return isPinScreen ? null : '/pin-setup';
        }

        // ✅ ÉTAPE 3 : VÉRIFICATION ESSAI + ROOT
        final db = DBService();
        final firebaseService = FirebaseService();
        final isRoot = firebaseService.isRootUser;

        // ✅ SI ROOT → ACCÈS ILLIMITÉ
        if (isRoot) {
          Logger.info('👑 Redirection: Utilisateur Root - Accès illimité');
          if (isActivationScreen) {
            return '/home';
          }
          return null;
        }

        // ✅ VÉRIFICATION ESSAI AVEC FALLBACK
        bool essaiExpire = false;
        bool aAcces = false;

        try {
          // Utiliser la version synchrone (plus rapide)
          essaiExpire = db.essaiGratuitExpire;
          aAcces = db.aAccesAVie;

          // Si la date n'est pas trouvée, essayer la version asynchrone
          if (!essaiExpire && db.joursRestantsEssai == 0) {
            essaiExpire = await db.isEssaiGratuitExpire();
          }
        } catch (e) {
          Logger.error('❌ Erreur vérification essai: $e');
          essaiExpire = false; // ✅ FALLBACK: considérer que l'essai n'est pas expiré
        }

        Logger.info('🔍 Redirection - Essai expiré: $essaiExpire, Accès: $aAcces, Root: $isRoot');

        // ✅ SI ESSAI EXPIRE ET PAS D'ACCES (ET PAS ROOT)
        if (essaiExpire && !aAcces && !isActivationScreen) {
          Logger.info('🔄 Redirection: Essai expiré → /activation');
          return '/activation';
        }

        // ✅ SI SUR ACTIVATION MAIS ACCÈS VALIDE (PREMIUM OU ESSAI)
        if (isActivationScreen && (aAcces || !essaiExpire)) {
          Logger.info('🔄 Redirection: Activation déjà validée → /home');
          return '/home';
        }

        // ✅ ÉTAPE 4 : ACCUEIL
        if (isAuthScreen || isOnboardingScreen || isPinScreen || isActivationScreen) {
          Logger.info('🔄 Redirection: Accès validé → /home');
          return '/home';
        }

        return null;
      },
      routes: [
        // ============================================
        // ROUTES PUBLIQUES
        // ============================================
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/inscription',
          builder: (context, state) => const InscriptionScreen(),
        ),
        GoRoute(
          path: '/verify-phone',
          builder: (context, state) {
            final args = state.extra as Map<String, String>? ?? {};
            return VerifyPhoneScreen(
              prenom: args['prenom'] ?? '',
              telephone: args['telephone'] ?? '',
              indicatif: args['indicatif'] ?? '+225',
              codePays: args['codePays'] ?? 'CI',
              monnaie: args['monnaie'] ?? 'FCFA',
            );
          },
        ),
        GoRoute(
          path: '/pin-login',
          builder: (context, state) => const PinScreen(isSetup: false),
        ),
        GoRoute(
          path: '/pin-setup',
          builder: (context, state) => const PinScreen(isSetup: true),
        ),
        GoRoute(
          path: '/activation',
          builder: (context, state) => const ActivationScreen(),
        ),

        // ============================================
        // ROUTES PROTÉGÉES
        // ============================================
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/setup-wallets',
          builder: (context, state) => const SetupWalletsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/change-pin',
          builder: (context, state) => const ChangePinScreen(),
        ),
        GoRoute(
          path: '/abonnement',
          builder: (context, state) => const AbonnementScreen(),
        ),
        GoRoute(
          path: '/wallets',
          builder: (context, state) => const WalletsScreen(),
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (context, state) => const AddTransactionScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/voice-transaction',
          builder: (context, state) => const VoiceTransactionScreen(),
        ),
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen(),
        ),
        GoRoute(
          path: '/transfer',
          builder: (context, state) => const TransferScreen(),
        ),
        GoRoute(
          path: '/savings',
          builder: (context, state) => const SavingsScreen(),
        ),
        GoRoute(
          path: '/savings/add',
          builder: (context, state) => const AddGoalScreen(),
        ),
        GoRoute(
          path: '/epargne-programmee',
          builder: (context, state) => const EpargneProgrammeeScreen(),
        ),
        GoRoute(
          path: '/epargne-programmee/creer',
          builder: (context, state) => const CreerEpargneScreen(),
        ),
        GoRoute(
          path: '/budget',
          builder: (context, state) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/dettes',
          builder: (context, state) => const DettesScreen(),
        ),
        GoRoute(
          path: '/rapports',
          builder: (context, state) => const RapportsScreen(),
        ),
        GoRoute(
          path: '/score',
          builder: (context, state) => const ScoreScreen(),
        ),
        GoRoute(
          path: '/analyse',
          builder: (context, state) => const AnalyseScreen(),
        ),
        GoRoute(
          path: '/coach',
          builder: (context, state) => const CoachScreen(),
        ),
        GoRoute(
          path: '/guide',
          builder: (context, state) => const GuideScreen(),
        ),
        GoRoute(
          path: '/echeances',
          builder: (context, state) => const EcheancesScreen(),
        ),
        GoRoute(
          path: '/echeances/ajouter',
          builder: (context, state) => const AjouterEcheanceScreen(),
        ),
        GoRoute(
          path: '/investir',
          builder: (context, state) => const InvestirScreen(),
        ),
        GoRoute(
          path: '/investir/fcp',
          builder: (context, state) => const InvestirFCPScreen(),
        ),
        GoRoute(
          path: '/investir/produit/:id',
          builder: (context, state) {
            final produit = state.extra as Map<String, dynamic>? ?? {};
            return ProduitDetailScreen(produit: produit);
          },
        ),
        GoRoute(
          path: '/investir/portefeuille',
          builder: (context, state) => const PortefeuilleScreen(),
        ),
        GoRoute(
          path: '/investir/assurance',
          builder: (context, state) => const AssuranceScreen(),
        ),
        GoRoute(
          path: '/investir/assurance/:id',
          builder: (context, state) {
            final produit = state.extra as Map<String, dynamic>? ?? {};
            return AssuranceDetailScreen(produit: produit);
          },
        ),
        GoRoute(
          path: '/devis-auto/:produit',
          builder: (context, state) {
            final produitNom = state.pathParameters['produit'] ?? 'Assurance Auto';
            return DevisAutoScreen(produitNom: produitNom);
          },
        ),
        GoRoute(
          path: '/migration',
          builder: (context, state) => const MigrationPage(),
        ),
      ],
    );
  }
}