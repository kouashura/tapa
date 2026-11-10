// lib/domain/repositories/i_budget_repository.dart

import '../../data/models/models.dart'; // ✅ Utiliser les modèles de données

/// Interface du repository des budgets
abstract class IBudgetRepository {
  /// Récupère le budget d'un mois donné
  Future<BudgetMensuel?> getBudget(String uid, int mois, int annee);

  /// Sauvegarde un budget
  Future<void> saveBudget(BudgetMensuel budget);

  /// Supprime un budget
  Future<void> deleteBudget(String uid, int mois, int annee);
}
