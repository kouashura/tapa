// lib/screens/auth/inscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';
import '../../presentation/providers/auth/auth_provider.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../core/utils/logger.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key});

  @override
  ConsumerState<InscriptionScreen> createState() => _InscriptionScreenState();
}

/// Métriques responsives
class _Metrics {
  final bool isTablet;
  final bool isCompact;
  final double contentMaxWidth;
  final double horizontalPadding;
  final double headerTitleSize;
  final double stepTitleSize;
  final double gridCrossAxisCount;
  final double gridItemHeight;
  final double gapLarge;
  final double gapMedium;

  _Metrics(BoxConstraints c)
      : isTablet = c.maxWidth >= 600,
        isCompact = c.maxHeight < 700,
        contentMaxWidth = c.maxWidth >= 900
            ? 520
            : (c.maxWidth >= 600 ? 480 : double.infinity),
        horizontalPadding = c.maxWidth >= 600 ? 32 : 24,
        headerTitleSize = c.maxWidth >= 600 ? 22 : 20,
        stepTitleSize = c.maxWidth >= 600 ? 27 : (c.maxHeight < 700 ? 21 : 24),
        gridCrossAxisCount = c.maxWidth >= 900 ? 3 : 2,
        gridItemHeight = c.maxWidth >= 600 ? 72 : (c.maxHeight < 700 ? 58 : 66),
        gapLarge = c.maxHeight < 700 ? 16 : 24,
        gapMedium = c.maxHeight < 700 ? 10 : 16;
}

class _InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController(); // ✅ CHANGÉ : email au lieu de téléphone
  int _step = 0;
  String _monnaie = 'FCFA';
  String _codePays = 'CI';
  bool _loading = false;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_step == 0) {
      final prenom = _prenomCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      if (prenom.isEmpty) {
        _snack('Entre ton prénom pour continuer');
        return;
      }
      if (email.isEmpty || !_isValidEmail(email)) {
        _snack('Entre un email valide');
        return;
      }

      setState(() => _step++);
      return;
    }
    await _inscrire();
  }

  // ✅ AJOUT : Validation d'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _inscrire() async {
    final prenom = _prenomCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (prenom.isEmpty || email.isEmpty) {
      _snack('Remplis tous les champs');
      return;
    }

    setState(() => _loading = true);

    try {
      final authState = ref.read(authStateProvider);

      if (!authState.isAuthenticated) {
        Logger.warning('⚠️ Utilisateur non authentifié - Redirection vers verify-phone');
        setState(() => _loading = false);

        if (mounted) {
          // ✅ CHANGÉ : Envoyer l'email au lieu du téléphone
          context.push('/verify-phone', extra: {
            'prenom': prenom,
            'telephone': email, // L'email est envoyé comme "telephone" pour compatibilité
            'indicatif': '',
            'codePays': _codePays,
            'monnaie': _monnaie,
          });
        }
        return;
      }

      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.createUserProfile(
        prenom: prenom,
        telephone: email, // L'email est utilisé comme identifiant
        indicatif: '',
        codePays: _codePays,
        monnaie: _monnaie,
      );

      if (mounted) {
        final user = ref.read(currentUserProvider);
        if (user?.onboardingVu ?? false) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      Logger.error('❌ Erreur inscription: $e');
      _snack('Erreur: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TAPAColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated == false) {
        Logger.info('✅ Authentification détectée - Mise à jour de l\'état');
        setState(() {});
      }
    });

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: LayoutBuilder(builder: (context, constraints) {
        final m = _Metrics(constraints);
        return SafeArea(
          child: Column(
            children: [
              // En-tête
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: m.contentMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        m.horizontalPadding, 16, m.horizontalPadding, 0),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _step > 0
                              ? GestureDetector(
                            key: const ValueKey('back'),
                            onTap: () => setState(() => _step--),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  color: TAPAColors.white, size: 16),
                            ),
                          )
                              : const SizedBox(key: ValueKey('nospace')),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'TAPA',
                                style: TextStyle(
                                  fontSize: m.headerTitleSize,
                                  fontWeight: FontWeight.w800,
                                  color: TAPAColors.gold,
                                ),
                              ),
                              TextSpan(
                                text: ' Invest',
                                style: TextStyle(
                                  fontSize: m.headerTitleSize,
                                  color: TAPAColors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Étape ${_step + 1}/2',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Barre de progression
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: m.contentMaxWidth),
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: m.horizontalPadding),
                    child: Row(
                      children: List.generate(2, (i) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? TAPAColors.gold
                                  : Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              SizedBox(height: m.gapLarge),

              // Contenu
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: TAPAColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: m.contentMaxWidth),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(m.horizontalPadding, 28,
                            m.horizontalPadding, 20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _step == 0
                              ? _buildStep1(m, key: const ValueKey('s1'))
                              : _buildStep2(m, key: const ValueKey('s2')),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1(_Metrics m, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenue !',
              style: TextStyle(
                fontSize: m.stepTitleSize,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 6),
          const Text('Comment tu t\'appelles ?',
              style: TextStyle(
                color: TAPAColors.textSecond,
                fontSize: 14,
              )),
          SizedBox(height: m.gapMedium),
          TextField(
            controller: _prenomCtrl,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              hintText: 'ex : Kouassi, Marie...',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          SizedBox(height: m.gapMedium),
          // ✅ CHANGÉ : Champ email au lieu de téléphone
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Adresse Email *',
              hintText: 'ex : kouassi@gmail.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 13, color: TAPAColors.textSecond),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Un code de vérification sera envoyé sur votre email',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TAPAColors.textSecond,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: m.gapMedium),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TAPAColors.goldLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: TAPAColors.gold.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: TAPAColors.gold.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 16, color: TAPAColors.amber),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ton compte est protégé par un code PIN à 4 chiffres.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TAPAColors.navy,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: m.gapLarge),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
              child: _loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(TAPAColors.gold),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuer'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep2(_Metrics m, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quelle monnaie tu utilises ?',
            style: TextStyle(
              fontSize: m.stepTitleSize * 0.9,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy,
              letterSpacing: -0.2,
            )),
        const SizedBox(height: 6),
        const Text('Tu pourras changer ça dans les réglages.',
            style: TextStyle(color: TAPAColors.textSecond, fontSize: 14)),
        SizedBox(height: m.gapLarge),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: m.gridCrossAxisCount.toInt(),
              mainAxisExtent: m.gridItemHeight,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AppConstants.monnaies.length,
            itemBuilder: (ctx, i) {
              final mon = AppConstants.monnaies[i];
              final sel = _monnaie == mon['symbole'];
              return GestureDetector(
                onTap: () => setState(() => _monnaie = mon['symbole']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? TAPAColors.navy : TAPAColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? TAPAColors.gold : TAPAColors.border,
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: sel
                        ? [
                      BoxShadow(
                        color: TAPAColors.navy.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(mon['symbole']!,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: sel
                                          ? TAPAColors.gold
                                          : TAPAColors.navy,
                                    )),
                                const SizedBox(height: 2),
                                Text(mon['nom']!,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? Colors.white70
                                          : TAPAColors.textSecond,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (sel)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.check_circle,
                              color: TAPAColors.gold, size: 18),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: m.gapMedium),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor:
                AlwaysStoppedAnimation<Color>(TAPAColors.gold),
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Créer mon compte'),
                SizedBox(width: 8),
                Icon(Icons.check_circle_outline_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}