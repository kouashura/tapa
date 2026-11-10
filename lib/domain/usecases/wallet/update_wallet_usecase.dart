// lib/domain/usecases/wallet/update_wallet_usecase.dart

import '../../repositories/i_wallet_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Paramètres pour la mise à jour d'un portefeuille
class UpdateWalletParams {
  final String walletId;
  final String? nom;
  final String? emoji;
  final String? type;
  final double? solde;
  final String? monnaie;
  final String? description;

  const UpdateWalletParams({
    required this.walletId,
    this.nom,
    this.emoji,
    this.type,
    this.solde,
    this.monnaie,
    this.description,
  });

  /// Vérifie si au moins un champ est modifié
  bool get hasChanges {
    return nom != null ||
        emoji != null ||
        type != null ||
        solde != null ||
        monnaie != null ||
        description != null;
  }

  /// Vérifie si les paramètres sont valides
  bool get isValid {
    if (walletId.isEmpty) return false;
    return hasChanges;
  }
}

/// Résultat de la mise à jour d'un portefeuille
class UpdateWalletResult {
  final WalletModel? wallet;
  final bool success;
  final String? message;

  const UpdateWalletResult({
    this.wallet,
    this.success = false,
    this.message,
  });

  /// Succès
  factory UpdateWalletResult.success(WalletModel wallet) {
    return UpdateWalletResult(
      wallet: wallet,
      success: true,
      message: '✅ Portefeuille "${wallet.nom}" mis à jour !',
    );
  }

  /// Erreur
  factory UpdateWalletResult.error(String message) {
    return UpdateWalletResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Mettre à jour un portefeuille
class UpdateWalletUseCase {
  final IWalletRepository _walletRepository;

  UpdateWalletUseCase(this._walletRepository);

  /// Exécute la mise à jour d'un portefeuille
  Future<UpdateWalletResult> execute(UpdateWalletParams params) async {
    try {
      Logger.info('📝 Mise à jour du portefeuille: ${params.walletId}');

      // Valider les paramètres
      if (!params.isValid) {
        return UpdateWalletResult.error(
          'Aucune modification à appliquer.',
        );
      }

      // Récupérer le portefeuille existant par son ID
      final existingWallet =
          await _walletRepository.getWalletById(params.walletId);
      if (existingWallet == null) {
        return UpdateWalletResult.error(
          'Portefeuille non trouvé.',
        );
      }

      // Créer le portefeuille mis à jour
      final updatedWallet = existingWallet.copyWith(
        nom: params.nom ?? existingWallet.nom,
        emoji: params.emoji ?? existingWallet.emoji,
        type: params.type ?? existingWallet.type,
        solde: params.solde ?? existingWallet.solde,
        monnaie: params.monnaie ?? existingWallet.monnaie,
        description: params.description ?? existingWallet.description,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder
      await _walletRepository.updateWallet(updatedWallet);

      Logger.success('✅ Portefeuille mis à jour: ${updatedWallet.nom}');

      return UpdateWalletResult.success(updatedWallet);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur mise à jour portefeuille: ${failure.message}');

      if (failure is DatabaseFailure) {
        return UpdateWalletResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return UpdateWalletResult.error(
        'Erreur lors de la mise à jour du portefeuille.',
      );
    }
  }
}

/// Cas d'utilisation : Mettre à jour le solde d'un portefeuille
class UpdateWalletBalanceUseCase {
  final IWalletRepository _walletRepository;

  UpdateWalletBalanceUseCase(this._walletRepository);

  /// Exécute la mise à jour du solde
  Future<UpdateWalletResult> execute({
    required String walletId,
    required double newBalance,
  }) async {
    try {
      Logger.info('💰 Mise à jour du solde: $walletId → $newBalance');

      if (walletId.isEmpty) {
        return UpdateWalletResult.error('ID du portefeuille invalide.');
      }

      if (newBalance < 0) {
        return UpdateWalletResult.error('Le solde ne peut pas être négatif.');
      }

      // Récupérer le portefeuille par son ID
      final wallet = await _walletRepository.getWalletById(walletId);
      if (wallet == null) {
        return UpdateWalletResult.error('Portefeuille non trouvé.');
      }

      final updatedWallet = wallet.copyWith(
        solde: newBalance,
        updatedAt: DateTime.now(),
      );

      // Sauvegarder
      await _walletRepository.updateWallet(updatedWallet);

      Logger.success('✅ Solde mis à jour: $newBalance');

      return UpdateWalletResult.success(updatedWallet);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur mise à jour solde: ${failure.message}');

      return UpdateWalletResult.error(
        'Erreur lors de la mise à jour du solde.',
      );
    }
  }
}
