// lib/services/pin_security.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class PinSecurity {
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  static const String _kSaltKey = 'pin_salt';
  static const String _kHashKey = 'pin_hash';
  static const String _kLegacyPlainKey = 'user_pin';
  static const String _kAttemptsKey = 'pin_attempts';
  static const String _kLockedUntilKey = 'pin_locked_until';

  /// Génère un sel aléatoire cryptographiquement sûr.
  static String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  /// Sauvegarde un nouveau PIN pour un utilisateur donné
  static Future<void> savePin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hash(pin, salt);

    final prefix = '${userId}_';
    await prefs.setString('$prefix$_kSaltKey', salt);
    await prefs.setString('$prefix$_kHashKey', hash);
    await prefs.remove('$prefix$_kLegacyPlainKey');
    await _resetAttempts(prefs, userId);

    Logger.info('🔐 PIN haché et sauvegardé pour $userId');
  }

  /// Hash un PIN pour le stockage Firestore (sans salt, pour compatibilité)
  static Future<String> hashPinForStorage(String pin) async {
    // Utilise un salt fixe pour le stockage Firestore
    const fixedSalt = 'TAPA_BUDGET_FIXED_SALT_2026';
    return sha256.convert(utf8.encode('$fixedSalt:$pin')).toString();
  }

  /// Vérifie le PIN saisi pour un utilisateur donné
  static Future<PinCheckResult> verifyPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';

    // Vérifier le verrouillage
    final lockedUntilMs = prefs.getInt('$prefix$_kLockedUntilKey');
    if (lockedUntilMs != null) {
      final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      if (DateTime.now().isBefore(lockedUntil)) {
        final remaining = lockedUntil.difference(DateTime.now());
        return PinCheckResult(
          success: false,
          isLocked: true,
          lockTime: lockedUntil,
          remainingAttempts: 0,
          message: 'PIN verrouillé (${remaining.inMinutes} min restantes)',
        );
      }
      await _resetAttempts(prefs, userId);
    }

    // Récupérer le hash stocké
    final salt = prefs.getString('$prefix$_kSaltKey');
    final storedHash = prefs.getString('$prefix$_kHashKey');

    bool isValid = false;
    if (salt != null && storedHash != null) {
      isValid = _hash(pin, salt) == storedHash;
    } else {
      // Migration depuis l'ancien format
      final legacyPlain = prefs.getString('$prefix$_kLegacyPlainKey');
      if (legacyPlain != null && legacyPlain == pin) {
        isValid = true;
        Logger.info('🔁 Migration PIN legacy → hash pour $userId');
        await savePin(userId, pin);
      }
    }

    if (isValid) {
      await _resetAttempts(prefs, userId);
      return PinCheckResult(
        success: true,
        isLocked: false,
        remainingAttempts: maxAttempts,
        message: 'PIN valide',
      );
    }

    // Incrémenter les échecs
    final attempts = (prefs.getInt('$prefix$_kAttemptsKey') ?? 0) + 1;
    await prefs.setInt('$prefix$_kAttemptsKey', attempts);

    if (attempts >= maxAttempts) {
      final lockedUntil = DateTime.now().add(lockoutDuration);
      await prefs.setInt('$prefix$_kLockedUntilKey', lockedUntil.millisecondsSinceEpoch);
      Logger.warning('🔒 PIN verrouillé après $attempts tentatives pour $userId');
      return PinCheckResult(
        success: false,
        isLocked: true,
        lockTime: lockedUntil,
        remainingAttempts: 0,
        message: 'Trop de tentatives, PIN verrouillé',
      );
    }

    return PinCheckResult(
      success: false,
      isLocked: false,
      remainingAttempts: maxAttempts - attempts,
      message: 'PIN incorrect, ${maxAttempts - attempts} essais restants',
    );
  }

  static Future<void> _resetAttempts(SharedPreferences prefs, String userId) async {
    final prefix = '${userId}_';
    await prefs.remove('$prefix$_kAttemptsKey');
    await prefs.remove('$prefix$_kLockedUntilKey');
  }

  /// Vérifie si un PIN existe pour l'utilisateur
  static Future<bool> hasPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';
    return prefs.containsKey('$prefix$_kHashKey') ||
        prefs.containsKey('$prefix$_kLegacyPlainKey');
  }

  /// Migre un PIN depuis Firestore vers le stockage local
  static Future<void> migrateFromFirestore(String userId, String hashedPin) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';

    // Stocker le hash tel quel (comme si c'était un hash avec salt)
    // Pour la migration, on stocke le hash sans salt
    await prefs.setString('$prefix$_kHashKey', hashedPin);
    await prefs.setString('$prefix$_kSaltKey', 'migrated_from_firestore');
    await _resetAttempts(prefs, userId);

    Logger.info('🔁 PIN migré depuis Firestore pour $userId');
  }

  /// Supprime toutes les données PIN de l'utilisateur
  static Future<void> clearPinData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';

    await prefs.remove('$prefix$_kSaltKey');
    await prefs.remove('$prefix$_kHashKey');
    await prefs.remove('$prefix$_kLegacyPlainKey');
    await prefs.remove('$prefix$_kAttemptsKey');
    await prefs.remove('$prefix$_kLockedUntilKey');

    Logger.info('🗑️ Données PIN supprimées pour $userId');
  }

  /// Vérifie si le PIN est verrouillé (pour compatibilité avec l'ancienne version)
  static Future<bool> isLocked(String userId, int lockTime) async {
    if (lockTime == 0) return false;
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockTime);
    return DateTime.now().isBefore(lockedUntil);
  }
}

/// Résultat de la vérification du PIN
class PinCheckResult {
  final bool success;
  final bool isLocked;
  final DateTime? lockTime;
  final int remainingAttempts;
  final String message;

  const PinCheckResult({
    required this.success,
    this.isLocked = false,
    this.lockTime,
    this.remainingAttempts = 0,
    this.message = '',
  });
}