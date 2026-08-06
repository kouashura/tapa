// lib/screens/savings/creer_epargne_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../models/models.dart';
import '../../models/epargne_programmee_model.dart';  // ✅ Depuis models/
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class CreerEpargneScreen extends ConsumerStatefulWidget {
  const CreerEpargneScreen({super.key});

  @override
  ConsumerState<CreerEpargneScreen> createState() => _CreerEpargneScreenState();
}

class _CreerEpargneScreenState extends ConsumerState<CreerEpargneScreen> {
  final TextEditingController _titreCtrl = TextEditingController();
  final TextEditingController _objectifCtrl = TextEditingController();
  final TextEditingController _depotCtrl = TextEditingController();
  final TextEditingController _dureeCtrl = TextEditingController();
  String _frequence = 'mois';
  String? _walletId;
  bool _verrouille = false;
  String _codeDeverrouillage = '';
  bool _loading = false;

  List<WalletModel> _wallets = [];

  @override
  void initState() {
    super.initState();
    _chargerWallets();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _objectifCtrl.dispose();
    _depotCtrl.dispose();
    _dureeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerWallets() async {
    // TODO: Remplacer par un provider
    // _wallets = await ref.read(walletListProvider.future);
    if (_wallets.isNotEmpty && _walletId == null) {
      _walletId = _wallets.first.id?.toString();
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_titreCtrl.text.trim().isEmpty ||
        _objectifCtrl.text.isEmpty ||
        _depotCtrl.text.isEmpty ||
        _dureeCtrl.text.isEmpty ||
        _walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplis tous les champs'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final objectif = double.tryParse(_objectifCtrl.text) ?? 0;
    final depot = double.tryParse(_depotCtrl.text) ?? 0;
    final duree = int.tryParse(_dureeCtrl.text) ?? 1;

    if (objectif <= 0 || depot <= 0 || duree <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez des valeurs valides'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    if (depot > objectif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le dépôt ne peut pas dépasser l\'objectif'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = await ref.read(userRepositoryProvider).getCurrentUserId();

      final epargne = EpargneProgrammeeModel(
        id: '',
        uuid: Fmt.genId(),
        utilisateurId: int.tryParse(userId) ?? 1,
        titre: _titreCtrl.text.trim(),
        montantObjectif: objectif,
        frequence: _frequence,
        duree: duree,
        montantParDepot: depot,
        portefeuilleId: int.tryParse(_walletId!) ?? 0,
        dateCreation: DateTime.now(),
        dateFinPrevue: DateTime.now().add(
          Duration(days: duree * (_frequence == 'jour' ? 1 : _frequence == 'semaine' ? 7 : 30)),
        ),
        montantEpargne: 0,
        verrouille: _verrouille,
        codeDeverrouillage: _verrouille ? _codeDeverrouillage : null,
        termine: false,
      );

      // TODO: Utiliser un provider
      // await ref.read(epargneRepositoryProvider).saveEpargneProgrammee(epargne);
      Logger.info('📝 Épargne programmée créée: ${epargne.titre}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épargne programmée créée !'),
            backgroundColor: TAPAColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: TAPAColors.red,
          ),
        );
      }
      Logger.error('❌ Erreur création épargne programmée: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Créer une épargne programmée'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Objectif d\'épargne',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Créez votre épargne programmée automatique',
              style: TextStyle(
                color: TAPAColors.textSecond,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'ex : Vacances 2024',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _objectifCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Objectif total *',
                suffixText: monnaie,
                hintText: '1 000 000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _depotCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Montant par dépôt *',
                suffixText: monnaie,
                hintText: '50 000',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequence,
              decoration: const InputDecoration(
                labelText: 'Fréquence *',
              ),
              items: const [
                DropdownMenuItem(value: 'jour', child: Text('Journalière')),
                DropdownMenuItem(value: 'semaine', child: Text('Hebdomadaire')),
                DropdownMenuItem(value: 'mois', child: Text('Mensuelle')),
              ],
              onChanged: (v) => setState(() => _frequence = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dureeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Durée (en ${_frequence == 'jour' ? 'jours' : _frequence == 'semaine' ? 'semaines' : 'mois'}) *',
                hintText: '12',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _walletId,
              decoration: const InputDecoration(
                labelText: 'Portefeuille *',
              ),
              items: _wallets.map((w) =>
                  DropdownMenuItem<String>(
                    value: w.id?.toString(),
                    child: Text('${w.emoji} ${w.nom}'),
                  ),
              ).toList(),
              onChanged: (v) => setState(() => _walletId = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _verrouille,
                  onChanged: (v) => setState(() {
                    _verrouille = v ?? false;
                    if (_verrouille) {
                      _codeDeverrouillage = Fmt.genId().substring(0, 6).toUpperCase();
                    }
                  }),
                ),
                const Expanded(
                  child: Text(
                    'Verrouiller l\'épargne (ne peut être déverrouillée que par code)',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (_verrouille) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.goldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code de déverrouillage :',
                      style: TextStyle(
                        fontSize: 12,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _codeDeverrouillage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Conservez ce code précieusement !',
                      style: TextStyle(
                        fontSize: 11,
                        color: TAPAColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TAPAColors.gold,
                ),
              )
                  : const Text(
                'Créer mon épargne',
                style: TextStyle(color: TAPAColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}