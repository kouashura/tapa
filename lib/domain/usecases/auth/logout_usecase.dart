// lib/domain/usecases/auth/logout_usecase.dart

import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_user_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Résultat du logout
class LogoutResult {
  final bool success;
  final String? message;

  const LogoutResult({
    required this.success,
    this.message,
  });

  /// Succès
  factory LogoutResult.success() {
    return const LogoutResult(success: true);
  }

  /// Erreur
  factory LogoutResult.error(String message) {
    return LogoutResult(
      success: false,
      message: message,
    );
  }
}

/// Cas d'utilisation : Déconnexion utilisateur
class LogoutUseCase {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;

  LogoutUseCase({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  /// Exécute la déconnexion
  Future<LogoutResult> execute() async {
    try {
      Logger.info('🔓 Déconnexion en cours...');

      // 1. Mettre à jour la dernière connexion
      await _userRepository.updateLastLogin();
      Logger.info('📝 Dernière connexion mise à jour');

      // 2. Se déconnecter de Firebase
      await _authRepository.signOut();
      Logger.success('✅ Déconnexion réussie');

      return LogoutResult.success();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur de déconnexion: ${failure.message}');

      return LogoutResult.error(
        'Erreur lors de la déconnexion. Veuillez réessayer.',
      );
    }
  }
}
