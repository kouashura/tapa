// lib/domain/usecases/wallet/get_wallets_usecase.dart

import 'dart:async';
import '../../repositories/i_wallet_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Résultat de la récupération des portefeuilles
class GetWalletsResult {
  final List<WalletModel> wallets;
  final bool success;
  final String? message;
  final double totalBalance;

  const GetWalletsResult({
    this.wallets = const [],
    this.success = false,
    this.message,
    this.totalBalance = 0,
  });

  /// Succès
  factory GetWalletsResult.success(List<WalletModel> wallets) {
    final total = wallets.fold(0.0, (sum, w) => sum + w.solde);
    return GetWalletsResult(
      wallets: wallets,
      success: true,
      totalBalance: total,
    );
  }

  /// Erreur
  factory GetWalletsResult.error(String message) {
    return GetWalletsResult(
      success: false,
      message: message,
    );
  }

  /// Vide
  factory GetWalletsResult.empty() {
    return const GetWalletsResult(
      wallets: [],
      success: true,
      totalBalance: 0,
    );
  }
}

/// Cas d'utilisation : Récupérer les portefeuilles (une seule fois)
class GetWalletsUseCase {
  final IWalletRepository _walletRepository;

  GetWalletsUseCase(this._walletRepository);

  /// Exécute la récupération (une seule fois)
  Future<GetWalletsResult> execute(String uid) async {
    try {
      Logger.info('📊 Récupération des portefeuilles pour: $uid');

      if (uid.isEmpty) {
        return GetWalletsResult.error('Utilisateur non identifié.');
      }

      final wallets = await _walletRepository.getWalletsOnce(uid);

      if (wallets.isEmpty) {
        Logger.info('📭 Aucun portefeuille trouvé');
        return GetWalletsResult.empty();
      }

      Logger.success('✅ ${wallets.length} portefeuilles récupérés');
      return GetWalletsResult.success(wallets);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur récupération portefeuilles: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetWalletsResult.error(
          'Erreur de base de données. Veuillez réessayer.',
        );
      }

      return GetWalletsResult.error(
        'Erreur lors de la récupération des portefeuilles.',
      );
    }
  }
}

/// Cas d'utilisation : Écouter les portefeuilles (Stream temps réel)
class WatchWalletsUseCase {
  final IWalletRepository _walletRepository;

  WatchWalletsUseCase(this._walletRepository);

  /// Exécute l'écoute en temps réel
  Stream<List<WalletModel>> execute(String uid) {
    Logger.info('👂 Écoute des portefeuilles pour: $uid');
    return _walletRepository.getUserWallets(uid);
  }
}
