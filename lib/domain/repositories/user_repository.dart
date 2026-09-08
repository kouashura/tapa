// lib/domain/repositories/user_repository.dart

import '../../data/models/models.dart';

/// Interface du repository utilisateur (legacy)
/// À déprécier au profit de IUserRepository
abstract class UserRepository {
  // ============================================
  // AUTHENTIFICATION
  // ============================================

  Future<AppUser?> getCurrentUser();
  Future<AppUser> createUser({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  });
  Future<void> updateUser(AppUser user);
  Future<void> deleteUser();
  Future<void> signOut();
  Future<bool> isAuthenticated();
  Future<String> getCurrentUserId();

  // ============================================
  // PROFIL
  // ============================================

  Future<void> markOnboardingAsSeen();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<void> updateLastLogin();
  Future<void> updateMonnaie(String monnaie);
  Future<void> updatePrenom(String prenom);

  // ============================================
  // PIN
  // ============================================

  Future<bool> verifyPin(String pin);
  Future<void> savePin(String pin);
  Future<bool> hasPin();
}