// lib/domain/usecases/transaction/delete_transaction_usecase.dart

import '../../repositories/i_transaction_repository.dart';
import '../../repositories/i_wallet_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Résultat de la suppression d'une transaction
class DeleteTransactionResult {
  final bool success;
  final String? message;
  final double? nouveauSolde;

  const DeleteTransactionResult({
    this.success = false,
    this.message,
    this.nouveauSolde,
  });

  /// Succès
  factory DeleteTransactionResult.success({double? nouveauSolde}) {
    return DeleteTransactionResult(
      success: true,
      message: '✅ Transaction supprimée !',
      nouveauSolde: nouveauSolde,
    );
  }

  /// Erreur
  factory DeleteTransactionResult.error(String message) {
    return DeleteTransactionResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Supprimer une transaction
class DeleteTransactionUseCase {
  final ITransactionRepository _transactionRepository;
  final IWalletRepository _walletRepository;

  DeleteTransactionUseCase({
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository;

  /// Exécute la suppression d'une transaction
  Future<DeleteTransactionResult> execute(String transactionId) async {
    try {
      Logger.info('🗑️ Suppression de la transaction: $transactionId');

      if (transactionId.isEmpty) {
        return DeleteTransactionResult.error('ID de transaction invalide.');
      }

      // Récupérer la transaction à supprimer
      final transactions = await _transactionRepository.getTransactionsOnce(
        '',
        limit: 1000,
      );

      final transaction = transactions.firstWhere(
        (tx) => tx.id == transactionId,
        orElse: () => throw Exception('Transaction non trouvée'),
      );

      // Supprimer la transaction
      await _transactionRepository.deleteTransaction(transactionId);

      // Récupérer le solde mis à jour du portefeuille
      final updatedWallets = await _walletRepository.getWalletsOnce(
        transaction.walletId,
      );
      double nouveauSolde = 0;
      if (updatedWallets.isNotEmpty) {
        nouveauSolde = updatedWallets.first.solde;
      }

      Logger.success('✅ Transaction supprimée: $transactionId');

      return DeleteTransactionResult.success(nouveauSolde: nouveauSolde);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur suppression transaction: ${failure.message}');

      if (failure is DatabaseFailure) {
        return DeleteTransactionResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return DeleteTransactionResult.error(
        'Erreur lors de la suppression de la transaction.',
      );
    }
  }
}
