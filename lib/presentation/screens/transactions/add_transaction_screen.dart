// lib/screens/transactions/add_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import '../../../services/db_service_mysql.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final DBService _db = DBService();
  final TextEditingController _montantCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.depense;
  String _categorieId = '';
  String _categorieLabel = '';
  String _categorieEmoji = '📌';
  String? _walletId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  List<WalletModel> _wallets = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _transitionReady = false;
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chargerDonnees();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAttached) return;
    _listenerAttached = true;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _transitionReady = true;
    } else {
      void onStatusChange(AnimationStatus status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _transitionReady = true);
          animation.removeStatusListener(onStatusChange);
        }
      }

      animation.addStatusListener(onStatusChange);
    }
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    try {
      _wallets = await _db.getWallets();
      _categories = _db.getCategories();
      if (_wallets.isNotEmpty && _walletId == null) {
        _walletId = _wallets.first.id;
      }
      _syncCategorySelection();
    } catch (e) {
      Logger.error('❌ Erreur chargement données: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      // ✅ CORRECTION : utiliser currentUserProvider au lieu de userRepositoryProvider
      final userId = ref.read(currentUserProvider)?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final tx = TransactionModel(
        id: Fmt.genId(),
        uid: userId,
        walletId: _walletId!,
        montant: montant,
        type: _type,
        categorieId: _categorieId,
        categorieLabel: _categorieLabel,
        categorieEmoji: _categorieEmoji,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dateTransaction: _date,
        createdAt: DateTime.now(),
      );

      await _db.addTransaction(tx);
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

  Widget _fieldPlaceholder(String label) {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TAPAColors.textSecond,
          fontSize: 14,
        ),
      ),
    );
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
        actions: [
          TextButton(
            onPressed: (blocked || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TAPAColors.gold,
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: TAPAColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ============================================
                // TYPE DE TRANSACTION
                // ============================================
                Container(
                  decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.depense
                                  ? TAPAColors.red
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: _type == TransactionType.depense
                                      ? Colors.white
                                      : TAPAColors.textSecond,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dépense',
                                  style: TextStyle(
                                    color: _type == TransactionType.depense
                                        ? Colors.white
                                        : TAPAColors.textSecond,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: blocked
                              ? null
                              : () => setState(() {
                                    _type = TransactionType.revenu;
                                    _syncCategorySelection();
                                  }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.revenu
                                  ? TAPAColors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: _type == TransactionType.revenu
                                      ? Colors.white
                                      : TAPAColors.textSecond,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Revenu',
                                  style: TextStyle(
                                    color: _type == TransactionType.revenu
                                        ? Colors.white
                                        : TAPAColors.textSecond,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================
                // MONTANT
                // ============================================
                Container(
                  decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _montantCtrl,
                    enabled: !blocked,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Montant *',
                      labelStyle: const TextStyle(
                        color: TAPAColors.textSecond,
                        fontSize: 14,
                      ),
                      suffixText: monnaie,
                      suffixStyle: const TextStyle(
                        color: TAPAColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: TAPAColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================
                // CATÉGORIE
                // ============================================
                _transitionReady
                    ? Container(
                        decoration: BoxDecoration(
                          color: TAPAColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _categorieId.isEmpty ? null : _categorieId,
                          decoration: InputDecoration(
                            labelText: 'Catégorie *',
                            labelStyle: const TextStyle(
                              color: TAPAColors.textSecond,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: TAPAColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            prefixIcon: _categorieId.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _categorieEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  )
                                : null,
                          ),
                          items: filteredCats.map((cat) {
                            final id = cat['id'] as String? ?? '';
                            final label = cat['label'] as String? ?? 'Autre';
                            final emoji = cat['emoji'] as String? ?? '📌';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Row(
                                children: [
                                  Text(emoji,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: blocked
                              ? null
                              : (v) {
                                  if (v == null) return;
                                  final cat = filteredCats
                                      .firstWhere((c) => c['id'] == v);
                                  setState(() {
                                    _categorieId = v;
                                    _categorieLabel =
                                        cat['label'] ?? 'Autre';
                                    _categorieEmoji =
                                        cat['emoji'] ?? '📌';
                                  });
                                },
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: TAPAColors.textSecond,
                            size: 28,
                          ),
                          dropdownColor: TAPAColors.surface,
                          style: const TextStyle(
                            color: TAPAColors.navy,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : _fieldPlaceholder('Catégorie *'),

                const SizedBox(height: 16),

                // ============================================
                // PORTEFEUILLE
                // ============================================
                _transitionReady
                    ? Container(
                        decoration: BoxDecoration(
                          color: TAPAColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _walletId,
                          decoration: InputDecoration(
                            labelText: 'Portefeuille *',
                            labelStyle: const TextStyle(
                              color: TAPAColors.textSecond,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: TAPAColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          items: _wallets.where((w) => w != null).map((w) {
                            final wallet = w;
                            return DropdownMenuItem<String>(
                              value: wallet.id,
                              child: Row(
                                children: [
                                  Text(
                                    wallet.emoji ?? '💳',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      wallet.nom ?? 'Portefeuille',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    Fmt.montant(wallet.solde,
                                        monnaie: monnaie),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TAPAColors.textSecond,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: blocked
                              ? null
                              : (v) => setState(() => _walletId = v),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: TAPAColors.textSecond,
                            size: 28,
                          ),
                          dropdownColor: TAPAColors.surface,
                          style: const TextStyle(
                            color: TAPAColors.navy,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : _fieldPlaceholder('Portefeuille *'),

                const SizedBox(height: 16),

                // ============================================
                // DATE
                // ============================================
                GestureDetector(
                  onTap: blocked
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: TAPAColors.navy,
                                  onPrimary: Colors.white,
                                  onSurface: TAPAColors.navy,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) {
                            setState(() => _date = date);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: TAPAColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: TAPAColors.goldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: TAPAColors.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date de la transaction',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TAPAColors.textSecond,
                                ),
                              ),
                              Text(
                                Fmt.dateComplete(_date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: TAPAColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: TAPAColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================
                // NOTE
                // ============================================
                Container(
                  decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _noteCtrl,
                    enabled: !blocked,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Note (optionnelle)',
                      labelStyle: const TextStyle(
                        color: TAPAColors.textSecond,
                        fontSize: 14,
                      ),
                      hintText: 'ex : Courses supermarché',
                      hintStyle: const TextStyle(
                        color: TAPAColors.textHint,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: TAPAColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.edit_note_outlined,
                        color: TAPAColors.textHint,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================
                // BOUTON ENREGISTRER
                // ============================================
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (blocked || _saving) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _type == TransactionType.revenu
                          ? TAPAColors.green
                          : TAPAColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: _type == TransactionType.revenu
                          ? TAPAColors.green.withOpacity(0.3)
                          : TAPAColors.navy.withOpacity(0.3),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _type == TransactionType.revenu
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _type == TransactionType.revenu
                                    ? 'Enregistrer le revenu'
                                    : 'Enregistrer la dépense',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // ============================================
                // MESSAGES D'ERREUR / INFO
                // ============================================
                if (blocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TAPAColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TAPAColors.red.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: TAPAColors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            noWallets
                                ? 'Créez d\'abord un portefeuille'
                                : 'Aucune catégorie disponible',
                            style: const TextStyle(
                              color: TAPAColors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading || !_transitionReady)
            Positioned.fill(
              child: Container(
                color: TAPAColors.background.withOpacity(0.85),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
