// lib/domain/repositories/i_savings_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class ISavingsRepository {
  // Objectifs d'épargne
  Stream<List<SavingsGoalModel>> getUserGoals(String uid);
  Future<List<SavingsGoalModel>> getGoalsOnce(String uid);
  Future<void> addGoal(SavingsGoalModel goal);
  Future<void> updateGoal(SavingsGoalModel goal);
  Future<void> deleteGoal(String goalId);

  // Épargne programmée
  Stream<List<EpargneProgrammeeModel>> getUserEpargne(String uid);
  Future<List<EpargneProgrammeeModel>> getEpargneOnce(String uid);
  Future<void> addEpargne(EpargneProgrammeeModel epargne);
  Future<void> updateEpargne(EpargneProgrammeeModel epargne);
  Future<void> deleteEpargne(String epargneId);
  Future<void> effectuerDepot(String epargneId, double montant);
}
