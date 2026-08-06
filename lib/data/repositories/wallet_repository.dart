import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../datasources/firebase/firebase_firestore.dart';

class WalletRepository {
  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();

  // Récupérer les portefeuilles en temps réel
  Stream<List<WalletModel>> getUserWallets(String uid) {
    final stream = _firestore.wallets
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();

    return stream.map((snapshot) {
      final List<WalletModel> wallets = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final wallet = WalletModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          nom: data['nom'] ?? '',
          emoji: data['emoji'] ?? '💵',
          type: data['type'] ?? 'autre',
          solde: (data['solde'] as num?)?.toDouble() ?? 0,
          monnaie: data['monnaie'] ?? 'FCFA',
          description: data['description'] ?? '',
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          updatedAt: data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
        );
        wallets.add(wallet);
      }

      return wallets;
    });
  }

  // Ajouter un portefeuille
  Future<String> addWallet({
    required String uid,
    required String nom,
    required String emoji,
    required String type,
    required double solde,
    String? monnaie,
    String? description,
  }) async {
    final walletId = _firestore.generateId();
    final data = {
      'uid': uid,
      'nom': nom,
      'emoji': emoji,
      'type': type,
      'solde': solde,
      'monnaie': monnaie ?? 'FCFA',
      'description': description ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.saveWallet(data, walletId);
    return walletId;
  }

  // Mettre à jour un portefeuille
  Future<void> updateWallet({
    required String walletId,
    String? nom,
    String? emoji,
    String? type,
    double? solde,
    String? monnaie,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (nom != null) data['nom'] = nom;
    if (emoji != null) data['emoji'] = emoji;
    if (type != null) data['type'] = type;
    if (solde != null) data['solde'] = solde;
    if (monnaie != null) data['monnaie'] = monnaie;
    if (description != null) data['description'] = description;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.saveWallet(data, walletId);
  }

  // Supprimer un portefeuille
  Future<void> deleteWallet(String walletId) async {
    await _firestore.deleteWallet(walletId);
  }

  // Ajouter une transaction
  Future<void> addTransaction({
    required String uid,
    required String walletId,
    required String type,
    required double montant,
    required String monnaie,
    String? description,
    String? categorieId,
    String? categorieNom,
    DateTime? dateTransaction,
  }) async {
    final txId = _firestore.generateId();
    final data = {
      'uid': uid,
      'walletId': walletId,
      'type': type,
      'montant': montant,
      'monnaie': monnaie,
      'description': description ?? '',
      'categorieId': categorieId ?? '',
      'categorieNom': categorieNom ?? '',
      'dateTransaction': dateTransaction ?? DateTime.now(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.saveTransaction(data, txId);

    // Mettre à jour le solde du portefeuille
    final walletDocs = await _firestore.wallets
        .where('uid', isEqualTo: uid)
        .get();

    final walletDoc = walletDocs.docs.firstWhere(
          (doc) => doc.id == walletId,
      orElse: () => throw Exception('Portefeuille non trouvé'),
    );

    final walletData = walletDoc.data();
    final currentBalance = (walletData['solde'] as num?)?.toDouble() ?? 0;
    final newBalance = type == 'revenu'
        ? currentBalance + montant
        : currentBalance - montant;

    await updateWallet(
      walletId: walletId,
      solde: newBalance,
    );
  }

  // Récupérer les transactions d'un portefeuille
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getWalletTransactions(
      String uid,
      String walletId, {
        int limit = 50,
      }) async {
    final docs = await _firestore.transactions
        .where('uid', isEqualTo: uid)
        .where('walletId', isEqualTo: walletId)
        .orderBy('dateTransaction', descending: true)
        .limit(limit)
        .get();
    return docs.docs;
  }
}