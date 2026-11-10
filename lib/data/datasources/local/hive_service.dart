// lib/data/datasources/local/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';

/// Service de gestion du stockage local avec Hive
/// Stockage NoSQL rapide pour les données structurées
class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() => _instance;

  HiveService._internal();

  bool _isInitialized = false;
  final Map<String, Box> _openBoxes = {};

  // ============================================
  // NOMS DES BOX
  // ============================================

  static const String boxUser = 'user';
  static const String boxWallets = 'wallets';
  static const String boxTransactions = 'transactions';
  static const String boxBudget = 'budget';
  static const String boxDebts = 'debts';
  static const String boxSavings = 'savings';
  static const String boxEcheances = 'echeances';
  static const String boxCategories = 'categories';
  static const String boxSettings = 'settings';
  static const String boxCache = 'cache';

  // ============================================
  // INITIALISATION
  // ============================================

  /// Initialise Hive (à appeler au démarrage de l'app)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final path = appDocumentDir.path;

      // Initialiser Hive
      await Hive.initFlutter(path);

      // Enregistrer les adaptateurs si nécessaire
      // _registerAdapters();

      _isInitialized = true;
      Logger.info('✅ HiveService initialisé (path: $path)');
    } catch (e) {
      Logger.error('❌ Erreur init HiveService: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // OUVERTURE / FERMETURE DES BOX
  // ============================================

  /// Ouvre une boîte (si elle n'est pas déjà ouverte)
  Future<Box> openBox(String boxName) async {
    _ensureInitialized();

    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]!;
    }

    try {
      final box = await Hive.openBox(boxName);
      _openBoxes[boxName] = box;
      Logger.debug('📦 Boîte ouverte: $boxName (${box.length} éléments)');
      return box;
    } catch (e) {
      Logger.error('❌ Erreur ouverture box $boxName: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Ferme une boîte
  Future<void> closeBox(String boxName) async {
    _ensureInitialized();

    try {
      if (_openBoxes.containsKey(boxName)) {
        final box = _openBoxes.remove(boxName);
        await box?.close();
        Logger.debug('📦 Boîte fermée: $boxName');
      }
    } catch (e) {
      Logger.error('❌ Erreur fermeture box $boxName: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Ferme toutes les boîtes
  Future<void> closeAllBoxes() async {
    _ensureInitialized();

    try {
      final boxNames = _openBoxes.keys.toList();
      for (final name in boxNames) {
        await closeBox(name);
      }
      Logger.info('📦 Toutes les boîtes ont été fermées');
    } catch (e) {
      Logger.error('❌ Erreur fermeture toutes les boîtes: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Supprime une boîte (et ses données)
  Future<void> deleteBox(String boxName) async {
    _ensureInitialized();

    try {
      if (_openBoxes.containsKey(boxName)) {
        await _openBoxes[boxName]?.clear();
        await _openBoxes[boxName]?.close();
        _openBoxes.remove(boxName);
      }
      await Hive.deleteBoxFromDisk(boxName);
      Logger.warning('🗑️ Boîte supprimée: $boxName');
    } catch (e) {
      Logger.error('❌ Erreur suppression box $boxName: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // MÉTHODES CRUD GÉNÉRIQUES
  // ============================================

  /// Ajoute ou met à jour une entrée
  Future<void> put<T>(String boxName, dynamic key, T value) async {
    _ensureInitialized();
    try {
      final box = await openBox(boxName);
      await box.put(key, value);
      Logger.debug('📝 Hive put: $boxName[$key] = $value');
    } catch (e) {
      Logger.error('❌ Erreur Hive put: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Récupère une entrée
  T? get<T>(String boxName, dynamic key) {
    _ensureInitialized();
    try {
      final box = _openBoxes[boxName];
      if (box == null) return null;
      return box.get(key) as T?;
    } catch (e) {
      Logger.error('❌ Erreur Hive get: $e');
      return null;
    }
  }

  /// Récupère une entrée avec valeur par défaut
  T getOrDefault<T>(String boxName, dynamic key, T defaultValue) {
    final value = get<T>(boxName, key);
    return value ?? defaultValue;
  }

  /// Supprime une entrée
  Future<void> delete(String boxName, dynamic key) async {
    _ensureInitialized();
    try {
      final box = await openBox(boxName);
      await box.delete(key);
      Logger.debug('🗑️ Hive delete: $boxName[$key]');
    } catch (e) {
      Logger.error('❌ Erreur Hive delete: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Supprime toutes les entrées d'une boîte
  Future<void> clearBox(String boxName) async {
    _ensureInitialized();
    try {
      final box = await openBox(boxName);
      await box.clear();
      Logger.debug('🗑️ Hive clear: $boxName');
    } catch (e) {
      Logger.error('❌ Erreur Hive clear: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Vérifie si une clé existe
  bool containsKey(String boxName, dynamic key) {
    _ensureInitialized();
    try {
      final box = _openBoxes[boxName];
      if (box == null) return false;
      return box.containsKey(key);
    } catch (e) {
      Logger.error('❌ Erreur Hive containsKey: $e');
      return false;
    }
  }

  /// Récupère toutes les clés d'une boîte
  Iterable<dynamic> getKeys(String boxName) {
    _ensureInitialized();
    try {
      final box = _openBoxes[boxName];
      if (box == null) return [];
      return box.keys;
    } catch (e) {
      Logger.error('❌ Erreur Hive getKeys: $e');
      return [];
    }
  }

  /// Récupère toutes les valeurs d'une boîte
  Iterable<T> getValues<T>(String boxName) {
    _ensureInitialized();
    try {
      final box = _openBoxes[boxName];
      if (box == null) return [];
      return box.values.cast<T>();
    } catch (e) {
      Logger.error('❌ Erreur Hive getValues: $e');
      return [];
    }
  }

  /// Récupère toutes les entrées d'une boîte (Map)
  Map<dynamic, dynamic> getAll(String boxName) {
    _ensureInitialized();
    try {
      final box = _openBoxes[boxName];
      if (box == null) return {};
      return box.toMap();
    } catch (e) {
      Logger.error('❌ Erreur Hive getAll: $e');
      return {};
    }
  }

  // ============================================
  // MÉTHODES SPÉCIFIQUES À L'APPLICATION
  // ============================================

  // --- Utilisateur ---

  Future<void> saveUser(Map<String, dynamic> user) async {
    await put(boxUser, 'current_user', user);
  }

  Map<String, dynamic>? getUser() {
    return get<Map<String, dynamic>>(boxUser, 'current_user');
  }

  Future<void> deleteUser() async {
    await delete(boxUser, 'current_user');
  }

  // --- Wallets ---

  Future<void> saveWallet(String walletId, Map<String, dynamic> wallet) async {
    await put(boxWallets, walletId, wallet);
  }

  Map<String, dynamic>? getWallet(String walletId) {
    return get<Map<String, dynamic>>(boxWallets, walletId);
  }

  List<Map<String, dynamic>> getAllWallets() {
    return getValues<Map<String, dynamic>>(boxWallets).toList();
  }

  Future<void> deleteWallet(String walletId) async {
    await delete(boxWallets, walletId);
  }

  Future<void> clearAll() async {
    final boxes = [
      boxUser,
      boxWallets,
      boxTransactions,
      boxBudget,
      boxDebts,
      boxSavings,
      boxEcheances,
      boxCategories,
      boxSettings,
      boxCache,
    ];
    for (final b in boxes) {
      try {
        await clearBox(b);
      } catch (e) {
        Logger.error('Erreur clearAll box $b: $e');
      }
    }
    Logger.success('🗑️ Hive: toutes les boxes vidées');
  }

  Future<void> clearWallets() async {
    await clearBox(boxWallets);
  }

  // --- Transactions ---

  Future<void> saveTransaction(
      String txId, Map<String, dynamic> transaction) async {
    await put(boxTransactions, txId, transaction);
  }

  Map<String, dynamic>? getTransaction(String txId) {
    return get<Map<String, dynamic>>(boxTransactions, txId);
  }

  List<Map<String, dynamic>> getAllTransactions() {
    return getValues<Map<String, dynamic>>(boxTransactions).toList();
  }

  Future<void> deleteTransaction(String txId) async {
    await delete(boxTransactions, txId);
  }

  Future<void> clearTransactions() async {
    await clearBox(boxTransactions);
  }

  // --- Budget ---

  Future<void> saveBudget(String monthKey, Map<String, dynamic> budget) async {
    await put(boxBudget, monthKey, budget);
  }

  Map<String, dynamic>? getBudget(String monthKey) {
    return get<Map<String, dynamic>>(boxBudget, monthKey);
  }

  List<Map<String, dynamic>> getAllBudgets() {
    return getValues<Map<String, dynamic>>(boxBudget).toList();
  }

  Future<void> deleteBudget(String monthKey) async {
    await delete(boxBudget, monthKey);
  }

  // --- Dettes ---

  Future<void> saveDebt(String debtId, Map<String, dynamic> debt) async {
    await put(boxDebts, debtId, debt);
  }

  Map<String, dynamic>? getDebt(String debtId) {
    return get<Map<String, dynamic>>(boxDebts, debtId);
  }

  List<Map<String, dynamic>> getAllDebts() {
    return getValues<Map<String, dynamic>>(boxDebts).toList();
  }

  Future<void> deleteDebt(String debtId) async {
    await delete(boxDebts, debtId);
  }

  // --- Épargne ---

  Future<void> saveSavingsGoal(String goalId, Map<String, dynamic> goal) async {
    await put(boxSavings, goalId, goal);
  }

  Map<String, dynamic>? getSavingsGoal(String goalId) {
    return get<Map<String, dynamic>>(boxSavings, goalId);
  }

  List<Map<String, dynamic>> getAllSavingsGoals() {
    return getValues<Map<String, dynamic>>(boxSavings).toList();
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    await delete(boxSavings, goalId);
  }

  // --- Catégories ---

  Future<void> saveCategory(
      String categoryId, Map<String, dynamic> category) async {
    await put(boxCategories, categoryId, category);
  }

  Map<String, dynamic>? getCategory(String categoryId) {
    return get<Map<String, dynamic>>(boxCategories, categoryId);
  }

  List<Map<String, dynamic>> getAllCategories() {
    return getValues<Map<String, dynamic>>(boxCategories).toList();
  }

  Future<void> deleteCategory(String categoryId) async {
    await delete(boxCategories, categoryId);
  }

  // --- Échéances ---

  Future<void> saveEcheance(
      String echeanceId, Map<String, dynamic> echeance) async {
    await put(boxEcheances, echeanceId, echeance);
  }

  Map<String, dynamic>? getEcheance(String echeanceId) {
    return get<Map<String, dynamic>>(boxEcheances, echeanceId);
  }

  List<Map<String, dynamic>> getAllEcheances() {
    return getValues<Map<String, dynamic>>(boxEcheances).toList();
  }

  Future<void> deleteEcheance(String echeanceId) async {
    await delete(boxEcheances, echeanceId);
  }

  // ============================================
  // CACHE
  // ============================================

  /// Met en cache une valeur
  Future<void> cacheData(String key, dynamic value, {Duration? ttl}) async {
    final cacheEntry = {
      'data': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds ?? 0,
    };
    await put(boxCache, key, cacheEntry);
  }

  /// Récupère une valeur du cache (si elle n'a pas expiré)
  T? getCachedData<T>(String key) {
    final entry = get<Map<String, dynamic>>(boxCache, key);
    if (entry == null) return null;

    final timestamp = entry['timestamp'] as int? ?? 0;
    final ttl = entry['ttl'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Vérifier si le cache a expiré
    if (ttl > 0 && (now - timestamp) > ttl) {
      delete(boxCache, key); // Nettoyer automatiquement
      return null;
    }

    return entry['data'] as T?;
  }

  /// Supprime une entrée du cache
  Future<void> clearCache() async {
    await clearBox(boxCache);
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const CacheFailure(
        message: 'HiveService non initialisé. Appelez init() d\'abord.',
        code: 'NOT_INITIALIZED',
      );
    }
  }

  /// Vérifie l'état d'une boîte
  bool isBoxOpen(String boxName) {
    return _openBoxes.containsKey(boxName);
  }

  /// Récupère la taille d'une boîte
  int getBoxSize(String boxName) {
    final box = _openBoxes[boxName];
    return box?.length ?? 0;
  }

  /// Affiche un résumé des boîtes
  void logSummary() {
    _ensureInitialized();
    Logger.info('📊 HiveService Summary: ${_openBoxes.length} boîtes ouvertes');
    for (final entry in _openBoxes.entries) {
      Logger.debug('  - ${entry.key}: ${entry.value.length} éléments');
    }
  }
}
