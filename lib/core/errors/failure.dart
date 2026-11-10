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
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'NETWORK_ERROR',
        );
}

/// Erreurs d'authentification (Firebase, OTP, etc.)
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'AUTH_ERROR',
        );
}

/// Erreurs de validation (formulaires, données invalides)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'VALIDATION_ERROR',
        );
}

/// Erreurs de base de données (Firestore, Hive, etc.)
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'DATABASE_ERROR',
        );
}

/// Erreurs de cache (SharedPreferences, Hive)
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'CACHE_ERROR',
        );
}

/// Erreurs de paiement (Wave, Orange Money, etc.)
class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'PAYMENT_ERROR',
        );
}

/// Erreurs de permissions (caméra, microphone, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'PERMISSION_ERROR',
        );
}

/// Erreurs de serveur / API (HTTP 500, etc.)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'SERVER_ERROR',
        );
}

/// Erreurs inattendues (catch-all)
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'UNEXPECTED_ERROR',
        );
}

/// Erreurs de PIN (verrouillage, incorrect, etc.)
class PinFailure extends Failure {
  const PinFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'PIN_ERROR',
        );
}

/// Erreurs de session (expirée, invalide)
class SessionFailure extends Failure {
  const SessionFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'SESSION_ERROR',
        );
}

/// Erreurs de notifications
class NotificationFailure extends Failure {
  const NotificationFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'NOTIFICATION_ERROR',
        );
}

/// Erreurs de PDF / génération de documents
class PdfFailure extends Failure {
  const PdfFailure({
    required super.message,
    String? code,
    super.originalError,
  }) : super(
          code: code ?? 'PDF_ERROR',
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
        return message.isNotEmpty
            ? message
            : 'Données invalides. Vérifiez les champs.';
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
        return message.isNotEmpty
            ? message
            : 'Une erreur est survenue. Réessayez.';
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
