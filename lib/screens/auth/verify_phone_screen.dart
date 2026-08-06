import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../core/utils/logger.dart';  // ← Changé de '../../../utils/logger.dart'


class VerifyPhoneScreen extends ConsumerStatefulWidget {
  final String prenom;
  final String telephone;
  final String indicatif;
  final String codePays;
  final String monnaie;

  const VerifyPhoneScreen({
    super.key,
    required this.prenom,
    required this.telephone,
    this.indicatif = '+225',
    this.codePays = 'CI',
    this.monnaie = 'FCFA',
  });

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  int _countdown = 60;
  bool _canResend = false;
  String _errorMessage = '';

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // ✅ Future(() {...}) planifie l'exécution sur une nouvelle itération de la
    // boucle d'événements, complètement en dehors du cycle de build/frame en
    // cours. Contrairement à addPostFrameCallback (qui s'exécute encore à
    // l'intérieur de la même frame et peut donc déclencher l'erreur Riverpod
    // "Tried to modify a provider while the widget tree was building"), ceci
    // garantit que le premier build est totalement terminé avant de modifier
    // le provider et d'utiliser le BuildContext (ScaffoldMessenger, etc.).
    Future(() {
      if (mounted) {
        _sendCode();
        _startCountdown();
      }
    });
  }

  void _sendCode() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authNotifier = ref.read(authStateProvider.notifier);
    authNotifier.sendVerificationCode(widget.telephone);
    Logger.info('📱 Code envoyé à ${widget.telephone}');

    // ✅ ScaffoldMessenger.of(context) est maintenant sûr car on est dans un callback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📱 Code envoyé à ${widget.telephone}'),
        backgroundColor: TAPAColors.gold,
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() => _isLoading = false);
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final allFilled = _codeControllers.every((c) => c.text.isNotEmpty);
    if (allFilled) {
      final code = _codeControllers.map((c) => c.text).join();
      _verifierCode(code);
    }
  }

  Future<void> _verifierCode(String code) async {
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authNotifier = ref.read(authStateProvider.notifier);

    try {
      await authNotifier.verifyCode(code);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && ref.read(isAuthenticatedProvider)) {
        await authNotifier.createUserProfile(
          prenom: widget.prenom,
          telephone: widget.telephone,
          indicatif: widget.indicatif,
          codePays: widget.codePays,
          monnaie: widget.monnaie,
        );

        if (mounted) {
          final user = ref.read(currentUserProvider);
          Logger.success('✅ Compte créé avec succès pour ${user?.prenom}');

          if (user?.onboardingVu ?? false) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Code invalide. Réessayez.';
        });
        for (final controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes.first.requestFocus();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
      });
      Logger.error('❌ Erreur vérification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      appBar: AppBar(
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        title: const Text('Vérification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.go('/inscription'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: isSmall ? 70 : 80,
                height: isSmall ? 70 : 80,
                decoration: BoxDecoration(
                  color: TAPAColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: TAPAColors.gold,
                  size: isSmall ? 32 : 40,
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                'Code de vérification',
                style: TextStyle(
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                'Nous avons envoyé un code SMS à',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isSmall ? 12 : 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: TAPAColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.telephone,
                  style: TextStyle(
                    color: TAPAColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Code fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: isSmall ? 36 : 48,
                    height: isSmall ? 50 : 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      style: TextStyle(
                        fontSize: isSmall ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.white,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: TAPAColors.gold, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: TAPAColors.red),
                        ),
                      ),
                      onChanged: (value) => _onCodeChanged(value, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Message d'erreur
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: TAPAColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TAPAColors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: TAPAColors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: TAPAColors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (authState.error != null && authState.error!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: TAPAColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TAPAColors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: TAPAColors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: TAPAColors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Loading ou bouton renvoyer
              if (_isLoading || authState.isLoading)
                const CircularProgressIndicator(color: TAPAColors.gold)
              else if (_canResend)
                TextButton(
                  onPressed: () {
                    _sendCode();
                    _startCountdown();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: TAPAColors.gold.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: TAPAColors.gold),
                    ),
                  ),
                  child: const Text(
                    'Renvoyer le code',
                    style: TextStyle(
                      color: TAPAColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Renvoyer dans $_countdown s',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 24),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un SMS de vérification a été envoyé sur votre numéro',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: isSmall ? 10 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Bouton de debug (uniquement en développement)
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () {
                      // Remplir automatiquement avec le code de test
                      final testCode = '123456';
                      for (int i = 0; i < testCode.length; i++) {
                        _codeControllers[i].text = testCode[i];
                      }
                      _verifierCode(testCode);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: TAPAColors.gold.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '🔧 Mode Debug - Code 123456',
                      style: TextStyle(color: TAPAColors.gold),
                    ),
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