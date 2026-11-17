// lib/services/pin_security.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class PinSecurity {
  // ---- Politique de verrouillage progressif ----
  static const List<Duration> lockoutSteps = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 24),
  ];

  static const int maxAttempts = 5;

  // ---- Clés SharedPreferences ----
  static const String _kSaltKey = 'pin_salt';
  static const String _kHashKey = 'pin_hash';
  static const String _kLegacyPlainKey = 'user_pin';
  static const String _kAttemptsKey = 'pin_attempts';
  static const String _kTotalFailsKey = 'pin_total_fails';
  static const String _kLockedUntilKey = 'pin_locked_until';
  static const String _kLocalUserIdKey = 'local_user_id';

  // ============================================================
  // IDENTITÉ LOCALE (indépendante de Firebase)
  // ============================================================

  /// Retourne un identifiant local persistant, créé au premier usage.
  /// Ce n'est PAS un identifiant Firebase : c'est une clé de stockage
  /// qui garantit que le PIN reste vérifiable même si la session
  /// Firebase a expiré ou si l'utilisateur est hors-ligne.
  static Future<String> getOrCreateLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kLocalUserIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final rand = Random.secure();
    final bytes = List<int>.generate(24, (_) => rand.nextInt(256));
    final id = base64Url.encode(bytes);

    await prefs.setString(_kLocalUserIdKey, id);
    Logger.info('🆔 Identifiant local créé');
    return id;
  }

  // ============================================================
  // CRYPTO
  // ============================================================

  static String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  /// Hash utilisé pour un stockage distant (salt fixe, à ne PAS utiliser
  /// pour de la vérification locale forte).
  static Future<String> hashPinForStorage(String pin) async {
    const fixedSalt = 'TAPA_BUDGET_FIXED_SALT_2026';
    return sha256.convert(utf8.encode('$fixedSalt:$pin')).toString();
  }

  // ============================================================
  // SAUVEGARDE / VÉRIFICATION
  // ============================================================

  static Future<void> savePin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    final prefix = '${userId}_';

    await prefs.setString('$prefix$_kSaltKey', salt);
    await prefs.setString('$prefix$_kHashKey', hash);
    await prefs.remove('$prefix$_kLegacyPlainKey');
    await _resetAttempts(prefs, userId);

    // Note : on NE reset PAS _kTotalFailsKey ici (compteur cumulatif).
    Logger.info('🔐 PIN haché et sauvegardé');
  }

  static Future<PinCheckResult> verifyPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';

    // 1) Verrouillage actif ?
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
          message: 'PIN verrouillé (${_fmtRemaining(remaining)})',
        );
      }
      // Expiré → on nettoie le lockout mais on garde le compteur cumulatif
      await prefs.remove('$prefix$_kLockedUntilKey');
      await prefs.remove('$prefix$_kAttemptsKey');
    }

    // 2) Hash présent ?
    final salt = prefs.getString('$prefix$_kSaltKey');
    final storedHash = prefs.getString('$prefix$_kHashKey');

    bool isValid = false;
    if (salt != null && storedHash != null) {
      isValid = _hash(pin, salt) == storedHash;
    } else {
      // Migration legacy
      final legacyPlain = prefs.getString('$prefix$_kLegacyPlainKey');
      if (legacyPlain != null && legacyPlain == pin) {
        isValid = true;
        Logger.info('🔁 Migration PIN legacy → hash');
        await savePin(userId, pin);
      }
    }

    if (isValid) {
      await _resetAttempts(prefs, userId);
      // On NE reset PAS le cumulatif → un attaquant ne peut pas "nettoyer"
      // son passif en devinant juste une fois.
      return const PinCheckResult(
        success: true,
        isLocked: false,
        remainingAttempts: maxAttempts,
        message: 'PIN valide',
      );
    }

    // 3) Échec : incrément tentatives + total
    final attempts = (prefs.getInt('$prefix$_kAttemptsKey') ?? 0) + 1;
    final totalFails = (prefs.getInt('$prefix$_kTotalFailsKey') ?? 0) + 1;
    await prefs.setInt('$prefix$_kAttemptsKey', attempts);
    await prefs.setInt('$prefix$_kTotalFailsKey', totalFails);

    if (attempts >= maxAttempts) {
      // Étape de lockout = min(totalFails / maxAttempts, steps.length-1)
      final stepIndex =
          ((totalFails ~/ maxAttempts) - 1).clamp(0, lockoutSteps.length - 1);
      final duration = lockoutSteps[stepIndex];
      final lockedUntil = DateTime.now().add(duration);
      await prefs.setInt(
        '$prefix$_kLockedUntilKey',
        lockedUntil.millisecondsSinceEpoch,
      );
      await prefs.setInt('$prefix$_kAttemptsKey', 0); // reset compteur court

      Logger.warning(
        '🔒 Verrouillé ${duration.inMinutes}min (total échecs: $totalFails)',
      );
      return PinCheckResult(
        success: false,
        isLocked: true,
        lockTime: lockedUntil,
        remainingAttempts: 0,
        message: 'Trop de tentatives. Réessayez dans ${_fmtRemaining(duration)}.',
      );
    }

    return PinCheckResult(
      success: false,
      isLocked: false,
      remainingAttempts: maxAttempts - attempts,
      message: 'PIN incorrect, ${maxAttempts - attempts} essai(s) restant(s).',
    );
  }

  static String _fmtRemaining(Duration d) {
    if (d.inHours >= 1) return '${d.inHours}h${d.inMinutes % 60}min';
    return '${d.inMinutes}min';
  }

  static Future<void> _resetAttempts(
      SharedPreferences prefs, String userId) async {
    final prefix = '${userId}_';
    await prefs.remove('$prefix$_kAttemptsKey');
    await prefs.remove('$prefix$_kLockedUntilKey');
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  static Future<bool> hasPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';
    return prefs.containsKey('$prefix$_kHashKey') ||
        prefs.containsKey('$prefix$_kLegacyPlainKey');
  }

  static Future<void> migrateFromFirestore(
      String userId, String hashedPin) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';
    await prefs.setString('$prefix$_kHashKey', hashedPin);
    await prefs.setString('$prefix$_kSaltKey', 'migrated_from_firestore');
    await _resetAttempts(prefs, userId);
    Logger.info('🔁 PIN migré depuis Firestore');
  }

  /// Supprime toutes les données PIN (⚠️ ne supprime PAS le localUserId
  /// pour permettre une réinitialisation propre du PIN par OTP).
  static Future<void> clearPinData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';
    await prefs.remove('$prefix$_kSaltKey');
    await prefs.remove('$prefix$_kHashKey');
    await prefs.remove('$prefix$_kLegacyPlainKey');
    await prefs.remove('$prefix$_kAttemptsKey');
    await prefs.remove('$prefix$_kLockedUntilKey');
    await prefs.remove('$prefix$_kTotalFailsKey');
    Logger.info('🗑️ Données PIN supprimées');
  }
}

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
