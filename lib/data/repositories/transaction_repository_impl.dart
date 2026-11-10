// lib/data/repositories/transaction_repository_impl.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/date_parser.dart';

/// Implémentation du repository des transactions
class TransactionRepositoryImpl implements ITransactionRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  TransactionRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource =
            firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Stream<List<TransactionModel>> getUserTransactions(String uid,
      {int limit = 50}) {
    return _firestoreDatasource
        .listenToTransactions(uid, limit: limit)
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          walletId: data['walletId'] ?? '',
          montant: (data['montant'] as num?)?.toDouble() ?? 0,
          type: _parseTransactionType(data['type'] as String? ?? 'depense'),
          categorieId: data['categorieId'] ?? '',
          categorieLabel: data['categorieLabel'] ?? 'Autre',
          categorieEmoji: data['categorieEmoji'] ?? '📌',
          note: data['note'],
          dateTransaction: parseFirestoreDate(data['dateTransaction']),
          createdAt: parseFirestoreDate(data['createdAt']),
        );
      }).toList();
    });
  }

  @override
  Future<List<TransactionModel>> getTransactionsOnce(String uid,
      {int limit = 50}) async {
    try {
      return await _firestoreDatasource.getTransactions(uid, limit: limit);
    } catch (e) {
      Logger.error('❌ Erreur récupération transactions: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _firestoreDatasource.saveTransaction(transaction);
      Logger.info('📝 Transaction ajoutée: ${transaction.id}');

      // Mettre à jour le solde du portefeuille
      await _updateWalletBalance(transaction);
    } catch (e) {
      Logger.error('❌ Erreur ajout transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestoreDatasource.saveTransaction(transaction);
      Logger.info('📝 Transaction mise à jour: ${transaction.id}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestoreDatasource.deleteTransaction(transactionId);
      Logger.info('🗑️ Transaction supprimée: $transactionId');
    } catch (e) {
      Logger.error('❌ Erreur suppression transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<List<TransactionModel>> getWalletTransactions(String walletId) async {
    try {
      return await _firestoreDatasource.getWalletTransactions(walletId);
    } catch (e) {
      Logger.error('❌ Erreur récupération transactions portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<double> getDepensesByCategorie(
      String categorieId, int mois, int annee) async {
    try {
      // Cette méthode nécessite l'UID de l'utilisateur
      Logger.info('📊 Calcul des dépenses par catégorie: $categorieId');
      return 0.0;
    } catch (e) {
      Logger.error('❌ Erreur calcul dépenses par catégorie: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<double> getTotalDepenses(int mois, int annee) async {
    try {
      Logger.info('📊 Calcul des dépenses totales: $mois/$annee');
      return 0.0;
    } catch (e) {
      Logger.error('❌ Erreur calcul dépenses totales: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<double> getTotalRevenus(int mois, int annee) async {
    try {
      Logger.info('📊 Calcul des revenus totaux: $mois/$annee');
      return 0.0;
    } catch (e) {
      Logger.error('❌ Erreur calcul revenus totaux: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // MÉTHODES PRIVÉES
  // ============================================

  TransactionType _parseTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'revenu':
        return TransactionType.revenu;
      case 'transfert':
        return TransactionType.transfert;
      default:
        return TransactionType.depense;
    }
  }

  Future<void> _updateWalletBalance(TransactionModel transaction) async {
    try {
      final walletDoc =
          await _firestoreDatasource.wallets.doc(transaction.walletId).get();
      if (!walletDoc.exists) {
        Logger.warning('⚠️ Portefeuille non trouvé: ${transaction.walletId}');
        return;
      }

      final data = walletDoc.data()!;
      final currentBalance = (data['solde'] as num?)?.toDouble() ?? 0;
      final newBalance = transaction.isRevenu
          ? currentBalance + transaction.montant
          : currentBalance - transaction.montant;

      await _firestoreDatasource.wallets.doc(transaction.walletId).update({
        'solde': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('💰 Solde mis à jour: $newBalance');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour solde: $e');
    }
  }
}
