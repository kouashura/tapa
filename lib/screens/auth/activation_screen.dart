// lib/screens/auth/activation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';  // ✅ CHEMIN CORRIGÉ
import '../../presentation/providers/auth/auth_provider.dart';  // ✅ CHEMIN CORRIGÉ
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../services/firebase_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/models.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final TextEditingController _cleCtrl = TextEditingController();
  final TextEditingController _numeroCtrl = TextEditingController();
  bool _loading = false;
  bool _paiementLoading = false;
  String? _error;
  bool _accesActive = false;
  String _selectedPaymentMethod = '';

  // ✅ UNE SEULE CLÉ ROOT (pour le développeur) - DEPUIS .env
  static String get _rootDevKey => dotenv.env['ROOT_DEV_KEY'] ?? '';

  static const String _numeroWhatsApp = '2250160254102';
  static const int _montant = 5000;

  @override
  void initState() {
    super.initState();
    _verifierAcces();
    _verifierConfiguration();
  }

  @override
  void dispose() {
    _cleCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  // ✅ VÉRIFIER LA CONFIGURATION .env
  void _verifierConfiguration() {
    if (_rootDevKey.isEmpty) {
      Logger.warning('⚠️ ROOT_DEV_KEY non définie dans .env');
    } else {
      Logger.info('✅ ROOT_DEV_KEY chargée avec succès');
    }
  }

  Future<void> _verifierAcces() async {
    final hasAcces = ref.read(hasAccessVieProvider);
    setState(() {
      _accesActive = hasAcces;
    });
  }

  // ============================================
  // OUVRIR WHATSAPP
  // ============================================

  Future<void> _ouvrirWhatsApp({String message = ''}) async {
    try {
      final encodedMessage = Uri.encodeComponent(message);

      final urls = [
        'https://wa.me/$_numeroWhatsApp?text=$encodedMessage',
        'https://api.whatsapp.com/send?phone=$_numeroWhatsApp&text=$encodedMessage',
        'whatsapp://send?phone=$_numeroWhatsApp&text=$encodedMessage',
      ];

      for (final url in urls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (_) {}
      }

      _showCoordonneesWhatsApp();

    } catch (e) {
      _showCoordonneesWhatsApp();
      Logger.error('❌ Erreur WhatsApp: $e');
    }
  }

  // ============================================
  // AFFICHER LES COORDONNÉES WHATSAPP
  // ============================================

  void _showCoordonneesWhatsApp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TAPAColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Icon(Icons.chat, size: 48, color: Color(0xFF25D366)),
            const SizedBox(height: 12),
            const Text(
              'Contactez-nous sur WhatsApp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    '📱 WhatsApp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF25D366),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '+225 01 60 25 41 02',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Message à envoyer :',
                    style: TextStyle(
                      fontSize: 12,
                      color: TAPAColors.textSecond,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: TAPAColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      'Bonjour TAPA Budget ! Je souhaite obtenir l\'accès à vie.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TAPAColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: '+2250160254102'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Numéro copié !'),
                          backgroundColor: TAPAColors.gold,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copier le numéro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.navy,
                      foregroundColor: TAPAColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ouvrirWhatsApp(
                      message: 'Bonjour TAPA Budget ! Je souhaite obtenir l\'accès à vie.',
                    ),
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text('Ouvrir WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Fermer',
                style: TextStyle(color: TAPAColors.textSecond),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DEMANDER UNE CLÉ PAR WHATSAPP
  // ============================================

  void _demanderCleWhatsApp() {
    final message = 'Bonjour TAPA Budget ! 👋\n\n'
        'Je souhaite obtenir l\'accès à vie de TAPA Budget à ${_montant.toString()} FCFA.\n'
        'Pouvez-vous m\'envoyer ma clé d\'accès ?\n\n'
        '📱 Mon numéro: ${_numeroCtrl.text.isNotEmpty ? _numeroCtrl.text : "__________________"}\n'
        '📅 Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    _ouvrirWhatsApp(message: message);
  }

  // ============================================
  // SIMULER UN PAIEMENT
  // ============================================

  void _simulerPaiement(String method) {
    final numero = _numeroCtrl.text.trim();

    if (numero.isEmpty || numero.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() {
      _paiementLoading = true;
      _selectedPaymentMethod = method;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        _paiementLoading = false;
      });

      final cleGeneree = _genererCle(numero, method);
      _showPaiementSuccess(
        method: method,
        cle: cleGeneree,
        numero: numero,
      );
    });
  }

  // ============================================
  // GÉNÉRER UNE CLÉ
  // ============================================

  String _genererCle(String numero, String method) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = (numero.hashCode + timestamp).abs().toString().substring(0, 8);
    return 'TB-2026-$hash';
  }

  // ============================================
  // AFFICHER LE SUCCÈS DU PAIEMENT
  // ============================================

  void _showPaiementSuccess({
    required String method,
    required String cle,
    required String numero,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TAPAColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              '✅ Paiement validé !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paiement de ${_montant.toString()} FCFA via $method',
              style: const TextStyle(
                fontSize: 14,
                color: TAPAColors.textSecond,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TAPAColors.goldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔑 Votre clé d\'accès',
                    style: TextStyle(
                      fontSize: 12,
                      color: TAPAColors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    cle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _cleCtrl.text = cle;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 Clé copiée !'),
                                backgroundColor: TAPAColors.gold,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TAPAColors.navy,
                            foregroundColor: TAPAColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _cleCtrl.text = cle;
                            _activerAvecCle(cle);
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Activer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                label: const Text('Fermer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIVER AVEC UNE CLÉ - AVEC SUPPORT ROOT
  // ============================================

  Future<void> _activerAvecCle(String cle) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firebaseService = FirebaseService();

      // ✅ VÉRIFICATION UNIQUE - ROOT KEY DEPUIS .env
      final isRoot = cle == _rootDevKey && _rootDevKey.isNotEmpty;

      // ✅ VÉRIFIER LA CLÉ (ROOT OU STANDARD)
      final cleValide = firebaseService.verifierCle(cle) || isRoot;

      if (!cleValide) {
        setState(() {
          _error = 'Clé invalide. Format : TB-2026-XXXXXXXX';
          _loading = false;
        });
        return;
      }

      if (isRoot) {
        Logger.info('👑 Accès Root activé avec la clé: $cle');
      } else {
        Logger.info('✅ Accès premium activé avec la clé: $cle');
      }

      // ✅ ACTIVER L'ACCÈS
      await firebaseService.activerAccesVie(cle);

      // ✅ METTRE À JOUR L'ÉTAT
      final authNotifier = ref.read(authStateProvider.notifier);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser != null) {
        final updatedUser = AppUser(
          id: currentUser.id,
          phoneNumber: currentUser.phoneNumber,
          prenom: currentUser.prenom,
          monnaie: currentUser.monnaie,
          codePays: currentUser.codePays,
          hasAccessVie: true,
          onboardingVu: currentUser.onboardingVu,
          notificationsActivees: currentUser.notificationsActivees,
          createdAt: currentUser.createdAt,
          dernierActive: DateTime.now(),
        );
        await authNotifier.updateUser(updatedUser);
      }

      setState(() {
        _accesActive = true;
        _loading = false;
      });

      if (mounted) {
        final message = isRoot
            ? '👑 Accès Root activé avec succès !'
            : '✅ Accès activé avec succès !';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isRoot ? TAPAColors.purple : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: ${e.toString().replaceAll('Exception: ', '')}';
        _loading = false;
      });
      Logger.error('❌ Erreur activation: $e');
    }
  }

  // ============================================
  // ACTIVER AVEC LE CHAMP DE SAISIE
  // ============================================

  Future<void> _activer() async {
    final cle = _cleCtrl.text.trim().toUpperCase();
    await _activerAvecCle(cle);
  }

  // ============================================
  // AFFICHER LES OPTIONS DE PAIEMENT
  // ============================================

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TAPAColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text(
                'Choisissez votre moyen de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paiement unique de ${_montant.toString()} FCFA',
                style: const TextStyle(
                  fontSize: 13,
                  color: TAPAColors.textSecond,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _numeroCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Votre numéro de téléphone *',
                  hintText: 'Ex: 05 04 77 57 57',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Wave
              _paymentOption(
                icon: Icons.waves,
                color: const Color(0xFF1DC8F2),
                title: 'Wave',
                subtitle: 'Paiement mobile',
                onTap: () {
                  if (_numeroCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Entrez votre numéro de téléphone'),
                        backgroundColor: TAPAColors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _simulerPaiement('Wave');
                },
              ),
              const SizedBox(height: 12),

              // Orange Money
              _paymentOption(
                icon: Icons.wifi_tethering,
                color: const Color(0xFFFF7900),
                title: 'Orange Money',
                subtitle: 'Paiement mobile',
                onTap: () {
                  if (_numeroCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Entrez votre numéro de téléphone'),
                        backgroundColor: TAPAColors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _simulerPaiement('Orange Money');
                },
              ),
              const SizedBox(height: 12),

              // MTN MoMo
              _paymentOption(
                icon: Icons.sim_card,
                color: const Color(0xFFFFCC00),
                title: 'MTN MoMo',
                subtitle: 'Paiement mobile',
                onTap: () {
                  if (_numeroCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Entrez votre numéro de téléphone'),
                        backgroundColor: TAPAColors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _simulerPaiement('MTN MoMo');
                },
              ),
              const SizedBox(height: 12),

              // WhatsApp - Demander une clé
              _paymentOption(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                title: 'WhatsApp',
                subtitle: 'Demander une clé',
                onTap: () {
                  Navigator.pop(ctx);
                  _demanderCleWhatsApp();
                },
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: TAPAColors.textSecond),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGET OPTION DE PAIEMENT
  // ============================================

  Widget _paymentOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TAPAColors.textSecond,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: TAPAColors.textHint),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BOUTON POUR CLÉ ROOT (DÉVELOPPEUR)
  // ============================================

  Widget _buildRootButton() {
    final hasRootKey = _rootDevKey.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TAPAColors.purple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasRootKey ? TAPAColors.purple.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextButton.icon(
          onPressed: hasRootKey
              ? () {
            if (_rootDevKey.isNotEmpty) {
              _cleCtrl.text = _rootDevKey;
              _activerAvecCle(_rootDevKey);
            }
          }
              : null,
          icon: Icon(
            hasRootKey ? Icons.admin_panel_settings : Icons.lock_outline,
            color: hasRootKey ? TAPAColors.purple : Colors.grey,
            size: 20,
          ),
          label: Text(
            hasRootKey
                ? '🔑 Mode Développeur (Accès Root)'
                : '🔒 Clé Root non configurée (voir .env)',
            style: TextStyle(
              color: hasRootKey ? TAPAColors.purple : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final paddingSize = isSmall ? 16.0 : (isTablet ? 32.0 : 20.0);
    final spacingSize = isSmall ? 12.0 : (isTablet ? 24.0 : 16.0);
    final titleSize = isSmall ? 18.0 : (isTablet ? 28.0 : 22.0);
    final hasRootKey = _rootDevKey.isNotEmpty;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Activation'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        // ✅ INDICATEUR DE CONFIGURATION ROOT
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasRootKey ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  hasRootKey ? Icons.check_circle : Icons.warning,
                  size: 12,
                  color: hasRootKey ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  hasRootKey ? 'Root OK' : 'Root manquante',
                  style: TextStyle(
                    fontSize: 9,
                    color: hasRootKey ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _accesActive
          ? _buildActivatedState()
          : _buildActivationForm(isSmall, isTablet, paddingSize, spacingSize, titleSize),
    );
  }

  Widget _buildActivatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ Accès activé !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous avez accès à toutes les fonctionnalités de TAPA Budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: TAPAColors.textSecond,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à l\'accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.gold,
                foregroundColor: TAPAColors.navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationForm(
      bool isSmall,
      bool isTablet,
      double paddingSize,
      double spacingSize,
      double titleSize,
      ) {
    final hasRootKey = _rootDevKey.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(paddingSize),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Header
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: TAPAColors.goldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_outline,
              size: 36,
              color: TAPAColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Obtenir l\'accès à vie',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Paiement unique de ${_montant.toString()} FCFA',
            style: TextStyle(
              color: TAPAColors.textSecond,
              fontSize: isSmall ? 12 : 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          // Forfait
          Container(
            padding: EdgeInsets.all(paddingSize),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [TAPAColors.navy, Color(0xFF14274E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Column(
              children: [
                _avantageVie('✅ Toutes les fonctionnalités à vie'),
                _avantageVie('✅ Toutes les mises à jour futures'),
                _avantageVie('✅ Support prioritaire'),
                _avantageVie('✅ Accès aux nouvelles fonctionnalités'),
                const SizedBox(height: 16),

                // Bouton Payer maintenant
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _paiementLoading ? null : _showPaymentOptions,
                    icon: _paiementLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TAPAColors.navy,
                      ),
                    )
                        : const Icon(
                      Icons.payment,
                      color: TAPAColors.navy,
                      size: 18,
                    ),
                    label: Text(
                      _paiementLoading ? 'Traitement en cours...' : 'Payer maintenant — 5 000 FCFA',
                      style: TextStyle(
                        color: TAPAColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: isSmall ? 12 : 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Bouton WhatsApp
                TextButton.icon(
                  onPressed: _demanderCleWhatsApp,
                  icon: const Icon(
                    Icons.chat,
                    color: TAPAColors.gold,
                    size: 16,
                  ),
                  label: Text(
                    'Demander une clé par WhatsApp',
                    style: TextStyle(
                      color: TAPAColors.gold,
                      fontSize: isSmall ? 11 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacingSize),

          // Section clé d'activation
          Container(
            padding: EdgeInsets.all(paddingSize),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TAPAColors.border,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      size: 18,
                      color: TAPAColors.navy,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'J\'ai déjà ma clé d\'accès',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Entre la clé reçue après ton paiement',
                  style: TextStyle(
                    fontSize: 12,
                    color: TAPAColors.textSecond,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cleCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'TB-2026-XXXXXXXX',
                    errorText: _error,
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _activer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Activer mon accès',
                      style: TextStyle(
                        color: TAPAColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ BOUTON ROOT (MODE DÉVELOPPEUR)
          _buildRootButton(),

          // ✅ AVERTISSEMENT SI ROOT_DEV_KEY MANQUANTE
          if (!hasRootKey)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '💡 Pour activer le mode Root, définissez ROOT_DEV_KEY dans votre fichier .env',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _avantageVie(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
