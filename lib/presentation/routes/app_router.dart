// lib/presentation/routes/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../../services/db_service_mysql.dart';
import '../../core/utils/logger.dart';

// ============================================
// IMPORTS DES ÉCRANS
// ============================================
import '../screens/splash/splash_screen.dart';
import '../screens/auth/inscription_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/auth/verify_phone_screen.dart';
import '../screens/auth/activation_screen.dart';
import '../screens/auth/setup_wallets_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wallets/wallets_screen.dart';
import '../screens/wallets/add_wallet_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/categories_screen.dart';
import '../screens/profile/change_pin_screen.dart';
import '../screens/profile/abonnement_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/history_screen.dart';
import '../screens/transactions/voice_transaction_screen.dart';
import '../screens/transactions/scanner_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/savings/add_goal_screen.dart';
import '../screens/savings/epargne_programmee_screen.dart';
import '../screens/savings/creer_epargne_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/dettes/dettes_screen.dart';
import '../screens/rapports/rapports_screen.dart';
import '../screens/score/score_screen.dart';
import '../screens/analyse/analyse_screen.dart';
import '../screens/coach/coach_screen.dart';
import '../screens/guide/guide_screen.dart';
import '../screens/transfer/transfer_screen.dart';
import '../screens/echeances/echeances_screen.dart';
import '../screens/echeances/ajouter_echeance_screen.dart';
import '../screens/investir/investir_screen.dart';
import '../screens/investir/fcp_screen.dart';
import '../screens/investir/produit_detail_screen.dart';
import '../screens/investir/portefeuille_screen.dart';
import '../screens/investir/assurance_screen.dart';
import '../screens/investir/assurance_detail_screen.dart';
import '../screens/investir/devis_auto_screen.dart';
import '../screens/investir/assurance_success_screen.dart';
import '../screens/investir/sonam_simulator_screen.dart';
import '../screens/profile/historique_paiements_screen.dart';
import '../screens/admin/admin_tarifs_screen.dart';
import '../screens/admin/admin_souscriptions_screen.dart';
import '../screens/migration/migration_page.dart';
import '../screens/admin/admin_withdraw_screen.dart';
import '../screens/investir/my_sonam_contracts_screen.dart';

class AppRouter {
  final GoRouter router;

  AppRouter(WidgetRef ref) : router = _buildRouter(ref);

  /// Fonction pour vérifier l'existence du PIN
  static Future<bool> _checkIfPinExists(WidgetRef ref) async {
    try {
      final db = DBService();
      final hasPin = await db.hasPin();
      Logger.info(hasPin ? '✅ PIN trouvé' : '❌ Aucun PIN trouvé');
      return hasPin;
    } catch (e) {
      Logger.error('❌ Erreur vérification PIN: $e');
      return false;
    }
  }

  static GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) async {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final user = ref.read(currentUserProvider);
        final location = state.matchedLocation;

        final isOnboardingScreen = location == '/onboarding';
        final isPinScreen =
            location == '/pin-setup' || location == '/pin-login';
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
        final hasPin = await _checkIfPinExists(ref);
        final needsPin = !hasPin;

        // ÉTAPE 1 : ONBOARDING
        if (needsOnboarding) {
          Logger.info('🔄 Redirection: Onboarding nécessaire');
          return isOnboardingScreen ? null : '/onboarding';
        }

        // ÉTAPE 2 : PIN
        if (needsPin) {
          Logger.info('🔄 Redirection: PIN nécessaire (hasPin=$hasPin)');
          return isPinScreen ? null : '/pin-setup';
        }

        // ✅ ACCÈS GRATUIT POUR TOUS : plus de vérification d'essai/abonnement
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
          path: '/admin/withdraws',
          builder: (context, state) => const AdminWithdrawScreen(),
        ),
        // ✅ Route Admin (accès réservé)
        GoRoute(
          path: '/admin/withdraws',
          builder: (context, state) => const AdminWithdrawScreen(),
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
          path: '/wallets/add',
          builder: (context, state) => const AddWalletScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (context, state) => AddTransactionScreen(initialData: state.extra as Map<String, dynamic>?),
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
          path: '/investir/sonam',
          builder: (context, state) => const SonamSimulatorScreen(),
        ),
        GoRoute(
          path: '/investir/sonam/contrats',
          builder: (context, state) => const MySonamContractsScreen(),
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
            final produitNom =
                state.pathParameters['produit'] ?? 'Assurance Auto';
            return DevisAutoScreen(produitNom: produitNom);
          },
        ),
        GoRoute(
          path: '/assurance/success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return AssuranceSuccessScreen(
              produitNom: extra['produitNom'] ?? 'Auto',
              montantPaye: extra['montantPaye'] ?? 0,
              reference: extra['reference'] ?? '',
            );
          },
        ),
        GoRoute(
          path: '/historique-paiements',
          builder: (context, state) => const HistoriquePaiementsScreen(),
        ),
        GoRoute(
          path: '/admin/tarifs',
          builder: (context, state) => const AdminTarifsScreen(),
        ),
        GoRoute(
          path: '/admin/souscriptions',
          builder: (context, state) => const AdminSouscriptionsScreen(),
        ),
        GoRoute(
          path: '/migration',
          builder: (context, state) => const MigrationPage(),
        ),
      ],
    );
  }
}
