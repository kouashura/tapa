// lib/presentation/providers/providers.dart

// ============================================
// EXPORT DE TOUS LES PROVIDERS
// ============================================

// --- État Global ---
export 'app_state.dart';


// --- Auth Providers ---
export 'auth/auth_provider.dart';
export 'auth/auth_state.dart';

// --- Wallet Providers ---
export 'wallet/wallet_provider.dart';

// --- Transaction Providers ---
export 'transaction/transaction_provider.dart';

// --- User Repository ---


// --- Budget Providers ---
// export 'budget/budget_provider.dart';  // Commenté pour éviter les conflits

// --- Savings Providers ---
// export 'savings/savings_provider.dart';

// --- Debt Providers ---
// export 'debt/debt_provider.dart';

// --- Echeance Providers ---
// export 'echeance/echeance_provider.dart';

// --- Theme Providers ---
// export 'theme/theme_provider.dart';

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import 'app_state.dart';
import 'auth/auth_provider.dart';
import 'transaction/transaction_provider.dart';
import 'wallet/wallet_provider.dart';
import '../../core/utils/logger.dart';

// ============================================
// PROVIDERS D'UTILISATEUR
// ============================================

/// Provider pour obtenir l'utilisateur courant
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(appStateProvider).currentUser;
});

/// Provider pour savoir si l'utilisateur est authentifié
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isAuthenticated;
});

/// Provider pour savoir si l'utilisateur est root
final isRootProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isRoot;
});

/// Provider pour savoir si l'utilisateur a l'accès à vie
final hasAccessVieProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).hasAccessVie;
});

/// Provider pour la monnaie de l'utilisateur
final userMonnaieProvider = Provider<String>((ref) {
  return ref.watch(appStateProvider).monnaie;
});

/// Provider pour le prénom de l'utilisateur
final userPrenomProvider = Provider<String>((ref) {
  return ref.watch(appStateProvider).displayName;
});

/// Provider pour vérifier si l'onboarding est terminé
final onboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).onboardingCompleted;
});

/// Provider pour vérifier si l'utilisateur a un PIN
final hasPinProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).hasPin;
});

/// Provider pour vérifier si l'utilisateur doit faire l'onboarding
final needsOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).needsOnboarding;
});

/// Provider pour vérifier si l'utilisateur doit créer un PIN
final needsPinProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).needsPin;
});

/// Provider pour vérifier si l'utilisateur doit activer son compte
final needsActivationProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).needsActivation;
});

/// Provider pour vérifier si l'utilisateur a accès à l'app
final canAccessAppProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).canAccessApp;
});

/// Provider pour le mode sombre
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isDarkMode;
});

/// Provider pour l'état de chargement
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isLoading;
});

/// Provider pour l'erreur
final errorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).error;
});

/// Provider pour les notifications
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).notificationsEnabled;
});

// ============================================
// USER REPOSITORY PROVIDER
// ============================================

/// Provider pour le repository utilisateur
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Classe UserRepository pour les opérations utilisateur
class UserRepository {
  /// Récupère l'ID de l'utilisateur courant
  Future<String> getCurrentUserId() async {
    // TODO: Implémenter la récupération de l'ID utilisateur
    // Pour l'instant, on simule
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Récupère l'utilisateur courant
  Future<AppUser?> getCurrentUser() async {
    // TODO: Implémenter la récupération de l'utilisateur
    return null;
  }

  /// Crée un objectif d'épargne
  Future<void> createSavingsGoal({
    required String userId,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required String currency,
    required DateTime targetDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Implémenter la sauvegarde dans Firestore
      Logger.info('✅ Objectif d\'épargne créé: $name');
    } catch (e) {
      Logger.error('❌ Erreur création objectif: $e');
      rethrow;
    }
  }

  /// Crée une épargne programmée
  Future<void> createScheduledSaving({
    required String userId,
    required String name,
    required double amount,
    required String frequency,
    required DateTime startDate,
    required String walletId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Implémenter la sauvegarde dans Firestore
      Logger.info('✅ Épargne programmée créée: $name');
    } catch (e) {
      Logger.error('❌ Erreur création épargne: $e');
      rethrow;
    }
  }

  /// Ajoute une transaction
  Future<void> addTransaction({
    required String userId,
    required String walletId,
    required double amount,
    required String type,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Implémenter la sauvegarde dans Firestore
      Logger.info('✅ Transaction ajoutée: $description');
    } catch (e) {
      Logger.error('❌ Erreur ajout transaction: $e');
      rethrow;
    }
  }

  /// Supprime une transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // TODO: Implémenter la suppression dans Firestore
      Logger.info('✅ Transaction supprimée: $transactionId');
    } catch (e) {
      Logger.error('❌ Erreur suppression transaction: $e');
      rethrow;
    }
  }

  /// Met à jour une transaction
  Future<void> updateTransaction(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // TODO: Implémenter la mise à jour dans Firestore
      Logger.info('✅ Transaction mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour transaction: $e');
      rethrow;
    }
  }
}

// ============================================
// PROVIDERS DE CATÉGORIES
// ============================================

/// Provider pour les catégories de dépenses
final expenseCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'id': 'alimentation', 'label': 'Alimentation', 'emoji': '🛒', 'type': 'depense'},
    {'id': 'transport', 'label': 'Transport', 'emoji': '🚗', 'type': 'depense'},
    {'id': 'logement', 'label': 'Logement', 'emoji': '🏠', 'type': 'depense'},
    {'id': 'sante', 'label': 'Santé', 'emoji': '🏥', 'type': 'depense'},
    {'id': 'education', 'label': 'Éducation', 'emoji': '📚', 'type': 'depense'},
    {'id': 'loisirs', 'label': 'Loisirs', 'emoji': '🎮', 'type': 'depense'},
    {'id': 'habillement', 'label': 'Habillement', 'emoji': '👕', 'type': 'depense'},
    {'id': 'services', 'label': 'Services', 'emoji': '🔧', 'type': 'depense'},
    {'id': 'autre', 'label': 'Autre', 'emoji': '📌', 'type': 'depense'},
  ];
});

/// Provider pour les catégories de revenus
final incomeCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰', 'type': 'revenu'},
    {'id': 'freelance', 'label': 'Freelance', 'emoji': '💻', 'type': 'revenu'},
    {'id': 'investissement', 'label': 'Investissement', 'emoji': '📈', 'type': 'revenu'},
    {'id': 'cadeau', 'label': 'Cadeau', 'emoji': '🎁', 'type': 'revenu'},
    {'id': 'remboursement', 'label': 'Remboursement', 'emoji': '🔄', 'type': 'revenu'},
    {'id': 'autre_revenu', 'label': 'Autre', 'emoji': '📌', 'type': 'revenu'},
  ];
});

/// Provider combiné pour toutes les catégories
final allCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final expenseCats = ref.watch(expenseCategoriesProvider);
  final incomeCats = ref.watch(incomeCategoriesProvider);
  return [...expenseCats, ...incomeCats];
});

// ============================================
// PROVIDERS DE STATISTIQUES
// ============================================

/// Provider pour le total des dépenses du mois
final monthlyExpensesProvider = FutureProvider<double>((ref) async {
  // TODO: Implémenter le calcul des dépenses du mois
  return 0.0;
});

/// Provider pour le total des revenus du mois
final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  // TODO: Implémenter le calcul des revenus du mois
  return 0.0;
});

/// Provider pour le solde du mois (revenus - dépenses)
final monthlyBalanceProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(monthlyExpensesProvider.future);
  final income = await ref.watch(monthlyIncomeProvider.future);
  return income - expenses;
});