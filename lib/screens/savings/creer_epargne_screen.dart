// lib/screens/savings/creer_epargne_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

// ✅ RENOMMÉ : CreerEpargneScreen au lieu de EpargneProgrammeeScreen
class CreerEpargneScreen extends ConsumerStatefulWidget {
  const CreerEpargneScreen({super.key});

  @override
  ConsumerState<CreerEpargneScreen> createState() => _CreerEpargneScreenState();
}

class _CreerEpargneScreenState extends ConsumerState<CreerEpargneScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedFrequency = 'Mensuel';
  String _selectedWalletId = '';
  bool _isLoading = false;

  final List<String> _frequencies = ['Hebdomadaire', 'Mensuel', 'Trimestriel'];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveEpargne() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (name.isEmpty) {
      _showSnackBar('Veuillez entrer un nom', isError: true);
      return;
    }

    if (amount == null || amount <= 0) {
      _showSnackBar('Veuillez entrer un montant valide', isError: true);
      return;
    }

    if (_selectedWalletId.isEmpty) {
      _showSnackBar('Veuillez sélectionner un portefeuille', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';

      if (userId.isEmpty) {
        _showSnackBar('Utilisateur non trouvé', isError: true);
        return;
      }

      final userRepo = ref.read(userRepositoryProvider);

      await userRepo.createScheduledSaving(
        userId: userId,
        name: name,
        amount: amount,
        frequency: _selectedFrequency,
        startDate: DateTime.now(),
        walletId: _selectedWalletId,
      );

      if (mounted) {
        _showSnackBar('✅ Épargne programmée créée avec succès !');
        context.pop(true);
      }
    } catch (e) {
      Logger.error('❌ Erreur création épargne: $e');
      if (mounted) {
        _showSnackBar('Erreur: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? TAPAColors.red : TAPAColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final walletsAsync = ref.watch(walletListProvider(ref.watch(currentUserProvider)?.id ?? ''));

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Créer une épargne programmée'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEpargne,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TAPAColors.gold,
              ),
            )
                : const Text(
              'Sauvegarder',
              style: TextStyle(
                color: TAPAColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'épargne',
                hintText: 'ex: Épargne mensuelle',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant à épargner',
                hintText: 'ex: 50000',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                suffixText: monnaie,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
              items: _frequencies.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(freq),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFrequency = value);
                }
              },
            ),
            const SizedBox(height: 16),
            walletsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TAPAColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: TAPAColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Erreur chargement des portefeuilles',
                        style: TextStyle(color: TAPAColors.red),
                      ),
                    ),
                  ],
                ),
              ),
              data: (wallets) {
                if (wallets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Aucun portefeuille. Créez-en un d\'abord.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/wallets'),
                          child: const Text('Créer'),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedWalletId.isEmpty && wallets.isNotEmpty) {
                  _selectedWalletId = wallets.first.id;
                }

                return DropdownButtonFormField<String>(
                  value: _selectedWalletId,
                  decoration: const InputDecoration(
                    labelText: 'Portefeuille source',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: wallets.map((wallet) {
                    return DropdownMenuItem(
                      value: wallet.id,
                      child: Row(
                        children: [
                          Text(wallet.emoji),
                          const SizedBox(width: 8),
                          Text(wallet.nom),
                          const Spacer(),
                          Text(
                            Fmt.montant(wallet.solde, monnaie: monnaie),
                            style: const TextStyle(
                              fontSize: 12,
                              color: TAPAColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedWalletId = value);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEpargne,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  foregroundColor: TAPAColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      TAPAColors.gold,
                    ),
                  ),
                )
                    : const Text(
                  'Créer l\'épargne programmée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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