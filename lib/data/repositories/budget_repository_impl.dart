// lib/data/repositories/budget_repository_impl.dart

import '../../domain/repositories/i_budget_repository.dart';
import '../models/models.dart';  // ✅ Utiliser models.dart au lieu de domain/entities
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository des budgets
class BudgetRepositoryImpl implements IBudgetRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  BudgetRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Future<BudgetMensuel?> getBudget(String uid, int mois, int annee) async {
    try {
      final budget = await _firestoreDatasource.getBudget(uid, mois, annee);
      return budget;  // ✅ Déjà un BudgetMensuel?
    } catch (e) {
      Logger.error('❌ Erreur récupération budget: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> saveBudget(BudgetMensuel budget) async {
    try {
      Logger.info('📝 Sauvegarde budget: ${budget.mois}/${budget.annee}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde budget: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteBudget(String uid, int mois, int annee) async {
    try {
      await _firestoreDatasource.deleteBudget(uid, mois, annee);
      Logger.info('🗑️ Budget supprimé: $mois/$annee');
    } catch (e) {
      Logger.error('❌ Erreur suppression budget: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}