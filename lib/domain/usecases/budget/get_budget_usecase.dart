// lib/domain/usecases/budget/get_budget_usecase.dart

import '../../repositories/i_budget_repository.dart';
import '../../repositories/i_transaction_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Résultat de la récupération du budget avec comparatif
class BudgetWithComparison {
  final BudgetMensuel? budget;
  final bool exists;
  final Map<String, double> depensesReelles;
  final double totalRevenusReels;
  final double totalDepensesReelles;
  final double totalRevenusPrevus;
  final double totalDepensesPrevues;

  BudgetWithComparison({
    this.budget,
    this.exists = false,
    this.depensesReelles = const {},
    this.totalRevenusReels = 0,
    this.totalDepensesReelles = 0,
    this.totalRevenusPrevus = 0,
    this.totalDepensesPrevues = 0,
  });

  /// Budget existant avec données réelles
  factory BudgetWithComparison.fromBudget(
    BudgetMensuel budget,
    Map<String, double> depensesReelles,
    double revenusReels,
    double depensesReellesTotal,
  ) {
    return BudgetWithComparison(
      budget: budget,
      exists: true,
      depensesReelles: depensesReelles,
      totalRevenusReels: revenusReels,
      totalDepensesReelles: depensesReellesTotal,
      totalRevenusPrevus: budget.totalRevenusPrevu,
      totalDepensesPrevues: budget.totalDepensesPrevu,
    );
  }

  /// Budget vide
  factory BudgetWithComparison.empty() {
    return  BudgetWithComparison();
  }

  /// Récupère l'écart pour une catégorie
  double getEcartForCategorie(String categorieId) {
    if (budget == null) return 0;

    final ligne = budget!.lignes.firstWhere(
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
    if (budget == null) return false;

    final ligne = budget!.lignes.firstWhere(
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

  /// Récupère le pourcentage d'utilisation pour une catégorie
  double getPercentageForCategorie(String categorieId) {
    if (budget == null) return 0;

    final ligne = budget!.lignes.firstWhere(
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

    if (ligne.montantPrevu <= 0) return 0;

    final reel = depensesReelles[categorieId] ?? 0;
    return (reel / ligne.montantPrevu * 100).clamp(0, 100);
  }
}

/// Résultat de la récupération du budget
class GetBudgetResult {
  final BudgetMensuel? budget;
  final bool success;
  final String? message;
  final BudgetWithComparison? comparison;
  final bool hasBudget;

  const GetBudgetResult({
    this.budget,
    this.success = false,
    this.message,
    this.comparison,
    this.hasBudget = false,
  });

  /// Succès avec budget
  factory GetBudgetResult.success(BudgetWithComparison comparison) {
    return GetBudgetResult(
      budget: comparison.budget,
      success: true,
      comparison: comparison,
      hasBudget: true,
    );
  }

  /// Succès sans budget
  factory GetBudgetResult.empty() {
    return const GetBudgetResult(
      success: true,
      hasBudget: false,
      message: 'Aucun budget pour ce mois.',
    );
  }

  /// Erreur
  factory GetBudgetResult.error(String message) {
    return GetBudgetResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Récupérer un budget
class GetBudgetUseCase {
  final IBudgetRepository _budgetRepository;
  final ITransactionRepository _transactionRepository;

  GetBudgetUseCase({
    required IBudgetRepository budgetRepository,
    required ITransactionRepository transactionRepository,
  })  : _budgetRepository = budgetRepository,
        _transactionRepository = transactionRepository;

  /// Exécute la récupération du budget
  Future<GetBudgetResult> execute({
    required String uid,
    required int mois,
    required int annee,
  }) async {
    try {
      Logger.info('📊 Récupération du budget: $mois/$annee');

      if (uid.isEmpty) {
        return GetBudgetResult.error('Utilisateur non identifié.');
      }

      // Récupérer le budget
      final budget = await _budgetRepository.getBudget(uid, mois, annee);

      if (budget == null) {
        Logger.info('📭 Aucun budget pour $mois/$annee');
        return GetBudgetResult.empty();
      }

      // Récupérer les dépenses réelles par catégorie
      final depensesReelles = <String, double>{};
      double totalRevenusReels = 0;
      double totalDepensesReelles = 0;

      // Récupérer les transactions du mois
      final transactions = await _transactionRepository.getTransactionsOnce(
        uid,
        limit: 1000,
      );

      // Filtrer les transactions du mois
      final transactionsMois = transactions.where((tx) {
        return tx.dateTransaction.month == mois &&
            tx.dateTransaction.year == annee;
      }).toList();

      // Calculer les dépenses par catégorie
      for (final tx in transactionsMois) {
        if (tx.isDepense) {
          depensesReelles[tx.categorieId] =
              (depensesReelles[tx.categorieId] ?? 0) + tx.montant;
          totalDepensesReelles += tx.montant;
        } else if (tx.isRevenu) {
          totalRevenusReels += tx.montant;
        }
      }

      // Créer le comparatif
      final comparison = BudgetWithComparison.fromBudget(
        budget,
        depensesReelles,
        totalRevenusReels,
        totalDepensesReelles,
      );

      Logger.success('✅ Budget récupéré: ${budget.moisLabel}');
      Logger.info('💰 Prévu: ${budget.totalRevenusPrevu}/${budget.totalDepensesPrevu}');
      Logger.info('📊 Réel: $totalRevenusReels/$totalDepensesReelles');

      return GetBudgetResult.success(comparison);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur récupération budget: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetBudgetResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return GetBudgetResult.error(
        'Erreur lors de la récupération du budget.',
      );
    }
  }
}

/// Cas d'utilisation : Récupérer les budgets d'une année
class GetBudgetsForYearUseCase {
  final IBudgetRepository _budgetRepository;

  GetBudgetsForYearUseCase(this._budgetRepository);

  /// Exécute la récupération des budgets de l'année
  Future<List<BudgetMensuel>> execute({
    required String uid,
    required int annee,
  }) async {
    try {
      Logger.info('📊 Récupération des budgets pour $annee');

      final List<BudgetMensuel> budgets = [];

      for (int mois = 1; mois <= 12; mois++) {
        final budget = await _budgetRepository.getBudget(uid, mois, annee);
        if (budget != null) {
          budgets.add(budget);
        }
      }

      Logger.success('✅ ${budgets.length} budgets récupérés pour $annee');
      return budgets;
    } catch (e) {
      Logger.error('❌ Erreur récupération budgets annuels: $e');
      return [];
    }
  }
}

/// Cas d'utilisation : Supprimer un budget
class DeleteBudgetUseCase {
  final IBudgetRepository _budgetRepository;

  DeleteBudgetUseCase(this._budgetRepository);

  /// Exécute la suppression du budget
  Future<bool> execute({
    required String uid,
    required int mois,
    required int annee,
  }) async {
    try {
      Logger.info('🗑️ Suppression du budget: $mois/$annee');

      await _budgetRepository.deleteBudget(uid, mois, annee);

      Logger.success('✅ Budget supprimé: $mois/$annee');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur suppression budget: $e');
      return false;
    }
  }
}
