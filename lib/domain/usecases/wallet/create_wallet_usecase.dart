// lib/domain/usecases/wallet/create_wallet_usecase.dart

import '../../repositories/i_wallet_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Paramètres pour la création d'un portefeuille
class CreateWalletParams {
  final String uid;
  final String nom;
  final String emoji;
  final String type;
  final double solde;
  final String monnaie;
  final String description;

  const CreateWalletParams({
    required this.uid,
    required this.nom,
    required this.emoji,
    required this.type,
    required this.solde,
    required this.monnaie,
    this.description = '',
  });

  /// Vérifie si les paramètres sont valides
  bool get isValid {
    if (uid.isEmpty) return false;
    if (nom.isEmpty || nom.length < 2) return false;
    if (solde < 0) return false;
    if (monnaie.isEmpty) return false;
    return true;
  }
}

/// Résultat de la création d'un portefeuille
class CreateWalletResult {
  final WalletModel? wallet;
  final bool success;
  final String? message;
  final String? walletId;

  const CreateWalletResult({
    this.wallet,
    this.success = false,
    this.message,
    this.walletId,
  });

  /// Succès
  factory CreateWalletResult.success(WalletModel wallet) {
    return CreateWalletResult(
      wallet: wallet,
      success: true,
      walletId: wallet.id,
      message: '✅ Portefeuille "${wallet.nom}" créé avec succès !',
    );
  }

  /// Erreur
  factory CreateWalletResult.error(String message) {
    return CreateWalletResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Créer un portefeuille
class CreateWalletUseCase {
  final IWalletRepository _walletRepository;

  CreateWalletUseCase(this._walletRepository);

  /// Exécute la création d'un portefeuille
  Future<CreateWalletResult> execute(CreateWalletParams params) async {
    try {
      Logger.info('📝 Création du portefeuille: ${params.nom}');

      // Valider les paramètres
      if (!params.isValid) {
        return CreateWalletResult.error(
          'Veuillez remplir tous les champs obligatoires.',
        );
      }

      // Générer un ID unique AVANT la sauvegarde
      final walletId = DateTime.now().millisecondsSinceEpoch.toString();

      // Créer le portefeuille avec l'ID
      final wallet = WalletModel(
        id: walletId,
        uid: params.uid,
        nom: params.nom,
        emoji: params.emoji,
        type: params.type,
        solde: params.solde,
        monnaie: params.monnaie,
        description: params.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder
      await _walletRepository.addWallet(wallet);

      // Récupérer le portefeuille créé
      final createdWallet = wallet;

      Logger.success(
          '✅ Portefeuille créé: ${createdWallet.nom} (ID: $walletId)');

      return CreateWalletResult.success(createdWallet);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur création portefeuille: ${failure.message}');

      if (failure is DatabaseFailure) {
        return CreateWalletResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return CreateWalletResult.error(
        'Erreur lors de la création du portefeuille.',
      );
    }
  }
}
