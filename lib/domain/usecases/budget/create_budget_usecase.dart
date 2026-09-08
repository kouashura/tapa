// lib/domain/usecases/budget/create_budget_usecase.dart

import '../../repositories/i_budget_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Ligne de budget pour la création
class CreateBudgetLigneParams {
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final double montantPrevu;
  final bool isRevenu;

  const CreateBudgetLigneParams({
    required this.categorieId,
    required this.categorieLabel,
    required this.categorieEmoji,
    required this.montantPrevu,
    required this.isRevenu,
  });

  /// Vérifie si la ligne est valide
  bool get isValid => montantPrevu > 0 && categorieId.isNotEmpty;
}

/// Paramètres pour la création d'un budget
class CreateBudgetParams {
  final String uid;
  final int mois;
  final int annee;
  final List<CreateBudgetLigneParams> lignes;

  const CreateBudgetParams({
    required this.uid,
    required this.mois,
    required this.annee,
    required this.lignes,
  });

  /// Vérifie si les paramètres sont valides
  bool get isValid {
    if (uid.isEmpty) return false;
    if (mois < 1 || mois > 12) return false;
    if (annee < 2020) return false;
    if (lignes.isEmpty) return false;
    return lignes.any((l) => l.isValid);
  }

  /// Convertit les lignes en BudgetLigne
  List<BudgetLigne> get budgetLignes {
    return lignes
        .where((l) => l.isValid)
        .map((l) => BudgetLigne(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              categorieId: l.categorieId,
              categorieLabel: l.categorieLabel,
              categorieEmoji: l.categorieEmoji,
              montantPrevu: l.montantPrevu,
              isRevenu: l.isRevenu,
            ))
        .toList();
  }

  /// Récupère le total des revenus prévus
  double get totalRevenusPrevu {
    return lignes
        .where((l) => l.isRevenu)
        .fold(0.0, (sum, l) => sum + l.montantPrevu);
  }

  /// Récupère le total des dépenses prévues
  double get totalDepensesPrevu {
    return lignes
        .where((l) => !l.isRevenu)
        .fold(0.0, (sum, l) => sum + l.montantPrevu);
  }

  /// Récupère le solde prévu
  double get soldePrevu => totalRevenusPrevu - totalDepensesPrevu;
}

/// Résultat de la création d'un budget
class CreateBudgetResult {
  final BudgetMensuel? budget;
  final bool success;
  final String? message;
  final double? totalRevenus;
  final double? totalDepenses;
  final double? solde;

  const CreateBudgetResult({
    this.budget,
    this.success = false,
    this.message,
    this.totalRevenus,
    this.totalDepenses,
    this.solde,
  });

  /// Succès
  factory CreateBudgetResult.success(BudgetMensuel budget) {
    return CreateBudgetResult(
      budget: budget,
      success: true,
      message: '✅ Budget créé pour ${budget.moisLabel} !',
      totalRevenus: budget.totalRevenusPrevu,
      totalDepenses: budget.totalDepensesPrevu,
      solde: budget.totalRevenusPrevu - budget.totalDepensesPrevu,
    );
  }

  /// Erreur
  factory CreateBudgetResult.error(String message) {
    return CreateBudgetResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Créer un budget
class CreateBudgetUseCase {
  final IBudgetRepository _budgetRepository;

  CreateBudgetUseCase(this._budgetRepository);

  /// Exécute la création d'un budget
  Future<CreateBudgetResult> execute(CreateBudgetParams params) async {
    try {
      Logger.info('📝 Création du budget: ${params.mois}/${params.annee}');

      // Valider les paramètres
      if (!params.isValid) {
        return CreateBudgetResult.error(
          'Veuillez renseigner au moins un montant pour les catégories.',
        );
      }

      // Vérifier si un budget existe déjà pour ce mois
      final existingBudget = await _budgetRepository.getBudget(
        params.uid,
        params.mois,
        params.annee,
      );

      if (existingBudget != null) {
        return CreateBudgetResult.error(
          'Un budget existe déjà pour ${existingBudget.moisLabel}. '
          'Vous pouvez le modifier.',
        );
      }

      // Créer le budget
      final budget = BudgetMensuel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mois: params.mois,
        annee: params.annee,
        lignes: params.budgetLignes,
      );

      // Sauvegarder
      await _budgetRepository.saveBudget(budget);

      Logger.success('✅ Budget créé pour ${budget.moisLabel}');
      Logger.info('💰 Revenus: ${budget.totalRevenusPrevu}, Dépenses: ${budget.totalDepensesPrevu}');

      return CreateBudgetResult.success(budget);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur création budget: ${failure.message}');

      if (failure is DatabaseFailure) {
        return CreateBudgetResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return CreateBudgetResult.error(
        'Erreur lors de la création du budget.',
      );
    }
  }
}

/// Cas d'utilisation : Mettre à jour un budget
class UpdateBudgetUseCase {
  final IBudgetRepository _budgetRepository;

  UpdateBudgetUseCase(this._budgetRepository);

  /// Exécute la mise à jour d'un budget
  Future<CreateBudgetResult> execute(CreateBudgetParams params) async {
    try {
      Logger.info('📝 Mise à jour du budget: ${params.mois}/${params.annee}');

      // Valider les paramètres
      if (!params.isValid) {
        return CreateBudgetResult.error(
          'Veuillez renseigner au moins un montant pour les catégories.',
        );
      }

      // Vérifier si le budget existe
      final existingBudget = await _budgetRepository.getBudget(
        params.uid,
        params.mois,
        params.annee,
      );

      if (existingBudget == null) {
        // Si le budget n'existe pas, en créer un nouveau
        return await CreateBudgetUseCase(_budgetRepository).execute(params);
      }

      // Créer le budget mis à jour
      final updatedBudget = BudgetMensuel(
        id: existingBudget.id,
        mois: existingBudget.mois,
        annee: existingBudget.annee,
        lignes: params.budgetLignes,
      );

      // Sauvegarder
      await _budgetRepository.saveBudget(updatedBudget);

      Logger.success('✅ Budget mis à jour pour ${updatedBudget.moisLabel}');

      return CreateBudgetResult.success(updatedBudget);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur mise à jour budget: ${failure.message}');

      return CreateBudgetResult.error(
        'Erreur lors de la mise à jour du budget.',
      );
    }
  }
}
