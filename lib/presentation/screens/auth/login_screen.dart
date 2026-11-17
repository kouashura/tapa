import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  void _onPinDigit(String digit) {
    if (_pin.length < 4 && !_isLoading) {
      setState(() {
        _pin += digit;
        _error = null;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.verifyPin(_pin);

      if (success && mounted) {
        context.go('/home');
      } else {
        setState(() {
          _error = 'PIN incorrect. Réessayez.';
          _pin = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur : ${e.toString()}';
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo / Titre
              const Text(
                'TAPA Invest',
                style: TextStyle(
                  color: TAPAColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Content de te revoir !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entre ton code PIN à 4 chiffres.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Indicateurs de PIN (4 cercles)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 2),
                      color: filled ? TAPAColors.gold : Colors.transparent,
                    ),
                  );
                }),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 40),

              // Pavé numérique
              Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '⌫'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((digit) {
                          if (digit.isEmpty) {
                            return const SizedBox(width: 70, height: 70);
                          }
                          return InkWell(
                            onTap: _isLoading
                                ? null
                                : () {
                                    if (digit == '⌫') {
                                      _onBackspace();
                                    } else {
                                      _onPinDigit(digit);
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 70,
                              height: 70,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                digit,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: TAPAColors.gold),
                ),

              const SizedBox(height: 24),

              // Bouton S'inscrire
              TextButton(
                onPressed: _isLoading ? null : () => context.push('/inscription'),
                child: const Text(
                  'Pas encore de compte ? S\'inscrire',
                  style: TextStyle(color: TAPAColors.gold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
