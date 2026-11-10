// lib/services/secure_http_service.dart

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import '../core/utils/logger.dart';

class SecureHttpService {
  static final SecureHttpService _instance = SecureHttpService._internal();
  factory SecureHttpService() => _instance;
  SecureHttpService._internal();

  late Dio _dio;
  bool _isInitialized = false;

  // ============================================
  // CERTIFICATS SHA-256 À PINNER
  // ============================================
  // 🔧 GÉNÉREZ CES HASH AVEC LA COMMANDE CI-DESSOUS
  // echo | openssl s_client -servername api.anthropic.com -connect api.anthropic.com:443 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64

  static const Map<String, List<String>> _pinnedCertificates = {
    'api.anthropic.com': [
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    ],
    'api.wave.com': [
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    ],
    'firestore.googleapis.com': [
      'sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
    ],
    'tapa-budget-6ed7c.firebaseio.com': [
      'sha256/DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=',
    ],
  };

  // ============================================
  // INITIALISATION
  // ============================================

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ));

      // ✅ Intercepteur de sécurité
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          Logger.debug('🌐 ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.debug(
              '✅ ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          Logger.error(
              '❌ ${error.response?.statusCode} ${error.requestOptions.uri}');
          return handler.next(error);
        },
      ));

      // ✅ Retry automatique
      _dio.interceptors.add(
        RetryInterceptor(
          dio: _dio,
          logPrint: (message) => Logger.debug('🔄 Retry: $message'),
          retries: 3,
          retryDelays: const [
            Duration(seconds: 1),
            Duration(seconds: 2),
            Duration(seconds: 3),
          ],
        ),
      );

      _isInitialized = true;
      Logger.info('✅ SecureHttpService initialisé');
    } catch (e) {
      Logger.error('❌ Erreur init SecureHttpService: $e');
      rethrow;
    }
  }

  // ============================================
  // MÉTHODES HTTP
  // ============================================

  Future<Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureInitialized();
    return _dio.get(
      url,
      options: Options(headers: headers),
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    await _ensureInitialized();
    return _dio.post(
      url,
      options: Options(headers: headers),
      data: data,
    );
  }

  Future<Response> put(
    String url, {
    Map<String, String>? headers,
    dynamic data,
  }) async {
    await _ensureInitialized();
    return _dio.put(
      url,
      options: Options(headers: headers),
      data: data,
    );
  }

  Future<Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    await _ensureInitialized();
    return _dio.delete(
      url,
      options: Options(headers: headers),
    );
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Dio get dio => _dio;

  /// Vérifie le statut du pinning pour un domaine
  bool isDomainPinned(String domain) {
    return _pinnedCertificates.containsKey(domain);
  }
}
