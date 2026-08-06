// lib/screens/savings/add_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../models/models.dart';  // ✅ Depuis models/
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _montantCtrl = TextEditingController();
  DateTime? _dateLimite;
  String? _walletId;
  bool _loading = false;

  List<WalletModel> _wallets = [];

  @override
  void initState() {
    super.initState();
    _chargerWallets();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
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
    if (_nomCtrl.text.trim().isEmpty ||
        _montantCtrl.text.isEmpty ||
        _walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplis tous les champs.'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    if (montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez un montant valide.'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = await ref.read(userRepositoryProvider).getCurrentUserId();

      final goal = SavingsGoalModel(
        id: null,
        uuid: Fmt.genId(),
        utilisateurId: int.tryParse(userId) ?? 1,
        nom: _nomCtrl.text.trim(),
        montantCible: montant,
        montantActuel: 0,
        dateLimite: _dateLimite,
        portefeuilleId: int.tryParse(_walletId!) ?? 0,
        estAtteint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Utiliser un provider
      // await ref.read(savingsGoalRepositoryProvider).addSavingsGoal(goal);
      Logger.info('📝 Objectif créé: ${goal.nom}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objectif créé avec succès !'),
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
      Logger.error('❌ Erreur création objectif: $e');
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
        title: const Text('Nouvel objectif'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Quel est ton objectif ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ex : Rentrée scolaire, Loyer...',
            style: TextStyle(
              color: TAPAColors.textSecond,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nomCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'objectif *',
              hintText: 'ex : Rentrée scolaire',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Montant à atteindre *',
              suffixText: monnaie,
              hintText: '100 000',
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) {
                setState(() => _dateLimite = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TAPAColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: TAPAColors.navy,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _dateLimite != null
                        ? 'Date limite : ${Fmt.dateComplete(_dateLimite!)}'
                        : 'Date limite (optionnel)',
                    style: TextStyle(
                      color: _dateLimite != null ? TAPAColors.navy : TAPAColors.textHint,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _walletId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille dédié *',
            ),
            items: _wallets.map((w) =>
                DropdownMenuItem<String>(
                  value: w.id?.toString(),
                  child: Text('${w.emoji} ${w.nom}'),
                ),
            ).toList(),
            onChanged: (v) => setState(() => _walletId = v),
          ),
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
              'Créer mon objectif',
              style: TextStyle(color: TAPAColors.white),
            ),
          ),
        ],
      ),
    );
  }
}