// lib/domain/usecases/auth/check_auth_usecase.dart

import '../../repositories/i_auth_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/logger.dart';

/// Résultat de la vérification d'authentification
class AuthStatusResult {
  final bool isAuthenticated;
  final AppUser? user;
  final bool needsOnboarding;
  final bool needsPin;

  const AuthStatusResult({
    required this.isAuthenticated,
    this.user,
    this.needsOnboarding = false,
    this.needsPin = false,
  });

  /// Utilisateur authentifié et complet
  factory AuthStatusResult.authenticated(AppUser user) {
    return AuthStatusResult(
      isAuthenticated: true,
      user: user,
      needsOnboarding: !user.onboardingVu,
      needsPin: false,
    );
  }

  /// Utilisateur non authentifié
  factory AuthStatusResult.unauthenticated() {
    return const AuthStatusResult(isAuthenticated: false);
  }
}

/// Cas d'utilisation : Vérifier l'état d'authentification
class CheckAuthUseCase {
  final IAuthRepository _authRepository;

  CheckAuthUseCase(this._authRepository);

  /// Exécute la vérification
  Future<AuthStatusResult> execute() async {
    try {
      Logger.info('🔍 Vérification de l\'authentification...');

      final isAuthenticated = await _authRepository.isAuthenticated();

      if (!isAuthenticated) {
        Logger.info('👤 Utilisateur non authentifié');
        return AuthStatusResult.unauthenticated();
      }

      final user = await _authRepository.getCurrentUser();

      if (user == null) {
        Logger.warning('⚠️ Utilisateur authentifié mais données non trouvées');
        return AuthStatusResult.unauthenticated();
      }

      Logger.info('👤 Utilisateur authentifié: ${user.prenom}');
      return AuthStatusResult.authenticated(user);
    } catch (e) {
      Logger.error('❌ Erreur vérification authentification: $e');
      return AuthStatusResult.unauthenticated();
    }
  }
}
