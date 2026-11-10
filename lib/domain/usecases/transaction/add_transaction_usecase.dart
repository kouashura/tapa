// lib/domain/usecases/transaction/add_transaction_usecase.dart

import '../../repositories/i_transaction_repository.dart';
import '../../repositories/i_wallet_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Types de transaction pour le paramètre
enum TransactionTypeParam {
  revenu,
  depense,
  transfert,
}

/// Paramètres pour l'ajout d'une transaction
class AddTransactionParams {
  final String uid;
  final String walletId;
  final double montant;
  final TransactionTypeParam type;
  final String categorieId;
  final String categorieLabel;
  final String categorieEmoji;
  final String? note;
  final DateTime? dateTransaction;
  final String? walletDestinationId;

  const AddTransactionParams({
    required this.uid,
    required this.walletId,
    required this.montant,
    required this.type,
    required this.categorieId,
    required this.categorieLabel,
    required this.categorieEmoji,
    this.note,
    this.dateTransaction,
    this.walletDestinationId,
  });

  /// Vérifie si les paramètres sont valides
  bool get isValid {
    if (uid.isEmpty) return false;
    if (walletId.isEmpty) return false;
    if (montant <= 0) return false;
    if (categorieId.isEmpty) return false;

    // Pour un transfert, il faut un wallet de destination
    if (type == TransactionTypeParam.transfert) {
      if (walletDestinationId == null || walletDestinationId!.isEmpty) {
        return false;
      }
      if (walletDestinationId == walletId) {
        return false;
      }
    }

    return true;
  }

  /// Convertit en TransactionType
  TransactionType get transactionType {
    switch (type) {
      case TransactionTypeParam.revenu:
        return TransactionType.revenu;
      case TransactionTypeParam.depense:
        return TransactionType.depense;
      case TransactionTypeParam.transfert:
        return TransactionType.transfert;
    }
  }
}

/// Résultat de l'ajout d'une transaction
class AddTransactionResult {
  final TransactionModel? transaction;
  final bool success;
  final String? message;
  final double? nouveauSolde;

  const AddTransactionResult({
    this.transaction,
    this.success = false,
    this.message,
    this.nouveauSolde,
  });

  /// Succès
  factory AddTransactionResult.success(
    TransactionModel transaction, {
    double? nouveauSolde,
  }) {
    final typeLabel = transaction.isRevenu
        ? 'revenu'
        : transaction.isTransfert
            ? 'transfert'
            : 'dépense';
    return AddTransactionResult(
      transaction: transaction,
      success: true,
      message: '✅ $typeLabel de ${transaction.montant} FCFA enregistré !',
      nouveauSolde: nouveauSolde,
    );
  }

  /// Erreur
  factory AddTransactionResult.error(String message) {
    return AddTransactionResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Ajouter une transaction
class AddTransactionUseCase {
  final ITransactionRepository _transactionRepository;
  final IWalletRepository _walletRepository;

  AddTransactionUseCase({
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
  })  : _transactionRepository = transactionRepository,
        _walletRepository = walletRepository;

  /// Exécute l'ajout d'une transaction
  Future<AddTransactionResult> execute(AddTransactionParams params) async {
    try {
      Logger.info('📝 Ajout d\'une transaction: ${params.montant} FCFA');

      // Valider les paramètres
      if (!params.isValid) {
        return AddTransactionResult.error(
          'Veuillez remplir tous les champs obligatoires.',
        );
      }

      // Vérifier le solde du portefeuille pour une dépense
      if (params.type == TransactionTypeParam.depense ||
          params.type == TransactionTypeParam.transfert) {
        final wallet = await _walletRepository.getWalletById(params.walletId);
        if (wallet == null) {
          return AddTransactionResult.error('Portefeuille non trouvé.');
        }

        if (wallet.solde < params.montant) {
          return AddTransactionResult.error(
            'Solde insuffisant. Solde actuel: ${wallet.solde} FCFA',
          );
        }
      }

      // Générer un ID unique
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Créer la transaction
      final transaction = TransactionModel(
        id: transactionId,
        uid: params.uid,
        walletId: params.walletId,
        montant: params.montant,
        type: params.transactionType,
        categorieId: params.categorieId,
        categorieLabel: params.categorieLabel,
        categorieEmoji: params.categorieEmoji,
        note: params.note,
        dateTransaction: params.dateTransaction ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Sauvegarder la transaction
      await _transactionRepository.addTransaction(transaction);

      // Récupérer le solde mis à jour
      final updatedWallet =
          await _walletRepository.getWalletById(params.walletId);
      double nouveauSolde = 0;
      if (updatedWallet != null) {
        nouveauSolde = updatedWallet.solde;
      }

      Logger.success('✅ Transaction enregistrée');

      return AddTransactionResult.success(
        transaction,
        nouveauSolde: nouveauSolde,
      );
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur ajout transaction: ${failure.message}');

      if (failure is DatabaseFailure) {
        return AddTransactionResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return AddTransactionResult.error(
        'Erreur lors de l\'enregistrement de la transaction.',
      );
    }
  }
}
