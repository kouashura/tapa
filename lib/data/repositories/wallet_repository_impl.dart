// lib/data/repositories/wallet_repository_impl.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository des portefeuilles
class WalletRepositoryImpl implements IWalletRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  WalletRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Stream<List<WalletModel>> getUserWallets(String uid) {
    return _firestoreDatasource.listenToWallets(uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WalletModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          nom: data['nom'] ?? '',
          emoji: data['emoji'] ?? '💵',
          type: data['type'] ?? 'autre',
          solde: (data['solde'] as num?)?.toDouble() ?? 0,
          monnaie: data['monnaie'] ?? 'FCFA',
          description: data['description'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  @override
  Future<List<WalletModel>> getWalletsOnce(String uid) async {
    try {
      return await _firestoreDatasource.getWallets(uid);
    } catch (e) {
      Logger.error('❌ Erreur récupération portefeuilles: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<String> addWallet(WalletModel wallet) async {
    try {
      await _firestoreDatasource.saveWallet(wallet);
      Logger.info('📝 Portefeuille ajouté: ${wallet.nom}');
      return wallet.id;
    } catch (e) {
      Logger.error('❌ Erreur ajout portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    try {
      await _firestoreDatasource.saveWallet(wallet);
      Logger.info('📝 Portefeuille mis à jour: ${wallet.nom}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    try {
      await _firestoreDatasource.deleteWallet(walletId);
      Logger.info('🗑️ Portefeuille supprimé: $walletId');
    } catch (e) {
      Logger.error('❌ Erreur suppression portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateBalance(String walletId, double newBalance) async {
    try {
      final wallet = await _firestoreDatasource.getWallets(walletId);
      // Mise à jour du solde
      await _firestoreDatasource.wallets.doc(walletId).update({
        'solde': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('📝 Solde mis à jour: $newBalance');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour solde: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}
