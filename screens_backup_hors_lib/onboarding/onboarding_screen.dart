// lib/presentation/screens/onboarding/onboarding_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/app_state.dart';
import '../../presentation/providers/auth/auth_provider.dart';
import '../../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Métriques responsives
class _Metrics {
  final double width;
  final double height;
  final bool isCompact;
  final bool isTablet;
  final double contentMaxWidth;
  final double horizontalPadding;
  final double iconSize;
  final double emojiFontSize;
  final double titleFontSize;
  final double subtitleFontSize;
  final double descriptionFontSize;
  final double itemFontSize;
  final double buttonHeight;
  final double cardPadding;
  final double cardRadius;
  final double gapLarge;
  final double gapMedium;

  _Metrics(BuildContext context, BoxConstraints constraints)
      : width = constraints.maxWidth,
        height = constraints.maxHeight,
        isCompact = constraints.maxHeight < 700 || constraints.maxWidth < 340,
        isTablet = constraints.maxWidth >= 600,
        contentMaxWidth = constraints.maxWidth >= 600 ? 480 : double.infinity,
        horizontalPadding = constraints.maxWidth >= 600 ? 0 : 24,
        iconSize = constraints.maxWidth >= 600
            ? 108
            : (constraints.maxHeight < 700 ? 72 : 92),
        emojiFontSize = constraints.maxWidth >= 600
            ? 46
            : (constraints.maxHeight < 700 ? 32 : 40),
        titleFontSize = constraints.maxWidth >= 600
            ? 28
            : (constraints.maxHeight < 700 ? 20 : 24),
        subtitleFontSize = constraints.maxWidth >= 600 ? 13 : 11.5,
        descriptionFontSize = constraints.maxWidth >= 600 ? 15 : 13.5,
        itemFontSize = constraints.maxWidth >= 600 ? 14 : 13,
        buttonHeight = constraints.maxHeight < 700 ? 52 : 58,
        cardPadding = constraints.maxWidth >= 600 ? 28 : 20,
        cardRadius = 28,
        gapLarge = constraints.maxHeight < 700 ? 14 : 24,
        gapMedium = constraints.maxHeight < 700 ? 8 : 12;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late final AnimationController _contentCtrl;
  int _page = 0;
  bool _isCompleting = false;

