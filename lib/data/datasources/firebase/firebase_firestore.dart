// lib/data/datasources/firebase/firebase_firestore.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/utils/logger.dart';

class FirebaseFirestoreService {
  static final FirebaseFirestoreService _instance =
  FirebaseFirestoreService._internal();
  factory FirebaseFirestoreService() => _instance;
  FirebaseFirestoreService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  CollectionReference<Map<String, dynamic>> get echeances =>
      _firestore.collection('echeances');
  CollectionReference<Map<String, dynamic>> get epargneProgrammee =>
      _firestore.collection('epargne_programmee');

  // ============================================
  // AUTH
  // ============================================

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.success('🔓 Déconnexion réussie');
    } catch (e) {
      Logger.error('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  // ============================================
  // AUTHENTIFICATION PAR TÉLÉPHONE
  // ============================================

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
      Logger.info('📱 Code SMS envoyé à $phoneNumber');
    } catch (e) {
      Logger.error('❌ Erreur envoi SMS: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      Logger.success('✅ Connexion réussie: ${result.user?.uid}');
      return result;
    } catch (e) {
      Logger.error('❌ Erreur connexion: $e');
      rethrow;
    }
  }

  // ============================================
  // UTILISATEURS
  // ============================================

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      final query = await users.where('uid', isEqualTo: uid).limit(1).get();
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      Logger.error('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  Future<void> setUserData(Map<String, dynamic> data, String userId) async {
    try {
      await users.doc(userId).set(data, SetOptions(merge: true));
      Logger.info('📝 Données utilisateur mises à jour');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour utilisateur: $e');
      rethrow;
    }
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await users.doc(uid).delete();
      Logger.info('🗑️ Utilisateur supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression utilisateur: $e');
      rethrow;
    }
  }

  // ============================================
  // PORTEFEUILLES
  // ============================================

  Future<List<QueryDocumentSnapshot>> getWallets(String uid) async {
    try {
      final query = await wallets.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération portefeuilles: $e');
      return [];
    }
  }

  Future<void> saveWallet(Map<String, dynamic> data, String walletId) async {
    try {
      await wallets.doc(walletId).set(data, SetOptions(merge: true));
      Logger.info('📝 Portefeuille mis à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde portefeuille: $e');
      rethrow;
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      await wallets.doc(walletId).delete();
      Logger.info('🗑️ Portefeuille supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression portefeuille: $e');
      rethrow;
    }
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getTransactions(String uid, {int limit = 50}) async {
    try {
      final query = await transactions
          .where('uid', isEqualTo: uid)
          .orderBy('dateTransaction', descending: true)
          .limit(limit)
          .get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération transactions: $e');
      return [];
    }
  }

  Future<void> saveTransaction(Map<String, dynamic> data, String txId) async {
    try {
      await transactions.doc(txId).set(data);
      Logger.info('📝 Transaction enregistrée');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String txId) async {
    try {
      await transactions.doc(txId).delete();
      Logger.info('🗑️ Transaction supprimée');
    } catch (e) {
      Logger.error('❌ Erreur suppression transaction: $e');
      rethrow;
    }
  }

  // ============================================
  // CATÉGORIES
  // ============================================

  Future<List<QueryDocumentSnapshot>> getCategories(String uid) async {
    try {
      final query = await categories.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération catégories: $e');
      return [];
    }
  }

  Future<void> saveCategory(Map<String, dynamic> data, String categoryId) async {
    try {
      await categories.doc(categoryId).set(data, SetOptions(merge: true));
      Logger.info('📝 Catégorie mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde catégorie: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await categories.doc(categoryId).delete();
      Logger.info('🗑️ Catégorie supprimée');
    } catch (e) {
      Logger.error('❌ Erreur suppression catégorie: $e');
      rethrow;
    }
  }

  // ============================================
  // OBJECTIFS D'ÉPARGNE
  // ============================================

  Future<List<QueryDocumentSnapshot>> getSavingsGoals(String uid) async {
    try {
      final query = await savingsGoals.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération objectifs: $e');
      return [];
    }
  }

  Future<void> saveSavingsGoal(Map<String, dynamic> data, String goalId) async {
    try {
      await savingsGoals.doc(goalId).set(data, SetOptions(merge: true));
      Logger.info('📝 Objectif d\'épargne mis à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde objectif: $e');
      rethrow;
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    try {
      await savingsGoals.doc(goalId).delete();
      Logger.info('🗑️ Objectif d\'épargne supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression objectif: $e');
      rethrow;
    }
  }

  // ============================================
  // DETTES
  // ============================================

  Future<List<QueryDocumentSnapshot>> getDettes(String uid) async {
    try {
      final query = await dettes.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération dettes: $e');
      return [];
    }
  }

  Future<void> saveDette(Map<String, dynamic> data, String detteId) async {
    try {
      await dettes.doc(detteId).set(data, SetOptions(merge: true));
      Logger.info('📝 Dette mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde dette: $e');
      rethrow;
    }
  }

  Future<void> deleteDette(String detteId) async {
    try {
      await dettes.doc(detteId).delete();
      Logger.info('🗑️ Dette supprimée');
    } catch (e) {
      Logger.error('❌ Erreur suppression dette: $e');
      rethrow;
    }
  }

  // ============================================
  // BUDGETS
  // ============================================

  String _budgetDocId(int mois, int annee) => '$annee-$mois';

  Future<DocumentSnapshot?> getBudget(String uid, int mois, int annee) async {
    try {
      return await budgets
          .doc('${uid}_${_budgetDocId(mois, annee)}')
          .get();
    } catch (e) {
      Logger.error('❌ Erreur récupération budget: $e');
      return null;
    }
  }

  Future<void> saveBudget(Map<String, dynamic> data, String uid, int mois, int annee) async {
    try {
      await budgets
          .doc('${uid}_${_budgetDocId(mois, annee)}')
          .set(data);
      Logger.info('📝 Budget sauvegardé');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String uid, int mois, int annee) async {
    try {
      await budgets
          .doc('${uid}_${_budgetDocId(mois, annee)}')
          .delete();
      Logger.info('🗑️ Budget supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression budget: $e');
      rethrow;
    }
  }

  // ============================================
  // ÉCHÉANCES
  // ============================================

  Future<List<QueryDocumentSnapshot>> getEcheances(String uid) async {
    try {
      final query = await echeances.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération échéances: $e');
      return [];
    }
  }

  Future<void> saveEcheance(Map<String, dynamic> data, String echeanceId) async {
    try {
      await echeances.doc(echeanceId).set(data, SetOptions(merge: true));
      Logger.info('📝 Échéance mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde échéance: $e');
      rethrow;
    }
  }

  Future<void> deleteEcheance(String echeanceId) async {
    try {
      await echeances.doc(echeanceId).delete();
      Logger.info('🗑️ Échéance supprimée');
    } catch (e) {
      Logger.error('❌ Erreur suppression échéance: $e');
      rethrow;
    }
  }

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  Future<List<QueryDocumentSnapshot>> getEpargneProgrammee(String uid) async {
    try {
      final query = await epargneProgrammee.where('uid', isEqualTo: uid).get();
      return query.docs;
    } catch (e) {
      Logger.error('❌ Erreur récupération épargne programmée: $e');
      return [];
    }
  }

  Future<void> saveEpargneProgrammee(Map<String, dynamic> data, String id) async {
    try {
      await epargneProgrammee.doc(id).set(data, SetOptions(merge: true));
      Logger.info('📝 Épargne programmée mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde épargne programmée: $e');
      rethrow;
    }
  }

  Future<void> deleteEpargneProgrammee(String id) async {
    try {
      await epargneProgrammee.doc(id).delete();
      Logger.info('🗑️ Épargne programmée supprimée');
    } catch (e) {
      Logger.error('❌ Erreur suppression épargne programmée: $e');
      rethrow;
    }
  }

  // ============================================
  // SUPPRESSION DE COMPTE
  // ============================================

  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non authentifié');

    try {
      final uid = user.uid;

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

      await users.doc(uid).delete();
      await user.delete();
      Logger.success('🗑️ Compte supprimé avec succès');
    } catch (e) {
      Logger.error('❌ Erreur suppression compte: $e');
      rethrow;
    }
  }

  // ============================================
  // TRANSACTIONS AVEC BATCH
  // ============================================

  Future<void> runTransaction(Future<void> Function(Transaction) action) async {
    try {
      await _firestore.runTransaction(action);
    } catch (e) {
      Logger.error('❌ Erreur transaction: $e');
      rethrow;
    }
  }

  WriteBatch batch() => _firestore.batch();

  // ============================================
  // ÉCOUTEURS EN TEMPS RÉEL
  // ============================================

  Stream<QuerySnapshot<Map<String, dynamic>>> listenToWallets(String uid) {
    return wallets
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
  Stream<QuerySnapshot> listenToTransactions(String uid, {int limit = 50}) {
    return transactions
        .where('uid', isEqualTo: uid)
        .orderBy('dateTransaction', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot> listenToSavingsGoals(String uid) {
    return savingsGoals
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> listenToDettes(String uid) {
    return dettes
        .where('uid', isEqualTo: uid)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> listenToEcheances(String uid) {
    return echeances
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> listenToCategories(String uid) {
    return categories
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  String generateId() => _firestore.collection('temp').doc().id;

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ============================================
  // STATISTIQUES (CORRIGÉ)
  // ============================================

  Future<Map<String, dynamic>> getStatistics(String uid) async {
    try {
      final txs = await getTransactions(uid, limit: 1000);

      double totalRevenus = 0;
      double totalDepenses = 0;

      for (final doc in txs) {
        final data = doc.data();
        // ✅ CORRECTION : Vérification que data n'est pas null
        if (data == null) continue;

        final montant = (data['montant'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? '';

        if (type == 'revenu') {
          totalRevenus += montant;
        } else if (type == 'depense') {
          totalDepenses += montant;
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

  Future<double> getTotalDepensesReelles(String uid, int mois, int annee) async {
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
        if (data == null) continue;
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
        if (data == null) continue;
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
      int annee
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
        if (data == null) continue;
        total += (data['montant'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      Logger.error('❌ Erreur calcul dépenses par catégorie: $e');
      return 0;
    }
  }
}