// lib/data/datasources/remote/firebase/firebase_firestore_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/date_parser.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../models/models.dart';

/// Datasource pour Firestore
/// Gère toutes les interactions avec Firebase Firestore
class FirebaseFirestoreDatasource {
  static final FirebaseFirestoreDatasource _instance =
      FirebaseFirestoreDatasource._internal();

  factory FirebaseFirestoreDatasource() => _instance;

  FirebaseFirestoreDatasource._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // COLLECTIONS
  // ============================================

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get wallets =>
      _firestore.collection('wallets');
  CollectionReference<Map<String, dynamic>> get transactions =>
      _firestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get savingsGoals =>
      _firestore.collection('savings_goals');
  CollectionReference<Map<String, dynamic>> get dettes =>
      _firestore.collection('dettes');
  CollectionReference<Map<String, dynamic>> get budgets =>
      _firestore.collection('budgets');
  CollectionReference<Map<String, dynamic>> get souscriptions =>
      _firestore.collection('souscriptions');
  CollectionReference<Map<String, dynamic>> get config =>
      _firestore.collection('config');
  CollectionReference<Map<String, dynamic>> get echeances =>
      _firestore.collection('echeances');
  CollectionReference<Map<String, dynamic>> get epargneProgrammee =>
      _firestore.collection('epargne_programmee');

