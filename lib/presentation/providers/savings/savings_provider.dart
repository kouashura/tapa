// lib/presentation/providers/savings/savings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/savings_repository_impl.dart';
import '../../../domain/repositories/i_savings_repository.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final savingsRepositoryProvider = Provider<ISavingsRepository>((ref) {
  return SavingsRepositoryImpl();
});

// ============================================
// STREAM PROVIDERS (Temps réel)
// ============================================

/// Objectifs d'épargne en temps réel
final userSavingsGoalsProvider =
    StreamProvider.family<List<SavingsGoalModel>, String>((ref, uid) {
  final repo = ref.watch(savingsRepositoryProvider);
  return repo.getUserGoals(uid);
});

/// Épargne programmée en temps réel
final userEpargneProgrammeeProvider =
    StreamProvider.family<List<EpargneProgrammeeModel>, String>((ref, uid) {
  final repo = ref.watch(savingsRepositoryProvider);
  return repo.getUserEpargne(uid);
});

// ============================================
// ACTIONS PROVIDERS
// ============================================

/// Ajouter un objectif d'épargne
final addSavingsGoalProvider =
    FutureProvider.family<void, SavingsGoalModel>((ref, goal) async {
  final repo = ref.read(savingsRepositoryProvider);
  await repo.addGoal(goal);
  // Rafraîchir la liste
  ref.invalidate(userSavingsGoalsProvider(goal.uid));
});

/// Supprimer un objectif d'épargne
final deleteSavingsGoalProvider =
    FutureProvider.family<void, String>((ref, goalId) async {
  final repo = ref.read(savingsRepositoryProvider);
  await repo.deleteGoal(goalId);
});
