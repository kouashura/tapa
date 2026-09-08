// lib/screens/payment/payment_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../services/firebase_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedProvider = 'wave';
  String _phoneNumber = '';
  bool _isLoading = false;
  bool _agreeTerms = false;
  String _generatedCode = '';

  final TextEditingController _phoneController = TextEditingController();

  final List<PaymentProvider> _providers = [
    PaymentProvider(
      id: 'wave',
      name: 'Wave',
      logoAsset: 'assets/logos/wave.png',
      color: const Color(0xFF1DC8F2),
      bgColor: const Color(0xFFE8F9FE),
      minAmount: 500,
      maxAmount: 1000000,
    ),
    PaymentProvider(
      id: 'orange_money',
      name: 'Orange Money',
      logoAsset: 'assets/logos/orange_money.png',
      color: const Color(0xFFFF7900),
      bgColor: const Color(0xFFFFF0E0),
      minAmount: 500,
      maxAmount: 500000,
    ),
    PaymentProvider(
      id: 'mtn_money',
      name: 'MTN Money',
      logoAsset: 'assets/logos/mtn_money.png',
      color: const Color(0xFFFFCC00),
      bgColor: const Color(0xFFFFF8E0),
      minAmount: 500,
      maxAmount: 1000000,
    ),
    PaymentProvider(
      id: 'moov_money',
      name: 'Moov Money',
      logoAsset: 'assets/logos/moov_money.png',
      color: const Color(0xFF7B1FA2),
      bgColor: const Color(0xFFF3E5F5),
      minAmount: 500,
      maxAmount: 500000,
    ),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ==========================================================
  // GÉNÉRATION DU CODE D'ACTIVATION
  // ==========================================================
  String _genererCodeActivation() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final code = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return 'TB-2026-$code';
  }

  // ==========================================================
  // SAUVEGARDE DU CODE D'ACTIVATION
  // ==========================================================
  Future<void> _sauvegarderCodeActivation(String code) async {
    try {
      final firebaseService = FirebaseService();
      final userId = firebaseService.getCurrentUserId();

      if (userId != null) {
        // Sauvegarder dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'activationCode': code,
          'codeGeneratedAt': FieldValue.serverTimestamp(),
          'codeUsed': false,
          'hasAccesVie': true,
          'licenseKey': code,
          'licenseType': 'premium',
          'licenseActivatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Sauvegarder aussi en local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('activation_code', code);
        await prefs.setBool('acces_vie', true);
        await prefs.setString('cle_activee', code);

        Logger.info('✅ Code d\'activation sauvegardé: $code');
      }
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final amount = 5000;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Paiement',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(monnaie, amount),
            const SizedBox(height: 24),
            const Text(
              'Choisissez votre opérateur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez le service de paiement mobile',
              style: TextStyle(
                fontSize: 13,
                color: TAPAColors.textSecond,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final provider = _providers[index];
                final isSelected = _selectedProvider == provider.id;
                return _buildProviderCard(provider, isSelected);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Numéro de téléphone',
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
                enabled: !_isLoading,
                onChanged: (value) {
                  setState(() => _phoneNumber = value);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: TAPAColors.textHint,
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
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le numéro utilisé pour le paiement mobile',
              style: TextStyle(
                fontSize: 11,
                color: TAPAColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentSummary(monnaie, amount),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  onChanged: _isLoading
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
            ),
            const SizedBox(height: 16),
            _buildPaymentButton(monnaie, amount),
            const SizedBox(height: 16),
            _buildSecurityInfo(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WIDGETS
  // ==========================================================

  Widget _buildOrderSummary(String monnaie, int amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TAPAColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: TAPAColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accès à vie - TAPA Budget',
                  style: TextStyle(
                    color: TAPAColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paiement unique · Toutes les mises à jour incluses',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amount $monnaie',
                style: const TextStyle(
                  color: TAPAColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'à payer',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(PaymentProvider provider, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? provider.color.withOpacity(0.10) : TAPAColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? provider.color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: provider.color.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    provider.logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: provider.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        provider.initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: provider.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? provider.color : TAPAColors.navy,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: provider.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(String monnaie, int amount) {
    final selectedProvider = _providers.firstWhere(
          (p) => p.id == _selectedProvider,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          _summaryRow('Article', 'Accès à vie TAPA Budget'),
          _summaryRow('Opérateur', selectedProvider.name),
          _summaryRow('Numéro', _phoneNumber.isEmpty ? 'Non renseigné' : _phoneNumber),
          const Divider(height: 16),
          _summaryRow(
            'Total',
            '$amount $monnaie',
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

  Widget _buildPaymentButton(String monnaie, int amount) {
    final bool canPay = _phoneNumber.length >= 8 && _agreeTerms && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canPay ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canPay ? TAPAColors.gold : Colors.grey.shade300,
          foregroundColor: canPay ? TAPAColors.navy : Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canPay ? 4 : 0,
          shadowColor: canPay ? TAPAColors.gold.withOpacity(0.3) : Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: TAPAColors.navy,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 20),
            const SizedBox(width: 12),
            Text(
              'Payer $amount $monnaie',
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
                  'Paiement sécurisé',
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
  // LOGIQUE DE PAIEMENT AVEC GÉNÉRATION DE CODE
  // ==========================================================

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final selectedProvider = _providers.firstWhere(
            (p) => p.id == _selectedProvider,
      );

      Logger.info('💳 Paiement initié:');
      Logger.info('   - Opérateur: ${selectedProvider.name}');
      Logger.info('   - Téléphone: $_phoneNumber');
      Logger.info('   - Montant: 5000 FCFA');

      // Simuler l'appel API
      await Future.delayed(const Duration(seconds: 2));

      // ✅ Générer le code d'activation
      final activationCode = _genererCodeActivation();
      setState(() => _generatedCode = activationCode);

      // ✅ Sauvegarder le code
      await _sauvegarderCodeActivation(activationCode);

      Logger.info('🎫 Code d\'activation généré: $activationCode');

      // ✅ Paiement réussi
      if (mounted) {
        final monnaie = ref.read(userMonnaieProvider);
        _showSuccessDialog(selectedProvider, activationCode, 5000, monnaie);
      }
    } catch (e) {
      Logger.error('❌ Erreur paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du paiement: ${e.toString()}'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(
      PaymentProvider provider,
      String activationCode,
      int amount,
      String monnaie,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // Marge d'insertion réduite pour laisser plus de place au contenu
        // sur les petits écrans / quand le clavier est encore visible.
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        // ✅ Le contenu peut désormais défiler au lieu de déborder
        // (Column) quand il ne tient pas dans la hauteur disponible.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TAPAColors.greenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: TAPAColors.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '🎉 Paiement réussi !',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Vous avez payé $amount $monnaie via ${provider.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: TAPAColors.textSecond,
                ),
              ),
              const SizedBox(height: 14),
              // ✅ AFFICHAGE DU CODE D'ACTIVATION
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
                      '🔑 VOTRE CODE D\'ACTIVATION',
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: TAPAColors.navy,
                          onPressed: () async {
                            // ✅ Copie réelle dans le presse-papiers
                            await Clipboard.setData(
                              ClipboardData(text: activationCode),
                            );
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Code copié !'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copier',
                          style: TextStyle(
                            fontSize: 11,
                            color: TAPAColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ce code est automatiquement enregistré dans votre compte.\nVous pouvez aussi le copier pour le garder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: TAPAColors.textHint,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
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
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/activation');
                },
                child: const Text(
                  'Voir mes clés d\'activation',
                  style: TextStyle(
                    fontSize: 12,
                    color: TAPAColors.textSecond,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// MODÈLE
// ==========================================================

class PaymentProvider {
  final String id;
  final String name;
  final String logoAsset;
  final Color color;
  final Color bgColor;
  final int minAmount;
  final int maxAmount;

  const PaymentProvider({
    required this.id,
    required this.name,
    required this.logoAsset,
    required this.color,
    required this.bgColor,
    required this.minAmount,
    required this.maxAmount,
  });

  String get initials {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}