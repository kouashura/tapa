// lib/screens/budget/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';  // ✅ CHEMIN CORRIGÉ
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../presentation/providers/app_state.dart';  // ✅ AJOUTÉ
import '../../services/db_service_mysql.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../core/utils/logger.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final DBService _db = DBService();
  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;
  int _selectedIndex = 3;

  bool _loading = true;
  BudgetMensuel? _budget;
  Map<String, double> _reelParCategorie = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  String get _moisLabel =>
      BudgetMensuel(id: '', mois: _mois, annee: _annee, lignes: const []).moisLabel;

  Future<void> _charger() async {
    setState(() => _loading = true);

    final budget = await _db.getBudget(_mois, _annee);
    final reel = <String, double>{};

    if (budget != null) {
      final montants = await Future.wait(
        budget.lignes.map((l) => _db.getDepensesReellesByCategorie(l.categorieId, _mois, _annee)),
      );
      for (var i = 0; i < budget.lignes.length; i++) {
        reel[budget.lignes[i].categorieId] = montants[i];
      }
    }

    if (!mounted) return;
    setState(() {
      _budget = budget;
      _reelParCategorie = reel;
      _loading = false;
    });
  }

  void _changerMois(int delta) {
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

  Future<void> _ouvrirEditeur() async {
    final categories = _db.getCategories();
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune catégorie disponible'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final resultat = await showModalBottomSheet<BudgetMensuel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetEditorSheet(
        mois: _mois,
        annee: _annee,
        categories: categories,
        existant: _budget,
      ),
    );

    if (resultat != null) {
      await _db.saveBudget(resultat);
      _charger();
    }
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Budget',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        elevation: 0,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _charger,
        child: _budget == null ? _buildEmptyState() : _buildBudgetState(),
      ),
      floatingActionButton: _budget != null
          ? FloatingActionButton.extended(
        backgroundColor: TAPAColors.navy,
        elevation: 3,
        onPressed: _ouvrirEditeur,
        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
        label: const Text(
          'Modifier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        _buildMonthSelector(),
        SizedBox(
          height: 440,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: TAPAColors.navy.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 38,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun budget ce mois-ci',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez le budget de $_moisLabel pour suivre\nvos dépenses et revenus au fil du mois',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TAPAColors.textSecond, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _ouvrirEditeur,
                  icon: const Icon(Icons.add, size: 18, color: TAPAColors.white),
                  label: const Text(
                    'Commencer le budget',
                    style: TextStyle(
                      color: TAPAColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetState() {
    final budget = _budget!;
    final reelDepenses = budget.depenses.fold<double>(
      0.0,
          (sum, l) => sum + (_reelParCategorie[l.categorieId] ?? 0),
    );
    final reelRevenus = budget.revenus.fold<double>(
      0.0,
          (sum, l) => sum + (_reelParCategorie[l.categorieId] ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildMonthSelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Revenus prévus',
                  prevu: budget.totalRevenusPrevu,
                  reel: reelRevenus,
                  color: TAPAColors.green,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Dépenses prévues',
                  prevu: budget.totalDepensesPrevu,
                  reel: reelDepenses,
                  color: TAPAColors.red,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (budget.depenses.isNotEmpty) ...[
          _sectionTitle('Dépenses', budget.depenses.length),
          ...budget.depenses.map((l) => _buildLigne(l)),
        ],
        if (budget.revenus.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Revenus', budget.revenus.length),
          ...budget.revenus.map((l) => _buildLigne(l)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: TAPAColors.border),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TAPAColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLigne(BudgetLigne ligne) {
    final reel = _reelParCategorie[ligne.categorieId] ?? 0;
    final prevu = ligne.montantPrevu;
    final progression = prevu > 0 ? (reel / prevu).clamp(0.0, 1.0) : 0.0;
    final depasse = prevu > 0 && reel > prevu;
    final accentColor = depasse
        ? TAPAColors.red
        : (ligne.isRevenu ? TAPAColors.green : TAPAColors.navy);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(ligne.categorieEmoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ligne.categorieLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: TAPAColors.navy,
                      ),
                    ),
                    if (depasse) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Budget dépassé',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reel.toStringAsFixed(0),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    '/ ${prevu.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: TAPAColors.textHint),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 7,
              backgroundColor: TAPAColors.background,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _monthNavButton(Icons.chevron_left, () => _changerMois(-1)),
          Column(
            children: [
              Text(
                _moisLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SUIVI MENSUEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: TAPAColors.textHint,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          _monthNavButton(Icons.chevron_right, () => _changerMois(1)),
        ],
      ),
    );
  }

  Widget _monthNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: TAPAColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: TAPAColors.navy, size: 22),
        ),
      ),
    );
  }

  // ==========================================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ==========================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                index: 0,
                route: '/home',
              ),
              _buildNavItem(
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield,
                label: 'Assurance',
                index: 1,
                route: '/investir/assurance',
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet,
                label: 'Enveloppe',
                index: 2,
                route: '/savings',
              ),
              _buildNavItem(
                icon: Icons.pie_chart_outline,
                activeIcon: Icons.pie_chart,
                label: 'Budget',
                index: 3,
                route: '/budget',
              ),
              _buildNavItem(
                icon: Icons.credit_card_outlined,
                activeIcon: Icons.credit_card,
                label: 'Dettes',
                index: 4,
                route: '/dettes',
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 5,
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String route,
  }) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateTo(route, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 0,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 22 : 20,
                color: isActive ? Colors.amber : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF1A237E) : Colors.grey.shade500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// BUDGET EDITOR SHEET
// ==========================================================

class _BudgetEditorSheet extends StatefulWidget {
  final int mois;
  final int annee;
  final List<Map<String, dynamic>> categories;
  final BudgetMensuel? existant;

  const _BudgetEditorSheet({
    required this.mois,
    required this.annee,
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
      final existingLigne = widget.existant?.lignes.firstWhere(
            (l) => l.categorieId == id,
        orElse: () => BudgetLigne(
          id: '',
          categorieId: id,
          categorieLabel: '',
          categorieEmoji: '',
          montantPrevu: 0,
          isRevenu: false,
        ),
      );
      final montant = existingLigne?.montantPrevu ?? 0;
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
        const SnackBar(
          content: Text('Renseignez au moins un montant'),
          backgroundColor: TAPAColors.red,
        ),
      );
      return;
    }

    final budget = BudgetMensuel(
      id: widget.existant?.id ?? Fmt.genId(),
      mois: widget.mois,
      annee: widget.annee,
      lignes: lignes,
    );
    Navigator.of(context).pop(budget);
  }

  @override
  Widget build(BuildContext context) {
    final depenses = widget.categories.where((c) => c['type'] == 'depense').toList();
    final revenus = widget.categories.where((c) => c['type'] == 'revenu').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: TAPAColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              widget.existant == null ? 'Créer le budget' : 'Modifier le budget',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: TAPAColors.navy,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              BudgetMensuel(id: '', mois: widget.mois, annee: widget.annee, lignes: const []).moisLabel,
              style: const TextStyle(color: TAPAColors.textSecond, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (depenses.isNotEmpty) ...[
                    Text('DÉPENSES',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                          color: TAPAColors.textHint,
                        )),
                    const SizedBox(height: 10),
                    ...depenses.map(_buildCategoryField),
                    const SizedBox(height: 20),
                  ],
                  if (revenus.isNotEmpty) ...[
                    Text('REVENUS',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                          color: TAPAColors.textHint,
                        )),
                    const SizedBox(height: 10),
                    ...revenus.map(_buildCategoryField),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryField(Map<String, dynamic> cat) {
    final id = cat['id'] as String? ?? '';
    final label = cat['label'] as String? ?? 'Autre';
    final emoji = cat['emoji'] as String? ?? '📌';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TAPAColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: TAPAColors.navy, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _controllers[id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, color: TAPAColors.navy),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                filled: true,
                fillColor: TAPAColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// SUMMARY CARD
// ==========================================================

class _SummaryCard extends StatelessWidget {
  final String label;
  final double prevu;
  final double reel;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.prevu,
    required this.reel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progression = prevu > 0 ? (reel / prevu).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.textSecond,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reel.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'sur ${prevu.toStringAsFixed(0)} prévu',
            style: const TextStyle(fontSize: 11.5, color: TAPAColors.textSecond),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