  // ============================================
  // UTILISATEURS
  // ============================================

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await users.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!, uid);
    } catch (e) {
      Logger.error('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  Future<List<AppUser>> findUserByPhone(String phoneNumber) async {
    try {
      final query =
          await users.where('phoneNumber', isEqualTo: phoneNumber).get();
      return query.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur recherche utilisateur: $e');
      return [];
    }
  }

  Future<void> saveUser(AppUser user) async {
    try {
      await users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
      Logger.info('📝 Utilisateur sauvegardé: ${user.prenom} (${user.id})');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await users.doc(uid).delete();

      final collections = [
        wallets,
        transactions,
        savingsGoals,
        dettes,
        budgets,
        echeances,
        epargneProgrammee,
        categories,
      ];

      final batch = _firestore.batch();
      for (final collection in collections) {
        final snapshot = await collection.where('uid', isEqualTo: uid).get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();

      Logger.info('🗑️ Utilisateur et données supprimés: $uid');
    } catch (e) {
      Logger.error('❌ Erreur suppression utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // PORTEFEUILLES
  // ============================================

  Future<WalletModel?> getWalletById(String walletId) async {
    try {
      final doc = await wallets.doc(walletId).get();
      if (!doc.exists) {
        Logger.warning('Portefeuille introuvable: $walletId');
        return null;
      }
      final data = doc.data()!;
      return WalletModel(
        id: doc.id,
        uid: data['uid'] ?? '',
        nom: data['nom'] ?? '',
        emoji: data['emoji'] ?? '💵',
        type: data['type'] ?? 'autre',
        solde: (data['solde'] as num?)?.toDouble() ?? 0,
        monnaie: data['monnaie'] ?? 'FCFA',
        description: data['description'] ?? '',
        createdAt: parseFirestoreDateOrNull(data['createdAt']),
        updatedAt: parseFirestoreDateOrNull(data['updatedAt']),
      );
    } catch (e) {
      Logger.error('Erreur recuperation wallet par ID: $e');
      return null;
    }
  }

  Future<List<WalletModel>> getWallets(String uid) async {
    try {
      final query = await wallets.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => WalletModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération portefeuilles: $e');
      return [];
    }
  }

  Future<void> saveWallet(WalletModel wallet) async {
    try {
      await wallets.doc(wallet.id).set(wallet.toMap(), SetOptions(merge: true));
      Logger.info('📝 Portefeuille sauvegardé: ${wallet.nom}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      await wallets.doc(walletId).delete();
      Logger.info('🗑️ Portefeuille supprimé: $walletId');
    } catch (e) {
      Logger.error('❌ Erreur suppression portefeuille: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<List<TransactionModel>> getTransactions(
    String uid, {
    int limit = 50,
    bool descending = true,
  }) async {
    try {
      final query = await transactions
          .where('uid', isEqualTo: uid)
          .orderBy('dateTransaction', descending: descending)
          .limit(limit)
          .get();
      return query.docs
          .map((doc) => TransactionModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération transactions: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getWalletTransactions(
    String walletId, {
    int limit = 50,
  }) async {
    try {
      final query = await transactions
          .where('walletId', isEqualTo: walletId)
          .orderBy('dateTransaction', descending: true)
          .limit(limit)
          .get();
      return query.docs
          .map((doc) => TransactionModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération transactions portefeuille: $e');
      return [];
    }
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      await transactions.doc(transaction.id).set(transaction.toMap());
      Logger.info('📝 Transaction sauvegardée: ${transaction.id}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteTransaction(String txId) async {
    try {
      await transactions.doc(txId).delete();
      Logger.info('🗑️ Transaction supprimée: $txId');
    } catch (e) {
      Logger.error('❌ Erreur suppression transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // CATÉGORIES
  // ============================================

  Future<List<CategorieModel>> getCategories(String uid) async {
    try {
      final query = await categories.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => CategorieModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération catégories: $e');
      return [];
    }
  }

  Future<void> saveCategory(CategorieModel category) async {
    try {
      await categories
          .doc(category.id)
          .set(category.toMap(), SetOptions(merge: true));
      Logger.info('📝 Catégorie sauvegardée: ${category.label}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde catégorie: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await categories.doc(categoryId).delete();
      Logger.info('🗑️ Catégorie supprimée: $categoryId');
    } catch (e) {
      Logger.error('❌ Erreur suppression catégorie: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // OBJECTIFS D'ÉPARGNE
  // ============================================

  Future<List<SavingsGoalModel>> getSavingsGoals(String uid) async {
    try {
      final query = await savingsGoals.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => SavingsGoalModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération objectifs: $e');
      return [];
    }
  }

  /// Sauvegarde un objectif d'épargne.
  /// ✅ Si l'ID est vide, un nouvel ID est généré automatiquement.
  Future<void> saveSavingsGoal(SavingsGoalModel goal) async {
    try {
      final docId = goal.id.isEmpty ? savingsGoals.doc().id : goal.id;
      final goalToSave = goal.id.isEmpty ? goal.copyWith(id: docId) : goal;

      await savingsGoals
          .doc(docId)
          .set(goalToSave.toMap(), SetOptions(merge: true));
      Logger.info('📝 Objectif sauvegardé: ${goal.nom} (id: $docId)');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde objectif: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      await savingsGoals.doc(goalId).delete();
      Logger.info('🗑️ Objectif supprimé: $goalId');
    } catch (e) {
      Logger.error('❌ Erreur suppression objectif: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // DETTES
  // ============================================

  Future<List<DetteModel>> getDettes(String uid) async {
    try {
      final query = await dettes.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => DetteModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération dettes: $e');
      return [];
    }
  }

  Future<void> saveDette(DetteModel dette) async {
    try {
      await dettes.doc(dette.id).set(dette.toMap(), SetOptions(merge: true));
      Logger.info('📝 Dette sauvegardée: ${dette.id}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde dette: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteDette(String detteId) async {
    try {
      await dettes.doc(detteId).delete();
      Logger.info('🗑️ Dette supprimée: $detteId');
    } catch (e) {
      Logger.error('❌ Erreur suppression dette: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // CONFIG (Tarifs assurance auto)
  // ============================================

  Future<TarifConfigModel?> getTarifsConfig() async {
    try {
      final doc = await config.doc('tarifs_assurance_auto').get();
      if (!doc.exists) {
        Logger.info('Config tarifs non trouvee, valeurs par defaut');
        return null;
      }
      return TarifConfigModel.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Erreur recuperation tarifs: $e');
      return null;
    }
  }

  Future<void> saveTarifsConfig(TarifConfigModel tarifConfig) async {
    try {
      await config
          .doc('tarifs_assurance_auto')
          .set(tarifConfig.toMap(), SetOptions(merge: true));
      Logger.success('Config tarifs sauvegardee');
    } catch (e) {
      Logger.error('Erreur sauvegarde tarifs: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Stream<TarifConfigModel?> listenToTarifsConfig() {
    return config.doc('tarifs_assurance_auto').snapshots().map((doc) {
      if (!doc.exists) return null;
      return TarifConfigModel.fromMap(doc.data()!);
    });
  }

  // ============================================
  // SOUSCRIPTIONS (Assurances)
  // ============================================

  Future<List<SouscriptionModel>> getSouscriptions(String uid) async {
    try {
      final query = await souscriptions.where('userId', isEqualTo: uid).get();
      return query.docs
          .map((doc) => SouscriptionModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('Erreur recuperation souscriptions: $e');
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToSouscriptions(
      String uid) {
    return souscriptions.where('userId', isEqualTo: uid).snapshots();
  }

  // ============================================
  // SOUSCRIPTIONS - ADMIN
  // ============================================

  Future<List<SouscriptionModel>> getAllSouscriptions() async {
    try {
      final query =
          await souscriptions.orderBy('dateCreation', descending: true).get();
      return query.docs
          .map((doc) => SouscriptionModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('Erreur recuperation toutes souscriptions: $e');
      return [];
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToAllSouscriptions() {
    return souscriptions.orderBy('dateCreation', descending: true).snapshots();
  }

  Future<void> updateSouscriptionStatut(String reference, String statut) async {
    try {
      await souscriptions.doc(reference).update({
        'statut': statut,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.success('Souscription $reference -> $statut');
    } catch (e) {
      Logger.error('Erreur mise a jour statut: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // BUDGETS
  // ============================================

  String _budgetDocId(int mois, int annee) => '$annee-$mois';

  Future<BudgetMensuel?> getBudget(String uid, int mois, int annee) async {
    try {
      final doc =
          await budgets.doc('${uid}_${_budgetDocId(mois, annee)}').get();
      if (!doc.exists) return null;
      return BudgetMensuel.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      Logger.error('❌ Erreur récupération budget: $e');
      return null;
    }
  }

  Future<void> saveBudget(BudgetMensuel budget, String uid) async {
    try {
      await budgets
          .doc('${uid}_${_budgetDocId(budget.mois, budget.annee)}')
          .set(budget.toMap());
      Logger.info('📝 Budget sauvegardé: ${budget.mois}/${budget.annee}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde budget: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteBudget(String uid, int mois, int annee) async {
    try {
      await budgets.doc('${uid}_${_budgetDocId(mois, annee)}').delete();
      Logger.info('🗑️ Budget supprimé: $mois/$annee');
    } catch (e) {
      Logger.error('❌ Erreur suppression budget: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // ÉCHÉANCES
  // ============================================

  Future<List<EcheanceModel>> getEcheances(String uid) async {
    try {
      final query = await echeances.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => EcheanceModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération échéances: $e');
      return [];
    }
  }

  Future<void> saveEcheance(EcheanceModel echeance) async {
    try {
      await echeances
          .doc(echeance.id)
          .set(echeance.toMap(), SetOptions(merge: true));
      Logger.info('📝 Échéance sauvegardée: ${echeance.titre}');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde échéance: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteEcheance(String echeanceId) async {
    try {
      await echeances.doc(echeanceId).delete();
      Logger.info('🗑️ Échéance supprimée: $echeanceId');
    } catch (e) {
      Logger.error('❌ Erreur suppression échéance: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  Future<List<EpargneProgrammeeModel>> getEpargneProgrammee(String uid) async {
    try {
      final query = await epargneProgrammee.where('uid', isEqualTo: uid).get();
      return query.docs
          .map((doc) => EpargneProgrammeeModel.fromMap(
                {...doc.data(), 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      Logger.error('❌ Erreur récupération épargne programmée: $e');
      return [];
    }
  }

  /// Sauvegarde une épargne programmée.
  /// ✅ Si l'ID est vide, un nouvel ID est généré automatiquement.
  Future<void> saveEpargneProgrammee(EpargneProgrammeeModel epargne) async {
    try {
      final docId =
          epargne.id.isEmpty ? epargneProgrammee.doc().id : epargne.id;

      final data = epargne.toMap();
      data['uid'] = _auth.currentUser?.uid ?? '';

      await epargneProgrammee.doc(docId).set(data, SetOptions(merge: true));
      Logger.info(
          '📝 Épargne programmée sauvegardée: ${epargne.titre} (id: $docId)');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  Future<void> deleteEpargneProgrammee(String id) async {
    try {
      await epargneProgrammee.doc(id).delete();
      Logger.info('🗑️ Épargne programmée supprimée: $id');
    } catch (e) {
      Logger.error('❌ Erreur suppression épargne programmée: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  Future<Map<String, dynamic>> getStatistics(String uid) async {
    try {
      final txs = await getTransactions(uid, limit: 1000);

      double totalRevenus = 0;
      double totalDepenses = 0;

      for (final tx in txs) {
        if (tx.isRevenu) {
          totalRevenus += tx.montant;
        } else if (tx.isDepense) {
          totalDepenses += tx.montant;
        }
      }

      return {
        'total_revenus': totalRevenus,
        'total_depenses': totalDepenses,
        'solde': totalRevenus - totalDepenses,
        'nombre_transactions': txs.length,
      };
    } catch (e) {
      Logger.error('❌ Erreur statistiques: $e');
      return {
        'total_revenus': 0,
        'total_depenses': 0,
        'solde': 0,
        'nombre_transactions': 0,
      };
    }
  }

  Future<double> getTotalDepensesReelles(
      String uid, int mois, int annee) async {
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);

    try {
      final query = await transactions
          .where('uid', isEqualTo: uid)
          .where('type', isEqualTo: 'depense')
          .where('dateTransaction', isGreaterThanOrEqualTo: debut)
          .where('dateTransaction', isLessThan: fin)
          .get();

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        total += (data['montant'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      Logger.error('❌ Erreur calcul dépenses réelles: $e');
      return 0;
    }
  }

  Future<double> getTotalRevenusReels(String uid, int mois, int annee) async {
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);

    try {
      final query = await transactions
          .where('uid', isEqualTo: uid)
          .where('type', isEqualTo: 'revenu')
          .where('dateTransaction', isGreaterThanOrEqualTo: debut)
          .where('dateTransaction', isLessThan: fin)
          .get();

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        total += (data['montant'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      Logger.error('❌ Erreur calcul revenus réels: $e');
      return 0;
    }
  }

  Future<double> getDepensesReellesByCategorie(
    String uid,
    String categorieId,
    int mois,
    int annee,
  ) async {
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);

    try {
      final query = await transactions
          .where('uid', isEqualTo: uid)
          .where('categorieId', isEqualTo: categorieId)
          .where('dateTransaction', isGreaterThanOrEqualTo: debut)
          .where('dateTransaction', isLessThan: fin)
          .get();

      double total = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        total += (data['montant'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      Logger.error('❌ Erreur calcul dépenses par catégorie: $e');
      return 0;
    }
  }

  // ============================================
  // ÉCOUTEURS EN TEMPS RÉEL
  // ============================================

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToWallets(String uid) {
    return wallets.where('uid', isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToTransactions(
    String uid, {
    int limit = 50,
  }) {
    return transactions
        .where('uid', isEqualTo: uid)
        .orderBy('dateTransaction', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToSavingsGoals(String uid) {
    return savingsGoals
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToDettes(String uid) {
    return dettes
        .where('uid', isEqualTo: uid)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToEcheances(String uid) {
    return echeances
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCategories(String uid) {
    return categories
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ============================================
  // TRANSACTIONS BATCH
  // ============================================

  WriteBatch batch() => _firestore.batch();

  Future<void> runTransaction(Future<void> Function(Transaction) action) async {
    try {
      await _firestore.runTransaction(action);
    } catch (e) {
      Logger.error('❌ Erreur transaction: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  String generateId() => _firestore.collection('temp').doc().id;

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}
