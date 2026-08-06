// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/budget_model.dart';
import '../models/echeance_model.dart';
import '../models/epargne_programmee_model.dart';
import '../core/utils/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SharedPreferences? _prefs;
  String? _currentUserId;

  List<Map<String, dynamic>> _categories = [];

  // ============================================
  // CONSTANTES
  // ============================================

  static const int DUREE_ESSAI_JOURS = 10;
  static const int PRIX_ACCES_VIE = 5000;
  static const String FORMAT_CLE = 'TB-2026-XXXXXXXX';

  // ✅ CLÉS ROOT (ACCÈS ILLIMITÉ)
  static const List<String> ROOT_KEYS = [
    'TAPA-ROOT-2026-SUPER-ADMIN',
    'TAPA-ROOT-2026-DEVELOPPER',
    'TAPA-ROOT-2026-TESTER',
  ];

  // ============================================
  // INITIALISATION
  // ============================================

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _prefs?.setString('user_id', user.uid);
      Logger.info('✅ FirebaseService - Utilisateur déjà connecté: ${user.uid}');
    } else {
      _currentUserId = _prefs?.getString('user_id');
      if (_currentUserId != null) {
        Logger.info('✅ FirebaseService - Utilisateur restauré: $_currentUserId');
      } else {
        Logger.info('ℹ️ FirebaseService - Aucun utilisateur');
      }
    }

    if (_currentUserId != null) {
      await _loadCategories();
      Logger.info('📂 Catégories initiales: ${_categories.length}');
    }
  }

  // ============================================
  // AUTH - GESTION DE L'UTILISATEUR
  // ============================================

  /// RÉCUPÉRER L'ID UTILISATEUR (AVEC FALLBACK SUR FIREBASE AUTH)
  String? getCurrentUserId() {
    if (_currentUserId == null) {
      final user = _auth.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _prefs?.setString('user_id', user.uid);
        Logger.info('🔍 getCurrentUserId - Récupéré depuis Firebase Auth: ${user.uid}');
      }
    }
    return _currentUserId;
  }

  bool get isLoggedIn {
    final user = _auth.currentUser;
    return user != null || _currentUserId != null;
  }

  /// METTRE À JOUR L'UTILISATEUR APRÈS CONNEXION
  Future<void> setCurrentUser(User? user) async {
    if (user != null) {
      _currentUserId = user.uid;
      await _prefs?.setString('user_id', user.uid);
      await _loadCategories();
      Logger.info('👤 FirebaseService - Utilisateur connecté: ${user.uid}');
    } else {
      _currentUserId = null;
      await _prefs?.remove('user_id');
      _categories = [];
      Logger.info('👤 FirebaseService - Utilisateur déconnecté');
    }
  }

  // ============================================
  // GESTION DE L'ESSAI GRATUIT - VERSION SYNC
  // ============================================

  /// Vérifie si l'essai gratuit est expiré (version synchrone)
  bool get essaiGratuitExpire {
    final dateInscription = _prefs?.getString('date_inscription');
    if (dateInscription == null) {
      Logger.warning('⚠️ Date d\'inscription non trouvée dans SharedPreferences');
      return false; // ✅ FALLBACK: considérer que l'essai n'est pas expiré
    }

    try {
      final date = DateTime.parse(dateInscription);
      final now = DateTime.now();
      final diff = now.difference(date);
      final estExpire = diff.inDays > DUREE_ESSAI_JOURS;
      Logger.info('📅 Date inscription: ${date.toIso8601String()}, Jours: ${diff.inDays}, Expiré: $estExpire');
      return estExpire;
    } catch (e) {
      Logger.error('❌ Erreur lecture date inscription: $e');
      return false;
    }
  }

  /// Nombre de jours restants pour l'essai gratuit
  int get joursRestantsEssai {
    final dateInscription = _prefs?.getString('date_inscription');
    if (dateInscription == null) return 0;

    try {
      final date = DateTime.parse(dateInscription);
      final now = DateTime.now();
      final diff = now.difference(date);
      return (DUREE_ESSAI_JOURS - diff.inDays).clamp(0, DUREE_ESSAI_JOURS);
    } catch (e) {
      return 0;
    }
  }

  // ============================================
  // GESTION DE L'ESSAI GRATUIT - VERSION ASYNC
  // ============================================

  /// Vérifie si l'essai gratuit est expiré (version asynchrone avec Firestore)
  Future<bool> isEssaiGratuitExpire() async {
    // ✅ 1. ESSAYER SharedPreferences
    String? dateInscription = _prefs?.getString('date_inscription');

    // ✅ 2. SI PAS EN SharedPreferences, ESSAYER FIRESTORE
    if (dateInscription == null) {
      final userId = getCurrentUserId();
      if (userId != null) {
        try {
          final doc = await _firestore.collection('users').doc(userId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data.containsKey('dateInscription')) {
              dateInscription = data['dateInscription'] as String?;
              if (dateInscription != null) {
                await _prefs?.setString('date_inscription', dateInscription);
                Logger.info('📅 Date d\'inscription récupérée de Firestore: $dateInscription');
              }
            }
          }
        } catch (e) {
          Logger.error('❌ Erreur récupération date Firestore: $e');
        }
      }
    }

    // ✅ 3. SI TOUJOURS PAS DE DATE
    if (dateInscription == null) {
      Logger.warning('⚠️ Date d\'inscription non trouvée');
      return false;
    }

    try {
      final date = DateTime.parse(dateInscription);
      final now = DateTime.now();
      final diff = now.difference(date);
      final estExpire = diff.inDays > DUREE_ESSAI_JOURS;
      Logger.info('📅 Date inscription: ${date.toIso8601String()}, Jours: ${diff.inDays}, Expiré: $estExpire');
      return estExpire;
    } catch (e) {
      Logger.error('❌ Erreur lecture date inscription: $e');
      return false;
    }
  }

  /// Sauvegarde la date d'inscription
  Future<void> sauvegarderDateInscription(DateTime date) async {
    await _prefs?.setString('date_inscription', date.toIso8601String());
    Logger.info('📅 Date d\'inscription sauvegardée: ${date.toIso8601String()}');

    // ✅ AUSSI EN FIRESTORE
    final userId = getCurrentUserId();
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'dateInscription': date.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.info('📅 Date d\'inscription sauvegardée dans Firestore');
      } catch (e) {
        Logger.error('❌ Erreur sauvegarde date dans Firestore: $e');
      }
    }
  }

  // ============================================
  // GESTION DE L'ACCÈS
  // ============================================

  /// Vérifie si l'utilisateur a l'accès à vie
  bool get aAccesAVie {
    return _prefs?.getBool('acces_vie') ?? false;
  }

  /// Vérifie si l'utilisateur a un accès root
  bool get isRootUser {
    final cle = _prefs?.getString('cle_activee');
    if (cle == null) return false;
    return ROOT_KEYS.contains(cle);
  }

  /// Vérifie si une clé est valide (root ou standard)
  bool verifierCle(String cle) {
    if (cle.isEmpty) return false;

    // ✅ VÉRIFIER SI C'EST UNE CLÉ ROOT
    if (ROOT_KEYS.contains(cle)) {
      Logger.info('👑 Clé root validée: $cle');
      return true;
    }

    // ✅ VÉRIFIER LE FORMAT STANDARD
    final regex = RegExp(r'^TB-2026-[A-Z0-9]{8}$');
    return regex.hasMatch(cle);
  }

  /// Active l'accès à vie (root ou standard)
  Future<void> activerAccesVie(String cle) async {
    final isRoot = ROOT_KEYS.contains(cle);

    await _prefs?.setBool('acces_vie', true);
    await _prefs?.setString('cle_activee', cle);
    await _prefs?.setString('date_activation', DateTime.now().toIso8601String());

    // ✅ SI ROOT, SAUVEGARDER LE TYPE D'ACCÈS
    if (isRoot) {
      await _prefs?.setString('acces_type', 'root');
      Logger.info('👑 Accès root activé avec la clé: $cle');
    } else {
      await _prefs?.setString('acces_type', 'premium');
      Logger.info('✅ Accès premium activé avec la clé: $cle');
    }

    // Mettre à jour Firestore
    final userId = getCurrentUserId();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'hasAccesVie': true,
        'cleActivee': cle,
        'accesType': isRoot ? 'root' : 'premium',
        'dateActivation': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('✅ Accès activé dans Firestore pour: $userId');
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
    final isRoot = isRootUser;

    if (prenom == null) return null;
    return {
      'prenom': prenom,
      'telephone': telephone ?? '',
      'monnaie': monnaie,
      'pinCode': pinCode,
      'hasAccesVie': hasAccesVie,
      'isRoot': isRoot,
    };
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final uid = _auth.currentUser?.uid ?? user.uuid;

      await _firestore.collection('users').doc(uid).set({
        'uuid': user.uuid,
        'prenom': user.prenom,
        'telephone': user.telephone,
        'indicatif': user.indicatif,
        'codePays': user.codePays,
        'monnaie': user.monnaie,
        'pinCode': user.pinCode,
        'hasAccesVie': user.hasAccesVie,
        'dateInscription': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentUserId = uid;
      await _prefs?.setString('user_id', uid);
      await _prefs?.setString('user_telephone', user.telephone);
      await _prefs?.setString('user_prenom', user.prenom);
      await _prefs?.setString('user_monnaie', user.monnaie);
      await _prefs?.setString('user_pin', user.pinCode);

      // ✅ SAUVEGARDER LA DATE POUR L'ESSAI
      await sauvegarderDateInscription(DateTime.now());

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
    final userId = getCurrentUserId();
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
      {'uuid': 'wallet-${DateTime.now().millisecondsSinceEpoch}-001', 'nom': 'Compte Principal', 'type': 'compte', 'emoji': '🏦', 'solde': 0.0, 'seuilAlerte': 10000.0, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()},
      {'uuid': 'wallet-${DateTime.now().millisecondsSinceEpoch}-002', 'nom': 'Wave', 'type': 'mobile', 'emoji': '📱', 'solde': 0.0, 'seuilAlerte': 5000.0, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()},
      {'uuid': 'wallet-${DateTime.now().millisecondsSinceEpoch}-003', 'nom': 'Espèces', 'type': 'especes', 'emoji': '💵', 'solde': 0.0, 'seuilAlerte': 3000.0, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()},
    ];
    final batch = _firestore.batch();
    for (final wallet in defaultWallets) {
      final docRef = _firestore.collection('users').doc(userId).collection('wallets').doc();
      batch.set(docRef, wallet);
    }
    await batch.commit();
    Logger.info('📂 Portefeuilles par défaut créés');
  }

  List<WalletModel> getWallets() => [];

  Future<void> saveWallet(WalletModel wallet) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    if (wallet.id != null) {
      await _firestore.collection('users').doc(userId).collection('wallets').doc(wallet.id.toString()).update({
        'nom': wallet.nom, 'solde': wallet.solde, 'seuilAlerte': wallet.seuilAlerte, 'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('users').doc(userId).collection('wallets').add({
        'uuid': wallet.uuid, 'nom': wallet.nom, 'type': wallet.type, 'emoji': wallet.emoji,
        'solde': wallet.solde, 'seuilAlerte': wallet.seuilAlerte,
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  List<TransactionModel> getTransactions() => [];

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).collection('transactions').add({
      'uuid': transaction.uuid,
      'portefeuilleId': transaction.portefeuilleId,
      'portefeuilleDestId': transaction.portefeuilleDestId,
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

  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {}
  Future<void> deleteTransaction(TransactionModel transaction) async {}

  // ============================================
  // CATÉGORIES
  // ============================================

  Future<void> _initDefaultCategories(String userId) async {
    final categories = [
      {'id': 'nourriture', 'label': 'Alimentation', 'emoji': '🍽️', 'type': 'depense'},
      {'id': 'transport', 'label': 'Transport', 'emoji': '🚗', 'type': 'depense'},
      {'id': 'facture', 'label': 'Facture', 'emoji': '📄', 'type': 'depense'},
      {'id': 'logement', 'label': 'Logement', 'emoji': '🏠', 'type': 'depense'},
      {'id': 'sante', 'label': 'Santé', 'emoji': '🏥', 'type': 'depense'},
      {'id': 'education', 'label': 'Éducation', 'emoji': '📚', 'type': 'depense'},
      {'id': 'loisirs', 'label': 'Loisirs', 'emoji': '🎮', 'type': 'depense'},
      {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰', 'type': 'revenu'},
    ];
    final batch = _firestore.batch();
    for (final cat in categories) {
      final docRef = _firestore.collection('users').doc(userId).collection('categories').doc(cat['id']);
      batch.set(docRef, {
        'label': cat['label'],
        'emoji': cat['emoji'],
        'type': cat['type'],
        'isDefault': true,
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    Logger.info('📂 Catégories par défaut créées');
  }

  Future<void> _loadCategories() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      _categories = [];
      return;
    }
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();
      _categories = snap.docs.map((d) => {
        'id': d.id,
        ...d.data(),
      }).toList();
      Logger.info('📂 Catégories chargées: ${_categories.length}');
    } catch (e) {
      Logger.error('❌ Erreur chargement catégories: $e');
      _categories = [];
    }
  }

  Future<void> refreshCategories() => _loadCategories();

  List<Map<String, dynamic>> getCategories() => _categories;

  Future<void> addCategory(Map<String, dynamic> category) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      Logger.error('❌ addCategory - Utilisateur non authentifié');
      throw Exception('Utilisateur non authentifié');
    }

    final id = category['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    final label = category['label'] as String? ?? 'Autre';
    final emoji = category['emoji'] as String? ?? '📌';
    final type = category['type'] as String? ?? 'depense';

    Logger.info('📝 Ajout catégorie: $label ($type) - userId: $userId');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(id)
          .set({
        'label': label,
        'emoji': emoji,
        'type': type,
        'isDefault': category['isDefault'] ?? false,
        'uid': userId,
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
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId)
          .delete();

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
    final userId = getCurrentUserId();
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).collection('echeances').add({
      'titre': echeance.titre,
      'montant': echeance.montant,
      'type': echeance.type,
      'jourDuMois': echeance.jourDuMois,
      'jourDeLaSemaine': echeance.jourDeLaSemaine,
      'datePrecise': echeance.datePrecise,
      'rappelAvant': echeance.rappelAvant,
      'emoji': echeance.emoji,
      'active': echeance.active,
      'createdAt': FieldValue.serverTimestamp(),
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
    final userId = getCurrentUserId();
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
    final userId = getCurrentUserId();
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_budgetDocId(budget.mois, budget.annee))
        .set(budget.toMap());
  }

  Future<void> deleteBudget(int mois, int annee) async {
    final userId = getCurrentUserId();
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(_budgetDocId(mois, annee))
        .delete();
  }

  Future<double> _sommeTransactions(int mois, int annee, String type) async {
    final userId = getCurrentUserId();
    if (userId == null) return 0.0;
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
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

  Future<double> getDepensesReellesByCategorie(String categorieId, int mois, int annee) async {
    final userId = getCurrentUserId();
    if (userId == null) return 0.0;
    final debut = DateTime(annee, mois, 1);
    final fin = DateTime(annee, mois + 1, 1);
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
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
  Future<void> marquerOnboardingVu() async => await _prefs?.setBool('onboarding_vu', true);

  // ============================================
  // NOTIFICATIONS
  // ============================================

  bool get notificationsActivees => _prefs?.getBool('notifications_activees') ?? true;
  Future<void> setNotifications(bool value) async => await _prefs?.setBool('notifications_activees', value);

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