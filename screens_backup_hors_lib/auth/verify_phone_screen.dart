// lib/screens/auth/verify_phone_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../core/utils/logger.dart';

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
  // ============================================
  // CONTROLEURS ET FOCUS
  // ============================================

  final List<TextEditingController> _codeControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // ============================================
  // ÉTATS
  // ============================================

  bool _isLoading = false;
  int _countdown = 60;
  bool _canResend = false;
  String _errorMessage = '';
  bool _codeExpired = false;
  int _attempts = 0;
  Timer? _codeTimeoutTimer;
  Timer? _countdownTimer;
  bool _emailSent = false;
  bool _isVerified = false;

  // ============================================
  // GETTERS
  // ============================================

  bool get canResend => _canResend || _codeExpired;
  bool get isCodeComplete => _codeControllers.every((c) => c.text.isNotEmpty);
  String get code => _codeControllers.map((c) => c.text).join();
  bool get hasMaxAttempts => _attempts >= 5;

  // ============================================
  // CYCLE DE VIE
  // ============================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sendVerificationEmail();
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _codeTimeoutTimer?.cancel();
    _countdownTimer?.cancel();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ============================================
  // CRÉATION DU PROFIL UTILISATEUR
  // ============================================

  Future<void> _createUserProfile() async {
    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      await authNotifier.createUserProfile(
        prenom: widget.prenom,
        telephone: widget.telephone,
        indicatif: widget.indicatif,
        codePays: widget.codePays,
        monnaie: widget.monnaie,
      );

      if (!mounted) return;

      final userData = ref.read(currentUserProvider);
      Logger.success('✅ Compte créé avec succès pour ${userData?.prenom}');

      if (userData?.onboardingVu ?? false) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      Logger.error('❌ Erreur création profil: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  // ============================================
  // ENVOI DU CODE PAR EMAIL (Brevo via auth_provider.dart)
  // ============================================

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _codeExpired = false;
      _attempts = 0;
      _clearCodeFields();
      _emailSent = false;
      _isVerified = false;
    });

    _codeTimeoutTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      // ℹ️ widget.telephone contient en réalité l'adresse email saisie
      // à l'inscription (nommage hérité de l'ancien flow par SMS).
      await ref
          .read(authStateProvider.notifier)
          .envoyerCodeVerificationEmail(widget.telephone);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      _startCodeTimeout();

      _showSnackBar(
        '📧 Code envoyé à ${widget.telephone}',
        isSuccess: true,
      );
    } catch (e) {
      Logger.error('❌ Erreur envoi code email: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        });
        _showSnackBar('❌ Erreur envoi email', isError: true);
      }
    }
  }

  // ============================================
  // TIMERS
  // ============================================

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _startCodeTimeout() {
    _codeExpired = false;
    _codeTimeoutTimer?.cancel();
    // ⏰ Doit rester cohérent avec la durée d'expiration côté serveur
    // (15 minutes dans envoyerCodeVerificationEmail, auth_provider.dart).
    _codeTimeoutTimer = Timer(const Duration(minutes: 15), () {
      if (mounted) {
        setState(() {
          _codeExpired = true;
          _errorMessage = '⏰ Le code a expiré. Veuillez renvoyer un nouveau code.';
        });
        _showSnackBar('⏰ Le code a expiré', isError: true);
      }
    });
  }

  // ============================================
  // GESTION DU CODE
  // ============================================

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_errorMessage.isNotEmpty) {
      setState(() => _errorMessage = '');
    }

    if (isCodeComplete) {
      _verifierCode(code);
    }
  }

  void _clearCodeFields() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  // ============================================
  // VÉRIFICATION DU CODE (Brevo via auth_provider.dart)
  // ============================================

  Future<void> _verifierCode(String code) async {
    // ✅ VALIDATION 1: Le code doit faire 6 chiffres
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Le code doit contenir 6 chiffres.';
        _isLoading = false;
      });
      return;
    }

    // ✅ VALIDATION 2: Le code n'est pas expiré
    if (_codeExpired) {
      setState(() {
        _errorMessage = '⏰ Le code a expiré. Veuillez renvoyer un nouveau code.';
        _isLoading = false;
      });
      return;
    }

    // ✅ VALIDATION 3: Pas trop de tentatives
    if (hasMaxAttempts) {
      setState(() {
        _errorMessage = '❌ Trop de tentatives. Veuillez renvoyer un nouveau code.';
        _isLoading = false;
      });
      return;
    }

    Logger.info('📧 Vérification - Email: ${widget.telephone}');
    Logger.info('📧 Tentative: ${_attempts + 1}/5');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _attempts++;
    });

    try {
      final isValid = await ref
          .read(authStateProvider.notifier)
          .verifierCodeEmail(widget.telephone, code);

      if (!mounted) return;

      if (isValid) {
        // ✅ SUCCÈS
        _codeTimeoutTimer?.cancel();
        _countdownTimer?.cancel();

        setState(() {
          _isLoading = false;
          _isVerified = true;
        });

        _showSnackBar('✅ Code vérifié avec succès !', isSuccess: true);
        await _createUserProfile();
      } else {
        // ❌ CODE INVALIDE
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ Code invalide. Vérifiez votre email et réessayez. ($_attempts/5)';
        });

        _clearCodeFields();

        if (hasMaxAttempts) {
          _showSnackBar('❌ Trop de tentatives. Renvoyez un nouveau code.', isError: true);
        } else {
          _showSnackBar('❌ Code invalide. Réessayez.', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
      });
      Logger.error('❌ Erreur vérification: $e');

      _clearCodeFields();
      _showSnackBar('❌ Erreur: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  // ============================================
  // SNACKBAR
  // ============================================

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? TAPAColors.green : (isError ? TAPAColors.red : TAPAColors.gold),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    final showExpired = _codeExpired && !_isLoading;
    final bool canResendNow = canResend;

    // ✅ Écran de succès
    if (_isVerified) {
      return Scaffold(
        backgroundColor: TAPAColors.navy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: TAPAColors.green,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                '✅ Vérification réussie !',
                style: TextStyle(
                  color: TAPAColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenue ${widget.prenom}',
                style: TextStyle(
                  color: TAPAColors.gold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Écran principal
    return Scaffold(
      backgroundColor: TAPAColors.navy,
      appBar: AppBar(
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        title: const Text('Vérification par Email'),
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
                  Icons.email_outlined,
                  color: TAPAColors.gold,
                  size: isSmall ? 32 : 40,
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                _emailSent ? 'Code de vérification' : 'Vérification par Email',
                style: TextStyle(
                  fontSize: isSmall ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Message avec email
              Text(
                _emailSent
                    ? 'Nous avons envoyé un code à'
                    : 'Nous allons envoyer un code à',
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
              const SizedBox(height: 16),

              // Instructions
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: TAPAColors.gold.withOpacity(0.2),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      '📧 Comment vérifier votre compte ?',
                      style: TextStyle(
                        color: TAPAColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1️⃣ Ouvrez votre boîte mail\n'
                          '2️⃣ Récupérez le code à 6 chiffres\n'
                          '3️⃣ Entrez-le ci-dessous\n'
                          '4️⃣ Votre compte sera automatiquement vérifié',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Entrer le code manuellement
              const Text(
                'Entrez le code à 6 chiffres',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Champs du code
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
                      enabled: !_isLoading && !_codeExpired && !hasMaxAttempts && _emailSent,
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: (!_emailSent || _codeExpired || hasMaxAttempts)
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white10,
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

              // Indicateur d'expiration
              if (showExpired)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏰ Le code a expiré. Cliquez sur "Renvoyer le code".',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Indicateur de tentatives
              if (_attempts > 0 && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tentative $_attempts/5',
                    style: TextStyle(
                      color: _attempts >= 4 ? Colors.orange : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),

              // État d'envoi de l'email
              if (!_emailSent && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: TAPAColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TAPAColors.gold.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: TAPAColors.gold, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏳ Envoi du code en cours...',
                          style: TextStyle(color: TAPAColors.gold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_emailSent && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: TAPAColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TAPAColors.green.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: TAPAColors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Code envoyé ! Vérifiez votre boîte mail',
                          style: TextStyle(color: TAPAColors.green, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Bouton renvoyer
              if (_isLoading || authState.isLoading)
                const CircularProgressIndicator(color: TAPAColors.gold)
              else if (canResendNow)
                TextButton(
                  onPressed: _isLoading ? null : () {
                    _sendVerificationEmail();
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
                  child: Text(
                    _codeExpired ? '🔄 Renvoyer le code' : 'Renvoyer le code',
                    style: const TextStyle(
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

              // Information
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.white54,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📧 Un code de vérification a été envoyé sur votre email',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Astuce debug : le code réel est visible dans les logs
              // (Logger.success dans envoyerCodeVerificationEmail) et
              // dans la console Firestore (collection email_verifications),
              // il n'est plus généré côté écran donc on ne peut pas
              // l'afficher ici directement.
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    '🔧 Debug: consultez les logs ou Firestore '
                        '(email_verifications/${widget.telephone}) pour voir le code.',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
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