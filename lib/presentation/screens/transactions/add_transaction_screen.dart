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
import '../../../domain/usecases/transaction/add_transaction_usecase.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddTransactionScreen({super.key, this.initialData});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
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

  // ---------------------------------------------------------------
  // Constantes de design
  // ---------------------------------------------------------------
  static const double _radius = 20;
  static const Duration _anim = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    // ✅ Pré-remplissage depuis la saisie vocale
    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['montant'] != null) {
        _montantCtrl.text = data['montant'].toString();
      }
      if (data['type'] != null) {
        _type = data['type'] == 'revenu' ? TransactionType.revenu : TransactionType.depense;
      }
      if (data['note'] != null) {
        _noteCtrl.text = data['note'];
      }
      // Optionnel : Chercher la catégorie par son label pour l'assigner
      if (data['categorieLabel'] != null) {
        _categorieLabel = data['categorieLabel'];
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chargerDonnees();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAttached) return;
    _listenerAttached = true;

    // Marquer la transition comme prete immediatement + timer de securite
    _transitionReady = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_transitionReady) {
        setState(() => _transitionReady = true);
      }
    });
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    final uid = ref.read(currentUserProvider)?.id ?? '';
    try {
      // Charger depuis le stream Firestore
      if (uid.isNotEmpty) {
        _wallets = await ref.read(walletListProvider(uid).future);
      } else {
        _wallets = [];
      }

      Logger.info('DEBUG uid=$uid wallets=${_wallets.length} '
          'cats=${_categories.length} '
          'walletsIds=${_wallets.map((w) => w.id).toList()}');

      if (_wallets.isNotEmpty && _walletId == null) {
        _walletId = _wallets.first.id;
      }
      _syncCategorySelection();
    } catch (e, st) {
      Logger.error('❌ Erreur chargement données: $e\n$st');
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

  void _selectType(TransactionType type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _syncCategorySelection();
    });
  }

  void _selectCategory(Map<String, dynamic> cat) {
    HapticFeedback.selectionClick();
    setState(() {
      _categorieId = cat['id'] as String? ?? '';
      _categorieLabel = cat['label'] as String? ?? 'Autre';
      _categorieEmoji = cat['emoji'] as String? ?? '📌';
    });
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text);
    if (montant == null || montant <= 0) {
      _snack('Entrez un montant valide', TAPAColors.red);
      return;
    }
    if (_walletId == null || _walletId!.isEmpty) {
      _snack('Sélectionnez un portefeuille', TAPAColors.red);
      return;
    }
    if (_categorieId.isEmpty) {
      _snack('Sélectionnez une catégorie', TAPAColors.red);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final userId = ref.read(currentUserProvider)?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      // Convertir TransactionType (modele) en TransactionTypeParam (usecase)
      TransactionTypeParam typeParam;
      switch (_type) {
        case TransactionType.revenu:
          typeParam = TransactionTypeParam.revenu;
          break;
        case TransactionType.transfert:
          typeParam = TransactionTypeParam.transfert;
          break;
        default:
          typeParam = TransactionTypeParam.depense;
      }

      final params = AddTransactionParams(
        uid: userId,
        walletId: _walletId!,
        montant: montant,
        type: typeParam,
        categorieId: _categorieId,
        categorieLabel: _categorieLabel,
        categorieEmoji: _categorieEmoji,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        dateTransaction: _date,
      );

      final result = await ref.read(addTransactionProvider(params).future);

      if (!result.success) {
        throw Exception(result.message ?? 'Erreur enregistrement');
      }

      Logger.info('Transaction enregistree + solde mis a jour: $montant');

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _snack('Transaction enregistrée !', TAPAColors.green);
      context.pop(true);
    } catch (e, st) {
      Logger.error('❌ ECHEC ajout transaction: $e');
      Logger.error('Stack: $st');
      if (!mounted) return;
      _snack('Erreur lors de l\'enregistrement : $e', TAPAColors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
    if (date != null) setState(() => _date = date);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------------------------------------------------------
  // Briques UI réutilisables
  // ---------------------------------------------------------------

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: TAPAColors.textSecond,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _skeleton({double height = 64}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: _cardDecoration(),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _typeTab({
    required String label,
    required IconData icon,
    required TransactionType type,
    required Color color,
    required bool blocked,
  }) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: blocked ? null : () => _selectType(type),
        child: AnimatedContainer(
          duration: _anim,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête sombre : sélecteur de type + saisie du montant.
  Widget _buildHeader(String monnaie, bool blocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      decoration: const BoxDecoration(
        color: TAPAColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Sélecteur de type
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _typeTab(
                  label: 'Dépense',
                  icon: Icons.south_west_rounded,
                  type: TransactionType.depense,
                  color: TAPAColors.red,
                  blocked: blocked,
                ),
                _typeTab(
                  label: 'Revenu',
                  icon: Icons.north_east_rounded,
                  type: TransactionType.revenu,
                  color: TAPAColors.green,
                  blocked: blocked,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'MONTANT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),

          // Saisie du montant
          TextField(
            controller: _montantCtrl,
            enabled: !blocked,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            cursorColor: TAPAColors.gold,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.25),
                height: 1.1,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 10),

          // Devise
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: TAPAColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              monnaie,
              style: const TextStyle(
                color: TAPAColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> cat, Color accent) {
    final id = cat['id'] as String? ?? '';
    final label = cat['label'] as String? ?? 'Autre';
    final emoji = cat['emoji'] as String? ?? '📌';
    final selected = id == _categorieId;

    return GestureDetector(
      onTap: () => _selectCategory(cat),
      child: AnimatedContainer(
        duration: _anim,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : TAPAColors.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 17, height: 1.0)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : TAPAColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(List<Map<String, dynamic>> cats, Color accent) {
    if (!_transitionReady) return _skeleton(height: 120);
    if (cats.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: const Text(
          'Aucune catégorie disponible',
          style: TextStyle(color: TAPAColors.textSecond, fontSize: 14),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cats.map((c) => _buildCategoryChip(c, accent)).toList(),
      ),
    );
  }

  Widget _buildWalletCard(WalletModel wallet, String monnaie, bool blocked) {
    final selected = wallet.id == _walletId;
    return GestureDetector(
      onTap: blocked
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _walletId = wallet.id);
            },
      child: AnimatedContainer(
        duration: _anim,
        curve: Curves.easeOut,
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? TAPAColors.navy : TAPAColors.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: selected ? TAPAColors.gold : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: TAPAColors.navy.withOpacity(selected ? 0.22 : 0.06),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.12)
                        : TAPAColors.goldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    wallet.emoji ?? '💳',
                    style: const TextStyle(fontSize: 17, height: 1.0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    wallet.nom ?? 'Portefeuille',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : TAPAColors.navy,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      size: 18, color: TAPAColors.gold),
              ],
            ),
            Text(
              Fmt.montant(wallet.solde, monnaie: monnaie),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? TAPAColors.gold : TAPAColors.textSecond,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallets(String monnaie, bool blocked) {
    if (!_transitionReady) return _skeleton(height: 92);
    if (_wallets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: const Text(
          'Aucun portefeuille',
          style: TextStyle(color: TAPAColors.textSecond, fontSize: 14),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildWalletCard(_wallets[i], monnaie, blocked),
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _anim,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? TAPAColors.navy : TAPAColors.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? TAPAColors.gold : TAPAColors.textSecond,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : TAPAColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDate(bool blocked) {
    final now = DateTime.now();
    final isToday = _sameDay(_date, now);
    final isYesterday = _sameDay(_date, now.subtract(const Duration(days: 1)));
    final isCustom = !isToday && !isYesterday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _dateChip(
            label: 'Aujourd\'hui',
            selected: isToday,
            onTap: blocked ? null : () => setState(() => _date = now),
          ),
          _dateChip(
            label: 'Hier',
            selected: isYesterday,
            onTap: blocked
                ? null
                : () => setState(
                    () => _date = now.subtract(const Duration(days: 1))),
          ),
          _dateChip(
            label: isCustom ? Fmt.dateComplete(_date) : 'Autre date',
            icon: Icons.calendar_today_outlined,
            selected: isCustom,
            onTap: blocked ? null : _pickDate,
          ),
        ],
      ),
    );
  }

  Widget _buildNote(bool blocked) {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        controller: _noteCtrl,
        enabled: !blocked,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 14.5, color: TAPAColors.navy),
        decoration: InputDecoration(
          hintText: 'Ajouter une note  (ex : Courses supermarché)',
          hintStyle: const TextStyle(
            color: TAPAColors.textHint,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: TAPAColors.gold, width: 1.5),
          ),
          filled: true,
          fillColor: TAPAColors.surface,
          contentPadding: const EdgeInsets.all(18),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              Icons.edit_note_rounded,
              color: TAPAColors.textHint,
              size: 22,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  Widget _buildBlockedBanner(bool noWallets) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TAPAColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noWallets
                  ? 'Créez d\'abord un portefeuille'
                  : 'Aucune catégorie disponible',
              style: const TextStyle(
                color: TAPAColors.red,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool blocked, Color accent) {
    final isRevenu = _type == TransactionType.revenu;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (blocked || _saving) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withOpacity(0.4),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: AnimatedSwitcher(
              duration: _anim,
              child: _saving
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: ValueKey(isRevenu),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isRevenu
                              ? Icons.add_circle_outline_rounded
                              : Icons.remove_circle_outline_rounded,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isRevenu
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
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ✅ On écoute les catégories en temps réel
    // ✅ Utiliser le StreamProvider temps réel
    final dynamicCatsAsync = ref.watch(dynamicCategoriesProvider);
    final allCats = dynamicCatsAsync.valueOrNull ?? [];
    // Filtrer selon le type (depense ou revenu)
    final typeFilter = _type == TransactionType.revenu ? 'revenu' : 'depense';
    _categories = allCats.where((c) => c['type'] == typeFilter).toList();

    final monnaie = ref.watch(userMonnaieProvider);
    final filteredCats = _filteredCats;
    final noWallets = _wallets.isEmpty;
    final noCats = filteredCats.isEmpty;
    final blocked = noWallets || noCats;
    final accent =
        _type == TransactionType.revenu ? TAPAColors.green : TAPAColors.red;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Nouvelle transaction',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(false),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(blocked, accent),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(monnaie, blocked),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (blocked) _buildBlockedBanner(noWallets),
                        _sectionTitle('Catégorie'),
                        _buildCategories(filteredCats, accent),
                        const SizedBox(height: 24),
                        _sectionTitle('Portefeuille'),
                        _buildWallets(monnaie, blocked),
                        const SizedBox(height: 24),
                        _sectionTitle('Date'),
                        _buildDate(blocked),
                        const SizedBox(height: 24),
                        _sectionTitle('Note',
                            trailing: const Text(
                              'Optionnelle',
                              style: TextStyle(
                                fontSize: 12,
                                color: TAPAColors.textHint,
                              ),
                            )),
                        _buildNote(blocked),
                      ],
                    ),
                  ),
                ],
              ),
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
