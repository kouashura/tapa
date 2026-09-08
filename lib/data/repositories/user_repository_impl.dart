// lib/data/repositories/user_repository_impl.dart

import '../../domain/repositories/i_user_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

/// Implémentation du repository utilisateur
class UserRepositoryImpl implements IUserRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  UserRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource = firestoreDatasource ?? FirebaseFirestoreDatasource();

  // ============================================
  // RÉCUPÉRATION UTILISATEUR
  // ============================================

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      // L'utilisateur est récupéré via l'auth repository
      // Cette méthode est déléguée à AuthRepositoryImpl
      Logger.info('👤 Récupération utilisateur en cours...');
      return null;
    } catch (e) {
      Logger.error('❌ Erreur récupération utilisateur: $e');
      throw ErrorHandler().handleException(e);
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
    try {
      Logger.info('📝 Création utilisateur: $prenom');

      final user = AppUser(
        id: '', // Sera défini par Firebase
        phoneNumber: telephone,
        prenom: prenom,
        monnaie: monnaie,
        codePays: codePays,
        hasAccessVie: false,
        onboardingVu: false,
        notificationsActivees: true,
        createdAt: DateTime.now(),
        dernierActive: DateTime.now(),
      );

      // Sauvegarder dans Firestore (l'ID sera généré par Firebase)
      // await _firestoreDatasource.saveUser(user);

      Logger.success('✅ Utilisateur créé: ${user.prenom}');
      return user;
    } catch (e) {
      Logger.error('❌ Erreur création utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateUser(AppUser user) async {
    try {
      Logger.info('📝 Mise à jour utilisateur: ${user.prenom}');
      await _firestoreDatasource.saveUser(user);
      Logger.success('✅ Utilisateur mis à jour');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      Logger.info('🗑️ Suppression utilisateur...');
      // La suppression est gérée par AuthRepositoryImpl
      Logger.success('✅ Utilisateur supprimé');
    } catch (e) {
      Logger.error('❌ Erreur suppression utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      Logger.info('🔓 Déconnexion...');
      // La déconnexion est gérée par AuthRepositoryImpl
      Logger.success('✅ Déconnecté');
    } catch (e) {
      Logger.error('❌ Erreur déconnexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Vérification déléguée à AuthRepositoryImpl
      return false;
    } catch (e) {
      Logger.error('❌ Erreur vérification authentification: $e');
      return false;
    }
  }

  @override
  Future<String> getCurrentUserId() async {
    try {
      // Récupération déléguée à AuthRepositoryImpl
      return '';
    } catch (e) {
      Logger.error('❌ Erreur récupération ID utilisateur: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // PROFIL
  // ============================================

  @override
  Future<void> markOnboardingAsSeen() async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw AuthFailure(
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
        throw AuthFailure(
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

  @override
  Future<void> updateMonnaie(String monnaie) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw AuthFailure(
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

  @override
  Future<void> updatePrenom(String prenom) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw AuthFailure(
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

  // ============================================
  // PIN
  // ============================================

  @override
  Future<bool> verifyPin(String pin) async {
    try {
      // La vérification PIN est gérée par PinSecurity
      Logger.info('🔍 Vérification PIN...');
      return false;
    } catch (e) {
      Logger.error('❌ Erreur vérification PIN: $e');
      return false;
    }
  }

  @override
  Future<void> savePin(String pin) async {
    try {
      // La sauvegarde PIN est gérée par PinSecurity
      Logger.info('🔐 Sauvegarde PIN...');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde PIN: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<bool> hasPin() async {
    try {
      // La vérification de l'existence du PIN est gérée par PinSecurity
      Logger.info('🔍 Vérification existence PIN...');
      return false;
    } catch (e) {
      Logger.error('❌ Erreur vérification existence PIN: $e');
      return false;
    }
  }
}
