// lib/presentation/providers/budget/budget_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_budget_repository.dart';
import '../../../data/repositories/budget_repository_impl.dart';
import '../../../domain/usecases/budget/create_budget_usecase.dart';
import '../../../domain/usecases/budget/get_budget_usecase.dart';
import '../transaction/transaction_provider.dart';  // ✅ Importer le provider depuis transaction_provider.dart
import '../../../core/utils/logger.dart';

// ============================================
// PROVIDERS REPOSITORY & USE CASES
// ============================================

/// Provider du repository des budgets
final budgetRepositoryProvider = Provider<IBudgetRepository>((ref) {
  return BudgetRepositoryImpl();
});

/// Provider du Use Case pour créer un budget
final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return CreateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider du Use Case pour mettre à jour un budget
final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return UpdateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider du Use Case pour récupérer un budget
final getBudgetUseCaseProvider = Provider<GetBudgetUseCase>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);  // ✅ Utilise le provider importé
  return GetBudgetUseCase(
    budgetRepository: budgetRepo,
    transactionRepository: transactionRepo,
  );
});

/// Provider du Use Case pour récupérer les budgets d'une année
final getBudgetsForYearUseCaseProvider = Provider<GetBudgetsForYearUseCase>((ref) {
  return GetBudgetsForYearUseCase(ref.watch(budgetRepositoryProvider));
});

/// Provider du Use Case pour supprimer un budget
final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>((ref) {
  return DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

// ============================================
// FUTURE PROVIDERS (Actions)
// ============================================

/// Provider pour créer un budget
final createBudgetProvider = FutureProvider.family<CreateBudgetResult, CreateBudgetParams>(
  (ref, params) async {
    final useCase = ref.watch(createBudgetUseCaseProvider);
    final result = await useCase.execute(params);
    
    if (result.success) {
      Logger.success('✅ Budget créé: ${result.budget?.moisLabel}');
      ref.read(budgetStateProvider.notifier).setBudget(result.budget);
    } else {
      Logger.error('❌ Erreur création budget: ${result.message}');
    }
    
    return result;
  },
);

/// Provider pour mettre à jour un budget
final updateBudgetProvider = FutureProvider.family<CreateBudgetResult, CreateBudgetParams>(
  (ref, params) async {
    final useCase = ref.watch(updateBudgetUseCaseProvider);
    final result = await useCase.execute(params);
    
    if (result.success) {
      Logger.success('📝 Budget mis à jour: ${result.budget?.moisLabel}');
      ref.read(budgetStateProvider.notifier).setBudget(result.budget);
    } else {
      Logger.error('❌ Erreur mise à jour budget: ${result.message}');
    }
    
    return result;
  },
);

/// Provider pour récupérer un budget
final getBudgetProvider = FutureProvider.family<GetBudgetResult, GetBudgetParams>(
  (ref, params) async {
    final useCase = ref.watch(getBudgetUseCaseProvider);
    return await useCase.execute(
      uid: params.uid,
      mois: params.mois,
      annee: params.annee,
    );
  },
);

/// Provider pour récupérer les budgets de l'année
final getBudgetsForYearProvider = FutureProvider.family<List<BudgetMensuel>, GetBudgetsForYearParams>(
  (ref, params) async {
    final useCase = ref.watch(getBudgetsForYearUseCaseProvider);
    return await useCase.execute(
      uid: params.uid,
      annee: params.annee,
    );
  },
);

/// Provider pour supprimer un budget
final deleteBudgetProvider = FutureProvider.family<bool, DeleteBudgetParams>(
  (ref, params) async {
    final useCase = ref.watch(deleteBudgetUseCaseProvider);
    final result = await useCase.execute(
      uid: params.uid,
      mois: params.mois,
      annee: params.annee,
    );
    
    if (result) {
      Logger.success('🗑️ Budget supprimé: ${params.mois}/${params.annee}');
      ref.read(budgetStateProvider.notifier).clearBudget();
    } else {
      Logger.error('❌ Erreur suppression budget');
    }
    
    return result;
  },
);

// ============================================
// NOTIFIER PROVIDER (État local du budget)
// ============================================

/// Provider pour l'état du budget
final budgetStateProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref);
});

/// État du budget
class BudgetState {
  final BudgetMensuel? currentBudget;
  final bool isLoading;
  final String? error;
  final bool hasBudget;
  final Map<String, double> depensesReelles;
  final double totalRevenusReels;
  final double totalDepensesReelles;

  const BudgetState({
    this.currentBudget,
    this.isLoading = false,
    this.error,
    this.hasBudget = false,
    this.depensesReelles = const {},
    this.totalRevenusReels = 0,
    this.totalDepensesReelles = 0,
  });

  BudgetState copyWith({
    BudgetMensuel? currentBudget,
    bool? isLoading,
    String? error,
    bool? hasBudget,
    Map<String, double>? depensesReelles,
    double? totalRevenusReels,
    double? totalDepensesReelles,
  }) {
    return BudgetState(
      currentBudget: currentBudget ?? this.currentBudget,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasBudget: hasBudget ?? this.hasBudget,
      depensesReelles: depensesReelles ?? this.depensesReelles,
      totalRevenusReels: totalRevenusReels ?? this.totalRevenusReels,
      totalDepensesReelles: totalDepensesReelles ?? this.totalDepensesReelles,
    );
  }

  /// Récupère le total des revenus prévus
  double get totalRevenusPrevus {
    return currentBudget?.totalRevenusPrevu ?? 0;
  }

  /// Récupère le total des dépenses prévues
  double get totalDepensesPrevues {
    return currentBudget?.totalDepensesPrevu ?? 0;
  }

