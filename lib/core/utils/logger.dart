// lib/core/utils/logger.dart

/// Logger utilitaire pour le débogage
class Logger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void info(String message) {
    if (!_enabled) return;
    print('ℹ️ $message');
  }

  static void success(String message) {
    if (!_enabled) return;
    print('✅ $message');
  }

  static void warning(String message) {
    if (!_enabled) return;
    print('⚠️ $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled) return;
    print('❌ $message');
    if (error != null) {
      print('   Erreur: $error');
    }
    if (stackTrace != null) {
      print('   Stack: $stackTrace');
    }
  }

  static void debug(String message) {
    if (!_enabled) return;
    print('🐞 $message');
  }

  static void transaction(String message, {Map<String, dynamic>? data}) {
    if (!_enabled) return;
    print('💳 $message');
    if (data != null) {
      print('   📊 $data');
    }
  }
}