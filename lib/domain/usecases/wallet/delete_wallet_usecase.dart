// lib/domain/usecases/wallet/delete_wallet_usecase.dart

import '../../repositories/i_wallet_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Résultat de la suppression d'un portefeuille
class DeleteWalletResult {
  final bool success;
  final String? message;

  const DeleteWalletResult({
    this.success = false,
    this.message,
  });

  /// Succès
  factory DeleteWalletResult.success() {
    return const DeleteWalletResult(
      success: true,
      message: '✅ Portefeuille supprimé !',
    );
  }

  /// Erreur
  factory DeleteWalletResult.error(String message) {
    return DeleteWalletResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Supprimer un portefeuille
class DeleteWalletUseCase {
  final IWalletRepository _walletRepository;

  DeleteWalletUseCase(this._walletRepository);

  /// Exécute la suppression d'un portefeuille
  Future<DeleteWalletResult> execute(String walletId) async {
    try {
      Logger.info('🗑️ Suppression du portefeuille: $walletId');

      if (walletId.isEmpty) {
        return DeleteWalletResult.error('ID du portefeuille invalide.');
      }

      await _walletRepository.deleteWallet(walletId);

      Logger.success('✅ Portefeuille supprimé: $walletId');

      return DeleteWalletResult.success();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur suppression portefeuille: ${failure.message}');

      if (failure is DatabaseFailure) {
        return DeleteWalletResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return DeleteWalletResult.error(
        'Erreur lors de la suppression du portefeuille.',
      );
    }
  }
}
