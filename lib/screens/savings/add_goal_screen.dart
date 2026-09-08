// lib/screens/savings/add_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String _selectedCurrency = 'FCFA';

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final name = _nameController.text.trim();
    final targetAmount = double.tryParse(_targetController.text);
    final currentAmount = double.tryParse(_currentController.text) ?? 0;

    if (name.isEmpty) {
      _showSnackBar('Veuillez entrer un nom pour votre objectif', isError: true);
      return;
    }

    if (targetAmount == null || targetAmount <= 0) {
      _showSnackBar('Veuillez entrer un montant cible valide', isError: true);
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

      // ✅ CORRECTION: Utiliser userRepositoryProvider depuis providers.dart
      final userRepo = ref.read(userRepositoryProvider);

      await userRepo.createSavingsGoal(
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        currency: _selectedCurrency,
        targetDate: _targetDate,
      );

      if (mounted) {
        _showSnackBar('✅ Objectif d\'épargne créé avec succès !');
        context.pop(true);
      }
    } catch (e) {
      Logger.error('❌ Erreur création objectif: $e');
      if (mounted) {
        _showSnackBar('Erreur: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: TAPAColors.navy,
              onPrimary: TAPAColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
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
    _selectedCurrency = monnaie;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Nouvel objectif'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGoal,
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
                labelText: 'Nom de l\'objectif',
                hintText: 'ex: Voyage, Maison, Voiture...',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant cible',
                hintText: 'ex: 500000',
                prefixIcon: const Icon(Icons.trending_up_outlined),
                suffixText: _selectedCurrency,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant actuel (optionnel)',
                hintText: 'ex: 50000',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                suffixText: _selectedCurrency,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: TAPAColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TAPAColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: TAPAColors.textHint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Date cible: ${Fmt.dateRelative(_targetDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: TAPAColors.navy,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: TAPAColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
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
                  'Créer l\'objectif',
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