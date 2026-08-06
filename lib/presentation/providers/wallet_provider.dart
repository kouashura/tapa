import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

// Provider pour la liste des portefeuilles (temps réel)
final walletListProvider = StreamProvider.family<List<WalletModel>, String>((ref, uid) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getUserWallets(uid);
});

// Provider pour ajouter un portefeuille
final addWalletProvider = FutureProvider.family<void, AddWalletParams>((ref, params) async {
  final repository = ref.watch(walletRepositoryProvider);
  await repository.addWallet(
    uid: params.uid,
    nom: params.nom,
    emoji: params.emoji,
    type: params.type,
    solde: params.solde,
    monnaie: params.monnaie,
    description: params.description,
  );
});

// Provider pour mettre à jour un portefeuille
final updateWalletProvider = FutureProvider.family<void, UpdateWalletParams>((ref, params) async {
  final repository = ref.watch(walletRepositoryProvider);
  await repository.updateWallet(
    walletId: params.walletId,
    nom: params.nom,
    emoji: params.emoji,
    type: params.type,
    solde: params.solde,
    monnaie: params.monnaie,
    description: params.description,
  );
});

// Provider pour supprimer un portefeuille
final deleteWalletProvider = FutureProvider.family<void, String>((ref, walletId) async {
  final repository = ref.watch(walletRepositoryProvider);
  await repository.deleteWallet(walletId);
});

// Paramètres pour l'ajout
class AddWalletParams {
  final String uid;
  final String nom;
  final String emoji;
  final String type;
  final double solde;
  final String? monnaie;
  final String? description;

  AddWalletParams({
    required this.uid,
    required this.nom,
    required this.emoji,
    required this.type,
    required this.solde,
    this.monnaie,
    this.description,
  });
}

// Paramètres pour la mise à jour
class UpdateWalletParams {
  final String walletId;
  final String? nom;
  final String? emoji;
  final String? type;
  final double? solde;
  final String? monnaie;
  final String? description;

  UpdateWalletParams({
    required this.walletId,
    this.nom,
    this.emoji,
    this.type,
    this.solde,
    this.monnaie,
    this.description,
  });
}