  static const List<Map<String, dynamic>> _slides = [
    {
      'emoji': '👋',
      'titre': 'Bienvenue sur TAPA Invest',
      'sousTitre': 'LE COACH FINANCIER DE CHAQUE AFRICAIN',
      'description':
      'Prenez le contrôle de votre argent et construisez '
          'votre avenir financier pas à pas.',
      'couleur': 0xFF1A2B4A,
      'items': [
        {'icone': '💰', 'texte': 'Suivez vos revenus et dépenses'},
        {'icone': '📊', 'texte': 'Analysez votre budget en temps réel'},
        {'icone': '🎯', 'texte': 'Atteignez vos objectifs financiers'},
      ],
    },
    {
      'emoji': '📱',
      'titre': 'Tous vos portefeuilles\nen un seul endroit',
      'sousTitre': 'WAVE · ORANGE MONEY · MTN · MOOV · CASH · BANQUE',
      'description':
      'Centralisez tous vos comptes et suivez chaque FCFA '
          'peu importe où il se trouve.',
      'couleur': 0xFF14274E,
      'items': [
        {'icone': '🌊', 'texte': 'Wave — suivi automatique'},
        {'icone': '🟠', 'texte': 'Orange Money — en temps réel'},
        {'icone': '🟡', 'texte': 'MTN & Moov Money'},
        {'icone': '🏦', 'texte': 'Banque et cash inclus'},
      ],
    },
    {
      'emoji': '📈',
      'titre': 'Investissez et\nprotégez votre famille',
      'sousTitre': 'FCP ET ASSURANCE VIE SONAM VIE',
      'description':
      'Faites fructifier votre épargne et protégez '
          'vos proches avec nos partenaires agréés.',
      'couleur': 0xFF0D1B2E,
      'items': [
        {'icone': '📈', 'texte': 'Fonds Communs de Placement'},
        {'icone': '🛡️', 'texte': 'Assurance vie SONAM VIE'},
        {'icone': '💡', 'texte': 'Analyse financière 50/30/20'},
        {'icone': '⏰', 'texte': 'Rappels et échéances'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _slides.length - 1;

  // ============================================
  // SUIVANT - Change de page ou termine
  // ============================================

  void _suivant() {
    if (!_isLastPage) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);
    } else {
      _terminer();
    }
  }

  // ============================================
  // TERMINER - Marque l'onboarding comme vu
  // ============================================

  Future<void> _terminer() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      Logger.info('✅ Fin de l\'onboarding...');

      // ✅ 1. Marquer l'onboarding comme vu
      await ref.read(authStateProvider.notifier).markOnboardingAsSeen();
      Logger.info('✅ Onboarding marqué comme vu');

      // ✅ 2. Récupérer l'utilisateur mis à jour
      final user = ref.read(currentUserProvider);

      if (user != null) {
        // ✅ 3. Mettre à jour l'état global
        ref.read(appStateProvider.notifier).setAuthenticatedUser(user);
        Logger.info('✅ État utilisateur mis à jour: ${user.prenom}');
      } else {
        Logger.warning('⚠️ Utilisateur non trouvé après onboarding');
      }

      // ✅ 4. Naviguer vers la configuration du PIN
      if (mounted) {
        context.go('/pin-setup');
        Logger.info('🚀 Navigation vers /pin-setup');
      }
    } catch (e) {
      Logger.error('❌ Erreur lors de la fin de l\'onboarding: $e');
      if (mounted) {
        // En cas d'erreur, essayer de naviguer quand même
        context.go('/pin-setup');
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _contentCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final m = _Metrics(context, constraints);
          final orbBase = constraints.maxWidth >= 600
              ? constraints.maxHeight
              : constraints.maxWidth;

          return Stack(children: [
            // ============================================
            // FOND DÉGRADÉ ANIMÉ
            // ============================================
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(_slides[_page]['couleur'] as int),
                    const Color(0xFF0A1628),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ============================================
            // ORBES LUMINEUX (effet glow)
            // ============================================
            Positioned(
              top: -orbBase * 0.25,
              right: -orbBase * 0.2,
              child: _glowOrb(orbBase * 0.7, TAPAColors.gold.withOpacity(0.14)),
            ),
            Positioned(
              bottom: -orbBase * 0.3,
              left: -orbBase * 0.25,
              child: _glowOrb(orbBase * 0.6, TAPAColors.gold.withOpacity(0.07)),
            ),

            // ============================================
            // CONTENU
            // ============================================
            SafeArea(
              child: Column(
                children: [
                  // --- En-tête : marque + bouton passer ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TAPAColors.gold,
                                boxShadow: [
                                  BoxShadow(
                                    color: TAPAColors.gold.withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TAPA',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isCompleting ? 0 : 1,
                          child: TextButton(
                            onPressed: _isCompleting ? null : _terminer,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              backgroundColor: Colors.white.withOpacity(0.06),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Passer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Pages ---
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: _onPageChanged,
                      itemCount: _slides.length,
                      itemBuilder: (ctx, i) => _buildSlide(_slides[i], m),
                    ),
                  ),

                  // --- Indicateurs et bouton ---
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: m.contentMaxWidth),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.isTablet ? 0 : 28,
                          0,
                          m.isTablet ? 0 : 28,
                          m.isCompact ? 18 : 28,
                        ),
                        child: Column(
                          children: [
                            // Points indicateurs
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_slides.length, (i) =>
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _page == i ? 26 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _page == i
                                          ? TAPAColors.gold
                                          : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: _page == i
                                          ? [
                                        BoxShadow(
                                          color: TAPAColors.gold
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 0.5,
                                        ),
                                      ]
                                          : null,
                                    ),
                                  )),
                            ),
                            SizedBox(height: m.gapLarge),

                            // Bouton principal
                            _PrimaryButton(
                              height: m.buttonHeight,
                              isLastPage: _isLastPage,
                              isLoading: _isCompleting,
                              onTap: _suivant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  // ============================================
  // WIDGET ORBE LUMINEUX
  // ============================================

  Widget _glowOrb(double diameter, Color color) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGET SLIDE
  // ============================================

  Widget _buildSlide(Map<String, dynamic> slide, _Metrics m) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: m.horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: m.contentMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: m.gapMedium),

                        // --- Icône principale ---
                        Container(
                          width: m.iconSize,
                          height: m.iconSize,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                TAPAColors.gold,
                                TAPAColors.gold.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: TAPAColors.gold.withOpacity(0.25),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0A1628).withOpacity(0.85),
                            ),
                            child: Center(
                              child: Text(
                                slide['emoji'] as String,
                                style: TextStyle(fontSize: m.emojiFontSize),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: m.gapLarge),

                        // --- Carte verre dépoli ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(m.cardRadius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(m.cardPadding),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.045),
                                borderRadius: BorderRadius.circular(m.cardRadius),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.09),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Titre
                                  Text(
                                    slide['titre'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: m.titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: TAPAColors.white,
                                      letterSpacing: -0.3,
                                      height: 1.25,
                                    ),
                                  ),
                                  SizedBox(height: m.gapMedium),

                                  // Sous-titre (badge)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TAPAColors.gold.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: TAPAColors.gold.withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      slide['sousTitre'] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: m.subtitleFontSize,
                                        color: TAPAColors.gold,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: m.gapLarge * 0.6),

                                  // Description
                                  Text(
                                    slide['description'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: m.descriptionFontSize,
                                      color: Colors.white.withOpacity(0.62),
                                      height: 1.55,
                                    ),
                                  ),
                                  SizedBox(height: m.gapLarge * 0.9),

                                  // Séparateur
                                  Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  SizedBox(height: m.gapLarge * 0.9),

                                  // Items
                                  ...(slide['items'] as List<Map<String, String>>)
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final isLast = entry.key ==
                                        (slide['items'] as List).length - 1;
                                    final item = entry.value;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLast ? 0 : 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.08),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    TAPAColors.gold
                                                        .withOpacity(0.22),
                                                    TAPAColors.gold
                                                        .withOpacity(0.08),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  item['icone']!,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item['texte']!,
                                                style: TextStyle(
                                                  fontSize: m.itemFontSize,
                                                  color: Colors.white
                                                      .withOpacity(0.85),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: m.gapMedium),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================
// BOUTON PRINCIPAL PERSONNALISÉ
// ============================================

class _PrimaryButton extends StatefulWidget {
  final double height;
  final bool isLastPage;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.height,
    required this.isLastPage,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                TAPAColors.gold,
                TAPAColors.gold.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: TAPAColors.gold.withOpacity(disabled ? 0.15 : 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(TAPAColors.navy),
              ),
            )
                : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(widget.isLastPage),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isLastPage
                        ? 'Commencer maintenant'
                        : 'Suivant',
                    style: const TextStyle(
                      color: TAPAColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isLastPage
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: TAPAColors.navy,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}