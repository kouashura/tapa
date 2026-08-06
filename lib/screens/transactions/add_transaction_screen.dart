// lib/screens/transactions/add_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/logger.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final TextEditingController _montantCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.depense;
  String _categorieId = '';
  String _categorieLabel = '';
  String _categorieEmoji = '📌';
  String? _walletId;  // ← Changé de int? à String?
  DateTime _date = DateTime.now();
  bool _saving = false;

  List<WalletModel> _wallets = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    // TODO: Remplacer par des providers
    // _wallets = await ref.read(walletListProvider.future);
    // _categories = await ref.read(categoryListProvider.future);
    if (_wallets.isNotEmpty && _walletId == null) {
      _walletId = _wallets.first.id?.toString();
    }
    setState(() {});
  }

  List<Map<String, dynamic>> get _filteredCats {
    return _type == TransactionType.revenu
        ? _categories.where((c) => c['type'] == 'revenu').toList()
        : _categories.where((c) => c['type'] == 'depense').toList();
  }

  void _syncCategorySelection() {
    final cats = _filteredCats;
    if (cats.isEmpty) {
      _categorieId = '';
      _categorieLabel = '';
      _categorieEmoji = '📌';
      return;
    }
    final stillValid = cats.any((c) => c['id'] == _categorieId);
    if (!stillValid) {
      final first = cats.first;
      _categorieId = first['id'] as String? ?? '';
      _categorieLabel = first['label'] as String? ?? 'Autre';
      _categorieEmoji = first['emoji'] as String? ?? '📌';
    }
  }

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez un montant valide'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }
    if (_walletId == null || _walletId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un portefeuille'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }
    if (_categorieId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez une catégorie'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final userId = await ref.read(userRepositoryProvider).getCurrentUserId();

      final tx = TransactionModel(
        id: null,
        uuid: Fmt.genId(),
        utilisateurId: userId,  // ← String directement
        portefeuilleId: _walletId!,  // ← String
        portefeuilleDestId: null,
        montant: montant,
        type: _type,
        categorieId: _categorieId,
        categorieLabel: _categorieLabel,
        categorieEmoji: _categorieEmoji,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dateTransaction: _date,
        createdAt: DateTime.now(),
      );

      // TODO: Utiliser un provider
      // await ref.read(transactionRepositoryProvider).addTransaction(tx);
      Logger.info('📝 Transaction enregistrée: ${tx.montant}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction enregistrée !'),
          backgroundColor: TAPAColors.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement : $e'),
          backgroundColor: TAPAColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final filteredCats = _filteredCats;
    final noWallets = _wallets.isEmpty;
    final noCats = filteredCats.isEmpty;
    final blocked = noWallets || noCats;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle transaction'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (noWallets)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TAPAColors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'Aucun portefeuille disponible. Créez-en un avant '
                      'd\'ajouter une transaction.',
                  style: TextStyle(color: TAPAColors.red, fontSize: 13),
                ),
              ),
            ),
          if (!noWallets && noCats)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TAPAColors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'Aucune catégorie disponible pour ce type de transaction.',
                  style: TextStyle(color: TAPAColors.red, fontSize: 13),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: blocked
                      ? null
                      : () => setState(() {
                    _type = TransactionType.depense;
                    _syncCategorySelection();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == TransactionType.depense
                          ? TAPAColors.red
                          : TAPAColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _type == TransactionType.depense
                            ? TAPAColors.red
                            : TAPAColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          color: _type == TransactionType.depense
                              ? Colors.white
                              : TAPAColors.textSecond,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dépense',
                          style: TextStyle(
                            color: _type == TransactionType.depense
                                ? Colors.white
                                : TAPAColors.textSecond,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: blocked
                      ? null
                      : () => setState(() {
                    _type = TransactionType.revenu;
                    _syncCategorySelection();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == TransactionType.revenu
                          ? TAPAColors.green
                          : TAPAColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _type == TransactionType.revenu
                            ? TAPAColors.green
                            : TAPAColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          color: _type == TransactionType.revenu
                              ? Colors.white
                              : TAPAColors.textSecond,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Revenu',
                          style: TextStyle(
                            color: _type == TransactionType.revenu
                                ? Colors.white
                                : TAPAColors.textSecond,
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
          const SizedBox(height: 20),
          TextField(
            controller: _montantCtrl,
            enabled: !blocked,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Montant *',
              suffixText: monnaie,
              hintText: '0',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _categorieId.isEmpty ? null : _categorieId,
            decoration: const InputDecoration(
              labelText: 'Catégorie *',
            ),
            items: filteredCats.map((cat) {
              final id = cat['id'] as String? ?? '';
              final label = cat['label'] as String? ?? 'Autre';
              final emoji = cat['emoji'] as String? ?? '📌';
              return DropdownMenuItem<String>(
                value: id,
                child: Text('$emoji $label'),
              );
            }).toList(),
            onChanged: blocked
                ? null
                : (v) {
              if (v == null) return;
              final cat = filteredCats.firstWhere((c) => c['id'] == v);
              setState(() {
                _categorieId = v;
                _categorieLabel = cat['label'] ?? 'Autre';
                _categorieEmoji = cat['emoji'] ?? '📌';
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _walletId,
            decoration: const InputDecoration(
              labelText: 'Portefeuille *',
            ),
            items: _wallets.map((w) {
              return DropdownMenuItem<String>(
                value: w.id?.toString(),
                child: Text('${w.emoji} ${w.nom}'),
              );
            }).toList(),
            onChanged: blocked ? null : (v) => setState(() => _walletId = v),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: blocked
                ? null
                : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _date = date);
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
                    'Date : ${Fmt.dateComplete(_date)}',
                    style: const TextStyle(
                      color: TAPAColors.navy,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            enabled: !blocked,
            decoration: const InputDecoration(
              labelText: 'Note (optionnelle)',
              hintText: 'ex : Courses supermarché',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (blocked || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}