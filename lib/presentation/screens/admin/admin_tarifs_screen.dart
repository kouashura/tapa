// lib/presentation/screens/admin/admin_tarifs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/models.dart';
import '../../../domain/models/tarif_assurance_auto.dart';
import '../../providers/providers.dart';

class AdminTarifsScreen extends ConsumerStatefulWidget {
  const AdminTarifsScreen({super.key});

  @override
  ConsumerState<AdminTarifsScreen> createState() => _AdminTarifsScreenState();
}

class _AdminTarifsScreenState extends ConsumerState<AdminTarifsScreen> {
  late TextEditingController _basePremiumCtrl;
  late TextEditingController _baseHautGammeCtrl;
  late TextEditingController _basePopulaireCtrl;
  late TextEditingController _baseChinoiseCtrl;
  late TextEditingController _baseDefautCtrl;

  late TextEditingController _coefAge0a1Ctrl;
  late TextEditingController _coefAge1a3Ctrl;
  late TextEditingController _coefAge3a5Ctrl;
  late TextEditingController _coefAge5a10Ctrl;
  late TextEditingController _coefAge10a15Ctrl;
  late TextEditingController _coefAge15PlusCtrl;

  late TextEditingController _coefCv0a4Ctrl;
  late TextEditingController _coefCv4a6Ctrl;
  late TextEditingController _coefCv6a8Ctrl;
  late TextEditingController _coefCv8a10Ctrl;
  late TextEditingController _coefCv10a13Ctrl;
  late TextEditingController _coefCv13PlusCtrl;

