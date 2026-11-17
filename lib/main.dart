// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
// ✅ CHEMIN CORRIGÉ
import 'package:go_router/go_router.dart';
import 'presentation/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'data/datasources/local/shared_preferences_service.dart';
import 'data/datasources/local/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // 1. CHARGER .env
  // ============================================
  try {
    await dotenv.load();
    Logger.success('✅ .env chargé avec succès');
  } catch (e) {
    Logger.error('❌ Erreur chargement .env: $e');
  }

  // ============================================
  // 2. INITIALISER SHARED PREFERENCES
  // ============================================
  try {
    final prefs = SharedPreferencesService();
    await prefs.init();
    Logger.success('✅ SharedPreferencesService initialisé');
  } catch (e) {
    Logger.error('❌ Erreur SharedPreferencesService: $e');
  }

  // ============================================
  // 3. INITIALISER HIVE
  // ============================================
  try {
    final hive = HiveService();
    await hive.init();
    Logger.success('✅ HiveService initialisé');
  } catch (e) {
    Logger.error('❌ Erreur HiveService: $e');
  }

  // ============================================
  // 4. INITIALISER FIREBASE
  // ============================================
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.success('✅ Firebase initialisé avec succès');
    } else {
      Logger.info('ℹ️ Firebase déjà initialisé');
    }

    // Initialiser FirebaseService
    await FirebaseService().init();
    Logger.info('✅ FirebaseService initialisé');
  } catch (e) {
    Logger.error('❌ Erreur Firebase: $e');
  }

  // ============================================
  // 5. LANCER L'APPLICATION
  // ============================================
  runApp(
    const ProviderScope(
      child: TapaBudgetApp(),
    ),
  );
}

/// Provider global du router GoRouter, pour pouvoir naviguer depuis
/// n'importe où (deep links, notifs, etc.).
final goRouterProvider = Provider<GoRouter>((ref) {
  final appRouter = AppRouter(ref as WidgetRef);
  return appRouter.router;
});

class DeepLinkHandler extends ConsumerStatefulWidget {
  const DeepLinkHandler({super.key});

  @override
  ConsumerState<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends ConsumerState<DeepLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (e) {
      Logger.error('DeepLink error: $e');
    });

    // Gérer aussi le cas où l'app est ouverte via le deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    Logger.info('Deep Link recu: $uri');
    if (uri.scheme == 'tapa' && uri.host == 'wallet') {
      // Navigation vers le wallet
      final router = ref.read(goRouterProvider);
      router.go('/wallet');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class TapaBudgetApp extends ConsumerWidget {
  const TapaBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter(ref);

    return MaterialApp.router(
      title: 'TAPA Invest Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('fr', 'CI'),
        Locale('fr', 'SN'),
        Locale('en', 'US'),
      ],
      routerConfig: router.router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const DeepLinkHandler(),
          ],
        );
      },
    );
  }
}
