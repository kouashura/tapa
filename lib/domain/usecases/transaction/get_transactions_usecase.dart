// lib/domain/usecases/transaction/get_transactions_usecase.dart

import 'dart:async';
import '../../repositories/i_transaction_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Filtres pour les transactions
class TransactionFilters {
  final String? categorieId;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final TransactionType? type;
  final String? walletId;
  final double? montantMin;
  final double? montantMax;

  const TransactionFilters({
    this.categorieId,
    this.dateDebut,
    this.dateFin,
    this.type,
    this.walletId,
    this.montantMin,
    this.montantMax,
  });

  /// Vérifie si des filtres sont appliqués
  bool get hasFilters {
    return categorieId != null ||
        dateDebut != null ||
        dateFin != null ||
        type != null ||
        walletId != null ||
        montantMin != null ||
        montantMax != null;
  }
}

/// Résultat de la récupération des transactions
class GetTransactionsResult {
  final List<TransactionModel> transactions;
  final bool success;
  final String? message;
  final double totalRevenus;
  final double totalDepenses;
  final double solde;

  const GetTransactionsResult({
    this.transactions = const [],
    this.success = false,
    this.message,
    this.totalRevenus = 0,
    this.totalDepenses = 0,
    this.solde = 0,
  });

  /// Succès
  factory GetTransactionsResult.success(
    List<TransactionModel> transactions, {
    TransactionFilters? filters,
  }) {
    double revenus = 0;
    double depenses = 0;

    for (final tx in transactions) {
      if (tx.isRevenu) {
        revenus += tx.montant;
      } else if (tx.isDepense) {
        depenses += tx.montant;
      }
    }

    return GetTransactionsResult(
      transactions: transactions,
      success: true,
      totalRevenus: revenus,
      totalDepenses: depenses,
      solde: revenus - depenses,
    );
  }

  /// Erreur
  factory GetTransactionsResult.error(String message) {
    return GetTransactionsResult(
      success: false,
      message: message,
    );
  }

  /// Vide
  factory GetTransactionsResult.empty() {
    return const GetTransactionsResult(
      transactions: [],
      success: true,
    );
  }
}

/// Cas d'utilisation : Récupérer les transactions (une seule fois)
class GetTransactionsUseCase {
  final ITransactionRepository _transactionRepository;

  GetTransactionsUseCase(this._transactionRepository);

  /// Exécute la récupération (une seule fois)
  Future<GetTransactionsResult> execute({
    required String uid,
    int limit = 50,
    TransactionFilters? filters,
  }) async {
    try {
      Logger.info('📊 Récupération des transactions pour: $uid');

      if (uid.isEmpty) {
        return GetTransactionsResult.error('Utilisateur non identifié.');
      }

      // Récupérer les transactions
      var transactions = await _transactionRepository.getTransactionsOnce(
        uid,
        limit: limit,
      );

      // Appliquer les filtres
      if (filters != null && filters.hasFilters) {
        transactions = _applyFilters(transactions, filters);
      }

      if (transactions.isEmpty) {
        Logger.info('📭 Aucune transaction trouvée');
        return GetTransactionsResult.empty();
      }

      Logger.success('✅ ${transactions.length} transactions récupérées');
      return GetTransactionsResult.success(transactions, filters: filters);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur récupération transactions: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetTransactionsResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return GetTransactionsResult.error(
        'Erreur lors de la récupération des transactions.',
      );
    }
  }

  /// Applique les filtres sur la liste des transactions
  List<TransactionModel> _applyFilters(
    List<TransactionModel> transactions,
    TransactionFilters filters,
  ) {
    return transactions.where((tx) {
      // Filtre par catégorie
      if (filters.categorieId != null &&
          tx.categorieId != filters.categorieId) {
        return false;
      }

      // Filtre par type
      if (filters.type != null && tx.type != filters.type) {
        return false;
      }

      // Filtre par portefeuille
      if (filters.walletId != null && tx.walletId != filters.walletId) {
        return false;
      }

      // Filtre par date
      if (filters.dateDebut != null &&
          tx.dateTransaction.isBefore(filters.dateDebut!)) {
        return false;
      }
      if (filters.dateFin != null &&
          tx.dateTransaction.isAfter(filters.dateFin!)) {
        return false;
      }

      // Filtre par montant
      if (filters.montantMin != null &&
          tx.montant < filters.montantMin!) {
        return false;
      }
      if (filters.montantMax != null &&
          tx.montant > filters.montantMax!) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Cas d'utilisation : Écouter les transactions (Stream temps réel)
class WatchTransactionsUseCase {
  final ITransactionRepository _transactionRepository;

  WatchTransactionsUseCase(this._transactionRepository);

  /// Exécute l'écoute en temps réel
  Stream<List<TransactionModel>> execute(
    String uid, {
    int limit = 50,
  }) {
    Logger.info('👂 Écoute des transactions pour: $uid');
    return _transactionRepository.getUserTransactions(uid, limit: limit);
  }
}
