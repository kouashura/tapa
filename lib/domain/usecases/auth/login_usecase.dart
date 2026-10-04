// lib/domain/usecases/auth/login_usecase.dart

import '../../repositories/i_auth_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Paramètres pour le login
class LoginParams {
  final String phoneNumber;
  final String? verificationId;
  final String? smsCode;

  const LoginParams({
    required this.phoneNumber,
    this.verificationId,
    this.smsCode,
  });

  /// Vérifie si les paramètres sont valides
  bool get hasVerificationCode => verificationId != null && smsCode != null;
}

/// Résultat du login
class LoginResult {
  final AppUser? user;
  final bool requiresVerification;
  final bool requiresPin;
  final bool requiresOnboarding;
  final String? message;

  const LoginResult({
    this.user,
    this.requiresVerification = false,
    this.requiresPin = false,
    this.requiresOnboarding = false,
    this.message,
  });

  /// Succès complet
  factory LoginResult.success(AppUser user) {
    return LoginResult(
      user: user,
      requiresVerification: false,
      requiresPin: false,
      requiresOnboarding: false,
    );
  }

  /// Nécessite une vérification du numéro
  factory LoginResult.needVerification() {
    return const LoginResult(
      requiresVerification: true,
      message: 'Un code de vérification a été envoyé par SMS.',
    );
  }

  /// Nécessite la création d'un PIN
  factory LoginResult.needPin() {
    return const LoginResult(
      requiresPin: true,
      message: 'Veuillez créer un code PIN pour sécuriser votre compte.',
    );
  }

  /// Nécessite l'onboarding
  factory LoginResult.needOnboarding() {
    return const LoginResult(
      requiresOnboarding: true,
      message: 'Bienvenue ! Découvrez TAPA Invest.',
    );
  }

  /// Erreur
  factory LoginResult.error(String message) {
    return LoginResult(
      message: message,
    );
  }
}

/// Cas d'utilisation : Connexion utilisateur
class LoginUseCase {
  final IAuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  /// Exécute la connexion
  Future<LoginResult> execute(LoginParams params) async {
    try {
      Logger.info('🔑 Tentative de connexion pour: ${params.phoneNumber}');

      // Étape 1 : Vérifier si l'utilisateur existe déjà
      final existingUser = await _authRepository.getCurrentUser();

      if (existingUser != null) {
        Logger.info('👤 Utilisateur déjà connecté: ${existingUser.prenom}');
        return _handleAuthenticatedUser(existingUser);
      }

      // Étape 2 : Si code de vérification fourni
      if (params.hasVerificationCode) {
        Logger.info('📱 Vérification du code SMS...');
        final user = await _authRepository.verifyPhoneNumber(
          params.verificationId!,
          params.smsCode!,
        );
        Logger.success('✅ Connexion réussie pour: ${user.prenom}');
        return _handleAuthenticatedUser(user);
      }

      // Étape 3 : Envoyer le code de vérification
      Logger.info('📱 Envoi du code de vérification...');
      await _authRepository.sendVerificationCode(params.phoneNumber);
      Logger.success('✅ Code envoyé à: ${params.phoneNumber}');

      return LoginResult.needVerification();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur de connexion: ${failure.message}');

      if (failure is AuthFailure) {
        return LoginResult.error(failure.message);
      }

      return LoginResult.error('Erreur de connexion. Veuillez réessayer.');
    }
  }

  /// Gère un utilisateur authentifié
  LoginResult _handleAuthenticatedUser(AppUser user) {
    // Vérifier si l'onboarding est vu
    if (!user.onboardingVu) {
      return LoginResult.needOnboarding();
    }

    return LoginResult.success(user);
  }
}
