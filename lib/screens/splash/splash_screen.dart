import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // ✅ Le splash n'a plus sa propre logique de routing (qui utilisait un
    // DBService local totalement déconnecté de Firebase). On navigue vers
    // une destination neutre et c'est le `redirect` de GoRouter dans
    // app_router.dart — qui lit le vrai état Firebase via
    // isAuthenticatedProvider / currentUserProvider — qui prend le relais
    // et envoie l'utilisateur au bon endroit :
    //   non connecté          -> /inscription
    //   connecté, pas d'onboarding vu -> /onboarding
    //   connecté, pas de PIN  -> /pin-setup
    //   connecté, tout en ordre -> /home
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: TAPAColors.navy,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                          color: TAPAColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: TAPAColors.gold, width: 2)),
                      child: const Icon(
                          Icons.account_balance_wallet,
                          color: TAPAColors.gold, size: 36)),
                  const SizedBox(height: 20),
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'TAPA',
                        style: TextStyle(fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: TAPAColors.gold)),
                    TextSpan(text: ' Budget',
                        style: TextStyle(fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: TAPAColors.white)),
                  ])),
                  const SizedBox(height: 8),
                  const Text('Le budget simple pour tous.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                      color: TAPAColors.gold, strokeWidth: 2),
                ])));
  }
}