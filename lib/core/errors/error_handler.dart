// lib/core/errors/error_handler.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async'; // ✅ AJOUTER POUR TimeoutException
import 'failure.dart';
import '../utils/logger.dart';

/// Gestionnaire d'erreurs global
/// Centralise la gestion des exceptions et les convertit en Failures
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // ============================================
  // CONVERSION DES EXCEPTIONS EN FAILURES
  // ============================================

  /// Convertit n'importe quelle exception en Failure
  Failure handleException(dynamic error, {StackTrace? stackTrace}) {
    Logger.error('❌ Exception: $error', error: error, stackTrace: stackTrace);

    // Erreurs Firebase Auth
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error);
    }

    // Erreurs Firestore
    if (error is FirebaseException) {
      return _handleFirebaseException(error);
    }

    // Erreurs Dio (HTTP)
    if (error is DioException) {
      return _handleDioException(error);
    }

    // Erreurs de formatage (JSON, parsing)
    if (error is FormatException) {
      return ValidationFailure(
        message: 'Erreur de format de données: ${error.message}',
        originalError: error,
      );
    }

    // Erreurs de type
    if (error is TypeError) {
      return UnexpectedFailure(
        message: 'Erreur de type: ${error.toString()}',
        originalError: error,
      );
    }

    // Erreurs de socket / réseau
    if (error is SocketException) {
      return NetworkFailure(
        message: 'Problème de connexion: ${error.message}',
        originalError: error,
      );
    }

    // Erreurs de timeout
    if (error is TimeoutException) {
      return NetworkFailure(
        message: 'Délai dépassé: ${error.message}',
        code: 'TIMEOUT_ERROR',
        originalError: error,
      );
    }

    // Erreur générique
    if (error is Exception) {
      return UnexpectedFailure(
        message: error.toString().replaceAll('Exception: ', ''),
        originalError: error,
      );
    }

    // Erreur inconnue
    return UnexpectedFailure(
      message: error?.toString() ?? 'Erreur inconnue',
      originalError: error,
    );
  }

  // ============================================
  // GESTION DES ERREURS FIREBASE AUTH
  // ============================================

  Failure _handleFirebaseAuthException(FirebaseAuthException e) {
    Logger.error('🔥 FirebaseAuthException: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return AuthFailure(
          message: 'Email ou mot de passe incorrect.',
          code: e.code,
          originalError: e,
        );

      case 'invalid-email':
        return ValidationFailure(
          message: 'Adresse email invalide.',
          code: e.code,
          originalError: e,
        );

      case 'email-already-in-use':
        return AuthFailure(
          message: 'Cet email est déjà utilisé.',
          code: e.code,
          originalError: e,
        );

      case 'weak-password':
        return ValidationFailure(
          message: 'Mot de passe trop faible. Utilisez au moins 6 caractères.',
          code: e.code,
          originalError: e,
        );

      case 'too-many-requests':
        return AuthFailure(
          message: 'Trop de tentatives. Réessayez plus tard.',
          code: e.code,
          originalError: e,
        );

      case 'user-disabled':
        return AuthFailure(
          message: 'Ce compte a été désactivé.',
          code: e.code,
          originalError: e,
        );

      case 'requires-recent-login':
        return AuthFailure(
          message: 'Opération sensible. Reconnectez-vous.',
          code: e.code,
          originalError: e,
        );

      case 'invalid-verification-code':
        return AuthFailure(
          message: 'Code de vérification invalide.',
          code: e.code,
          originalError: e,
        );

      case 'invalid-phone-number':
        return ValidationFailure(
          message: 'Numéro de téléphone invalide.',
          code: e.code,
          originalError: e,
        );

      case 'session-expired':
        return SessionFailure(
          message: 'Session expirée. Reconnectez-vous.',
          code: e.code,
          originalError: e,
        );

      case 'network-request-failed':
        return NetworkFailure(
          message: 'Problème de connexion. Vérifiez votre réseau.',
          code: e.code,
          originalError: e,
        );

      default:
        return AuthFailure(
          message: e.message ?? 'Erreur d\'authentification.',
          code: e.code,
          originalError: e,
        );
    }
  }

  // ============================================
  // GESTION DES ERREURS FIRESTORE
  // ============================================

  Failure _handleFirebaseException(FirebaseException e) {
    Logger.error('🔥 FirebaseException: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'permission-denied':
        return AuthFailure(
          message: 'Vous n\'avez pas les permissions nécessaires.',
          code: e.code,
          originalError: e,
        );

      case 'not-found':
        return DatabaseFailure(
          message: 'Données non trouvées.',
          code: e.code,
          originalError: e,
        );

      case 'already-exists':
        return DatabaseFailure(
          message: 'Cette donnée existe déjà.',
          code: e.code,
          originalError: e,
        );

      case 'cancelled':
        return DatabaseFailure(
          message: 'Opération annulée.',
          code: e.code,
          originalError: e,
        );

      case 'deadline-exceeded':
        return NetworkFailure(
          message: 'Délai dépassé. Réessayez.',
          code: e.code,
          originalError: e,
        );

      case 'unavailable':
        return NetworkFailure(
          message: 'Service indisponible. Réessayez plus tard.',
          code: e.code,
          originalError: e,
        );

      case 'failed-precondition':
        return DatabaseFailure(
          message: 'Précondition échouée. Vérifiez les données.',
          code: e.code,
          originalError: e,
        );

      default:
        return DatabaseFailure(
          message: e.message ?? 'Erreur de base de données.',
          code: e.code,
          originalError: e,
        );
    }
  }

  // ============================================
  // GESTION DES ERREURS DIO (HTTP)
  // ============================================

  Failure _handleDioException(DioException e) {
    Logger.error('🌐 DioException: ${e.type} - ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Délai dépassé. Vérifiez votre connexion.',
          code: 'TIMEOUT',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'Problème de connexion. Vérifiez votre réseau.',
          code: 'CONNECTION_ERROR',
          originalError: e,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data;

        if (statusCode == 400) {
          return ValidationFailure(
            message: _extractErrorMessage(data) ?? 'Requête invalide.',
            code: 'BAD_REQUEST',
            originalError: e,
          );
        }

        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure(
            message: 'Non autorisé. Veuillez vous reconnecter.',
            code: 'UNAUTHORIZED',
            originalError: e,
          );
        }

        if (statusCode == 404) {
          return DatabaseFailure(
            message: 'Ressource non trouvée.',
            code: 'NOT_FOUND',
            originalError: e,
          );
        }

        if (statusCode >= 500) {
          return ServerFailure(
            message: 'Erreur serveur. Réessayez plus tard.',
            code: 'SERVER_ERROR',
            originalError: e,
          );
        }

        return ServerFailure(
          message: _extractErrorMessage(data) ?? 'Erreur serveur.',
          code: 'HTTP_$statusCode',
          originalError: e,
        );

      case DioExceptionType.cancel:
        return DatabaseFailure(
          message: 'Requête annulée.',
          code: 'CANCELLED',
          originalError: e,
        );

      case DioExceptionType.unknown:
      default:
        return UnexpectedFailure(
          message: e.message ?? 'Erreur inconnue.',
          originalError: e,
        );
    }
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Extrait le message d'erreur d'une réponse HTTP
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        // Format standard: { "message": "..." }
        if (data.containsKey('message')) {
          return data['message'] as String?;
        }
        // Format: { "error": { "message": "..." } }
        if (data.containsKey('error') && data['error'] is Map) {
          final error = data['error'] as Map;
          if (error.containsKey('message')) {
            return error['message'] as String?;
          }
        }
        // Format: { "errors": [ { "message": "..." } ] }
        if (data.containsKey('errors') && data['errors'] is List) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty && errors[0] is Map) {
            return (errors[0] as Map)['message'] as String?;
          }
        }
      }
      return data.toString();
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // AFFICHAGE DES ERREURS DANS L'UI
  // ============================================

  /// Affiche un SnackBar d'erreur
  static void showErrorSnackBar(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = failure.toUserMessage();
    final isRetryable = failure.isRetryable;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (isRetryable && onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Affiche un dialogue d'erreur
  static Future<void> showErrorDialog(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Erreur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              failure.toUserMessage(),
              style: const TextStyle(fontSize: 16),
            ),
            if (failure.code != null) ...[
              const SizedBox(height: 8),
              Text(
                'Code: ${failure.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDismiss?.call();
            },
            child: const Text('Fermer'),
          ),
          if (failure.isRetryable && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}

// ============================================
// EXTENSION POUR FACILITER L'UTILISATION
// ============================================

extension ErrorHandlerExtension on dynamic {
  /// Convertit n'importe quelle exception en Failure
  Failure toFailure() {
    return ErrorHandler().handleException(this);
  }

  /// Affiche l'erreur dans un SnackBar
  void showErrorSnackBar(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    final failure = toFailure();
    ErrorHandler.showErrorSnackBar(
      context,
      failure,
      onRetry: onRetry,
    );
  }

  /// Affiche l'erreur dans un Dialog
  Future<void> showErrorDialog(
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final failure = toFailure();
    return ErrorHandler.showErrorDialog(
      context,
      failure,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }
}
