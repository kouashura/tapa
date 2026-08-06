// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // ✅ CORRECT
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/routes/app_router.dart';
import 'theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ CHARGER .env (DOIT ÊTRE FAIT EN PREMIER)
  try {
    await dotenv.load();
    Logger.success('✅ .env chargé avec succès');
  } catch (e) {
    Logger.error('❌ Erreur chargement .env: $e');
  }

  // ✅ INITIALISER FIREBASE
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.success('✅ Firebase initialisé avec succès');
    } else {
      Logger.info('ℹ️ Firebase déjà initialisé');
    }

    // ✅ INITIALISER FIREBASE SERVICE (APRÈS FIREBASE)
    await FirebaseService().init();
    Logger.info('✅ FirebaseService initialisé');

  } catch (e) {
    Logger.error('❌ Erreur Firebase: $e');
  }

  runApp(
    const ProviderScope(
      child: TapaBudgetApp(),
    ),
  );
}

class TapaBudgetApp extends ConsumerWidget {
  const TapaBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter(ref);

    return MaterialApp.router(
      title: 'TAPA Budget Pro',
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
    );
  }
}