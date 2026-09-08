// lib/domain/repositories/i_auth_repository.dart

import '../../data/models/models.dart';

/// Interface du repository d'authentification
abstract class IAuthRepository {
  // ============================================
  // AUTHENTIFICATION PAR TÉLÉPHONE
  // ============================================

  /// Envoie un code de vérification par SMS
  Future<void> sendVerificationCode(String phoneNumber);

  /// Envoie un code de vérification par SMS avec callback
  Future<void> sendVerificationCodeWithCallback(
      String phoneNumber, {
        required void Function(String verificationId) onCodeSent,
        void Function(String error)? onError,
      });

  /// Vérifie le code SMS et authentifie l'utilisateur
  Future<AppUser> verifyPhoneNumber(String verificationId, String smsCode);

  /// Connecte un utilisateur avec son numéro de téléphone
  Future<AppUser> signInWithPhoneNumber(String phoneNumber);

  // ============================================
  // CRÉATION DE COMPTE
  // ============================================

  /// Crée un nouvel utilisateur
  Future<AppUser> createUser({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  });

  // ============================================
  // DÉCONNEXION ET SUPPRESSION
  // ============================================

  /// Déconnecte l'utilisateur
  Future<void> signOut();

  /// Supprime définitivement le compte
  Future<void> deleteAccount();

  // ============================================
  // RÉCUPÉRATION UTILISATEUR
  // ============================================

  /// Récupère l'utilisateur actuellement connecté
  Future<AppUser?> getCurrentUser();

  /// Vérifie si un utilisateur est connecté
  Future<bool> isAuthenticated();

  // ============================================
  // MISE À JOUR UTILISATEUR
  // ============================================

  /// Met à jour les informations de l'utilisateur
  Future<void> updateUser(AppUser user);

  /// Met à jour le prénom
  Future<void> updatePrenom(String prenom);

  /// Met à jour la monnaie
  Future<void> updateMonnaie(String monnaie);

  // ============================================
  // ONBOARDING ET NOTIFICATIONS
  // ============================================

  /// Marque l'onboarding comme vu
  Future<void> markOnboardingAsSeen();

  /// Active/désactive les notifications
  Future<void> setNotificationsEnabled(bool enabled);

  /// Met à jour la date de dernière connexion
  Future<void> updateLastLogin();
}