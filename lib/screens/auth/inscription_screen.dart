// lib/screens/auth/inscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/constants.dart';  // ← Changé de '../../core/utils/constants.dart'
import '../../presentation/providers/auth_provider.dart';
import '../../core/utils/logger.dart';  // ← Changé de '../../utils/logger.dart'

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
  final TextEditingController _telCtrl = TextEditingController();
  int _step = 0;
  String _monnaie = 'FCFA';
  String _codePays = 'CI';
  String _indicatif = '+225';
  String _drapeau = '🇨🇮';
  bool _loading = false;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_step == 0) {
      final prenom = _prenomCtrl.text.trim();
      final tel = _telCtrl.text.trim();

      if (prenom.isEmpty) {
        _snack('Entre ton prénom pour continuer');
        return;
      }
      if (tel.length < 6) {
        _snack('Entre ton numéro WhatsApp');
        return;
      }

      setState(() => _step++);
      return;
    }
    await _inscrire();
  }

  Future<void> _inscrire() async {
    final prenom = _prenomCtrl.text.trim();
    final tel = _telCtrl.text.trim();
    final fullNumber = '$_indicatif$tel';

    if (prenom.isEmpty || tel.length < 6) {
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
          context.push('/verify-phone', extra: {
            'prenom': prenom,
            'telephone': fullNumber,
          });
        }
        return;
      }

      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.createUserProfile(
        prenom: prenom,
        telephone: fullNumber,
        indicatif: _indicatif,
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
                                text: ' Budget',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TAPAColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_drapeau, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(_indicatif,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          )),
                      const Icon(Icons.expand_more,
                          size: 18, color: TAPAColors.textSecond),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'ex : 0748684403',
                    labelText: 'Numéro WhatsApp *',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 13, color: TAPAColors.textSecond),
              const SizedBox(width: 5),
              Expanded(
                child: Text('$_indicatif — numéro utilisé pour te contacter',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: TAPAColors.textSecond,
                    )),
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

  void _showCountryPicker() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final pays = AppConstants.pays.where((p) {
            if (query.isEmpty) return true;
            return p['nom']!.toLowerCase().contains(query) ||
                p['indicatif']!.contains(query);
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: TAPAColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TAPAColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Choisis ton pays',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un pays...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: TAPAColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: pays.isEmpty
                          ? const Center(
                          child: Text('Aucun pays trouvé',
                              style: TextStyle(
                                  color: TAPAColors.textSecond,
                                  fontSize: 13)))
                          : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: pays.length,
                        itemBuilder: (ctx, i) {
                          final p = pays[i];
                          final selected = _indicatif == p['indicatif'];
                          return ListTile(
                            leading: Text(p['flag']!,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(p['nom']!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(p['indicatif']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TAPAColors.textSecond,
                                )),
                            trailing: selected
                                ? const Icon(Icons.check_circle,
                                color: TAPAColors.green, size: 20)
                                : null,
                            onTap: () {
                              setState(() {
                                _indicatif = p['indicatif']!;
                                _codePays = p['code']!;
                                _monnaie = p['monnaie']!;
                                _drapeau = p['flag']!;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
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