  /// Récupère l'écart des revenus
  double get ecartRevenus {
    return totalRevenusReels - totalRevenusPrevus;
  }

  /// Récupère l'écart des dépenses
  double get ecartDepenses {
    return totalDepensesReelles - totalDepensesPrevues;
  }

  /// Vérifie si le budget est équilibré
  bool get isBalanced {
    return totalRevenusPrevus > 0 && totalDepensesPrevues > 0;
  }

  /// Récupère l'écart pour une catégorie
  double getEcartForCategorie(String categorieId) {
    if (currentBudget == null) return 0;
    
    final ligne = currentBudget!.lignes.firstWhere(
      (l) => l.categorieId == categorieId,
      orElse: () => BudgetLigne(
        id: '',
        categorieId: categorieId,
        categorieLabel: '',
        categorieEmoji: '📌',
        montantPrevu: 0,
        isRevenu: false,
      ),
    );
    
    final reel = depensesReelles[categorieId] ?? 0;
    return ligne.montantPrevu - reel;
  }

  /// Vérifie si une catégorie est en dépassement
  bool isCategorieExceeded(String categorieId) {
    if (currentBudget == null) return false;
    
    final ligne = currentBudget!.lignes.firstWhere(
      (l) => l.categorieId == categorieId,
      orElse: () => BudgetLigne(
        id: '',
        categorieId: categorieId,
        categorieLabel: '',
        categorieEmoji: '📌',
        montantPrevu: 0,
        isRevenu: false,
      ),
    );
    
    if (ligne.montantPrevu <= 0) return false;
    
    final reel = depensesReelles[categorieId] ?? 0;
    return reel > ligne.montantPrevu;
  }
}

/// Notifier pour l'état du budget
class BudgetNotifier extends StateNotifier<BudgetState> {
  final Ref _ref;

  BudgetNotifier(this._ref) : super(const BudgetState());

  /// Définit le budget
  void setBudget(BudgetMensuel? budget) {
    if (budget == null) {
      state = state.copyWith(
        currentBudget: null,
        hasBudget: false,
      );
      return;
    }

    state = state.copyWith(
      currentBudget: budget,
      hasBudget: true,
    );
  }

  /// Met à jour les données réelles
  void setReelData({
    required Map<String, double> depensesReelles,
    required double totalRevenusReels,
    required double totalDepensesReelles,
  }) {
    state = state.copyWith(
      depensesReelles: depensesReelles,
      totalRevenusReels: totalRevenusReels,
      totalDepensesReelles: totalDepensesReelles,
    );
  }

  /// Charge un budget
  Future<void> loadBudget({
    required String uid,
    required int mois,
    required int annee,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _ref.read(
        getBudgetProvider(GetBudgetParams(uid: uid, mois: mois, annee: annee))
            .future,
      );

      if (result.success && result.hasBudget) {
        state = state.copyWith(
          currentBudget: result.budget,
          hasBudget: true,
          depensesReelles: result.comparison?.depensesReelles ?? {},
          totalRevenusReels: result.comparison?.totalRevenusReels ?? 0,
          totalDepensesReelles: result.comparison?.totalDepensesReelles ?? 0,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hasBudget: false,
          currentBudget: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Efface le budget
  void clearBudget() {
    state = const BudgetState();
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Réinitialise l'état
  void reset() {
    state = const BudgetState();
  }
}

// ============================================
// PARAMÈTRES
// ============================================

/// Paramètres pour la récupération d'un budget
class GetBudgetParams {
  final String uid;
  final int mois;
  final int annee;

  const GetBudgetParams({
    required this.uid,
    required this.mois,
    required this.annee,
  });
}

/// Paramètres pour la récupération des budgets d'une année
class GetBudgetsForYearParams {
  final String uid;
  final int annee;

  const GetBudgetsForYearParams({
    required this.uid,
    required this.annee,
  });
}

/// Paramètres pour la suppression d'un budget
class DeleteBudgetParams {
  final String uid;
  final int mois;
  final int annee;

  const DeleteBudgetParams({
    required this.uid,
    required this.mois,
    required this.annee,
  });
}

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

/// Provider pour savoir si un budget existe
final hasBudgetProvider = Provider<bool>((ref) {
  final state = ref.watch(budgetStateProvider);
  return state.hasBudget;
});

/// Provider pour le mois courant du budget
final currentBudgetMonthProvider = Provider<String>((ref) {
  final state = ref.watch(budgetStateProvider);
  return state.currentBudget?.moisLabel ?? 'Aucun budget';
});

/// Provider pour l'écart des dépenses
final budgetEcartDepensesProvider = Provider<double>((ref) {
  final state = ref.watch(budgetStateProvider);
  return state.ecartDepenses;
});

/// Provider pour l'écart des revenus
final budgetEcartRevenusProvider = Provider<double>((ref) {
  final state = ref.watch(budgetStateProvider);
  return state.ecartRevenus;
});

/// Provider pour les catégories en dépassement
final exceededCategoriesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(budgetStateProvider);
  if (state.currentBudget == null) return [];
  
  return state.currentBudget!.lignes
      .where((l) => state.isCategorieExceeded(l.categorieId))
      .map((l) => l.categorieLabel)
      .toList();
});

/// Provider pour le pourcentage d'utilisation du budget
final budgetUsagePercentageProvider = Provider<double>((ref) {
  final state = ref.watch(budgetStateProvider);
  if (!state.hasBudget || state.totalDepensesPrevues == 0) return 0;
  return (state.totalDepensesReelles / state.totalDepensesPrevues * 100).clamp(0, 100);
});
