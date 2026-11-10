// lib/presentation/providers/transaction/transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../../data/repositories/transaction_repository_impl.dart';
import '../../../domain/usecases/transaction/add_transaction_usecase.dart';
import '../../../domain/usecases/transaction/get_transactions_usecase.dart';
import '../../../domain/usecases/transaction/delete_transaction_usecase.dart';
import '../../../domain/usecases/transaction/update_transaction_usecase.dart';
import '../wallet/wallet_provider.dart'; // ✅ Utiliser wallet_provider
import '../../../core/utils/logger.dart';

// ============================================
// PROVIDERS REPOSITORY & USE CASES
// ============================================

/// Provider du repository des transactions
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

/// Provider du Use Case pour ajouter une transaction
final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final walletRepo =
      ref.watch(walletRepositoryProvider); // ✅ Utilisé depuis wallet_provider
  return AddTransactionUseCase(
    transactionRepository: transactionRepo,
    walletRepository: walletRepo,
  );
});

/// Provider du Use Case pour récupérer les transactions
final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  return GetTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider du Use Case pour écouter les transactions
final watchTransactionsUseCaseProvider =
    Provider<WatchTransactionsUseCase>((ref) {
  return WatchTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

/// Provider du Use Case pour supprimer une transaction
final deleteTransactionUseCaseProvider =
    Provider<DeleteTransactionUseCase>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  return DeleteTransactionUseCase(
    transactionRepository: transactionRepo,
    walletRepository: walletRepo,
  );
});

/// Provider du Use Case pour mettre à jour une transaction
final updateTransactionUseCaseProvider =
    Provider<UpdateTransactionUseCase>((ref) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

// ============================================
// STREAM PROVIDERS (Temps réel)
// ============================================

/// Liste des transactions en temps réel
final transactionListProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, uid) {
  final useCase = ref.watch(watchTransactionsUseCaseProvider);
  return useCase.execute(uid, limit: 50);
});

/// Liste des transactions avec limite personnalisée
final transactionListWithLimitProvider =
    StreamProvider.family<List<TransactionModel>, TransactionListParams>(
  (ref, params) {
    final useCase = ref.watch(watchTransactionsUseCaseProvider);
    return useCase.execute(params.uid, limit: params.limit);
  },
);

// ============================================
// FUTURE PROVIDERS (Actions)
// ============================================

/// Provider pour ajouter une transaction
final addTransactionProvider =
    FutureProvider.family<AddTransactionResult, AddTransactionParams>(
  (ref, params) async {
    final useCase = ref.watch(addTransactionUseCaseProvider);
    final result = await useCase.execute(params);

    if (result.success) {
      Logger.success('✅ Transaction ajoutée: ${result.transaction?.id}');
      ref
          .read(transactionStateProvider.notifier)
          .addTransactionLocally(result.transaction!);
    } else {
      Logger.error('❌ Erreur ajout transaction: ${result.message}');
    }

    return result;
  },
);

/// Provider pour récupérer les transactions (une seule fois)
final getTransactionsProvider =
    FutureProvider.family<GetTransactionsResult, GetTransactionsParams>(
  (ref, params) async {
    final useCase = ref.watch(getTransactionsUseCaseProvider);
    return await useCase.execute(
      uid: params.uid,
      limit: params.limit,
      filters: params.filters,
    );
  },
);

/// Provider pour supprimer une transaction
final deleteTransactionProvider =
    FutureProvider.family<DeleteTransactionResult, String>(
  (ref, transactionId) async {
    final useCase = ref.watch(deleteTransactionUseCaseProvider);
    final result = await useCase.execute(transactionId);

    if (result.success) {
      Logger.success('🗑️ Transaction supprimée: $transactionId');
      ref
          .read(transactionStateProvider.notifier)
          .deleteTransactionLocally(transactionId);
    } else {
      Logger.error('❌ Erreur suppression transaction: ${result.message}');
    }

    return result;
  },
);

/// Provider pour mettre à jour une transaction
final updateTransactionProvider =
    FutureProvider.family<UpdateTransactionResult, UpdateTransactionParams>(
  (ref, params) async {
    final useCase = ref.watch(updateTransactionUseCaseProvider);
    final result = await useCase.execute(params);

    if (result.success) {
      Logger.success('📝 Transaction mise à jour: ${result.transaction?.id}');
      ref
          .read(transactionStateProvider.notifier)
          .updateTransactionLocally(result.transaction!);
    } else {
      Logger.error('❌ Erreur mise à jour transaction: ${result.message}');
    }

    return result;
  },
);

// ============================================
// NOTIFIER PROVIDER (État local des transactions)
// ============================================

/// Provider pour l'état des transactions
final transactionStateProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});

