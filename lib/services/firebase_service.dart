// lib/services/firebase_service.dart

import '../core/utils/date_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
import '../core/utils/logger.dart';
import 'pin_security.dart';

/// Service principal d'interaction avec Firebase
/// Gère l'authentification, les données utilisateur et la sécurité
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

  // ✅ ROOT_DEV_KEY depuis .env
  static String get _rootDevKey => dotenv.env['ROOT_DEV_KEY'] ?? '';

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
        Logger.info(
            '✅ FirebaseService - Utilisateur restauré: $_currentUserId');
      } else {
        Logger.info('ℹ️ FirebaseService - Aucun utilisateur');
      }
    }

    if (_currentUserId != null) {
      await _loadCategories();
      Logger.info('📂 Catégories initiales: ${_categories.length}');
    }

    _verifierConfigurationRoot();
  }

  // ✅ VÉRIFIER LA CONFIGURATION ROOT
  void _verifierConfigurationRoot() {
    if (_rootDevKey.isEmpty) {
      Logger.warning('⚠️ ROOT_DEV_KEY non définie dans .env');
    } else {
      Logger.info('✅ ROOT_DEV_KEY chargée avec succès');
    }
  }

  // ============================================
  // AUTH - GESTION DE L'UTILISATEUR
  // ============================================

  String? getCurrentUserId() {
    if (_currentUserId == null) {
      final user = _auth.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _prefs?.setString('user_id', user.uid);
        Logger.info(
            '🔍 getCurrentUserId - Récupéré depuis Firebase Auth: ${user.uid}');
      }
    }
    return _currentUserId;
  }

  bool get isLoggedIn {
    final user = _auth.currentUser;
    return user != null || _currentUserId != null;
  }

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
  // GESTION DE L'ESSAI GRATUIT - ✅ CORRIGÉ
  // ============================================

  bool get essaiGratuitExpire {
    // ✅ 1. Lire depuis SharedPreferences d'abord
    String? dateInscription = _prefs?.getString('date_inscription');

    // ✅ 2. Si pas en local, essayer de lire depuis Firestore (synchrone)
    if (dateInscription == null) {
      final userId = getCurrentUserId();
      if (userId != null) {
        try {
          // ⚠️ Lecture synchrone impossible avec Firestore
          // On va utiliser la version asynchrone via isEssaiGratuitExpire()
          Logger.warning(
              '⚠️ Date d\'inscription non trouvée localement, utilisez la version asynchrone');
          return false; // ✅ FALLBACK SÉCURISÉ
        } catch (e) {
          Logger.error('❌ Erreur récupération date: $e');
          return false;
        }
      }
      Logger.warning('⚠️ Date d\'inscription non trouvée');
      return false; // ✅ FALLBACK SÉCURISÉ
    }

    try {
      final date = DateTime.parse(dateInscription);
      final now = DateTime.now();
      final diff = now.difference(date);
      final isExpired = diff.inDays > DUREE_ESSAI_JOURS;
      Logger.info(
          '📅 Date inscription: $date, Jours écoulés: ${diff.inDays}, Expiré: $isExpired');
      return isExpired;
    } catch (e) {
      Logger.error('❌ Erreur lecture date inscription: $e');
      return false;
    }
  }

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

  Future<bool> isEssaiGratuitExpire() async {
    // ✅ 1. Lire depuis SharedPreferences
    String? dateInscription = _prefs?.getString('date_inscription');

    // ✅ 2. Si pas en local, lire depuis Firestore
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
                Logger.info(
                    '📅 Date chargée depuis Firestore: $dateInscription');
              }
            }
          }
        } catch (e) {
          Logger.error('❌ Erreur récupération date Firestore: $e');
        }
      }
    }

    if (dateInscription == null) {
      Logger.warning('⚠️ Date d\'inscription non trouvée');
      // ✅ FALLBACK : Si pas de date, on considère que l'essai n'est PAS expiré
      // pour ne pas bloquer l'utilisateur
      return false;
    }

    try {
      final date = DateTime.parse(dateInscription);
      final now = DateTime.now();
      final diff = now.difference(date);
      final isExpired = diff.inDays > DUREE_ESSAI_JOURS;
      Logger.info(
          '📅 Date inscription: $date, Jours écoulés: ${diff.inDays}, Expiré: $isExpired');
      return isExpired;
    } catch (e) {
      Logger.error('❌ Erreur lecture date inscription: $e');
      return false;
    }
  }

  Future<void> sauvegarderDateInscription(DateTime date) async {
    final dateStr = date.toIso8601String();

    // ✅ Sauvegarde locale
    await _prefs?.setString('date_inscription', dateStr);
    Logger.info('📅 Date d\'inscription sauvegardée localement: $dateStr');

    // ✅ Sauvegarde Firestore
    final userId = getCurrentUserId();
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'dateInscription': dateStr,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.info(
            '📅 Date d\'inscription sauvegardée dans Firestore: $dateStr');
      } catch (e) {
        Logger.error('❌ Erreur sauvegarde date dans Firestore: $e');
      }
    }
  }

  // ============================================
  // GESTION DE L'ACCÈS
  // ============================================

  bool get aAccesAVie => _prefs?.getBool('acces_vie') ?? false;

  bool get isRootUser {
    final cle = _prefs?.getString('cle_activee');
    if (cle == null) return false;
    final rootKey = _rootDevKey;
    return cle == rootKey && rootKey.isNotEmpty;
  }

  bool verifierCle(String cle) {
    if (cle.isEmpty) return false;

    // ✅ Vérifier la clé root
    final rootKey = _rootDevKey;
    if (cle == rootKey && rootKey.isNotEmpty) {
      Logger.info('👑 Clé root validée');
      return true;
    }

    // Vérifier les clés normales
    final regex = RegExp(r'^TB-2026-[A-Z0-9]{8}$');
    final isValid = regex.hasMatch(cle);
    if (isValid) {
      Logger.info('✅ Clé premium valide: $cle');
    } else {
      Logger.warning('⚠️ Clé invalide: $cle');
    }
    return isValid;
  }

  Future<void> activerAccesVie(String cle) async {
    final rootKey = _rootDevKey;
    final isRoot = cle == rootKey && rootKey.isNotEmpty;

    await _prefs?.setBool('acces_vie', true);
    await _prefs?.setString('cle_activee', cle);
    await _prefs?.setString(
        'date_activation', DateTime.now().toIso8601String());

    if (isRoot) {
      await _prefs?.setString('acces_type', 'root');
      Logger.info('👑 Accès root activé avec la clé: $cle');
    } else {
      await _prefs?.setString('acces_type', 'premium');
      Logger.info('✅ Accès premium activé avec la clé: $cle');
    }

    final userId = getCurrentUserId();
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'hasAccesVie': true,
          'cleActivee': cle,
          'accesType': isRoot ? 'root' : 'premium',
          'dateActivation': DateTime.now().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.info('✅ Accès sauvegardé dans Firestore pour $userId');
      } catch (e) {
        Logger.error('❌ Erreur sauvegarde accès dans Firestore: $e');
      }
    }
  }

  bool get peutAcceder => isRootUser || aAccesAVie || !essaiGratuitExpire;

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
      final uid = _auth.currentUser?.uid ?? user.id;
      final now = DateTime.now();

      await _firestore.collection('users').doc(uid).set({
        'phoneNumber': user.phoneNumber,
        'prenom': user.prenom,
        'monnaie': user.monnaie,
        'codePays': user.codePays,
        'hasAccessVie': user.hasAccessVie,
        'onboardingVu': user.onboardingVu,
        'notificationsActivees': user.notificationsActivees,
        'dateInscription': now.toIso8601String(), // ✅ SAUVEGARDE ICI
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _currentUserId = uid;
      await _prefs?.setString('user_id', uid);
      await _prefs?.setString('user_telephone', user.phoneNumber);
      await _prefs?.setString('user_prenom', user.prenom);
      await _prefs?.setString('user_monnaie', user.monnaie);

      // ✅ SAUVEGARDER LA DATE D'INSCRIPTION
      await sauvegarderDateInscription(now);

      await _initDefaultWallets(uid);
      await _initDefaultCategories(uid);
      await _loadCategories();

      Logger.info('✅ Utilisateur sauvegardé: $uid');
      Logger.info('📅 Date d\'inscription: $now');
    } catch (e) {
      Logger.error('❌ Erreur saveUser: $e');
      rethrow;
    }
  }

  // ============================================
  // PIN - SÉCURISÉ AVEC HASH ET ANTI-BRUTEFORCE
  // ============================================

  Future<void> savePin(String pin) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      await PinSecurity.savePin(userId, pin);

      final hashedPin = await PinSecurity.hashPinForStorage(pin);
      await _firestore.collection('users').doc(userId).set({
        'pinHash': hashedPin,
        'pinFailures': 0,
        'pinLockTime': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _prefs?.remove('user_pin');
      await _firestore.collection('users').doc(userId).update({
        'pinCode': FieldValue.delete(),
      });

      Logger.info('✅ PIN sauvegardé de manière sécurisée');
    } catch (e) {
      Logger.error('❌ Erreur savePin: $e');
      rethrow;
    }
  }

  Future<PinCheckResult> verifyPin(String pin) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return const PinCheckResult(
          success: false,
          message: 'Utilisateur non authentifié',
        );
      }

      final result = await PinSecurity.verifyPin(userId, pin);

      if (result.success) {
        await _firestore.collection('users').doc(userId).set({
          'pinFailures': 0,
          'pinLockTime': 0,
          'lastPinVerifiedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (result.isLocked) {
        await _firestore.collection('users').doc(userId).set({
          'pinLockTime': result.lockTime?.millisecondsSinceEpoch ?? 0,
          'pinFailures': 5,
        }, SetOptions(merge: true));
      } else {
        final doc = await _firestore.collection('users').doc(userId).get();
        final currentFailures = (doc.data()?['pinFailures'] as int?) ?? 0;
        await _firestore.collection('users').doc(userId).set({
          'pinFailures': currentFailures + 1,
        }, SetOptions(merge: true));
      }

      return result;
    } catch (e) {
      Logger.error('❌ Erreur verifyPin: $e');
      return const PinCheckResult(
        success: false,
        message: 'Erreur lors de la vérification',
      );
    }
  }

  Future<bool> hasPin() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final hasLocalPin = await PinSecurity.hasPin(userId);
      if (hasLocalPin) return true;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final pinHash = data['pinHash'] as String?;
          if (pinHash != null && pinHash.isNotEmpty) {
            await PinSecurity.migrateFromFirestore(userId, pinHash);
            Logger.info('✅ PIN migré de Firestore vers stockage local');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      Logger.error('❌ Erreur hasPin: $e');
      return false;
    }
  }

  Future<void> clearPinData() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      await PinSecurity.clearPinData(userId);
      await _firestore.collection('users').doc(userId).set({
        'pinHash': FieldValue.delete(),
        'pinFailures': FieldValue.delete(),
        'pinLockTime': FieldValue.delete(),
      }, SetOptions(merge: true));

      Logger.info('✅ Données PIN supprimées');
    } catch (e) {
      Logger.error('❌ Erreur clearPinData: $e');
      rethrow;
    }
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

  Future<List<WalletModel>> getWallets() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final snap = await _firestore
          .collection('wallets')
          .where('uid', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();

      return snap.docs.map((doc) {
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
          createdAt: parseFirestoreDateOrNull(data['createdAt']),
          updatedAt: parseFirestoreDateOrNull(data['updatedAt']),
        );
      }).toList();
    } catch (e) {
      Logger.error('❌ Erreur getWallets: $e');
      return [];
    }
  }

  Future<void> saveWallet(WalletModel wallet) async {
    final userId = getCurrentUserId();
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

  Future<List<TransactionModel>> getTransactions() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      final snap = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: userId)
          .orderBy('dateTransaction', descending: true)
          .limit(100)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          walletId: data['walletId'] ?? '',
          montant: (data['montant'] as num?)?.toDouble() ?? 0,
          type: _parseTransactionType(data['type'] as String? ?? 'depense'),
          categorieId: data['categorieId'] ?? '',
          categorieLabel: data['categorieLabel'] ?? 'Autre',
          categorieEmoji: data['categorieEmoji'] ?? '📌',
          note: data['note'],
          dateTransaction: parseFirestoreDate(data['dateTransaction']),
          createdAt: parseFirestoreDate(data['createdAt']),
        );
      }).toList();
    } catch (e) {
      Logger.error('❌ Erreur getTransactions: $e');
      return [];
    }
  }

  TransactionType _parseTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'revenu':
        return TransactionType.revenu;
      case 'transfert':
        return TransactionType.transfert;
      default:
        return TransactionType.depense;
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = getCurrentUserId();
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
      // Dépenses
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
      {
        'id': 'shopping',
        'label': 'Shopping',
        'emoji': '🛍️',
        'type': 'depense'
      },
      {
        'id': 'restaurant',
        'label': 'Restaurant',
        'emoji': '🍜',
        'type': 'depense'
      },

      // Revenus
      {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰', 'type': 'revenu'},
      {
        'id': 'freelance',
        'label': 'Freelance',
        'emoji': '💻',
        'type': 'revenu'
      },
      {
        'id': 'investissement',
        'label': 'Investissement',
        'emoji': '📈',
        'type': 'revenu'
      },
      {'id': 'cadeau', 'label': 'Cadeau', 'emoji': '🎁', 'type': 'revenu'},
      {
        'id': 'remboursement',
        'label': 'Remboursement',
        'emoji': '🔄',
        'type': 'revenu'
      },
      {'id': 'interet', 'label': 'Intérêt', 'emoji': '🏦', 'type': 'revenu'},
      {
        'id': 'autre_revenu',
        'label': 'Autre revenu',
        'emoji': '💵',
        'type': 'revenu'
      },
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
    Logger.info('📂 Catégories par défaut créées (${categories.length})');
  }

  Future<void> _loadCategories() async {
    final userId = getCurrentUserId();
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
    } catch (e) {
      Logger.error('❌ Erreur chargement catégories: $e');
      _categories = [];
    }
  }

  List<Map<String, dynamic>> getCategories() => _categories;

  /// ✅ NOUVELLE MÉTHODE : Recharge depuis Firestore ET retourne la liste
  /// Utilise cette méthode au lieu de getCategories() pour forcer le refresh
  Future<List<Map<String, dynamic>>> reloadCategoriesFromFirestore() async {
    await _loadCategories();
    return List<Map<String, dynamic>>.from(_categories);
  }

  Future<void> addCategory(Map<String, dynamic> category) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final id = category['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final label = category['label'] as String? ?? 'Autre';
    final emoji = category['emoji'] as String? ?? '📌';
    final type = category['type'] as String? ?? 'depense';

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
      await _firestore.collection('categories').doc(categoryId).delete();
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

  Future<void> supprimerEcheance(String id) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _firestore.collection('echeances').doc(id).delete();
  }

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  List<EpargneProgrammeeModel> getEpargnesProgrammees() => [];

  Future<void> saveEpargneProgrammee(EpargneProgrammeeModel epargne) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _firestore.collection('epargnes_programmees').add({
      'uid': userId,
      'titre': epargne.titre,
      'montantObjectif': epargne.montantObjectif,
      'montantEpargne': epargne.montantEpargne,
      'frequence': epargne.frequence,
      'duree': epargne.duree,
      'montantParDepot': epargne.montantParDepot,
      'portefeuilleId': epargne.portefeuilleId,
      'dateFinPrevue': epargne.dateFinPrevue,
      'verrouille': epargne.verrouille,
      'codeDeverrouillage': epargne.codeDeverrouillage,
      'termine': epargne.termine,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> supprimerEpargneProgrammee(String id) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _firestore.collection('epargnes_programmees').doc(id).delete();
  }

  Future<void> effectuerDepotEpargne(EpargneProgrammeeModel epargne) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _firestore.collection('epargnes_programmees').doc(epargne.id).update({
      'montantEpargne': epargne.montantEpargne,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // OBJECTIFS D'ÉPARGNE
  // ============================================

  List<SavingsGoalModel> getSavingsGoals() => [];

  Future<void> addSavingsGoal(SavingsGoalModel goal) async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _firestore.collection('savings_goals').add({
      'uid': userId,
      'nom': goal.nom,
      'montantCible': goal.montantCible,
      'montantActuel': goal.montantActuel,
      'dateLimite': goal.dateLimite,
      'walletId': goal.walletId,
      'estAtteint': goal.estAtteint,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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
        .collection('transactions')
        .where('uid', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .where('dateTransaction', isGreaterThanOrEqualTo: debut)
        .where('dateTransaction', isLessThan: fin)
        .get();

    double total = 0.0;
    for (final d in snap.docs) {
      total += (d.data()['montant'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  Future<double> getTotalDepensesReelles(int mois, int annee) =>
      _sommeTransactions(mois, annee, 'depense');

  Future<double> getTotalRevenusReels(int mois, int annee) =>
      _sommeTransactions(mois, annee, 'revenu');

  Future<double> getDepensesReellesByCategorie(
      String categorieId, int mois, int annee) async {
    final userId = getCurrentUserId();
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

    double total = 0.0;
    for (final d in snap.docs) {
      total += (d.data()['montant'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return {
          'total_revenus': 0.0,
          'total_depenses': 0.0,
          'solde': 0.0,
          'nombre_transactions': 0,
          'revenus_prevus': 0.0,
          'depenses_prevues': 0.0,
          'solde_previsionnel': 0.0,
          'taux_depense': 0.0,
          'taux_revenu': 0.0,
        };
      }

      final transactions = await getTransactions();

      double totalRevenus = 0.0;
      double totalDepenses = 0.0;

      for (final tx in transactions) {
        if (tx.type == TransactionType.revenu) {
          totalRevenus += tx.montant;
        } else if (tx.type == TransactionType.depense) {
          totalDepenses += tx.montant;
        }
      }

      final now = DateTime.now();
      final budget = await getBudget(now.month, now.year);

      double revenusPrevus = 0.0;
      double depensesPrevues = 0.0;

      if (budget != null) {
        revenusPrevus = budget.totalRevenusPrevu;
        depensesPrevues = budget.totalDepensesPrevu;
      }

      return {
        'total_revenus': totalRevenus,
        'total_depenses': totalDepenses,
        'solde': totalRevenus - totalDepenses,
        'solde_previsionnel': revenusPrevus - depensesPrevues,
        'nombre_transactions': transactions.length,
        'revenus_prevus': revenusPrevus,
        'depenses_prevues': depensesPrevues,
        'taux_depense':
            depensesPrevues > 0 ? (totalDepenses / depensesPrevues) : 0.0,
        'taux_revenu': revenusPrevus > 0 ? (totalRevenus / revenusPrevus) : 0.0,
      };
    } catch (e) {
      Logger.error('❌ Erreur getStatistics: $e');
      return {
        'total_revenus': 0.0,
        'total_depenses': 0.0,
        'solde': 0.0,
        'solde_previsionnel': 0.0,
        'nombre_transactions': 0,
        'revenus_prevus': 0.0,
        'depenses_prevues': 0.0,
        'taux_depense': 0.0,
        'taux_revenu': 0.0,
      };
    }
  }

  // ============================================
  // ONBOARDING
  // ============================================

  bool get onboardingVu => _prefs?.getBool('onboarding_vu') ?? false;

  Future<void> marquerOnboardingVu() async {
    await _prefs?.setBool('onboarding_vu', true);

    final userId = getCurrentUserId();
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'onboardingVu': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        Logger.info('✅ onboardingVu=true synchronisé dans Firestore');
      } catch (e) {
        Logger.error('❌ Erreur mise à jour onboardingVu dans Firestore: $e');
        rethrow;
      }
    } else {
      Logger.warning(
          '⚠️ marquerOnboardingVu: aucun userId, Firestore non mis à jour');
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  bool get notificationsActivees =>
      _prefs?.getBool('notifications_activees') ?? true;
  Future<void> setNotifications(bool value) async =>
      await _prefs?.setBool('notifications_activees', value);

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
