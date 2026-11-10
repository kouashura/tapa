// lib/services/api_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart'; // ✅ CORRIGÉ
import '../core/utils/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SharedPreferences? _prefs;
  String? _currentUserId;

  // Cache local des catégories
  List<Map<String, dynamic>> _categories = [];

  // ============================================
  // INITIALISATION
  // ============================================

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _prefs?.setString('user_id', user.uid);
    } else {
      _currentUserId = _prefs?.getString('user_id');
    }

    if (_currentUserId != null) {
      await _loadCategories();
      Logger.info('✅ FirebaseService initialisé - userId: $_currentUserId');
    } else {
      Logger.info('ℹ️ FirebaseService initialisé - Aucun utilisateur');
    }
  }

  // ============================================
  // AUTH - GESTION DE L'UTILISATEUR
  // ============================================

  String? getCurrentUserId() => _currentUserId;
  bool get isLoggedIn => _currentUserId != null;

  Future<void> setCurrentUser(User? user) async {
    if (user != null) {
      _currentUserId = user.uid;
      await _prefs?.setString('user_id', user.uid);
      await _loadCategories();
      Logger.info('👤 Utilisateur connecté: ${user.uid}');
    } else {
      _currentUserId = null;
      await _prefs?.remove('user_id');
      _categories = [];
      Logger.info('👤 Utilisateur déconnecté');
    }
  }

  // ============================================
  // UTILISATEUR
  // ============================================

  Map<String, dynamic>? getUser() {
    final prenom = _prefs?.getString('user_prenom');
    final telephone = _prefs?.getString('user_telephone');
    final monnaie = _prefs?.getString('user_monnaie') ?? 'FCFA';
    final pinCode = _prefs?.getString('user_pin') ?? '';
    final hasAccesVie = _prefs?.getBool('acces_vie') ?? false;

    if (prenom == null) return null;
    return {
      'prenom': prenom,
      'telephone': telephone ?? '',
      'monnaie': monnaie,
      'pinCode': pinCode,
      'hasAccesVie': hasAccesVie,
    };
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final uid = _auth.currentUser?.uid ?? user.id;

      await _firestore.collection('users').doc(uid).set({
        'phoneNumber': user.phoneNumber,
        'prenom': user.prenom,
        'monnaie': user.monnaie,
        'codePays': user.codePays,
        'hasAccessVie': user.hasAccessVie,
        'onboardingVu': user.onboardingVu,
        'notificationsActivees': user.notificationsActivees,
        'createdAt': FieldValue.serverTimestamp(),
        'dernierActive': FieldValue.serverTimestamp(),
      });

      _currentUserId = uid;
      await _prefs?.setString('user_id', uid);
      await _prefs?.setString('user_telephone', user.phoneNumber);
      await _prefs?.setString('user_prenom', user.prenom);
      await _prefs?.setString('user_monnaie', user.monnaie);

      await _initDefaultWallets(uid);
      await _initDefaultCategories(uid);
      await _loadCategories();

      Logger.info('✅ Utilisateur sauvegardé: $uid');
    } catch (e) {
      Logger.error('❌ Erreur saveUser: $e');
      rethrow;
    }
  }

  // ============================================
  // PIN
  // ============================================

  Future<void> savePin(String pin) async {
    await _prefs?.setString('user_pin', pin);
    final userId = _currentUserId;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({'pinCode': pin});
    }
  }

  bool verifyPin(String pin) {
    return _prefs?.getString('user_pin') == pin;
  }

  // ============================================
  // PORTEFEUILLES
  // ============================================

  Future<void> _initDefaultWallets(String userId) async {
    final defaultWallets = [
      {
        'uid': userId,
        'nom': 'Compte Principal',
        'type': 'compte',
        'emoji': '🏦',
        'solde': 0.0,
        'monnaie': 'FCFA',
        'description': 'Compte principal',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      },
      {
        'uid': userId,
        'nom': 'Wave',
        'type': 'mobile',
        'emoji': '📱',
        'solde': 0.0,
        'monnaie': 'FCFA',
        'description': 'Portefeuille Wave',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      },
      {
        'uid': userId,
        'nom': 'Espèces',
        'type': 'especes',
        'emoji': '💵',
        'solde': 0.0,
        'monnaie': 'FCFA',
        'description': 'Espèces',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp()
      },
    ];
    final batch = _firestore.batch();
    for (final wallet in defaultWallets) {
      final docRef = _firestore.collection('wallets').doc();
      batch.set(docRef, wallet);
    }
    await batch.commit();
    Logger.info('📂 Portefeuilles par défaut créés');
  }

  List<WalletModel> getWallets() => [];

  Future<void> saveWallet(WalletModel wallet) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _firestore.collection('wallets').doc(wallet.id).set({
      'uid': userId,
      'nom': wallet.nom,
      'emoji': wallet.emoji,
      'type': wallet.type,
      'solde': wallet.solde,
      'monnaie': wallet.monnaie,
      'description': wallet.description,
      'createdAt': wallet.createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  List<TransactionModel> getTransactions() => [];

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _firestore.collection('transactions').add({
      'uid': userId,
      'walletId': transaction.walletId,
      'montant': transaction.montant,
      'type': transaction.type.toString().split('.').last,
      'categorieId': transaction.categorieId,
      'categorieLabel': transaction.categorieLabel,
      'categorieEmoji': transaction.categorieEmoji,
      'note': transaction.note,
      'dateTransaction': transaction.dateTransaction,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTransaction(
      TransactionModel oldTx, TransactionModel newTx) async {}
  Future<void> deleteTransaction(TransactionModel transaction) async {}

  // ============================================
  // CATÉGORIES
  // ============================================

  Future<void> _initDefaultCategories(String userId) async {
    final categories = [
      {
        'id': 'nourriture',
        'label': 'Alimentation',
        'emoji': '🍽️',
        'type': 'depense'
      },
      {
        'id': 'transport',
        'label': 'Transport',
        'emoji': '🚗',
        'type': 'depense'
      },
      {'id': 'facture', 'label': 'Facture', 'emoji': '📄', 'type': 'depense'},
      {'id': 'logement', 'label': 'Logement', 'emoji': '🏠', 'type': 'depense'},
      {'id': 'sante', 'label': 'Santé', 'emoji': '🏥', 'type': 'depense'},
      {
        'id': 'education',
        'label': 'Éducation',
        'emoji': '📚',
        'type': 'depense'
      },
      {'id': 'loisirs', 'label': 'Loisirs', 'emoji': '🎮', 'type': 'depense'},
      {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰', 'type': 'revenu'},
    ];
    final batch = _firestore.batch();
    for (final cat in categories) {
      final docRef = _firestore.collection('categories').doc(cat['id']);
      batch.set(docRef, {
        'uid': userId,
        'categorieId': cat['id'],
        'label': cat['label'],
        'emoji': cat['emoji'],
        'type': cat['type'],
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    Logger.info('📂 Catégories par défaut créées');
  }

  Future<void> _loadCategories() async {
    final userId = _currentUserId;
    if (userId == null) {
      _categories = [];
      return;
    }
    try {
      final snap = await _firestore
          .collection('categories')
          .where('uid', isEqualTo: userId)
          .get();
      _categories = snap.docs
          .map((d) => {
                'id': d.id,
                ...d.data(),
              })
          .toList();
      Logger.info('📂 Catégories chargées: ${_categories.length}');
    } catch (e) {
      Logger.error('❌ Erreur chargement catégories: $e');
      _categories = [];
    }
  }

  Future<void> refreshCategories() => _loadCategories();

  List<Map<String, dynamic>> getCategories() => _categories;

  Future<void> addCategory(Map<String, dynamic> category) async {
    final userId = _currentUserId;
    if (userId == null) {
      Logger.error('❌ addCategory - Utilisateur non authentifié');
      throw Exception('Utilisateur non authentifié');
    }

    final id = category['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final label = category['label'] as String? ?? 'Autre';
    final emoji = category['emoji'] as String? ?? '📌';
    final type = category['type'] as String? ?? 'depense';

    Logger.info('📝 Ajout catégorie: $label ($type)');

    try {
      await _firestore.collection('categories').doc(id).set({
        'uid': userId,
        'categorieId': id,
        'label': label,
        'emoji': emoji,
        'type': type,
        'isDefault': category['isDefault'] ?? false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Logger.info('✅ Catégorie ajoutée Firestore: $label');
      await _loadCategories();
    } catch (e) {
      Logger.error('❌ Erreur addCategory: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      await _firestore.collection('categories').doc(categoryId).delete();

      Logger.info('🗑️ Catégorie supprimée: $categoryId');
      await _loadCategories();
    } catch (e) {
      Logger.error('❌ Erreur deleteCategory: $e');
      rethrow;
    }
  }

  // ============================================
  // ÉCHÉANCES
  // ============================================

  List<EcheanceModel> getEcheances() => [];

  Future<void> saveEcheance(EcheanceModel echeance) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _firestore.collection('echeances').add({
      'uid': userId,
      'titre': echeance.titre,
      'description': echeance.description,
      'montant': echeance.montant,
      'dateEcheance': echeance.dateEcheance,
      'type': echeance.type,
      'statut': echeance.statut,
      'descriptionRecurrence': echeance.descriptionRecurrence,
      'descriptionRappel': echeance.descriptionRappel,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> supprimerEcheance(String id) async {}

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  List<EpargneProgrammeeModel> getEpargnesProgrammees() => [];

  Future<void> saveEpargneProgrammee(EpargneProgrammeeModel epargne) async {}
  Future<void> supprimerEpargneProgrammee(String id) async {}
  Future<void> effectuerDepotEpargne(EpargneProgrammeeModel epargne) async {}

  // ============================================
  // OBJECTIFS D'ÉPARGNE
  // ============================================

  List<SavingsGoalModel> getSavingsGoals() => [];
  Future<void> addSavingsGoal(SavingsGoalModel goal) async {}

  // ============================================
  // DETTES
  // ============================================

  List<DetteModel> getDettes() => [];

  // ============================================
  // BUDGET
  // ============================================

  String _budgetDocId(int mois, int annee) => '$annee-$mois';

  Future<BudgetMensuel?> getBudget(int mois, int annee) async {
    final userId = _currentUserId;
    if (userId == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_budgetDocId(mois, annee))
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return BudgetMensuel.fromMap(doc.data()!);
  }

  Future<void> saveBudget(BudgetMensuel budget) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_budgetDocId(budget.mois, budget.annee))
        .set(budget.toMap());
  }

  Future<void> deleteBudget(int mois, int annee) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_budgetDocId(mois, annee))
        .delete();
  }

  Future<double> _sommeTransactions(int mois, int annee, String type) async {
    final userId = _currentUserId;
    if (userId == null) return 0.0;
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);
    final snap = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .where('dateTransaction', isGreaterThanOrEqualTo: debut)
        .where('dateTransaction', isLessThan: fin)
        .get();
    double total = 0;
    for (final d in snap.docs) {
      total += (d.data()['montant'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Future<double> getTotalDepensesReelles(int mois, int annee) =>
      _sommeTransactions(mois, annee, 'depense');

  Future<double> getTotalRevenusReels(int mois, int annee) =>
      _sommeTransactions(mois, annee, 'revenu');

  Future<double> getDepensesReellesByCategorie(
      String categorieId, int mois, int annee) async {
    final userId = _currentUserId;
    if (userId == null) return 0.0;
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);
    final snap = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: userId)
        .where('categorieId', isEqualTo: categorieId)
        .where('dateTransaction', isGreaterThanOrEqualTo: debut)
        .where('dateTransaction', isLessThan: fin)
        .get();
    double total = 0;
    for (final d in snap.docs) {
      total += (d.data()['montant'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ============================================
  // ONBOARDING
  // ============================================

  bool get onboardingVu => _prefs?.getBool('onboarding_vu') ?? false;
  Future<void> marquerOnboardingVu() async =>
      await _prefs?.setBool('onboarding_vu', true);

  // ============================================
  // NOTIFICATIONS
  // ============================================

  bool get notificationsActivees =>
      _prefs?.getBool('notifications_activees') ?? true;
  Future<void> setNotifications(bool value) async =>
      await _prefs?.setBool('notifications_activees', value);

  // ============================================
  // ACCÈS VIE
  // ============================================

  bool verifierCle(String cle) =>
      RegExp(r'^TB-2026-[A-Z0-9]{8}$').hasMatch(cle);
  Future<void> activerAccesAVie(String cle) async =>
      await _prefs?.setBool('acces_vie', true);
  bool get aAccesAVie => _prefs?.getBool('acces_vie') ?? false;
  bool get essaiGratuitExpire => false;
  int get joursRestantsEssai => 7;

  // ============================================
  // STATISTIQUES
  // ============================================

  Future<Map<String, dynamic>> getStatistics() async => {
        'total_revenus': 0.0,
        'total_depenses': 0.0,
        'solde': 0.0,
        'nombre_transactions': 0
      };

  // ============================================
  // NETTOYAGE
  // ============================================

  Future<void> clearAll() async {
    await _prefs?.clear();
    _categories = [];
    _currentUserId = null;
  }

  Future<void> clear() async => await _prefs?.clear();
}
