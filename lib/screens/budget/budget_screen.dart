// lib/screens/budget/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../services/db_service_mysql.dart';
import '../../models/budget_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
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
        title: const Text('Budget'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
          ? FloatingActionButton(
        backgroundColor: TAPAColors.navy,
        onPressed: _ouvrirEditeur,
        child: const Icon(Icons.edit, color: Colors.white),
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
          height: 420,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pie_chart_outline,
                  size: 60,
                  color: TAPAColors.textHint,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Budget',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun budget pour $_moisLabel.\nCréez-en un pour suivre\nvos dépenses et revenus',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TAPAColors.textSecond),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _ouvrirEditeur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text(
                    'Commencer le budget',
                    style: TextStyle(color: TAPAColors.white),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Dépenses prévues',
                  prevu: budget.totalDepensesPrevu,
                  reel: reelDepenses,
                  color: TAPAColors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (budget.depenses.isNotEmpty) ...[
          _sectionTitle('Dépenses'),
          ...budget.depenses.map((l) => _buildLigne(l)),
        ],
        if (budget.revenus.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sectionTitle('Revenus'),
          ...budget.revenus.map((l) => _buildLigne(l)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: TAPAColors.textSecond,
        ),
      ),
    );
  }

  Widget _buildLigne(BudgetLigne ligne) {
    final reel = _reelParCategorie[ligne.categorieId] ?? 0;
    final prevu = ligne.montantPrevu;
    final progression = prevu > 0 ? (reel / prevu).clamp(0.0, 1.0) : 0.0;
    final depasse = prevu > 0 && reel > prevu;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ligne.categorieEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ligne.categorieLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: TAPAColors.navy),
                ),
              ),
              Text(
                '${reel.toStringAsFixed(0)} / ${prevu.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: depasse ? TAPAColors.red : TAPAColors.textSecond,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 6,
              backgroundColor: TAPAColors.border,
              color: depasse
                  ? TAPAColors.red
                  : (ligne.isRevenu ? TAPAColors.green : TAPAColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: TAPAColors.navy),
            onPressed: () => _changerMois(-1),
          ),
          Text(
            _moisLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, color: TAPAColors.navy),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: TAPAColors.navy),
            onPressed: () => _changerMois(1),
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

/// Feuille modale pour créer ou modifier le budget d'un mois donné :
/// un champ montant par catégorie (dépenses puis revenus).
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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: TAPAColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              widget.existant == null ? 'Créer le budget' : 'Modifier le budget',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              BudgetMensuel(id: '', mois: widget.mois, annee: widget.annee, lignes: const []).moisLabel,
              style: const TextStyle(color: TAPAColors.textSecond, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (depenses.isNotEmpty) ...[
                    const Text('Dépenses',
                        style: TextStyle(fontWeight: FontWeight.w700, color: TAPAColors.textSecond)),
                    const SizedBox(height: 8),
                    ...depenses.map(_buildCategoryField),
                    const SizedBox(height: 16),
                  ],
                  if (revenus.isNotEmpty) ...[
                    const Text('Revenus',
                        style: TextStyle(fontWeight: FontWeight.w700, color: TAPAColors.textSecond)),
                    const SizedBox(height: 8),
                    ...revenus.map(_buildCategoryField),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: TAPAColors.navy)),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _controllers[id],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double prevu;
  final double reel;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.prevu,
    required this.reel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: TAPAColors.textSecond)),
          const SizedBox(height: 6),
          Text(
            reel.toStringAsFixed(0),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            'sur ${prevu.toStringAsFixed(0)} prévu',
            style: const TextStyle(fontSize: 11, color: TAPAColors.textSecond),
          ),
        ],
      ),
    );
  }
}