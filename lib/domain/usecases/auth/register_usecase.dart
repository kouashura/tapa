// lib/domain/usecases/auth/register_usecase.dart

import '../../repositories/i_auth_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

/// Paramètres pour l'inscription
class RegisterParams {
  final String prenom;
  final String telephone;
  final String indicatif;
  final String codePays;
  final String monnaie;
  final String? verificationId;
  final String? smsCode;

  const RegisterParams({
    required this.prenom,
    required this.telephone,
    required this.indicatif,
    required this.codePays,
    required this.monnaie,
    this.verificationId,
    this.smsCode,
  });

  /// Vérifie si les paramètres sont valides
  bool get hasVerificationCode => verificationId != null && smsCode != null;

  /// Numéro complet avec indicatif
  String get fullPhoneNumber => '$indicatif$telephone';
}

/// Résultat de l'inscription
class RegisterResult {
  final AppUser? user;
  final bool requiresVerification;
  final bool requiresPin;
  final String? message;

  const RegisterResult({
    this.user,
    this.requiresVerification = false,
    this.requiresPin = false,
    this.message,
  });

  /// Succès complet
  factory RegisterResult.success(AppUser user) {
    return RegisterResult(
      user: user,
      requiresVerification: false,
      requiresPin: true,
      message: '✅ Compte créé avec succès !',
    );
  }

  /// Nécessite une vérification du numéro
  factory RegisterResult.needVerification() {
    return const RegisterResult(
      requiresVerification: true,
      message: 'Un code de vérification a été envoyé par SMS.',
    );
  }

  /// Erreur
  factory RegisterResult.error(String message) {
    return RegisterResult(
      message: message,
    );
  }
}

/// Cas d'utilisation : Inscription utilisateur
class RegisterUseCase {
  final IAuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  /// Exécute l'inscription
  Future<RegisterResult> execute(RegisterParams params) async {
    try {
      Logger.info('📝 Tentative d\'inscription pour: ${params.prenom}');

      // Valider les paramètres
      if (params.prenom.isEmpty || params.prenom.length < 2) {
        return RegisterResult.error(
            'Le prénom doit contenir au moins 2 caractères.');
      }

      if (params.telephone.length < 8) {
        return RegisterResult.error('Numéro de téléphone invalide.');
      }

      // Si code de vérification fourni
      if (params.hasVerificationCode) {
        Logger.info('📱 Vérification du code SMS...');
        final user = await _authRepository.verifyPhoneNumber(
          params.verificationId!,
          params.smsCode!,
        );
        Logger.success('✅ Numéro vérifié pour: ${user.prenom}');

        // Créer le profil utilisateur
        final createdUser = await _authRepository.createUser(
          prenom: params.prenom,
          email: params.telephone,
          codePays: params.codePays,
          monnaie: params.monnaie,
        );

        Logger.success(
            '🎉 Compte créé avec succès pour: ${createdUser.prenom}');
        return RegisterResult.success(createdUser);
      }

      // Envoyer le code de vérification
      Logger.info('📱 Envoi du code de vérification...');
      await _authRepository.sendVerificationCode(params.fullPhoneNumber);
      Logger.success('✅ Code envoyé à: ${params.fullPhoneNumber}');

      return RegisterResult.needVerification();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('❌ Erreur d\'inscription: ${failure.message}');

      if (failure is AuthFailure) {
        return RegisterResult.error(failure.message);
      }

      return RegisterResult.error(
          'Erreur lors de l\'inscription. Veuillez réessayer.');
    }
  }
}
