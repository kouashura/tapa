// lib/screens/savings/add_goal_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
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

  // Raccourcis de date (jours)
  final List<Map<String, dynamic>> _quickDates = [
    {'label': '1 mois', 'days': 30},
    {'label': '3 mois', 'days': 90},
    {'label': '6 mois', 'days': 180},
    {'label': '1 an', 'days': 365},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  // ───────────────────────── Logique (inchangée) ─────────────────────────

  Future<void> _saveGoal() async {
    final name = _nameController.text.trim();
    final targetAmount = double.tryParse(_targetController.text);
    final currentAmount = double.tryParse(_currentController.text) ?? 0;

    if (name.isEmpty) {
      _showSnackBar('Veuillez entrer un nom pour votre objectif',
          isError: true);
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
        setState(() => _isLoading = false);
        return;
      }

      final goal = SavingsGoalModel(
        id: '',
        uid: userId,
        nom: name,
        montantCible: targetAmount,
        montantActuel: currentAmount,
        dateLimite: _targetDate,
        walletId: '',
        estAtteint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(addSavingsGoalProvider(goal).future);

      if (mounted) {
        _showSnackBar('Objectif d\'épargne créé avec succès !');
        context.pop(true);
      }
    } catch (e) {
      Logger.error('❌ Erreur création objectif: $e');
      if (mounted) {
        _showSnackBar(
          'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
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
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        backgroundColor: isError ? TAPAColors.red : TAPAColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ───────────────────────── Aides de style ─────────────────────────

  InputDecoration _dec({
    required String label,
    String? hint,
    required IconData icon,
    String? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, color: TAPAColors.navy, size: 22),
      filled: true,
      fillColor: TAPAColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(TAPAColors.border),
      enabledBorder: border(TAPAColors.border),
      focusedBorder: border(TAPAColors.gold, 1.6),
      labelStyle: const TextStyle(color: TAPAColors.textSecond),
      floatingLabelStyle: const TextStyle(
        color: TAPAColors.navy,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TAPAColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: TAPAColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ───────────────────────── Aperçu ─────────────────────────

  Widget _previewCard() {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text) ?? 0;
    final current = double.tryParse(_currentController.text) ?? 0;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -36,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TAPAColors.gold.withOpacity(0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TAPAColors.gold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flag_outlined,
                            size: 20, color: TAPAColors.gold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Votre nouvel objectif' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TAPAColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.montant(target, monnaie: _selectedCurrency),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(TAPAColors.gold),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Date ─────────────────────────

  bool _isQuickSelected(int days) {
    final target = DateTime.now().add(Duration(days: days));
    return _targetDate.year == target.year &&
        _targetDate.month == target.month &&
        _targetDate.day == target.day;
  }

  Widget _dateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap : les raccourcis passent à la ligne au lieu de déborder
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickDates.map((q) {
            final days = q['days'] as int;
            final selected = _isQuickSelected(days);
            return GestureDetector(
              onTap: () => setState(
                  () => _targetDate = DateTime.now().add(Duration(days: days))),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? TAPAColors.navy : TAPAColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? TAPAColors.navy : TAPAColors.border,
                  ),
                ),
                child: Text(
                  q['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? TAPAColors.white : TAPAColors.navy,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TAPAColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TAPAColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: TAPAColors.navy, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Fmt.dateFuture(_targetDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TAPAColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Modifier',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    _selectedCurrency = monnaie;

    const amountStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: TAPAColors.navy,
    );
    final amountFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Nouvel objectif',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      // Corps défilant : aucun débordement avec le clavier
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _previewCard(),
            const SizedBox(height: 16),
            _card(
              title: 'Votre objectif',
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: _dec(
                      label: 'Nom de l\'objectif',
                      hint: 'ex: Voyage, Maison, Voiture...',
                      icon: Icons.edit_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _targetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountFormatters,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    style: amountStyle,
                    decoration: _dec(
                      label: 'Montant cible',
                      hint: 'ex: 500000',
                      icon: Icons.trending_up_outlined,
                      suffix: _selectedCurrency,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _currentController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountFormatters,
                    onChanged: (_) => setState(() {}),
                    style: amountStyle,
                    decoration: _dec(
                      label: 'Déjà épargné (optionnel)',
                      hint: 'ex: 50000',
                      icon: Icons.account_balance_wallet_outlined,
                      suffix: _selectedCurrency,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(title: 'Date cible', child: _dateSection()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  foregroundColor: TAPAColors.white,
                  disabledBackgroundColor: TAPAColors.navy.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(TAPAColors.gold),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: TAPAColors.gold, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Créer l\'objectif',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
