// lib/screens/auth/pin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../services/db_service_mysql.dart';
import '../../services/firebase_service.dart';
import '../../core/utils/logger.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, required this.isSetup});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirmMode = false;
  bool _error = false;
  bool _isLoading = false;
  String _errorMessage = '';

  void _pressKey(String d) {
    if (_pin.length >= 4 || _isLoading) return;
    setState(() {
      _pin += d;
      _error = false;
      _errorMessage = '';
    });
    if (_pin.length == 4) {
      Future.delayed(
          const Duration(milliseconds: 200),
          _validate);
    }
  }

  void _delete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin =
          _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _validate() async {
    final authNotifier = ref.read(authStateProvider.notifier);

    if (widget.isSetup) {
      // ÉTAPE 1: Choix du PIN
      if (!_confirmMode) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _confirmMode = true;
        });
        return;
      }

      // ÉTAPE 2: Confirmation du PIN
      if (_pin != _confirmPin) {
        setState(() {
          _pin = '';
          _confirmMode = false;
          _error = true;
          _errorMessage = 'Les codes ne correspondent pas.';
        });
        return;
      }

      // ÉTAPE 3: Sauvegarde du PIN
      setState(() => _isLoading = true);

      try {
        await authNotifier.savePin(_pin);
        Logger.success('✅ PIN sauvegardé avec succès');

        final user = ref.read(currentUserProvider);
        if (user != null) {
          final notifier = ref.read(authStateProvider.notifier);
          notifier.state = notifier.state.copyWith(
            user: user,
            isAuthenticated: true,
          );
          Logger.info('👤 État mis à jour pour: ${user.prenom}');
        }

        // ✅ CORRECTION: Vérifier mounted avant navigation
        if (!mounted) return;

        final db = DBService();
        final firebaseService = FirebaseService();
        final isRoot = firebaseService.isRootUser;

        bool essaiExpire = false;
        bool aAcces = false;

        try {
          essaiExpire = db.essaiGratuitExpire;
          aAcces = db.aAccesAVie;

          if (!essaiExpire && db.joursRestantsEssai == 0) {
            essaiExpire = await db.isEssaiGratuitExpire();
          }
        } catch (e) {
          Logger.error('❌ Erreur vérification essai: $e');
          essaiExpire = false;
        }

        Logger.info('🔍 Navigation - Essai expiré: $essaiExpire, Accès: $aAcces, Root: $isRoot');

        // ✅ CORRECTION: Vérifier mounted après chaque await
        if (!mounted) return;

        if (isRoot) {
          Logger.info('👑 Root - Navigation vers /home');
          context.go('/home');
        } else if (essaiExpire && !aAcces) {
          Logger.info('🔄 Essai expiré - Navigation vers /activation');
          context.go('/activation');
        } else {
          Logger.info('✅ Accès validé - Navigation vers /home');
          context.go('/home');
        }
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant setState
        if (!mounted) return;
        Logger.error('❌ Erreur lors de la sauvegarde du PIN: $e');
        setState(() {
          _error = true;
          _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    } else {
      // ============================================
      // LOGIN AVEC PIN (Connexion)
      // ============================================
      setState(() => _isLoading = true);

      try {
        final isValid = await authNotifier.verifyPin(_pin);
        Logger.info('🔍 Vérification PIN: ${isValid ? "✅ Valide" : "❌ Invalide"}');

        // ✅ CORRECTION: Vérifier mounted après await
        if (!mounted) return;

        if (isValid) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final notifier = ref.read(authStateProvider.notifier);
            notifier.state = notifier.state.copyWith(
              user: user,
              isAuthenticated: true,
            );
            Logger.info('👤 Utilisateur connecté: ${user.prenom}');
          }

          final db = DBService();
          final firebaseService = FirebaseService();
          final isRoot = firebaseService.isRootUser;

          bool essaiExpire = false;
          bool aAcces = false;

          try {
            essaiExpire = db.essaiGratuitExpire;
            aAcces = db.aAccesAVie;

            if (!essaiExpire && db.joursRestantsEssai == 0) {
              essaiExpire = await db.isEssaiGratuitExpire();
            }
          } catch (e) {
            Logger.error('❌ Erreur vérification essai: $e');
            essaiExpire = false;
          }

          // ✅ CORRECTION: Vérifier mounted après await
          if (!mounted) return;

          if (isRoot) {
            context.go('/home');
          } else if (essaiExpire && !aAcces) {
            context.go('/activation');
          } else {
            context.go('/home');
          }
        } else {
          setState(() {
            _pin = '';
            _error = true;
            _errorMessage = 'Code PIN incorrect. Réessayez.';
            _isLoading = false;
          });
        }
      } catch (e) {
        // ✅ CORRECTION: Vérifier mounted avant setState
        if (!mounted) return;
        Logger.error('❌ Erreur vérification PIN: $e');
        setState(() {
          _error = true;
          _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_confirmMode
        ? 'Confirme ton code'
        : 'Choisis ton code PIN')
        : 'Entre ton code PIN';

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'TAPA',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.gold,
                    ),
                  ),
                  TextSpan(
                    text: ' Invest',
                    style: TextStyle(
                      fontSize: 26,
                      color: TAPAColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TAPAColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isSetup
                  ? 'Choisissez votre code PIN à 4 chiffres'
                  : 'Entrez votre code PIN',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
            if (_error) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: TAPAColors.red,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) =>
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? TAPAColors.gold
                          : Colors.transparent,
                      border: Border.all(
                        color: i < _pin.length
                            ? TAPAColors.gold
                            : Colors.white38,
                        width: 2,
                      ),
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: TAPAColors.gold,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (ctx, i) {
                    if (i == 9) return const SizedBox();
                    if (i == 11) {
                      return GestureDetector(
                      onTap: _delete,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Colors.white60,
                          size: 22,
                        ),
                      ),
                    );
                    }
                    final digit = i == 10 ? '0' : '${i + 1}';
                    return GestureDetector(
                      onTap: () => _pressKey(digit),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: TAPAColors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}