// lib/core/errors/failure.dart

import 'package:equatable/equatable.dart';

/// Classe de base pour toutes les erreurs de l'application
/// Utilise Equatable pour permettre la comparaison d'objets
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError];
}

// ============================================
// TYPES D'ERREURS SPÉCIFIQUES
// ============================================

/// Erreurs de connexion réseau
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    originalError: originalError,
  );
}

/// Erreurs d'authentification (Firebase, OTP, etc.)
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'AUTH_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de validation (formulaires, données invalides)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'VALIDATION_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de base de données (Firestore, Hive, etc.)
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'DATABASE_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de cache (SharedPreferences, Hive)
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'CACHE_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de paiement (Wave, Orange Money, etc.)
class PaymentFailure extends Failure {
  const PaymentFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'PAYMENT_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de permissions (caméra, microphone, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'PERMISSION_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de serveur / API (HTTP 500, etc.)
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    originalError: originalError,
  );
}

/// Erreurs inattendues (catch-all)
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'UNEXPECTED_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de PIN (verrouillage, incorrect, etc.)
class PinFailure extends Failure {
  const PinFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'PIN_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de session (expirée, invalide)
class SessionFailure extends Failure {
  const SessionFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'SESSION_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de notifications
class NotificationFailure extends Failure {
  const NotificationFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'NOTIFICATION_ERROR',
    originalError: originalError,
  );
}

/// Erreurs de PDF / génération de documents
class PdfFailure extends Failure {
  const PdfFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code ?? 'PDF_ERROR',
    originalError: originalError,
  );
}

// ============================================
// EXTENSION POUR CONVERTIR LES EXCEPTIONS
// ============================================

extension FailureExtension on Failure {
  /// Convertit une Failure en message utilisateur lisible
  String toUserMessage() {
    // Messages personnalisés pour l'utilisateur final
    switch (runtimeType) {
      case NetworkFailure:
        return 'Problème de connexion. Vérifiez votre réseau.';
      case AuthFailure:
        return 'Erreur d\'authentification. Veuillez vous reconnecter.';
      case ValidationFailure:
        return message.isNotEmpty ? message : 'Données invalides. Vérifiez les champs.';
      case DatabaseFailure:
        return 'Erreur de base de données. Réessayez plus tard.';
      case CacheFailure:
        return 'Erreur de cache. Redémarrez l\'application.';
      case PaymentFailure:
        return 'Erreur de paiement. Vérifiez vos informations.';
      case PermissionFailure:
        return 'Permission nécessaire. Accordez l\'accès dans les paramètres.';
      case ServerFailure:
        return 'Erreur serveur. Réessayez plus tard.';
      case PinFailure:
        return message.isNotEmpty ? message : 'Erreur de PIN. Réessayez.';
      case SessionFailure:
        return 'Session expirée. Veuillez vous reconnecter.';
      case NotificationFailure:
        return 'Erreur de notification. Vérifiez les paramètres.';
      case PdfFailure:
        return 'Erreur de génération PDF. Réessayez.';
      default:
        return message.isNotEmpty ? message : 'Une erreur est survenue. Réessayez.';
    }
  }

  /// Vérifie si c'est une erreur récupérable (l'utilisateur peut réessayer)
  bool get isRetryable {
    switch (runtimeType) {
      case NetworkFailure:
      case ServerFailure:
      case DatabaseFailure:
      case PaymentFailure:
      case PdfFailure:
        return true;
      default:
        return false;
    }
  }

  /// Vérifie si c'est une erreur critique qui nécessite une déconnexion
  bool get isCritical {
    switch (runtimeType) {
      case AuthFailure:
      case SessionFailure:
        return true;
      default:
        return false;
    }
  }
}