  late TextEditingController _primeMinCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initControllers(TarifConfigModel.defaut());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  void _initControllers(TarifConfigModel c) {
    _basePremiumCtrl =
        TextEditingController(text: c.basePremium.toStringAsFixed(0));
    _baseHautGammeCtrl =
        TextEditingController(text: c.baseHautGamme.toStringAsFixed(0));
    _basePopulaireCtrl =
        TextEditingController(text: c.basePopulaire.toStringAsFixed(0));
    _baseChinoiseCtrl =
        TextEditingController(text: c.baseChinoise.toStringAsFixed(0));
    _baseDefautCtrl =
        TextEditingController(text: c.baseDefaut.toStringAsFixed(0));

    _coefAge0a1Ctrl = TextEditingController(text: c.coefAge0a1.toString());
    _coefAge1a3Ctrl = TextEditingController(text: c.coefAge1a3.toString());
    _coefAge3a5Ctrl = TextEditingController(text: c.coefAge3a5.toString());
    _coefAge5a10Ctrl = TextEditingController(text: c.coefAge5a10.toString());
    _coefAge10a15Ctrl = TextEditingController(text: c.coefAge10a15.toString());
    _coefAge15PlusCtrl =
        TextEditingController(text: c.coefAge15Plus.toString());

    _coefCv0a4Ctrl = TextEditingController(text: c.coefCv0a4.toString());
    _coefCv4a6Ctrl = TextEditingController(text: c.coefCv4a6.toString());
    _coefCv6a8Ctrl = TextEditingController(text: c.coefCv6a8.toString());
    _coefCv8a10Ctrl = TextEditingController(text: c.coefCv8a10.toString());
    _coefCv10a13Ctrl = TextEditingController(text: c.coefCv10a13.toString());
    _coefCv13PlusCtrl = TextEditingController(text: c.coefCv13Plus.toString());

    _primeMinCtrl =
        TextEditingController(text: c.primeMinimum.toStringAsFixed(0));
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ref.read(tarifsConfigProvider.future);
      if (mounted) {
        _initControllers(config);
        setState(() => _initialized = true);
      }
    } catch (e) {
      Logger.error('Erreur chargement config: $e');
      if (mounted) setState(() => _initialized = true);
    }
  }

  TarifConfigModel _buildConfigFromControllers() {
    return TarifConfigModel(
      basePremium: double.tryParse(_basePremiumCtrl.text) ?? 15000,
      baseHautGamme: double.tryParse(_baseHautGammeCtrl.text) ?? 10000,
      basePopulaire: double.tryParse(_basePopulaireCtrl.text) ?? 8000,
      baseChinoise: double.tryParse(_baseChinoiseCtrl.text) ?? 7000,
      baseDefaut: double.tryParse(_baseDefautCtrl.text) ?? 8000,
      coefAge0a1: double.tryParse(_coefAge0a1Ctrl.text) ?? 1.30,
      coefAge1a3: double.tryParse(_coefAge1a3Ctrl.text) ?? 1.20,
      coefAge3a5: double.tryParse(_coefAge3a5Ctrl.text) ?? 1.10,
      coefAge5a10: double.tryParse(_coefAge5a10Ctrl.text) ?? 1.00,
      coefAge10a15: double.tryParse(_coefAge10a15Ctrl.text) ?? 0.90,
      coefAge15Plus: double.tryParse(_coefAge15PlusCtrl.text) ?? 0.80,
      coefCv0a4: double.tryParse(_coefCv0a4Ctrl.text) ?? 0.85,
      coefCv4a6: double.tryParse(_coefCv4a6Ctrl.text) ?? 1.00,
      coefCv6a8: double.tryParse(_coefCv6a8Ctrl.text) ?? 1.15,
      coefCv8a10: double.tryParse(_coefCv8a10Ctrl.text) ?? 1.30,
      coefCv10a13: double.tryParse(_coefCv10a13Ctrl.text) ?? 1.50,
      coefCv13Plus: double.tryParse(_coefCv13PlusCtrl.text) ?? 1.80,
      primeMinimum: double.tryParse(_primeMinCtrl.text) ?? 5000,
      updatedAt: DateTime.now(),
      updatedBy: ref.read(currentUserProvider)?.email ?? 'admin',
    );
  }

  Future<void> _sauvegarder() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final config = _buildConfigFromControllers();
    final success = await ref
        .read(tarifsStateProvider.notifier)
        .saveConfig(config, user.email);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarifs sauvegardes'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur sauvegarde'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
    }
  }

  int _calculerApercu() {
    final config = _buildConfigFromControllers();
    return TarifAssuranceAuto.calculerPrimeMensuelle(
      marque: 'Toyota',
      modele: 'Yaris',
      annee: 2020,
      puissance: 5,
      config: config,
    );
  }

  @override
  void dispose() {
    _basePremiumCtrl.dispose();
    _baseHautGammeCtrl.dispose();
    _basePopulaireCtrl.dispose();
    _baseChinoiseCtrl.dispose();
    _baseDefautCtrl.dispose();
    _coefAge0a1Ctrl.dispose();
    _coefAge1a3Ctrl.dispose();
    _coefAge3a5Ctrl.dispose();
    _coefAge5a10Ctrl.dispose();
    _coefAge10a15Ctrl.dispose();
    _coefAge15PlusCtrl.dispose();
    _coefCv0a4Ctrl.dispose();
    _coefCv4a6Ctrl.dispose();
    _coefCv6a8Ctrl.dispose();
    _coefCv8a10Ctrl.dispose();
    _coefCv10a13Ctrl.dispose();
    _coefCv13PlusCtrl.dispose();
    _primeMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tarifsStateProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Administration des tarifs'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: !_initialized
          ? const Center(
              child: CircularProgressIndicator(color: TAPAColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _banniere(),
                const SizedBox(height: 20),
                _sectionTitle(
                    'BASE PAR CATEGORIE DE MARQUE', Icons.directions_car),
                _champ(_basePremiumCtrl, 'Marque Premium',
                    'Mercedes, BMW, Audi...'),
                _champ(_baseHautGammeCtrl, 'Marque Haut de gamme',
                    'Toyota, Honda, Nissan...'),
                _champ(_basePopulaireCtrl, 'Marque Populaire',
                    'Peugeot, Renault, Suzuki...'),
                _champ(_baseChinoiseCtrl, 'Marque Chinoise',
                    'Chery, BYD, Geely...'),
                _champ(_baseDefautCtrl, 'Marque par defaut', 'Inconnue'),
                const SizedBox(height: 20),
                _sectionTitle('COEFFICIENTS D AGE', Icons.calendar_today),
                _champ(_coefAge0a1Ctrl, 'Vehicule 0-1 an', 'Neuf',
                    decimal: true),
                _champ(_coefAge1a3Ctrl, 'Vehicule 1-3 ans', 'Tres recent',
                    decimal: true),
                _champ(_coefAge3a5Ctrl, 'Vehicule 3-5 ans', 'Recent',
                    decimal: true),
                _champ(_coefAge5a10Ctrl, 'Vehicule 5-10 ans', 'Normal',
                    decimal: true),
                _champ(_coefAge10a15Ctrl, 'Vehicule 10-15 ans', 'Ancien',
                    decimal: true),
                _champ(_coefAge15PlusCtrl, 'Vehicule 15+ ans', 'Tres ancien',
                    decimal: true),
                const SizedBox(height: 20),
                _sectionTitle('COEFFICIENTS DE PUISSANCE', Icons.speed),
                _champ(_coefCv0a4Ctrl, 'Puissance 0-4 CV', 'Petite citadine',
                    decimal: true),
                _champ(_coefCv4a6Ctrl, 'Puissance 4-6 CV', 'Compacte',
                    decimal: true),
                _champ(_coefCv6a8Ctrl, 'Puissance 6-8 CV', 'Berline',
                    decimal: true),
                _champ(_coefCv8a10Ctrl, 'Puissance 8-10 CV', 'SUV',
                    decimal: true),
                _champ(_coefCv10a13Ctrl, 'Puissance 10-13 CV', '4x4',
                    decimal: true),
                _champ(_coefCv13PlusCtrl, 'Puissance 13+ CV', 'Gros moteur',
                    decimal: true),
                const SizedBox(height: 20),
                _sectionTitle('PRIME MINIMUM', Icons.trending_down),
                _champ(_primeMinCtrl, 'Prime minimum mensuelle', 'FCFA'),
                const SizedBox(height: 24),
                _apercu(),
                const SizedBox(height: 24),
                if (state.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF27AE60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF27AE60), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.successMessage!,
                            style: const TextStyle(color: Color(0xFF27AE60)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isSaving ? null : _sauvegarder,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label:
                        Text(state.isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.navy,
                      foregroundColor: TAPAColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _banniere() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TAPAColors.navy, Color(0xFF14274E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, color: TAPAColors.gold, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration des tarifs',
                  style: TextStyle(
                    color: TAPAColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ces valeurs sont utilisees pour le calcul des primes auto.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String titre, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TAPAColors.gold),
          const SizedBox(width: 8),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _champ(TextEditingController ctrl, String label, String hint,
      {bool decimal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: decimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: TAPAColors.surface,
          suffixText: decimal ? '' : 'FCFA',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: TAPAColors.gold, width: 2),
          ),
          prefixIcon: const Icon(Icons.edit, size: 18, color: TAPAColors.gold),
        ),
      ),
    );
  }

  Widget _apercu() {
    final prime = _calculerApercu();
    final total = prime * 12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Apercu du calcul',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Exemple : Toyota Yaris 2020, 5 CV, 12 mois',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prime mensuelle',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '${_format(prime)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total 12 mois',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                '${_format(total)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
