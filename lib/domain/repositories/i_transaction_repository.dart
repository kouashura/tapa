// lib/domain/repositories/i_transaction_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class ITransactionRepository {
  Stream<List<TransactionModel>> getUserTransactions(String uid, {int limit = 50});
  Future<List<TransactionModel>> getTransactionsOnce(String uid, {int limit = 50});
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);
  Future<List<TransactionModel>> getWalletTransactions(String walletId);
  Future<double> getDepensesByCategorie(String categorieId, int mois, int annee);
  Future<double> getTotalDepenses(int mois, int annee);
  Future<double> getTotalRevenus(int mois, int annee);
}
