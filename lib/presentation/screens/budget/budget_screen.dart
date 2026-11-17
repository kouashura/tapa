// lib/screens/budget/budget_screen.dart

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

// Chiffres de largeur fixe : les montants restent alignés d'une ligne à l'autre.
const _tabular = [FontFeature.tabularFigures()];
// Versions plus claires du vert et du rouge, lisibles sur fond marine.
const _okOnNavy = Color(0xFF5BD9A0);
const _alertOnNavy = Color(0xFFFF8A80);

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
}

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;
  int _selectedIndex = 3;
  bool _loading = true;
  String _monnaie = '';

  static const _navItems = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Accueil', '/home'),
    _NavItem(Icons.shield_outlined, Icons.shield, 'Assurance',
        '/investir/assurance'),
    _NavItem(Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet, 'Enveloppe', '/savings'),
    _NavItem(Icons.pie_chart_outline, Icons.pie_chart, 'Budget', '/budget'),
    _NavItem(
        Icons.credit_card_outlined, Icons.credit_card, 'Dettes', '/dettes'),
    _NavItem(Icons.person_outline, Icons.person, 'Profil', '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _charger();
    });
  }

  String get _moisLabel =>
      BudgetMensuel(id: '', mois: _mois, annee: _annee, lignes: const [])
          .moisLabel;

  String _fmt(num v) => Fmt.montant(v.toDouble(), monnaie: _monnaie);

  Future<void> _charger() async {
    setState(() => _loading = true);
    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await ref.read(budgetStateProvider.notifier).loadBudget(
          uid: uid,
          mois: _mois,
          annee: _annee,
        );
    if (mounted) setState(() => _loading = false);
  }

  void _changerMois(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      int m = _mois + delta;
      int a = _annee;
      if (m > 12) {
        m = 1;
        a++;
      } else if (m < 1) {
        m = 12;
        a--;
      }
      _mois = m;
      _annee = a;
    });
    _charger();
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
  }

  Future<void> _ouvrirEditeur([BudgetMensuel? budgetExistant]) async {
    final categories = ref.read(allCategoriesProvider);
    if (categories.isEmpty) {
      _snack('Aucune catégorie disponible', TAPAColors.red);
      return;
    }

    final resultat = await showModalBottomSheet<BudgetMensuel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetEditorSheet(
        mois: _mois,
        annee: _annee,
        monnaie: _monnaie,
        categories: categories,
        existant: budgetExistant,
      ),
    );
    if (resultat == null) return;

    final uid = ref.read(currentUserProvider)?.id ?? '';
    if (uid.isEmpty) return;

    final isUpdate = budgetExistant != null;
    final success = await ref.read(budgetStateProvider.notifier).saveBudget(
          uid: uid,
          budget: resultat,
          isUpdate: isUpdate,
        );

    if (mounted) {
      success
          ? _snack(
              isUpdate ? 'Budget mis à jour' : 'Budget créé', TAPAColors.green)
          : _snack('Le budget n\'a pas pu être enregistré. Réessayez.',
              TAPAColors.red);
    }
    await _charger();
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    _monnaie = ref.watch(userMonnaieProvider);
    final state = ref.watch(budgetStateProvider);
    final budget = state.currentBudget;
    // Dépenses/revenus réels venant du provider (et non d'une map locale vide).
    final Map<String, num> reel = state.depensesReelles;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Budget',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                children: budget == null
                    ? _emptyChildren()
                    : _budgetChildren(budget, reel),
              ),
            ),
      floatingActionButton: budget != null && !_loading
          ? FloatingActionButton.extended(
              backgroundColor: TAPAColors.gold,
              foregroundColor: TAPAColors.navy,
              elevation: 2,
              onPressed: () => _ouvrirEditeur(budget),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Modifier',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================================
  // HERO (mois + synthèse)
  // ==========================================================

  Widget _heroShell(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      decoration: const BoxDecoration(
        color: TAPAColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(children: [_monthSelector(), ...children]),
    );
  }

  Widget _monthSelector() {
    return Row(
      children: [
        _monthNavButton(Icons.chevron_left_rounded, () => _changerMois(-1)),
        Expanded(
          child: Text(
            _moisLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _monthNavButton(Icons.chevron_right_rounded, () => _changerMois(1)),
      ],
    );
  }

  Widget _monthNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildHero({
    required double prevuDep,
    required double reelDep,
    required double prevuRev,
    required double reelRev,
  }) {
    final restant = prevuDep - reelDep;
    final depasse = prevuDep > 0 && restant < 0;
    final ratio = prevuDep > 0 ? reelDep / prevuDep : 0.0;
    final soft = Colors.white.withOpacity(0.62);

    return _heroShell([
      const SizedBox(height: 26),
      Text(
        depasse ? 'Dépassement du budget' : 'Reste à dépenser',
        style:
            TextStyle(color: soft, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 6),
      Text(
        _fmt(restant.abs()),
        style: TextStyle(
          color: depasse ? _alertOnNavy : Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.5,
          fontFeatures: _tabular,
        ),
      ),
      const SizedBox(height: 18),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
          backgroundColor: Colors.white.withOpacity(0.12),
          color: depasse ? _alertOnNavy : TAPAColors.gold,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${(ratio * 100).round()} % utilisé',
              style: TextStyle(
                  color: soft, fontSize: 12.5, fontWeight: FontWeight.w600)),
          Text('Prévu ${_fmt(prevuDep)}',
              style: TextStyle(
                  color: soft, fontSize: 12.5, fontFeatures: _tabular)),
        ],
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            _heroStat('Revenus reçus', reelRev, prevuRev, _okOnNavy),
            Container(
              width: 1,
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withOpacity(0.12),
            ),
            _heroStat('Dépensé', reelDep, prevuDep, _alertOnNavy),
          ],
        ),
      ),
    ]);
  }

  Widget _heroStat(String label, double reel, double prevu, Color dot) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_fmt(reel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular)),
          const SizedBox(height: 2),
          Text('sur ${_fmt(prevu)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11.5,
                  fontFeatures: _tabular)),
        ],
      ),
    );
  }

  // ==========================================================
  // ÉTATS
  // ==========================================================

  List<Widget> _emptyChildren() {
    return [
      _heroShell(const <Widget>[]),
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: TAPAColors.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.donut_large_rounded,
                  size: 40, color: TAPAColors.navy),
            ),
            const SizedBox(height: 24),
            Text(
              'Pas encore de budget pour $_moisLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fixez un montant par catégorie et voyez ce qu\'il vous reste à dépenser.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TAPAColors.textSecond, height: 1.45),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _ouvrirEditeur(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Créer le budget',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TAPAColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _budgetChildren(BudgetMensuel b, Map<String, num> reel) {
    double somme(Iterable<BudgetLigne> l) => l.fold<double>(
        0.0, (s, x) => s + (reel[x.categorieId] ?? 0).toDouble());

    return [
      _buildHero(
        prevuDep: b.totalDepensesPrevu,
        reelDep: somme(b.depenses),
        prevuRev: b.totalRevenusPrevu,
        reelRev: somme(b.revenus),
      ),
      const SizedBox(height: 20),
      if (b.depenses.isNotEmpty)
        _buildGroup('Dépenses', b.depenses, reel, b.totalDepensesPrevu),
      if (b.revenus.isNotEmpty) ...[
        const SizedBox(height: 16),
        _buildGroup('Revenus', b.revenus, reel, b.totalRevenusPrevu),
      ],
    ];
  }

  // ==========================================================
  // LISTE PAR CATÉGORIE
  // ==========================================================

  Widget _buildGroup(String title, List<BudgetLigne> lignes,
      Map<String, num> reel, double total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TAPAColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TAPAColors.navy)),
                ),
                Text('Prévu ${_fmt(total)}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: TAPAColors.textSecond,
                        fontFeatures: _tabular)),
              ],
            ),
          ),
          for (int i = 0; i < lignes.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: TAPAColors.border),
            _buildLigne(lignes[i], reel),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLigne(BudgetLigne l, Map<String, num> reelMap) {
    final reel = (reelMap[l.categorieId] ?? 0).toDouble();
    final prevu = l.montantPrevu;
    final ratio = prevu > 0 ? reel / prevu : 0.0;
    final depasse = !l.isRevenu && prevu > 0 && reel > prevu;
    final Color color = l.isRevenu
        ? TAPAColors.green
        : (depasse
            ? TAPAColors.red
            : (ratio >= 0.8 ? TAPAColors.gold : TAPAColors.navy));
    final String info = l.isRevenu
        ? (reel >= prevu
            ? 'Objectif atteint'
            : 'Reste ${_fmt(prevu - reel)} à recevoir')
        : (depasse
            ? 'Dépassé de ${_fmt(reel - prevu)}'
            : 'Reste ${_fmt(prevu - reel)}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(l.categorieEmoji,
                    style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.categorieLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: TAPAColors.navy)),
                    const SizedBox(height: 2),
                    Text(info,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFeatures: _tabular,
                            color: depasse
                                ? TAPAColors.red
                                : TAPAColors.textSecond)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_fmt(reel),
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: _tabular,
                      color: depasse ? TAPAColors.red : TAPAColors.navy)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              backgroundColor: color.withOpacity(0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ==========================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TAPAColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < _navItems.length; i++) _buildNavItem(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final active = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateTo(item.route, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                  horizontal: active ? 16 : 0, vertical: 6),
              decoration: BoxDecoration(
                color: active ? TAPAColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                active ? item.activeIcon : item.icon,
                size: 21,
                color: active ? TAPAColors.gold : TAPAColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? TAPAColors.navy : TAPAColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// ÉDITEUR DE BUDGET
// ==========================================================

class _BudgetEditorSheet extends StatefulWidget {
  final int mois;
  final int annee;
  final String monnaie;
  final List<Map<String, dynamic>> categories;
  final BudgetMensuel? existant;

  const _BudgetEditorSheet({
    required this.mois,
    required this.annee,
    required this.monnaie,
    required this.categories,
    required this.existant,
  });

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final cat in widget.categories) {
      final id = cat['id'] as String? ?? '';
      double montant = 0;
      for (final l in widget.existant?.lignes ?? const <BudgetLigne>[]) {
        if (l.categorieId == id) montant = l.montantPrevu;
      }
      _controllers[id] = TextEditingController(
        text: montant > 0 ? montant.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(num v) => Fmt.montant(v.toDouble(), monnaie: widget.monnaie);

  double _total(String type) =>
      widget.categories.where((c) => c['type'] == type).fold<double>(
            0.0,
            (s, c) =>
                s +
                (double.tryParse(
                        _controllers[c['id'] as String? ?? '']?.text ?? '') ??
                    0),
          );

  void _enregistrer() {
    final lignes = <BudgetLigne>[];
    for (final cat in widget.categories) {
      final id = cat['id'] as String? ?? '';
      final montant = double.tryParse(_controllers[id]?.text ?? '') ?? 0;
      if (montant <= 0) continue;
      lignes.add(BudgetLigne(
        id: Fmt.genId(),
        categorieId: id,
        categorieLabel: cat['label'] as String? ?? 'Autre',
        categorieEmoji: cat['emoji'] as String? ?? '📌',
        montantPrevu: montant,
        isRevenu: cat['type'] == 'revenu',
      ));
    }

    if (lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Renseignez au moins un montant',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: TAPAColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    Navigator.of(context).pop(BudgetMensuel(
      id: widget.existant?.id ?? Fmt.genId(),
      mois: widget.mois,
      annee: widget.annee,
      lignes: lignes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final depenses =
        widget.categories.where((c) => c['type'] == 'depense').toList();
    final revenus =
        widget.categories.where((c) => c['type'] == 'revenu').toList();
    final moisLabel = BudgetMensuel(
        id: '',
        mois: widget.mois,
        annee: widget.annee,
        lignes: const []).moisLabel;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: TAPAColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TAPAColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              widget.existant == null
                  ? 'Créer le budget'
                  : 'Modifier le budget',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy),
            ),
            const SizedBox(height: 2),
            Text(moisLabel,
                style: const TextStyle(
                    color: TAPAColors.textSecond, fontSize: 13.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TAPAColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _summaryItem(
                      'Revenus prévus', _total('revenu'), _okOnNavy),
                  const SizedBox(width: 12),
                  _summaryItem(
                      'Dépenses prévues', _total('depense'), _alertOnNavy),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (depenses.isNotEmpty) _section('Dépenses', depenses),
                  if (revenus.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _section('Revenus', revenus),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Enregistrer',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color dot) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(_fmt(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> cats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: TAPAColors.navy)),
        ),
        Container(
          decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TAPAColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < cats.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: TAPAColors.border),
                _buildCategoryField(cats[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(Map<String, dynamic> cat) {
    final id = cat['id'] as String? ?? '';
    final label = cat['label'] as String? ?? 'Autre';
    final emoji = cat['emoji'] as String? ?? '📌';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TAPAColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: TAPAColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          Expanded(
            flex: 5,
            child: TextField(
              controller: _controllers[id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: TAPAColors.navy,
                  fontFeatures: _tabular),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: widget.monnaie,
                suffixStyle: const TextStyle(
                    color: TAPAColors.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                isDense: true,
                filled: true,
                fillColor: TAPAColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: TAPAColors.gold, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
