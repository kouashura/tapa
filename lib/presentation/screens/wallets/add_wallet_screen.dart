// lib/presentation/screens/wallets/add_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../providers/wallet/wallet_provider.dart';  // ✅ CHEMIN CORRIGÉ
import '../../../domain/usecases/wallet/create_wallet_usecase.dart';
import '../../../core/utils/logger.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _soldeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedEmoji = '💵';
  String _selectedType = 'cash';
  bool _isLoading = false;

  final List<Map<String, String>> _types = [
    {'id': 'cash', 'label': 'Cash', 'emoji': '💵'},
    {'id': 'wave', 'label': 'Wave', 'emoji': '🌊'},
    {'id': 'orange', 'label': 'Orange Money', 'emoji': '🟠'},
    {'id': 'mtn', 'label': 'MTN MoMo', 'emoji': '🟡'},
    {'id': 'moov', 'label': 'Moov Money', 'emoji': '🔵'},
    {'id': 'banque', 'label': 'Banque', 'emoji': '🏦'},
    {'id': 'tresor', 'label': 'Trésor Pay', 'emoji': '💎'},
    {'id': 'free', 'label': 'Free Money', 'emoji': '🟣'},
    {'id': 'autre', 'label': 'Autre', 'emoji': '💳'},
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _soldeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final params = CreateWalletParams(
        uid: user.id,
        nom: _nomController.text.trim(),
        emoji: _selectedEmoji,
        type: _selectedType,
        solde: double.parse(_soldeController.text.trim()),
        monnaie: user.monnaie ?? 'FCFA',
        description: _descriptionController.text.trim(),
      );

      await ref.read(createWalletProvider(params).future);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portefeuille créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      Logger.error('❌ Erreur création portefeuille: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Choisissez un emoji',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _types.length,
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = type['emoji']!;
                          _selectedType = type['id']!;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEmoji == type['emoji']
                                ? Colors.amber.shade700
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type['emoji']!,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nouveau portefeuille'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ============================================
            // 1. ÉMOJI / ICÔNE (cliquable)
            // ============================================
            Center(
              child: GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================
            // 2. NOM DU PORTEFEUILLE
            // ============================================
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du portefeuille',
                hintText: 'Ex: Mon compte Wave',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================
            // 3. TYPE DE PORTEFEUILLE (Dropdown)
            // ============================================
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de portefeuille',
                border: OutlineInputBorder(),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type['id'],
                  child: Row(
                    children: [
                      Text(type['emoji']!),
                      const SizedBox(width: 8),
                      Text(type['label']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    final type = _types.firstWhere((t) => t['id'] == value);
                    _selectedEmoji = type['emoji']!;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // ============================================
            // 4. SOLDE INITIAL
            // ============================================
            TextFormField(
              controller: _soldeController,
              decoration: const InputDecoration(
                labelText: 'Solde initial',
                hintText: '0',
                prefixText: 'FCFA ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un solde';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================
            // 5. DESCRIPTION (optionnelle)
            // ============================================
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Compte principal',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ============================================
            // 6. BOUTON CRÉER
            // ============================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A237E),
                  ),
                )
                    : const Text(
                  'Créer le portefeuille',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
