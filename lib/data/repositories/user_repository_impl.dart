// lib/data/repositories/user_repository_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../data/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/datasources/firebase/firebase_firestore.dart';
import '../../services/firebase_service.dart';
import '../../core/utils/logger.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  final FirebaseService _firebaseService = FirebaseService();

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firestore.currentUser;
    if (firebaseUser == null) {
      Logger.info('🔍 getCurrentUser - Aucun utilisateur Firebase');
      return null;
    }

    Logger.info('🔍 getCurrentUser - Firebase UID: ${firebaseUser.uid}');
    Logger.info('🔍 getCurrentUser - Firebase Phone: ${firebaseUser.phoneNumber}');

    try {
      final doc = await _firestore.getUserData(firebaseUser.uid);
      if (doc == null || !doc.exists) {
        Logger.info('🔍 getCurrentUser - Aucun document Firestore pour cet UID');
        return null;
      }
      final user = AppUser.fromFirestore(doc);
      Logger.info('✅ getCurrentUser - Utilisateur trouvé: ${user.prenom}');
      Logger.info('✅ getCurrentUser - Téléphone Firestore: ${user.telephone}');

      // ✅ VÉRIFIER L'ACCÈS (root, premium ou essai)
      final isRoot = _firebaseService.isRootUser;
      final aAcces = _firebaseService.aAccesAVie;
      final essaiExpire = _firebaseService.essaiGratuitExpire;

      final peutAcceder = isRoot || aAcces || !essaiExpire;
      Logger.info('🔍 getCurrentUser - Accès: ${peutAcceder ? "✅ Valide" : "❌ Expiré"}');
      Logger.info('🔍 getCurrentUser - Root: $isRoot, Premium: $aAcces, Essai expiré: $essaiExpire');

      return user;
    } catch (e) {
      Logger.error('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  @override
  Future<AppUser> createUser({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    final firebaseUser = _firestore.currentUser;
    if (firebaseUser == null) {
      Logger.error('❌ createUser - Utilisateur non authentifié');
      throw Exception('Utilisateur non authentifié');
    }

    // ✅ Utiliser le numéro Firebase Auth (source de vérité)
    final String firebasePhone = firebaseUser.phoneNumber ?? telephone;

    Logger.info('🔍 createUser - Firebase UID: ${firebaseUser.uid}');
    Logger.info('🔍 createUser - Firebase Phone: $firebasePhone');
    Logger.info('🔍 createUser - Param Phone reçu: $telephone');

    // ✅ UTILISER L'UID COMME ID FIRESTORE (un seul numéro par compte)
    final user = AppUser(
      id: firebaseUser.uid,        // ← ID = UID Firebase
      uid: firebaseUser.uid,       // ← UID Firebase
      prenom: prenom,
      telephone: firebasePhone,    // ← Numéro Firebase Auth (authentifié)
      indicatif: indicatif,
      codePays: codePays,
      monnaie: monnaie,
      dateInscription: DateTime.now(),
      dernierConnexion: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      hasAccesVie: false,          // ← Pas d'accès payant au départ
    );

    Logger.info('🔍 createUser - Données à sauvegarder: ${user.toFirestore()}');

    try {
      await _firestore.setUserData(user.toFirestore(), user.id);
      Logger.success('✅ Utilisateur créé avec succès: ${user.prenom}');
      Logger.success('✅ ID Firestore: ${user.id}');
      Logger.success('✅ Téléphone enregistré: ${user.telephone}');

      // ✅ SAUVEGARDER LA DATE D'INSCRIPTION POUR L'ESSAI GRATUIT
      await _firebaseService.sauvegarderDateInscription(DateTime.now());
      Logger.info('📅 Date d\'inscription sauvegardée pour l\'essai gratuit');

      // ✅ VÉRIFICATION IMMÉDIATE
      final checkUser = await getCurrentUser();
      if (checkUser != null) {
        Logger.success('✅ Vérification: Utilisateur trouvé dans Firestore');
      } else {
        Logger.error('❌ Vérification: Utilisateur NON trouvé dans Firestore après création');
      }

      return user;
    } catch (e) {
      Logger.error('❌ Erreur createUser: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    try {
      Logger.info('🔍 updateUser - Mise à jour pour: ${user.prenom} (${user.id})');
      await _firestore.setUserData(user.toFirestore(), user.id);
      Logger.success('📝 Utilisateur mis à jour: ${user.prenom}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour utilisateur: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      Logger.info('🔍 deleteUser - Suppression du compte');
      await _firestore.deleteUserAccount();
      Logger.success('🗑️ Compte utilisateur supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression compte: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firestore.signOut();

      // ✅ NETTOYER LES DONNÉES DE SESSION
      await _firebaseService.setCurrentUser(null);

      Logger.success('🔓 Déconnexion réussie');
    } catch (e) {
      Logger.error('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final isAuth = _firestore.isAuthenticated;
    Logger.info('🔍 isAuthenticated: $isAuth');
    return isAuth;
  }

  @override
  Future<String> getCurrentUserId() async {
    final uid = _firestore.currentUserId;
    if (uid == null) {
      Logger.error('❌ getCurrentUserId - Non authentifié');
      throw Exception('Non authentifié');
    }
    Logger.info('🔍 getCurrentUserId: $uid');
    return uid;
  }

  // ============================================
  // GESTION DE L'ESSAI GRATUIT ET ACCÈS
  // ============================================

  /// Vérifie si l'essai gratuit est expiré
  bool get essaiGratuitExpire => _firebaseService.essaiGratuitExpire;

  /// Nombre de jours restants pour l'essai gratuit
  int get joursRestantsEssai => _firebaseService.joursRestantsEssai;

  /// Vérifie si l'utilisateur a l'accès à vie
  bool get aAccesAVie => _firebaseService.aAccesAVie;

  /// Vérifie si l'utilisateur a un accès root
  bool get isRootUser => _firebaseService.isRootUser;

  /// Vérifie si l'utilisateur peut accéder à l'application
  bool get peutAcceder => _firebaseService.isRootUser ||
      _firebaseService.aAccesAVie ||
      !_firebaseService.essaiGratuitExpire;

  /// Vérifie si l'essai est expiré (version asynchrone)
  Future<bool> isEssaiGratuitExpire() async {
    return await _firebaseService.isEssaiGratuitExpire();
  }

  /// Active l'accès à vie avec une clé
  Future<void> activerAccesVie(String cle) async {
    await _firebaseService.activerAccesVie(cle);
    Logger.success('✅ Accès à vie activé avec la clé: $cle');
  }

  /// Vérifie si une clé est valide
  bool verifierCle(String cle) => _firebaseService.verifierCle(cle);

  // ============================================
  // PROFIL
  // ============================================

  @override
  Future<void> markOnboardingAsSeen() async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        onboardingVu: true,
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.info('📝 Onboarding marqué comme vu');
    } else {
      Logger.warning('⚠️ markOnboardingAsSeen - Utilisateur non trouvé');
    }
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        notificationsActivees: enabled,
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.info('📝 Notifications: $enabled');
    } else {
      Logger.warning('⚠️ setNotificationsEnabled - Utilisateur non trouvé');
    }
  }

  @override
  Future<void> updateLastLogin() async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        dernierConnexion: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.info('📝 Dernière connexion mise à jour');
    } else {
      Logger.warning('⚠️ updateLastLogin - Utilisateur non trouvé');
    }
  }

  @override
  Future<void> updateMonnaie(String monnaie) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        monnaie: monnaie,
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.info('📝 Monnaie mise à jour: $monnaie');
    } else {
      Logger.warning('⚠️ updateMonnaie - Utilisateur non trouvé');
    }
  }

  @override
  Future<void> updatePrenom(String prenom) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        prenom: prenom,
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.info('📝 Prénom mis à jour: $prenom');
    } else {
      Logger.warning('⚠️ updatePrenom - Utilisateur non trouvé');
    }
  }

  // ============================================
  // PIN
  // ============================================

  @override
  Future<bool> verifyPin(String pin) async {
    final user = await getCurrentUser();
    final isValid = user != null && user.pinCode == pin;
    Logger.info('🔍 verifyPin: ${isValid ? "✅ Valide" : "❌ Invalide"}');
    return isValid;
  }

  @override
  Future<void> savePin(String pin) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        pinCode: pin,
        updatedAt: DateTime.now(),
      );
      await updateUser(updated);
      Logger.success('📝 PIN sauvegardé');
    } else {
      Logger.warning('⚠️ savePin - Utilisateur non trouvé');
    }
  }

  @override
  Future<bool> hasPin() async {
    final user = await getCurrentUser();
    final hasPin = user != null && user.pinCode.isNotEmpty;
    Logger.info('🔍 hasPin: $hasPin');
    return hasPin;
  }
}