/// État des transactions
class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;
  final double totalRevenus;
  final double totalDepenses;
  final double solde;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.totalRevenus = 0,
    this.totalDepenses = 0,
    this.solde = 0,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
    double? totalRevenus,
    double? totalDepenses,
    double? solde,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalRevenus: totalRevenus ?? this.totalRevenus,
      totalDepenses: totalDepenses ?? this.totalDepenses,
      solde: solde ?? this.solde,
    );
  }

  /// Calcule les totaux à partir de la liste
  factory TransactionState.calculate(List<TransactionModel> transactions) {
    double revenus = 0;
    double depenses = 0;

    for (final tx in transactions) {
      if (tx.isRevenu) {
        revenus += tx.montant;
      } else if (tx.isDepense) {
        depenses += tx.montant;
      }
    }

    return TransactionState(
      transactions: transactions,
      totalRevenus: revenus,
      totalDepenses: depenses,
      solde: revenus - depenses,
    );
  }
}

/// Notifier pour l'état des transactions
class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super(const TransactionState());

  /// Charge les transactions
  Future<void> loadTransactions(String uid,
      {int limit = 50, TransactionFilters? filters}) async {
    if (uid.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _ref.read(getTransactionsProvider(
        GetTransactionsParams(uid: uid, limit: limit, filters: filters),
      ).future);

      if (result.success) {
        state = TransactionState.calculate(result.transactions);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Ajoute une transaction localement (optimiste)
  void addTransactionLocally(TransactionModel transaction) {
    final updatedTransactions = [transaction, ...state.transactions];
    state = TransactionState.calculate(updatedTransactions);
  }

  /// Met à jour une transaction localement
  void updateTransactionLocally(TransactionModel updatedTransaction) {
    final updatedTransactions = state.transactions.map((tx) {
      return tx.id == updatedTransaction.id ? updatedTransaction : tx;
    }).toList();

    state = TransactionState.calculate(updatedTransactions);
  }

  /// Supprime une transaction localement
  void deleteTransactionLocally(String transactionId) {
    final updatedTransactions =
        state.transactions.where((tx) => tx.id != transactionId).toList();
    state = TransactionState.calculate(updatedTransactions);
  }

  /// Filtre les transactions
  List<TransactionModel> filterTransactions({
    String? categorieId,
    TransactionType? type,
    String? walletId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    return state.transactions.where((tx) {
      if (categorieId != null && tx.categorieId != categorieId) return false;
      if (type != null && tx.type != type) return false;
      if (walletId != null && tx.walletId != walletId) return false;
      if (dateDebut != null && tx.dateTransaction.isBefore(dateDebut))
        return false;
      if (dateFin != null && tx.dateTransaction.isAfter(dateFin)) return false;
      return true;
    }).toList();
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Réinitialise l'état
  void reset() {
    state = const TransactionState();
  }
}

// ============================================
// PARAMÈTRES
// ============================================

/// Paramètres pour la récupération des transactions
class GetTransactionsParams {
  final String uid;
  final int limit;
  final TransactionFilters? filters;

  const GetTransactionsParams({
    required this.uid,
    this.limit = 50,
    this.filters,
  });
}

/// Paramètres pour l'écoute des transactions
class TransactionListParams {
  final String uid;
  final int limit;

  const TransactionListParams({
    required this.uid,
    this.limit = 50,
  });
}

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

/// Provider pour le solde total des transactions
final transactionBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(transactionStateProvider);
  return state.solde;
});

/// Provider pour le total des revenus
final totalRevenusProvider = Provider<double>((ref) {
  final state = ref.watch(transactionStateProvider);
  return state.totalRevenus;
});

/// Provider pour le total des dépenses
final totalDepensesProvider = Provider<double>((ref) {
  final state = ref.watch(transactionStateProvider);
  return state.totalDepenses;
});

/// Provider pour le nombre de transactions
final transactionCountProvider = Provider<int>((ref) {
  final state = ref.watch(transactionStateProvider);
  return state.transactions.length;
});

/// Provider pour les transactions d'un portefeuille
final walletTransactionsProvider =
    Provider.family<List<TransactionModel>, String>((ref, walletId) {
  final state = ref.watch(transactionStateProvider);
  return state.transactions.where((tx) => tx.walletId == walletId).toList();
});

/// Provider pour les transactions d'une catégorie
final categoryTransactionsProvider =
    Provider.family<List<TransactionModel>, String>((ref, categorieId) {
  final state = ref.watch(transactionStateProvider);
  return state.transactions
      .where((tx) => tx.categorieId == categorieId)
      .toList();
});

/// Provider pour les transactions du mois
final currentMonthTransactionsProvider =
    Provider<List<TransactionModel>>((ref) {
  final state = ref.watch(transactionStateProvider);
  final now = DateTime.now();
  return state.transactions.where((tx) {
    return tx.dateTransaction.month == now.month &&
        tx.dateTransaction.year == now.year;
  }).toList();
});
