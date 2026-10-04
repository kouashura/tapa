// lib/data/repositories/auth_repository_impl.dart

import '../../domain/repositories/i_auth_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_auth_datasource.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository d'authentification
class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuthDatasource _authDatasource;
  final FirebaseFirestoreDatasource _firestoreDatasource;

  AuthRepositoryImpl({
    FirebaseAuthDatasource? authDatasource,
    FirebaseFirestoreDatasource? firestoreDatasource,
  })  : _authDatasource = authDatasource ?? FirebaseAuthDatasource(),
        _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  // ============================================
  // AUTHENTIFICATION PAR TÉLÉPHONE
  // ============================================

  @override
  Future<void> sendVerificationCode(String phoneNumber) async {
    try {
      Logger.info('📱 Envoi du code de vérification à: $phoneNumber');
      await _authDatasource.sendVerificationCodeSimple(phoneNumber);
      Logger.success('✅ Code de vérification envoyé');
    } catch (e) {
      Logger.error('❌ Erreur envoi code: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ✅ NOUVELLE MÉTHODE AVEC CALLBACK
  @override
  Future<void> sendVerificationCodeWithCallback(
      String phoneNumber, {
        required void Function(String verificationId) onCodeSent,
        void Function(String error)? onError,
      }) async {
    try {
      Logger.info('📱 Envoi du code avec callback à: $phoneNumber');

      await _authDatasource.sendVerificationCode(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, forceResendingToken) {
          Logger.info('✅ Code envoyé, verificationId reçu');
          onCodeSent(verificationId);
        },
        onError: (error) {
          Logger.error('❌ Erreur Firebase: ${error.message}');
          onError?.call(error.message ?? 'Erreur inconnue');
        },
      );

      Logger.success('✅ Code de vérification envoyé');
    } catch (e) {
      Logger.error('❌ Erreur envoi code: $e');
      onError?.call(e.toString());
    }
  }

  @override
  Future<AppUser> verifyPhoneNumber(String verificationId, String smsCode) async {
    try {
      Logger.info('🔍 Vérification du code SMS...');

      // Vérification des paramètres
      if (verificationId.isEmpty || smsCode.isEmpty) {
        throw const AuthFailure(
          message: 'VerificationId ou code SMS vide',
          code: 'INVALID_PARAMS',
        );
      }

      if (smsCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(smsCode)) {
        throw const AuthFailure(
          message: 'Le code SMS doit contenir 6 chiffres',
          code: 'INVALID_CODE',
        );
      }

      final user = await _authDatasource.verifyPhoneNumber(verificationId, smsCode);

      if (user == null) {
        throw const AuthFailure(
          message: 'Utilisateur non trouvé après vérification.',
          code: 'USER_NOT_FOUND',
        );
      }

      Logger.success('✅ Utilisateur authentifié: ${user.id}');
      return user;
    } catch (e) {
      Logger.error('❌ Erreur vérification: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<AppUser> signInWithPhoneNumber(String phoneNumber) async {
    try {
      Logger.info('📱 Connexion avec numéro: $phoneNumber');
      throw const AuthFailure(
        message: 'Aucun compte trouvé avec ce numéro. Veuillez vous inscrire.',
        code: 'USER_NOT_FOUND',
      );
    } catch (e) {
      Logger.error('❌ Erreur connexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // CRÉATION DE COMPTE
  // ============================================

  @override
  Future<AppUser> createUser({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    try {
      Logger.info('🔍 Création utilisateur: $prenom ($telephone)');

      final user = await _authDatasource.createUser(
        prenom: prenom,
        telephone: telephone,
        indicatif: indicatif,
        codePays: codePays,
        monnaie: monnaie,
      );

      Logger.success('✅ Utilisateur créé: ${user.prenom} (${user.id})');
      return user;
    } catch (e) {
      Logger.error('❌ Erreur création utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // DÉCONNEXION
  // ============================================

  @override
  Future<void> signOut() async {
    try {
      Logger.info('🔓 Déconnexion...');
      await _authDatasource.signOut();
      Logger.success('✅ Déconnecté avec succès');
    } catch (e) {
      Logger.error('❌ Erreur déconnexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // SUPPRESSION DE COMPTE
  // ============================================

  @override
  Future<void> deleteAccount() async {
    try {
      Logger.info('🗑️ Suppression du compte...');
      await _authDatasource.deleteAccount();
      Logger.success('✅ Compte supprimé avec succès');
    } catch (e) {
      Logger.error('❌ Erreur suppression compte: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // RÉCUPÉRATION UTILISATEUR
  // ============================================

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _authDatasource.getCurrentUser();

      if (user == null) {
        Logger.info('🔍 Aucun utilisateur connecté');
        return null;
      }

      Logger.info('👤 Utilisateur trouvé: ${user.prenom}');
      return user;
    } catch (e) {
      Logger.error('❌ Erreur récupération utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return _authDatasource.isAuthenticated;
    } catch (e) {
      Logger.error('❌ Erreur vérification authentification: $e');
      return false;
    }
  }

  // ============================================
  // MISE À JOUR UTILISATEUR
  // ============================================

  @override
  Future<void> updateUser(AppUser user) async {
    try {
      Logger.info('📝 Mise à jour utilisateur: ${user.prenom}');
      await _authDatasource.updateUser(user);
      Logger.success('✅ Utilisateur mis à jour');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updatePrenom(String prenom) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw const AuthFailure(
          message: 'Aucun utilisateur connecté.',
          code: 'NOT_AUTHENTICATED',
        );
      }

      final updatedUser = user.copyWith(
        prenom: prenom,
        dernierActive: DateTime.now(),
      );

      await updateUser(updatedUser);
      Logger.success('✅ Prénom mis à jour: $prenom');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour prénom: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateMonnaie(String monnaie) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw const AuthFailure(
          message: 'Aucun utilisateur connecté.',
          code: 'NOT_AUTHENTICATED',
        );
      }

      final updatedUser = user.copyWith(
        monnaie: monnaie,
        dernierActive: DateTime.now(),
      );

      await updateUser(updatedUser);
      Logger.success('✅ Monnaie mise à jour: $monnaie');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour monnaie: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // ONBOARDING ET NOTIFICATIONS
  // ============================================

  @override
  Future<void> markOnboardingAsSeen() async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw const AuthFailure(
          message: 'Aucun utilisateur connecté.',
          code: 'NOT_AUTHENTICATED',
        );
      }

      final updatedUser = user.copyWith(
        onboardingVu: true,
        dernierActive: DateTime.now(),
      );

      await updateUser(updatedUser);
      Logger.success('✅ Onboarding marqué comme vu');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour onboarding: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw const AuthFailure(
          message: 'Aucun utilisateur connecté.',
          code: 'NOT_AUTHENTICATED',
        );
      }

      final updatedUser = user.copyWith(
        notificationsActivees: enabled,
        dernierActive: DateTime.now(),
      );

      await updateUser(updatedUser);
      Logger.success('✅ Notifications ${enabled ? 'activées' : 'désactivées'}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour notifications: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateLastLogin() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return;

      final updatedUser = user.copyWith(
        dernierActive: DateTime.now(),
      );

      await updateUser(updatedUser);
      Logger.info('📝 Dernière connexion mise à jour');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour dernière connexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}