import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// --- Savings Providers ---
export 'savings/savings_provider.dart';

// --- Dettes Providers ---
export 'dettes/dettes_provider.dart';

// --- Echeances Providers ---
export 'echeances/echeances_provider.dart';

// --- Souscriptions Providers ---
export 'souscriptions/souscriptions_provider.dart';

// --- Tarifs Providers ---
export 'tarifs/tarifs_provider.dart';

// --- Budget Providers ---
export 'budget/budget_provider.dart';

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import 'app_state.dart';

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
// PROVIDERS DE CATÉGORIES
// ============================================

// ═══════════════════════════════════════════════════════════════
// CATÉGORIES PAR DÉFAUT (STATIQUES)
// ═══════════════════════════════════════════════════════════════

const List<Map<String, dynamic>> defaultExpenseCategories = [
  {
    'id': 'alimentation',
    'label': 'Alimentation',
    'emoji': '🛒',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'transport',
    'label': 'Transport',
    'emoji': '🚗',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'logement',
    'label': 'Logement',
    'emoji': '🏠',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'sante',
    'label': 'Santé',
    'emoji': '🏥',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'education',
    'label': 'Éducation',
    'emoji': '📚',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'loisirs',
    'label': 'Loisirs',
    'emoji': '🎮',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'habillement',
    'label': 'Habillement',
    'emoji': '👕',
    'type': 'depense',
    'isDefault': true
  },
  {
    'id': 'services',
    'label': 'Services',
    'emoji': '🔧',
    'type': 'depense',
    'isDefault': true
  },
];

const List<Map<String, dynamic>> defaultIncomeCategories = [
  {
    'id': 'salaire',
    'label': 'Salaire',
    'emoji': '💰',
    'type': 'revenu',
    'isDefault': true
  },
  {
    'id': 'freelance',
    'label': 'Freelance',
    'emoji': '💻',
    'type': 'revenu',
    'isDefault': true
  },
  {
    'id': 'investissement',
    'label': 'Investissement',
    'emoji': '📈',
    'type': 'revenu',
    'isDefault': true
  },
  {
    'id': 'cadeau',
    'label': 'Cadeau',
    'emoji': '🎁',
    'type': 'revenu',
    'isDefault': true
  },
  {
    'id': 'remboursement',
    'label': 'Remboursement',
    'emoji': '🔄',
    'type': 'revenu',
    'isDefault': true
  },
];

// ═══════════════════════════════════════════════════════════════
// PROVIDER DYNAMIQUE (FIRESTORE + DÉFAUT)
// ═══════════════════════════════════════════════════════════════

/// StreamProvider qui écoute Firestore et fusionne avec les catégories par défaut
final dynamicCategoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value(
        [...defaultExpenseCategories, ...defaultIncomeCategories]);
  }

  return FirebaseFirestore.instance
      .collection('categories')
      .where('uid', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final userCategories = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // Fusionner avec les catégories par défaut
    final List<Map<String, dynamic>> mergedExpenses =
        List.from(defaultExpenseCategories);
    final List<Map<String, dynamic>> mergedIncomes =
        List.from(defaultIncomeCategories);

    for (final cat in userCategories) {
      final type = cat['type'] as String? ?? 'depense';
      final label = (cat['label'] as String? ?? '').toLowerCase().trim();

      final targetList = type == 'revenu' ? mergedIncomes : mergedExpenses;
      final exists = targetList.any(
          (c) => (c['label'] as String? ?? '').toLowerCase().trim() == label);

      if (!exists) targetList.add(cat);
    }

    return [...mergedExpenses, ...mergedIncomes];
  });
});

/// Provider pour les catégories de dépenses (dynamique)
final expenseCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(dynamicCategoriesProvider).valueOrNull ?? [];
  return all
      .where((c) => c['type'] == 'depense' || c['type'] == 'dépense')
      .toList();
});

/// Provider pour les catégories de revenus (dynamique)
final incomeCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(dynamicCategoriesProvider).valueOrNull ?? [];
  return all.where((c) => c['type'] == 'revenu').toList();
});

/// Provider combiné pour toutes les catégories (dynamique)
final allCategoriesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(dynamicCategoriesProvider).valueOrNull ?? [];
});
