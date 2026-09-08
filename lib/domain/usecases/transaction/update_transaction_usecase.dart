// lib/domain/usecases/transaction/update_transaction_usecase.dart

import '../../repositories/i_transaction_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Paramètres pour la mise à jour d'une transaction
class UpdateTransactionParams {
  final String id;
  final String? categorieId;
  final String? categorieLabel;
  final String? categorieEmoji;
  final double? montant;
  final String? note;
  final DateTime? dateTransaction;

  const UpdateTransactionParams({
    required this.id,
    this.categorieId,
    this.categorieLabel,
    this.categorieEmoji,
    this.montant,
    this.note,
    this.dateTransaction,
  });

  /// Vérifie si au moins un champ est modifié
  bool get hasChanges {
    return categorieId != null ||
        categorieLabel != null ||
        categorieEmoji != null ||
        montant != null ||
        note != null ||
        dateTransaction != null;
  }
}

/// Résultat de la mise à jour d'une transaction
class UpdateTransactionResult {
  final TransactionModel? transaction;
  final bool success;
  final String? message;

  const UpdateTransactionResult({
    this.transaction,
    this.success = false,
    this.message,
  });

  /// Succès
  factory UpdateTransactionResult.success(TransactionModel transaction) {
    return UpdateTransactionResult(
      transaction: transaction,
      success: true,
      message: '✅ Transaction mise à jour !',
    );
  }

  /// Erreur
  factory UpdateTransactionResult.error(String message) {
    return UpdateTransactionResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Mettre à jour une transaction
class UpdateTransactionUseCase {
  final ITransactionRepository _transactionRepository;

  UpdateTransactionUseCase(this._transactionRepository);

  /// Exécute la mise à jour d'une transaction
  Future<UpdateTransactionResult> execute(UpdateTransactionParams params) async {
    try {
      Logger.info('📝 Mise à jour de la transaction: ${params.id}');

      if (params.id.isEmpty) {
        return UpdateTransactionResult.error('ID de transaction invalide.');
      }

      if (!params.hasChanges) {
        return UpdateTransactionResult.error('Aucune modification à appliquer.');
      }

      // Récupérer la transaction existante
      final transactions = await _transactionRepository.getTransactionsOnce(
        '',
        limit: 1000,
      );

      final existingTransaction = transactions.firstWhere(
        (tx) => tx.id == params.id,
        orElse: () => throw Exception('Transaction non trouvée'),
      );

      // Créer la transaction mise à jour
      final updatedTransaction = TransactionModel(
        id: existingTransaction.id,
        uid: existingTransaction.uid,
        walletId: existingTransaction.walletId,
        montant: params.montant ?? existingTransaction.montant,
        type: existingTransaction.type,
        categorieId: params.categorieId ?? existingTransaction.categorieId,
        categorieLabel: params.categorieLabel ?? existingTransaction.categorieLabel,
        categorieEmoji: params.categorieEmoji ?? existingTransaction.categorieEmoji,
        note: params.note ?? existingTransaction.note,
        dateTransaction: params.dateTransaction ?? existingTransaction.dateTransaction,
        createdAt: existingTransaction.createdAt,
      );

      // Sauvegarder
      await _transactionRepository.updateTransaction(updatedTransaction);

      Logger.success('✅ Transaction mise à jour: ${updatedTransaction.id}');

      return UpdateTransactionResult.success(updatedTransaction);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur mise à jour transaction: ${failure.message}');

      return UpdateTransactionResult.error(
        'Erreur lors de la mise à jour de la transaction.',
      );
    }
  }
}
