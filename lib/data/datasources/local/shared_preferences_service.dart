// lib/data/datasources/local/shared_preferences_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';

/// Service de gestion du stockage local avec SharedPreferences
/// Gère les données simples (String, bool, int, double, List, Map)
class SharedPreferencesService {
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();

  factory SharedPreferencesService() => _instance;

  SharedPreferencesService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // ============================================
  // INITIALISATION
  // ============================================

  /// Initialise le service (à appeler au démarrage de l'app)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      Logger.info('✅ SharedPreferencesService initialisé');
    } catch (e) {
      Logger.error('❌ Erreur init SharedPreferencesService: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  // ============================================
  // MÉTHODES GÉNÉRIQUES
  // ============================================

  /// Vérifie si une clé existe
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// Supprime une clé
  Future<void> remove(String key) async {
    _ensureInitialized();
    try {
      await _prefs!.remove(key);
      Logger.debug('🗑️ Clé supprimée: $key');
    } catch (e) {
      Logger.error('❌ Erreur suppression clé $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Supprime toutes les données
  Future<void> clearUserData() async {
    _ensureInitialized();
    try {
      final keys = _prefs!.getKeys().toList();
      for (final key in keys) {
        // Garder le PIN et l'onboarding
        if (key == 'pin_hash' ||
            key == 'pin_salt' ||
            key == 'onboarding_done') {
          continue;
        }
        await _prefs!.remove(key);
      }
      Logger.success('🗑️ SharedPreferences: donnees utilisateur nettoyees');
    } catch (e) {
      Logger.error('❌ Erreur clearUserData: $e');
    }
  }

  Future<void> clear() async {
    _ensureInitialized();
    try {
      await _prefs!.clear();
      Logger.warning(
          '⚠️ Toutes les données SharedPreferences ont été effacées');
    } catch (e) {
      Logger.error('❌ Erreur clear SharedPreferences: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // STRING
  // ============================================

  /// Sauvegarde une String
  Future<void> setString(String key, String value) async {
    _ensureInitialized();
    try {
      await _prefs!.setString(key, value);
      Logger.debug('📝 String sauvegardée: $key = $value');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde String $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère une String
  String? getString(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getString(key);
    } catch (e) {
      Logger.error('❌ Erreur récupération String $key: $e');
      return null;
    }
  }

  /// Récupère une String avec valeur par défaut
  String getStringOrDefault(String key, {String defaultValue = ''}) {
    return getString(key) ?? defaultValue;
  }

  // ============================================
  // BOOL
  // ============================================

  /// Sauvegarde un booléen
  Future<void> setBool(String key, bool value) async {
    _ensureInitialized();
    try {
      await _prefs!.setBool(key, value);
      Logger.debug('📝 Bool sauvegardé: $key = $value');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde Bool $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère un booléen
  bool? getBool(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getBool(key);
    } catch (e) {
      Logger.error('❌ Erreur récupération Bool $key: $e');
      return null;
    }
  }

  /// Récupère un booléen avec valeur par défaut
  bool getBoolOrDefault(String key, {bool defaultValue = false}) {
    return getBool(key) ?? defaultValue;
  }

  // ============================================
  // INT
  // ============================================

  /// Sauvegarde un entier
  Future<void> setInt(String key, int value) async {
    _ensureInitialized();
    try {
      await _prefs!.setInt(key, value);
      Logger.debug('📝 Int sauvegardé: $key = $value');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde Int $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère un entier
  int? getInt(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getInt(key);
    } catch (e) {
      Logger.error('❌ Erreur récupération Int $key: $e');
      return null;
    }
  }

  /// Récupère un entier avec valeur par défaut
  int getIntOrDefault(String key, {int defaultValue = 0}) {
    return getInt(key) ?? defaultValue;
  }

  // ============================================
  // DOUBLE
  // ============================================

  /// Sauvegarde un double
  Future<void> setDouble(String key, double value) async {
    _ensureInitialized();
    try {
      await _prefs!.setDouble(key, value);
      Logger.debug('📝 Double sauvegardé: $key = $value');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde Double $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère un double
  double? getDouble(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getDouble(key);
    } catch (e) {
      Logger.error('❌ Erreur récupération Double $key: $e');
      return null;
    }
  }

  /// Récupère un double avec valeur par défaut
  double getDoubleOrDefault(String key, {double defaultValue = 0.0}) {
    return getDouble(key) ?? defaultValue;
  }

  // ============================================
  // LIST STRING
  // ============================================

  /// Sauvegarde une liste de String
  Future<void> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    try {
      await _prefs!.setStringList(key, value);
      Logger.debug(
          '📝 StringList sauvegardée: $key (${value.length} éléments)');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde StringList $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère une liste de String
  List<String>? getStringList(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getStringList(key);
    } catch (e) {
      Logger.error('❌ Erreur récupération StringList $key: $e');
      return null;
    }
  }

  /// Récupère une liste de String avec valeur par défaut
  List<String> getStringListOrDefault(String key,
      {List<String> defaultValue = const []}) {
    return getStringList(key) ?? defaultValue;
  }

  // ============================================
  // JSON / MAP
  // ============================================

  /// Sauvegarde une Map en JSON
  Future<void> setMap(String key, Map<String, dynamic> value) async {
    _ensureInitialized();
    try {
      final json = jsonEncode(value);
      await _prefs!.setString(key, json);
      Logger.debug('📝 Map sauvegardée: $key (${value.length} clés)');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde Map $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère une Map depuis JSON
  Map<String, dynamic>? getMap(String key) {
    _ensureInitialized();
    try {
      final json = _prefs!.getString(key);
      if (json == null) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      Logger.error('❌ Erreur récupération Map $key: $e');
      return null;
    }
  }

  /// Récupère une Map avec valeur par défaut
  Map<String, dynamic> getMapOrDefault(String key,
      {Map<String, dynamic> defaultValue = const {}}) {
    return getMap(key) ?? defaultValue;
  }

  // ============================================
  // LISTE DE MAPS
  // ============================================

  /// Sauvegarde une liste de Maps en JSON
  Future<void> setMapList(String key, List<Map<String, dynamic>> value) async {
    _ensureInitialized();
    try {
      final json = jsonEncode(value);
      await _prefs!.setString(key, json);
      Logger.debug('📝 MapList sauvegardée: $key (${value.length} éléments)');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde MapList $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère une liste de Maps depuis JSON
  List<Map<String, dynamic>>? getMapList(String key) {
    _ensureInitialized();
    try {
      final json = _prefs!.getString(key);
      if (json == null) return null;
      final decoded = jsonDecode(json);
      if (decoded is! List) return null;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error('❌ Erreur récupération MapList $key: $e');
      return null;
    }
  }

  /// Récupère une liste de Maps avec valeur par défaut
  List<Map<String, dynamic>> getMapListOrDefault(
    String key, {
    List<Map<String, dynamic>> defaultValue = const [],
  }) {
    return getMapList(key) ?? defaultValue;
  }

  // ============================================
  // OBJECT (Sérialisation personnalisée)
  // ============================================

  /// Sauvegarde un objet sérialisé en JSON
  Future<void> setObject<T>(
      String key, T value, Map<String, dynamic> Function(T) toJson) async {
    _ensureInitialized();
    try {
      final json = jsonEncode(toJson(value));
      await _prefs!.setString(key, json);
      Logger.debug('📝 Objet sauvegardé: $key (${value.runtimeType})');
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde objet $key: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère un objet sérialisé depuis JSON
  T? getObject<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    _ensureInitialized();
    try {
      final json = _prefs!.getString(key);
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return fromJson(map);
    } catch (e) {
      Logger.error('❌ Erreur récupération objet $key: $e');
      return null;
    }
  }

  // ============================================
  // MÉTHODES SPÉCIFIQUES À L'APPLICATION
  // ============================================

  // --- Utilisateur ---

  Future<void> saveUserId(String userId) => setString('user_id', userId);
  String? getUserId() => getString('user_id');

  Future<void> saveUserPrenom(String prenom) =>
      setString('user_prenom', prenom);
  String? getUserPrenom() => getString('user_prenom');

  Future<void> saveUserTelephone(String telephone) =>
      setString('user_telephone', telephone);
  String? getUserTelephone() => getString('user_telephone');

  Future<void> saveUserMonnaie(String monnaie) =>
      setString('user_monnaie', monnaie);
  String? getUserMonnaie() => getString('user_monnaie');

  // --- PIN ---

  Future<void> savePinHash(String userId, String hash) =>
      setString('pin_hash_$userId', hash);
  String? getPinHash(String userId) => getString('pin_hash_$userId');

  Future<void> savePinSalt(String userId, String salt) =>
      setString('pin_salt_$userId', salt);
  String? getPinSalt(String userId) => getString('pin_salt_$userId');

  Future<void> savePinAttempts(String userId, int attempts) =>
      setInt('pin_attempts_$userId', attempts);
  int getPinAttempts(String userId) => getIntOrDefault('pin_attempts_$userId');

  Future<void> savePinLockTime(String userId, int lockTime) =>
      setInt('pin_lock_time_$userId', lockTime);
  int getPinLockTime(String userId) => getIntOrDefault('pin_lock_time_$userId');

  // --- Onboarding ---

  Future<void> saveOnboardingVu(bool value) => setBool('onboarding_vu', value);
  bool getOnboardingVu() => getBoolOrDefault('onboarding_vu');

  // --- Notifications ---

  Future<void> saveNotificationsActivees(bool value) =>
      setBool('notifications_activees', value);
  bool getNotificationsActivees() =>
      getBoolOrDefault('notifications_activees', defaultValue: true);

  // --- Accès vie ---

  Future<void> saveAccesVie(bool value) => setBool('acces_vie', value);
  bool getAccesVie() => getBoolOrDefault('acces_vie');

  Future<void> saveCleActivee(String cle) => setString('cle_activee', cle);
  String? getCleActivee() => getString('cle_activee');

  Future<void> saveDateActivation(String date) =>
      setString('date_activation', date);
  String? getDateActivation() => getString('date_activation');

  // --- Date inscription ---

  Future<void> saveDateInscription(String date) =>
      setString('date_inscription', date);
  String? getDateInscription() => getString('date_inscription');

  // ============================================
  // UTILITAIRES
  // ============================================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const CacheFailure(
        message:
            'SharedPreferencesService non initialisé. Appelez init() d\'abord.',
        code: 'NOT_INITIALIZED',
      );
    }
  }

  /// Récupère toutes les clés
  Set<String> getKeys() {
    _ensureInitialized();
    return _prefs!.getKeys();
  }

  /// Affiche un résumé des données
  void logSummary() {
    _ensureInitialized();
    final keys = getKeys();
    Logger.info('📊 SharedPreferences Summary: ${keys.length} clés');
    for (final key in keys) {
      final value = _prefs!.get(key);
      final valueStr = value is String
          ? value.substring(0, value.length > 50 ? 50 : value.length)
          : value.toString();
      Logger.debug('  - $key: $valueStr');
    }
  }
}
