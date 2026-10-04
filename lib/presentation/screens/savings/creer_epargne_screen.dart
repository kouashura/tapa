// lib/screens/savings/creer_epargne_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class CreerEpargneScreen extends ConsumerStatefulWidget {
  const CreerEpargneScreen({super.key});

  @override
  ConsumerState<CreerEpargneScreen> createState() => _CreerEpargneScreenState();
}

class _CreerEpargneScreenState extends ConsumerState<CreerEpargneScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedFrequency = 'mois';
  String _selectedWalletId = '';
  bool _isLoading = false;

  // Valeurs attendues par le modèle
  final List<Map<String, dynamic>> _frequencies = [
    {
      'value': 'jour',
      'label': 'Quotidien',
      'short': 'par jour',
      'icon': Icons.today_outlined
    },
    {
      'value': 'semaine',
      'label': 'Hebdo',
      'short': 'par semaine',
      'icon': Icons.date_range_outlined
    },
    {
      'value': 'mois',
      'label': 'Mensuel',
      'short': 'par mois',
      'icon': Icons.calendar_month_outlined
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ───────────────────────── Logique (inchangée) ─────────────────────────

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
        setState(() => _isLoading = false);
        return;
      }

      final utilisateurIdInt = userId.hashCode.abs() % 1000000;
      final portefeuilleIdInt = _selectedWalletId.hashCode.abs() % 1000000;

      final epargne = EpargneProgrammeeModel(
        id: '',
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
        utilisateurId: utilisateurIdInt,
        titre: name,
        montantObjectif: amount * 10,
        frequence: _selectedFrequency,
        duree: 12,
        montantParDepot: amount,
        portefeuilleId: portefeuilleIdInt,
        dateCreation: DateTime.now(),
        dateFinPrevue: DateTime.now().add(const Duration(days: 365)),
        montantEpargne: 0,
        verrouille: false,
        codeDeverrouillage: null,
        termine: false,
      );

      await ref.read(savingsRepositoryProvider).addEpargne(epargne);

      if (mounted) {
        _showSnackBar('Épargne programmée créée avec succès !');
        context.go('/savings');
      }
    } catch (e) {
      Logger.error('❌ Erreur création épargne: $e');
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _previewCard(String monnaie) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final freq = _frequencies.firstWhere(
          (f) => f['value'] == _selectedFrequency,
      orElse: () => _frequencies.last,
    );
    final name = _nameController.text.trim();

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
                        child: const Icon(Icons.savings_outlined,
                            size: 20, color: TAPAColors.gold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Votre nouvelle épargne' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.montant(amount, monnaie: monnaie),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${freq['short']} · pendant 12 mois',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Fréquence ─────────────────────────

  Widget _frequencySelector() {
    return Row(
      children: [
        for (int i = 0; i < _frequencies.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _frequencyChip(_frequencies[i])),
        ],
      ],
    );
  }

  Widget _frequencyChip(Map<String, dynamic> freq) {
    final selected = _selectedFrequency == freq['value'];
    return GestureDetector(
      onTap: () => setState(() => _selectedFrequency = freq['value'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? TAPAColors.navy : TAPAColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? TAPAColors.navy : TAPAColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              freq['icon'] as IconData,
              size: 22,
              color: selected ? TAPAColors.gold : TAPAColors.textSecond,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                freq['label'] as String,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? TAPAColors.white : TAPAColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Portefeuille ─────────────────────────

  Widget _infoBox({
    required Color background,
    required Color color,
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _walletSection(String monnaie, AsyncValue<List<dynamic>> walletsAsync) {
    return walletsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: TAPAColors.gold),
          ),
        ),
      ),
      error: (err, stack) => _infoBox(
        background: TAPAColors.redLight,
        color: TAPAColors.red,
        icon: Icons.error_outline,
        message: 'Impossible de charger vos portefeuilles.',
      ),
      data: (wallets) {
        if (wallets.isEmpty) {
          return _infoBox(
            background: Colors.orange.shade50,
            color: Colors.orange.shade800,
            icon: Icons.warning_amber_outlined,
            message: 'Aucun portefeuille. Créez-en un d\'abord.',
            action: TextButton(
              onPressed: () => context.push('/wallets'),
              child: const Text('Créer'),
            ),
          );
        }

        if (_selectedWalletId.isEmpty) {
          _selectedWalletId = wallets.first.id;
        }

        return DropdownButtonFormField<String>(
          value: _selectedWalletId,
          isExpanded: true, // évite le débordement horizontal
          icon: const Icon(Icons.keyboard_arrow_down, color: TAPAColors.navy),
          borderRadius: BorderRadius.circular(14),
          decoration: _dec(
            label: 'Portefeuille source',
            icon: Icons.account_balance_wallet_outlined,
          ),
          selectedItemBuilder: (context) => wallets
              .map<Widget>((w) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${w.emoji} ${w.nom}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: TAPAColors.navy,
              ),
            ),
          ))
              .toList(),
          items: wallets.map<DropdownMenuItem<String>>((wallet) {
            return DropdownMenuItem<String>(
              value: wallet.id as String,
              child: Row(
                children: [
                  Text(wallet.emoji),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wallet.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      Fmt.montant(wallet.solde, monnaie: monnaie),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TAPAColors.textHint,
                      ),
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
    );
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final walletsAsync =
    ref.watch(walletListProvider(ref.watch(currentUserProvider)?.id ?? ''));

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Nouvelle épargne',
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
          onPressed: () => context.go('/savings'),
        ),
      ),
      // Le corps défile : plus de débordement quand le clavier s'ouvre
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _previewCard(monnaie),
            const SizedBox(height: 16),
            _card(
              title: 'Détails',
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: _dec(
                      label: 'Nom de l\'épargne',
                      hint: 'ex: Épargne mensuelle',
                      icon: Icons.edit_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                    ),
                    decoration: _dec(
                      label: 'Montant à épargner',
                      hint: 'ex: 50000',
                      icon: Icons.payments_outlined,
                      suffix: monnaie,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(title: 'Fréquence', child: _frequencySelector()),
            const SizedBox(height: 16),
            _card(
              title: 'Portefeuille',
              child: _walletSection(monnaie, walletsAsync),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEpargne,
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
                        'Créer l\'épargne programmée',
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