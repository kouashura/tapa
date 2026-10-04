// lib/screens/payment/wave_payment_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart'; // ✅ AJOUTÉ

class WavePaymentScreen extends ConsumerStatefulWidget {
  const WavePaymentScreen({super.key});

  @override
  ConsumerState<WavePaymentScreen> createState() => _WavePaymentScreenState();
}

class _WavePaymentScreenState extends ConsumerState<WavePaymentScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;
  bool _agreeTerms = false;
  String _paymentStatus = '';
  String _transactionId = '';
  String _errorMessage = '';

  // ✅ UTILISER .env
  static String get MERCHANT_ID => dotenv.env['WAVE_MERCHANT_ID'] ?? '';
  static String get MERCHANT_SECRET => dotenv.env['WAVE_MERCHANT_SECRET'] ?? '';
  static String get WAVE_API_URL => dotenv.env['WAVE_API_URL'] ?? 'https://api.wave.com/v1/checkout';

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ==========================================================
  // VÉRIFICATION DE LA CONFIGURATION
  // ==========================================================

  bool get _isWaveConfigured {
    return MERCHANT_ID.isNotEmpty && MERCHANT_SECRET.isNotEmpty;
  }

  void _checkWaveConfig() {
    if (!_isWaveConfigured) {
      Logger.error('❌ Configuration Wave manquante dans .env');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Configuration Wave manquante. Contactez le support.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ==========================================================
  // PAIEMENT WAVE
  // ==========================================================

  Future<void> _processWavePayment() async {
    // ✅ VÉRIFICATION DE LA CONFIGURATION
    if (!_isWaveConfigured) {
      _showError('Configuration Wave manquante. Contactez le support.');
      return;
    }

    // Vérifications
    if (_phoneController.text.length < 8) {
      _showError('Veuillez entrer un numéro de téléphone valide');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 500) {
      _showError('Le montant minimum est de 500 FCFA');
      return;
    }

    if (!_agreeTerms) {
      _showError('Veuillez accepter les conditions générales');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _paymentStatus = 'Initialisation du paiement...';
    });

    try {
      // ✅ 1. Créer la session de paiement Wave
      final session = await _createWaveSession(amount);

      if (session == null) {
        throw Exception('Impossible de créer la session de paiement');
      }

      setState(() {
        _paymentStatus = '🔐 Redirection vers Wave...';
        _transactionId = session['id'] ?? '';
      });

      // ✅ 2. Traiter le paiement Wave
      final result = await _processWaveCheckout(session, _phoneController.text);

      if (result['success'] == true) {
        setState(() {
          _paymentStatus = '✅ Paiement réussi !';
          _isLoading = false;
        });

        // ✅ 3. Générer le code d'activation
        final activationCode = _genererCodeActivation();
        await _sauvegarderActivation(activationCode);

        _showSuccessDialog(activationCode);
      } else {
        throw Exception(result['message'] ?? 'Erreur de paiement');
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _paymentStatus = '❌ Échec du paiement';
        _isLoading = false;
      });

      _showError(_errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================================
  // API WAVE
  // ==========================================================

  /// 1. Créer une session de paiement Wave
  Future<Map<String, dynamic>?> _createWaveSession(double amount) async {
    try {
      // ✅ VÉRIFICATION
      if (MERCHANT_ID.isEmpty || MERCHANT_SECRET.isEmpty) {
        Logger.error('❌ Configuration Wave manquante dans .env');
        return null;
      }

      final body = {
        'amount': amount.toString(),
        'currency': 'XOF',
        'merchantId': MERCHANT_ID,
        'merchantSecret': MERCHANT_SECRET,
        'description': 'Accès à vie - TAPA Invest',
        'successUrl': 'https://tapa-budget.com/success',
        'cancelUrl': 'https://tapa-budget.com/cancel',
      };

      Logger.info('📤 Création session Wave: $body');

      final response = await http.post(
        Uri.parse(WAVE_API_URL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      Logger.info('📥 Réponse Wave: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        Logger.error('❌ Erreur Wave: ${response.body}');
        return null;
      }

    } catch (e) {
      Logger.error('❌ Erreur createWaveSession: $e');
      return null;
    }
  }

  /// 2. Traiter le checkout Wave
  Future<Map<String, dynamic>> _processWaveCheckout(
      Map<String, dynamic> session,
      String phoneNumber,
      ) async {
    try {
      // Nettoyer le numéro
      String cleanPhone = phoneNumber
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('+', '');

      if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        cleanPhone = '225${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('225')) {
        cleanPhone = '225$cleanPhone';
      }

      final body = {
        'sessionId': session['id'],
        'phoneNumber': cleanPhone,
        'merchantId': MERCHANT_ID,
        'merchantSecret': MERCHANT_SECRET,
      };

      Logger.info('📤 Processus checkout Wave: $body');

      final response = await http.post(
        Uri.parse(WAVE_API_URL),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      Logger.info('📥 Réponse checkout: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur lors du traitement du paiement',
        };
      }

    } catch (e) {
      Logger.error('❌ Erreur processWaveCheckout: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ==========================================================
  // GÉNÉRATION CODE D'ACTIVATION
  // ==========================================================

  String _genererCodeActivation() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = random.toString().substring(random.toString().length - 8);
    return 'TB-2026-$code';
  }

  Future<void> _sauvegarderActivation(String code) async {
    try {
      // Sauvegarder dans Firestore
      final firebaseService = FirebaseService();
      final userId = firebaseService.getCurrentUserId();

      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'activationCode': code,
          'codeGeneratedAt': FieldValue.serverTimestamp(),
          'codeUsed': false,
          'hasAccesVie': true,
          'licenseKey': code,
          'licenseType': 'premium',
          'licenseActivatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Logger.info('✅ Code d\'activation sauvegardé: $code');
      }
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde code: $e');
    }
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION: Utiliser userMonnaieProvider depuis providers.dart
    final monnaie = ref.watch(userMonnaieProvider);
    final isConfigured = _isWaveConfigured;

    // ✅ VÉRIFIER LA CONFIGURATION AU CHARGEMENT
    _checkWaveConfig();

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Paiement Wave',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        // ✅ INDICATEUR DE CONFIGURATION
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConfigured ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isConfigured ? Icons.check_circle : Icons.warning,
                  size: 12,
                  color: isConfigured ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  isConfigured ? 'Wave OK' : 'Config manquante',
                  style: TextStyle(
                    fontSize: 9,
                    color: isConfigured ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================
            // EN-TÊTE WAVE
            // ==========================================================
            _buildWaveHeader(),

            const SizedBox(height: 24),

            // ==========================================================
            // MONTANT
            // ==========================================================
            _buildAmountField(monnaie),

            const SizedBox(height: 16),

            // ==========================================================
            // NUMÉRO DE TÉLÉPHONE
            // ==========================================================
            _buildPhoneField(),

            const SizedBox(height: 24),

            // ==========================================================
            // RÉSUMÉ
            // ==========================================================
            _buildPaymentSummary(monnaie),

            const SizedBox(height: 24),

            // ==========================================================
            // CONDITIONS
            // ==========================================================
            _buildTermsCheckbox(),

            const SizedBox(height: 16),

            // ==========================================================
            // BOUTON DE PAIEMENT
            // ==========================================================
            _buildPaymentButton(monnaie),

            const SizedBox(height: 16),

            // ==========================================================
            // STATUT
            // ==========================================================
            _buildStatusWidget(),

            const SizedBox(height: 16),

            // ==========================================================
            // SÉCURITÉ
            // ==========================================================
            _buildSecurityInfo(),

            // ==========================================================
            // AVERTISSEMENT CONFIGURATION
            // ==========================================================
            if (!isConfigured)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Configuration Wave manquante.\n'
                            'Veuillez vérifier votre fichier .env',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WIDGETS
  // ==========================================================

  Widget _buildWaveHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DC8F2), Color(0xFF0D8CAE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DC8F2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.waves,
              color: Color(0xFF1DC8F2),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paiement Wave',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID Marchand: ${_isWaveConfigured ? MERCHANT_ID : 'Non configuré'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '🔒 Sécurisé',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(String monnaie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading && _isWaveConfigured,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  monnaie,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.gold,
                  ),
                ),
              ),
              hintText: '5000',
              hintStyle: const TextStyle(
                color: TAPAColors.textHint,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: TAPAColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro Wave',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_isLoading && _isWaveConfigured,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: TAPAColors.textHint,
                ),
              ),
              hintText: 'Ex: 01 60 25 41 02',
              hintStyle: const TextStyle(
                color: TAPAColors.textHint,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: TAPAColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: _phoneController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: TAPAColors.green),
                onPressed: () {},
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez votre numéro Wave pour recevoir la demande de paiement',
          style: TextStyle(
            fontSize: 11,
            color: TAPAColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(String monnaie) {
    final amount = double.tryParse(_amountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          _summaryRow('Article', 'Accès à vie TAPA Invest'),
          _summaryRow('Méthode', 'Wave'),
          _summaryRow('Téléphone', _phoneController.text.isEmpty ? 'Non renseigné' : _phoneController.text),
          const Divider(height: 16),
          _summaryRow(
            'Total à payer',
            '${amount.toStringAsFixed(0)} $monnaie',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? TAPAColors.navy : TAPAColors.textSecond,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? TAPAColors.gold : TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeTerms,
          onChanged: _isLoading || !_isWaveConfigured
              ? null
              : (value) {
            setState(() => _agreeTerms = value ?? false);
          },
          activeColor: TAPAColors.gold,
          checkColor: TAPAColors.navy,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _agreeTerms = !_agreeTerms);
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: TAPAColors.textSecond,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'conditions générales',
                    style: const TextStyle(
                      color: TAPAColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: const TextStyle(
                      color: TAPAColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(String monnaie) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final bool canPay = _phoneController.text.length >= 8 &&
        amount >= 500 &&
        _agreeTerms &&
        !_isLoading &&
        _isWaveConfigured;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canPay ? _processWavePayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canPay ? const Color(0xFF1DC8F2) : Colors.grey.shade300,
          foregroundColor: canPay ? Colors.white : Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canPay ? 4 : 0,
          shadowColor: canPay ? const Color(0xFF1DC8F2).withOpacity(0.3) : Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.waves, size: 20),
            const SizedBox(width: 12),
            Text(
              _isWaveConfigured
                  ? 'Payer ${amount.toStringAsFixed(0)} $monnaie'
                  : 'Configuration manquante',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (_paymentStatus.isEmpty && _errorMessage.isEmpty) {
      return const SizedBox();
    }

    final bool isError = _errorMessage.isNotEmpty;
    final bool isSuccess = _paymentStatus.contains('✅');
    final Color statusColor = isError
        ? TAPAColors.red
        : isSuccess
        ? TAPAColors.green
        : TAPAColors.gold;

    final Color bgColor = isError
        ? TAPAColors.redLight
        : isSuccess
        ? TAPAColors.greenLight
        : TAPAColors.goldLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : isSuccess
                ? Icons.check_circle_outline
                : Icons.info_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isError ? _errorMessage : _paymentStatus,
              style: TextStyle(
                fontSize: 13,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TAPAColors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: TAPAColors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paiement sécurisé Wave',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.green,
                  ),
                ),
                Text(
                  'Transaction cryptée · Protection des données',
                  style: TextStyle(
                    fontSize: 11,
                    color: TAPAColors.green.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _paymentStatus = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: TAPAColors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String activationCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TAPAColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: TAPAColors.green,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 Paiement réussi !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre accès à vie est activé',
              style: TextStyle(
                fontSize: 14,
                color: TAPAColors.textSecond,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TAPAColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.gold, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔑 CODE D\'ACTIVATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    activationCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: TAPAColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.gold,
                  foregroundColor: TAPAColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retourner au profil',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}