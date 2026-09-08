// lib/domain/repositories/i_wallet_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class IWalletRepository {
  Stream<List<WalletModel>> getUserWallets(String uid);
  Future<List<WalletModel>> getWalletsOnce(String uid);
  Future<String> addWallet(WalletModel wallet);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String walletId);
  Future<void> updateBalance(String walletId, double newBalance);
}
