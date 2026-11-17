// lib/screens/investir/devis_auto_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/tarif_assurance_auto.dart';
import '../../../services/digital_pay_service.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/models.dart';

class DevisAutoScreen extends ConsumerStatefulWidget {
  final String produitNom;
  const DevisAutoScreen({super.key, required this.produitNom});

  @override
  ConsumerState<DevisAutoScreen> createState() => _DevisAutoScreenState();
}

class _DevisAutoScreenState extends ConsumerState<DevisAutoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _immatriculationCtrl = TextEditingController();
  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _puissanceCtrl = TextEditingController();
  final _nbMoisCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  File? _carteGriseImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _carteGriseScannee = false;
  int _modeSaisie = 0;
  int _selectedIndex = 1;

  int _tarifCalcule = 0;
  int _montantTotal = 0;
  bool _afficherTarif = false;
  TarifConfigModel? _tarifConfig;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telephoneCtrl.dispose();
    _emailCtrl.dispose();
    _immatriculationCtrl.dispose();
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _puissanceCtrl.dispose();
    _nbMoisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _chargerConfigTarifs();
  }

  void _calculerTarif() {
    final marque = _marqueCtrl.text.trim();
    final annee = int.tryParse(_anneeCtrl.text.trim()) ?? 0;
    final puissance = int.tryParse(_puissanceCtrl.text.trim()) ?? 0;
    final nbMois = int.tryParse(_nbMoisCtrl.text.trim()) ?? 0;

    if (marque.isEmpty || annee == 0 || puissance == 0 || nbMois == 0) {
      if (_afficherTarif) {
        setState(() {
          _afficherTarif = false;
          _tarifCalcule = 0;
          _montantTotal = 0;
        });
      }
      return;
    }

    final prime = TarifAssuranceAuto.calculerPrimeMensuelle(
      marque: marque,
      modele: _modeleCtrl.text.trim(),
      annee: annee,
      puissance: puissance,
      config: _tarifConfig,
    );

    final total = TarifAssuranceAuto.calculerMontantTotal(
      primeMensuelle: prime,
      nbMois: nbMois,
    );

    setState(() {
      _tarifCalcule = prime;
      _montantTotal = total;
      _afficherTarif = true;
    });
  }

  Future<void> _payerMaintenant() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_afficherTarif || _montantTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez completer les informations du vehicule'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecte');
      }

      final reference = 'ASSUR-${DateTime.now().millisecondsSinceEpoch}';

      Logger.info('Paiement assurance initie:');
      Logger.info('   - Produit: ${widget.produitNom}');
      Logger.info('   - Montant: $_montantTotal FCFA');
      Logger.info('   - Reference: $reference');

      final digitalPay = DigitalPayService();
      final success = await digitalPay.payerAvecDigitalPay(
        userId: currentUser.id,
        amount: _montantTotal,
        operator: 'WAVE_MONEY_CI',
        phone: _telephoneCtrl.text.trim().isNotEmpty ? _telephoneCtrl.text.trim() : currentUser.phoneNumber,
        sourceWalletId: '',
        description: 'Assurance  -  mois',
      );

      if (success && mounted) {
        context.push(
          '/assurance/success',
          extra: {
            'produitNom': widget.produitNom,
            'montantPaye': _montantTotal,
            'reference': reference,
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le paiement a ete annule'),
              backgroundColor: TAPAColors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Erreur paiement assurance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerConfigTarifs() async {
    try {
      final config = await ref.read(tarifsConfigProvider.future);
      if (mounted) {
        setState(() => _tarifConfig = config);
      }
    } catch (e) {
      Logger.error('Erreur chargement config tarifs: $e');
    }
  }

  Future<void> _pickerImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _carteGriseImage = File(image.path);
        _carteGriseScannee = true;
        _modeSaisie = 1;
      });
    }
  }

  Future<void> _prendrePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _carteGriseImage = File(image.path);
        _carteGriseScannee = true;
        _modeSaisie = 1;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _carteGriseImage = null;
      _carteGriseScannee = false;
      _modeSaisie = 0;
    });
  }

  void _setModeManuel() {
    setState(() {
      _modeSaisie = 0;
      _carteGriseImage = null;
      _carteGriseScannee = false;
    });
  }

  void _setModeScan() {
    setState(() {
      _modeSaisie = 1;
    });
  }

  String _construireMessage() {
    final nom = _nomCtrl.text.trim();
    final prenom = _prenomCtrl.text.trim();
    final telephone = _telephoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final immatriculation = _immatriculationCtrl.text.trim().toUpperCase();
    final marque = _marqueCtrl.text.trim();
    final modele = _modeleCtrl.text.trim();
    final annee = _anneeCtrl.text.trim();
    final puissance = _puissanceCtrl.text.trim();
    final nbMois = _nbMoisCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final parts = <String>[];

    parts.add('NOUVELLE DEMANDE DE DEVIS AUTO');
    parts.add('');
    parts.add('Produit: ${widget.produitNom}');
    parts.add('');

    parts.add('--- CLIENT ---');
    parts.add('Nom: $nom');
    parts.add('Prenom: $prenom');
    parts.add('Tel: $telephone');
    if (email.isNotEmpty) parts.add('Email: $email');
    parts.add('');

    parts.add('--- VEHICULE ---');
    if (_modeSaisie == 1) {
      parts.add('Carte grise scannée (image jointe)');
    } else {
      parts.add('Immatriculation: $immatriculation');
      parts.add('Marque: $marque');
      parts.add('Modèle: $modele');
      parts.add('Année: $annee');
      if (puissance.isNotEmpty) parts.add('Puissance: $puissance CV');
    }
    parts.add('');

    parts.add('--- DEMANDE ---');
    parts.add('Durée: $nbMois mois');
    parts.add('');

    if (notes.isNotEmpty) {
      parts.add('--- NOTES ---');
      parts.add(notes);
      parts.add('');
    }

    parts.add('---');
    parts.add('Envoyé depuis TAPA Invest');
    parts.add('Contact: +225 07 18 14 87 79');

    return parts.join('\n');
  }

  void _copierMessage() {
    final message = _construireMessage();
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Message copié dans le presse-papiers'),
        backgroundColor: TAPAColors.gold,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCopyDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat,
                color: Color(0xFF25D366),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'WhatsApp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Impossible d\'ouvrir WhatsApp automatiquement.\n'
              'Copiez le message et envoyez-le manuellement.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TAPAColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TAPAColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message.length > 50
                          ? '${message.substring(0, 50)}...'
                          : message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TAPAColors.textSecond,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Message copié !'),
                          backgroundColor: TAPAColors.gold,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.copy,
                      color: TAPAColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Message copié dans le presse-papiers'),
                  backgroundColor: TAPAColors.gold,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.gold,
              foregroundColor: TAPAColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _envoyerDevis() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final message = _construireMessage();
    final encoded = Uri.encodeComponent(message);

    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=2250718148779&text=$encoded',
    );

    final webUri = Uri.parse(
      'https://wa.me/2250718148779?text=$encoded',
    );

    try {
      bool launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (launched) {
        _showSuccess(
          "WhatsApp ouvert. Vous pouvez envoyer votre devis.",
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      } else {
        setState(() => _isLoading = false);
        _showCopyDialog(message);
      }
    } catch (e) {
      debugPrint("Erreur WhatsApp : $e");
      setState(() => _isLoading = false);
      _showCopyDialog(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final paddingSize = isSmall ? 12.0 : (isTablet ? 24.0 : 16.0);
    final spacingSize = isSmall ? 8.0 : (isTablet ? 16.0 : 12.0);
    final containerPadding = isSmall ? 12.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: Text(
          'Devis ${widget.produitNom}',
          style: TextStyle(fontSize: isSmall ? 14 : 16),
        ),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: TAPAColors.gold),
                  SizedBox(height: 16),
                  Text(
                    'Envoi de votre demande...',
                    style: TextStyle(
                      color: TAPAColors.textSecond,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(paddingSize),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Container(
                      padding: EdgeInsets.all(containerPadding),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [TAPAColors.navy, Color(0xFF1A2B4A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 8 : 10),
                            decoration: BoxDecoration(
                              color: TAPAColors.gold.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(isSmall ? 8 : 12),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: TAPAColors.gold,
                              size: isSmall ? 20 : 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Devis ${widget.produitNom}',
                                  style: TextStyle(
                                    fontSize:
                                        isSmall ? 16 : (isTablet ? 20 : 18),
                                    fontWeight: FontWeight.w800,
                                    color: TAPAColors.white,
                                  ),
                                ),
                                Text(
                                  'Remplissez les informations ci-dessous',
                                  style: TextStyle(
                                    fontSize:
                                        isSmall ? 10 : (isTablet ? 14 : 12),
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacingSize * 2),

                    // Section Informations personnelles
                    _sectionTitle('Informations personnelles', isSmall),
                    SizedBox(height: spacingSize),

                    if (isSmall || isTablet)
                      Column(
                        children: [
                          _textField(
                            controller: _nomCtrl,
                            label: 'Nom *',
                            hint: 'Votre nom',
                            icon: Icons.person_outline,
                            isSmall: isSmall,
                          ),
                          SizedBox(height: spacingSize),
                          _textField(
                            controller: _prenomCtrl,
                            label: 'Prénom *',
                            hint: 'Votre prénom',
                            icon: Icons.person_outline,
                            isSmall: isSmall,
                          ),
                          SizedBox(height: spacingSize),
                          _textField(
                            controller: _telephoneCtrl,
                            label: 'Téléphone *',
                            hint: '01 23 45 67 89',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            isSmall: isSmall,
                          ),
                          SizedBox(height: spacingSize),
                          _textField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'votre@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isSmall: isSmall,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  controller: _nomCtrl,
                                  label: 'Nom *',
                                  hint: 'Votre nom',
                                  icon: Icons.person_outline,
                                  isSmall: isSmall,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(
                                  controller: _prenomCtrl,
                                  label: 'Prénom *',
                                  hint: 'Votre prénom',
                                  icon: Icons.person_outline,
                                  isSmall: isSmall,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingSize),
                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  controller: _telephoneCtrl,
                                  label: 'Téléphone *',
                                  hint: '01 23 45 67 89',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  isSmall: isSmall,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'votre@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  isSmall: isSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: spacingSize * 2),

                    // Section véhicule
                    _sectionTitle('Informations du véhicule', isSmall),
                    SizedBox(height: spacingSize),

                    Container(
                      padding: EdgeInsets.all(containerPadding),
                      decoration: BoxDecoration(
                        color: TAPAColors.surface,
                        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                        border: Border.all(
                          color: TAPAColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _setModeManuel,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmall ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: _modeSaisie == 0
                                          ? TAPAColors.navy
                                          : TAPAColors.surface,
                                      borderRadius: BorderRadius.circular(
                                          isSmall ? 6 : 10),
                                      border: Border.all(
                                        color: _modeSaisie == 0
                                            ? TAPAColors.navy
                                            : TAPAColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: _modeSaisie == 0
                                              ? TAPAColors.gold
                                              : TAPAColors.textSecond,
                                          size: isSmall ? 14 : 18,
                                        ),
                                        SizedBox(width: isSmall ? 4 : 6),
                                        Text(
                                          isSmall
                                              ? 'Manuel'
                                              : 'Saisie manuelle',
                                          style: TextStyle(
                                            fontSize: isSmall
                                                ? 10
                                                : (isTablet ? 14 : 12),
                                            fontWeight: FontWeight.w700,
                                            color: _modeSaisie == 0
                                                ? TAPAColors.gold
                                                : TAPAColors.textSecond,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmall ? 6 : 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _setModeScan,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmall ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: _modeSaisie == 1
                                          ? TAPAColors.navy
                                          : TAPAColors.surface,
                                      borderRadius: BorderRadius.circular(
                                          isSmall ? 6 : 10),
                                      border: Border.all(
                                        color: _modeSaisie == 1
                                            ? TAPAColors.navy
                                            : TAPAColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.document_scanner_outlined,
                                          color: _modeSaisie == 1
                                              ? TAPAColors.gold
                                              : TAPAColors.textSecond,
                                          size: isSmall ? 14 : 18,
                                        ),
                                        SizedBox(width: isSmall ? 4 : 6),
                                        Text(
                                          isSmall ? 'Scanner' : 'Scanner CG',
                                          style: TextStyle(
                                            fontSize: isSmall
                                                ? 10
                                                : (isTablet ? 14 : 12),
                                            fontWeight: FontWeight.w700,
                                            color: _modeSaisie == 1
                                                ? TAPAColors.gold
                                                : TAPAColors.textSecond,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingSize),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _modeSaisie == 0
                                ? _buildFormulaireManuel(isSmall, spacingSize)
                                : _buildScanCarteGrise(isSmall, spacingSize),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacingSize * 2),

                    // Section Demande
                    _sectionTitle('Votre demande', isSmall),
                    SizedBox(height: spacingSize),

                    _textField(
                      controller: _nbMoisCtrl,
                      onChanged: _calculerTarif,
                      label: 'Nombre de mois *',
                      hint: '12',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      suffix: 'mois',
                      isSmall: isSmall,
                    ),
                    SizedBox(height: spacingSize),
                    _textField(
                      controller: _notesCtrl,
                      label: 'Notes supplémentaires',
                      hint: 'Informations complémentaires...',
                      icon: Icons.notes_outlined,
                      maxLines: isSmall ? 2 : 3,
                      isSmall: isSmall,
                    ),
                    SizedBox(height: spacingSize * 2),

                    // Carte du montant calcule
                    if (_afficherTarif) ...[
                      SizedBox(height: spacingSize * 2),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(containerPadding),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(isSmall ? 12 : 16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF27AE60).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calculate_outlined,
                                  color: Colors.white.withOpacity(0.9),
                                  size: isSmall ? 18 : 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Votre tarif',
                                  style: TextStyle(
                                    fontSize: isSmall ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Prime mensuelle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    TarifAssuranceAuto.formater(_tarifCalcule),
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Duree',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${_nbMoisCtrl.text} mois',
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Total a payer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    TarifAssuranceAuto.formater(_montantTotal),
                                    style: TextStyle(
                                      fontSize: isSmall ? 16 : 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacingSize),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _payerMaintenant,
                          icon: Icon(
                            Icons.payment,
                            size: isSmall ? 18 : 22,
                          ),
                          label: Text(
                            'Payer maintenant',
                            style: TextStyle(
                              fontSize: isSmall ? 14 : 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmall ? 14 : 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(isSmall ? 10 : 14),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: spacingSize * 2),
                    ],

                    // Boutons WhatsApp et Copier

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _envoyerDevis,
                            icon: const Icon(Icons.send_outlined, size: 18),
                            label: Text(
                              isSmall ? 'WhatsApp' : 'WhatsApp',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isSmall ? 8 : 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copierMessage,
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(
                              isSmall ? 'Copier' : 'Copier',
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TAPAColors.navy,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmall ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(isSmall ? 8 : 12),
                              ),
                              side: const BorderSide(color: TAPAColors.navy),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '📱 Envoyé via WhatsApp - Réponse sous 24h',
                        style: TextStyle(
                          fontSize: isSmall ? 9 : (isTablet ? 13 : 11),
                          color: TAPAColors.textSecond,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 20 : 40),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ==========================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield,
                label: 'Assurance',
                index: 1,
                route: '/investir/assurance',
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: 'Enveloppe',
                index: 2,
                route: '/savings',
              ),
              _buildNavItem(
                icon: Icons.pie_chart_outline,
                activeIcon: Icons.pie_chart,
                label: 'Budget',
                index: 3,
                route: '/budget',
              ),
              _buildNavItem(
                icon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card,
                label: 'Dettes',
                index: 4,
                route: '/dettes',
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 5,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String route,
  }) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateTo(route, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 0,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 22 : 20,
                color: isActive ? Colors.amber : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                    isActive ? const Color(0xFF1A237E) : Colors.grey.shade500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FORMULAIRE MANUEL
  // ==========================================================
  Widget _buildFormulaireManuel(bool isSmall, double spacing) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _textField(
          controller: _immatriculationCtrl,
          label: 'Immatriculation *',
          hint: 'AB-123-CD',
          icon: Icons.assignment_outlined,
          textCapitalization: TextCapitalization.characters,
          isSmall: isSmall,
        ),
        SizedBox(height: spacing),
        isSmall
            ? Column(
                children: [
                  _textField(
                    controller: _marqueCtrl,
                    onChanged: _calculerTarif,
                    label: 'Marque *',
                    hint: 'Toyota',
                    icon: Icons.directions_car_outlined,
                    isSmall: isSmall,
                  ),
                  SizedBox(height: spacing),
                  _textField(
                    controller: _modeleCtrl,
                    label: 'Modèle *',
                    hint: 'Yaris',
                    icon: Icons.directions_car_outlined,
                    isSmall: isSmall,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _marqueCtrl,
                      onChanged: _calculerTarif,
                      label: 'Marque *',
                      hint: 'Toyota',
                      icon: Icons.directions_car_outlined,
                      isSmall: isSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _modeleCtrl,
                      label: 'Modèle *',
                      hint: 'Yaris',
                      icon: Icons.directions_car_outlined,
                      isSmall: isSmall,
                    ),
                  ),
                ],
              ),
        SizedBox(height: spacing),
        isSmall
            ? Column(
                children: [
                  _textField(
                    controller: _anneeCtrl,
                    onChanged: _calculerTarif,
                    label: 'Année *',
                    hint: '2020',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    isSmall: isSmall,
                  ),
                  SizedBox(height: spacing),
                  _textField(
                    controller: _puissanceCtrl,
                    onChanged: _calculerTarif,
                    label: 'Puissance (CV)',
                    hint: '75',
                    icon: Icons.speed_outlined,
                    keyboardType: TextInputType.number,
                    isSmall: isSmall,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _anneeCtrl,
                      onChanged: _calculerTarif,
                      label: 'Année *',
                      hint: '2020',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      isSmall: isSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _puissanceCtrl,
                      onChanged: _calculerTarif,
                      label: 'Puissance (CV)',
                      hint: '75',
                      icon: Icons.speed_outlined,
                      keyboardType: TextInputType.number,
                      isSmall: isSmall,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  // ==========================================================
  // SCAN CARTE GRISE
  // ==========================================================
  Widget _buildScanCarteGrise(bool isSmall, double spacing) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _prendrePhoto,
                icon: Icon(
                  Icons.camera_alt_outlined,
                  size: isSmall ? 16 : 20,
                ),
                label: Text(
                  isSmall ? 'Scanner' : 'Prendre une photo',
                  style: TextStyle(fontSize: isSmall ? 10 : 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _carteGriseScannee ? Colors.green : TAPAColors.navy,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickerImage,
                icon: Icon(
                  Icons.photo_library_outlined,
                  size: isSmall ? 16 : 20,
                ),
                label: Text(
                  isSmall ? 'Galerie' : 'Choisir dans la galerie',
                  style: TextStyle(fontSize: isSmall ? 10 : 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _carteGriseScannee ? Colors.green : Colors.grey.shade200,
                  foregroundColor:
                      _carteGriseScannee ? Colors.white : TAPAColors.navy,
                  padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_carteGriseImage != null) ...[
          SizedBox(height: spacing),
          Container(
            height: isSmall ? 80 : 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
              image: DecorationImage(
                image: FileImage(_carteGriseImage!),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: TAPAColors.gold,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _resetScan,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: isSmall ? 12 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                '✅ Carte grise scannée',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // WIDGETS UTILITAIRES
  // ==========================================================
  Widget _sectionTitle(String title, bool isSmall) {
    return Row(
      children: [
        Container(
          width: isSmall ? 3 : 4,
          height: isSmall ? 14 : 18,
          decoration: BoxDecoration(
            color: TAPAColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? suffix,
    required bool isSmall,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      validator: (value) {
        if (label.contains('*') && (value == null || value.trim().isEmpty)) {
          return 'Ce champ est requis';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: TAPAColors.gold,
          size: isSmall ? 16 : 20,
        ),
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
          borderSide: const BorderSide(color: TAPAColors.gold, width: 2),
        ),
        filled: true,
        fillColor: TAPAColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 10 : 14,
        ),
        labelStyle: TextStyle(fontSize: isSmall ? 12 : 14),
        hintStyle: TextStyle(fontSize: isSmall ? 12 : 14),
      ),
    );
  }
}
