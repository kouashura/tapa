// lib/screens/savings/savings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  int _selectedIndex = 2;

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    final goalsAsync = ref.watch(userSavingsGoalsProvider(userId));
    final epargnesAsync = ref.watch(userEpargneProgrammeeProvider(userId));

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text(
          'Enveloppe',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Ajouter',
              style: IconButton.styleFrom(
                backgroundColor: TAPAColors.gold.withOpacity(0.18),
              ),
              icon: const Icon(Icons.add, color: TAPAColors.gold),
              onPressed: () async {
                await context.push('/savings/add');
              },
            ),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TAPAColors.gold),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: TAPAColors.red),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger vos enveloppes.\n$err',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TAPAColors.red),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(userSavingsGoalsProvider(userId)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (goals) {
          final epargnes = epargnesAsync.valueOrNull ?? [];
          final totalEpargne = goals.fold<double>(
            0.0,
                (sum, g) => sum + g.montantActuel,
          );

          return RefreshIndicator(
            color: TAPAColors.gold,
            onRefresh: () async {
              ref.invalidate(userSavingsGoalsProvider(userId));
              ref.invalidate(userEpargneProgrammeeProvider(userId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _heroCard(
                  total: totalEpargne,
                  nbGoals: goals.length,
                  nbEpargnes: epargnes.length,
                  monnaie: monnaie,
                ),
                const SizedBox(height: 24),
                if (goals.isNotEmpty) ...[
                  _sectionHeader('Objectifs d\'enveloppe', goals.length),
                  const SizedBox(height: 12),
                  ...goals.map((g) => _goalCard(g, monnaie)),
                  const SizedBox(height: 12),
                ],
                if (epargnes.isNotEmpty) ...[
                  _sectionHeader('Enveloppe programmée', epargnes.length),
                  const SizedBox(height: 12),
                  ...epargnes.map((e) => _epargneCard(e, monnaie)),
                  const SizedBox(height: 12),
                ],
                if (goals.isEmpty && epargnes.isEmpty) _emptyState(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ───────────────────────── Carte principale ─────────────────────────

  Widget _heroCard({
    required double total,
    required int nbGoals,
    required int nbEpargnes,
    required String monnaie,
  }) {
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
            // Décor : cercles coupés par le ClipRRect (aucun débordement)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TAPAColors.gold.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
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
                      const Expanded(
                        child: Text(
                          'Total ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // FittedBox : le montant réduit sa taille au lieu de déborder
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.montant(total, monnaie: monnaie),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _heroStat(
                          icon: Icons.flag_outlined,
                          value: '$nbGoals',
                          label: nbGoals > 1 ? 'Objectifs' : 'Objectif',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _heroStat(
                          icon: Icons.autorenew,
                          value: '$nbEpargnes',
                          label: nbEpargnes > 1 ? 'Programmées' : 'Programmée',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TAPAColors.gold),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TAPAColors.white,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Sections ─────────────────────────

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: TAPAColors.navy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({Color? borderColor, double borderWidth = 0.8}) {
    return BoxDecoration(
      color: TAPAColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: borderColor ?? TAPAColors.border,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: TAPAColors.navy.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // ───────────────────────── Objectif d'épargne ─────────────────────────

  Widget _goalCard(SavingsGoalModel goal, String monnaie) {
    final progress = goal.montantCible > 0
        ? (goal.montantActuel / goal.montantCible).clamp(0.0, 1.0)
        : 0.0;
    final reste = (goal.montantCible - goal.montantActuel);
    final atteint = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        borderColor: atteint ? TAPAColors.green : null,
        borderWidth: atteint ? 1.5 : 0.8,
      ),
      child: Row(
        children: [
          // Anneau de progression
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: TAPAColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      atteint ? TAPAColors.green : TAPAColors.gold,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        goal.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy,
                        ),
                      ),
                    ),
                    if (atteint) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle,
                          size: 16, color: TAPAColors.green),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.montant(goal.montantActuel, monnaie: monnaie),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atteint
                      ? 'Objectif atteint : ${Fmt.montant(goal.montantCible, monnaie: monnaie)}'
                      : 'Reste ${Fmt.montant(reste, monnaie: monnaie)} sur ${Fmt.montant(goal.montantCible, monnaie: monnaie)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TAPAColors.textSecond,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Épargne programmée ─────────────────────────

  Widget _epargneCard(EpargneProgrammeeModel epargne, String monnaie) {
    final progress = epargne.montantObjectif > 0
        ? (epargne.montantEpargne / epargne.montantObjectif).clamp(0.0, 1.0)
        : 0.0;
    final accent = epargne.termine ? TAPAColors.green : TAPAColors.gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        borderColor: epargne.termine ? TAPAColors.green : null,
        borderWidth: epargne.termine ? 1.5 : 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  epargne.termine ? Icons.check : Icons.autorenew,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            epargne.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TAPAColors.navy,
                            ),
                          ),
                        ),
                        if (epargne.verrouille) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock,
                              size: 14, color: TAPAColors.red),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      epargne.descriptionFrequence,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: epargne.termine
                        ? TAPAColors.green
                        : TAPAColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: TAPAColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.montant(epargne.montantEpargne, monnaie: monnaie),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'sur ${Fmt.montant(epargne.montantObjectif, monnaie: monnaie)}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TAPAColors.textSecond,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── État vide ─────────────────────────

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TAPAColors.gold.withOpacity(0.15),
            ),
            child: const Icon(Icons.savings_outlined,
                size: 42, color: TAPAColors.gold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Commencez ton objectif',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Créez un objectif ',
            textAlign: TextAlign.center,
            style: TextStyle(color: TAPAColors.textSecond, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              foregroundColor: TAPAColors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => context.push('/savings/add'),
            icon: const Icon(Icons.add, color: TAPAColors.gold, size: 18),
            label: const Text('Nouvel objectif'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Navigation basse ─────────────────────────

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Row(
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
              width: isActive ? 46 : 38,
              height: 32,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(16),
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
                size: 20,
                color: isActive ? Colors.amber : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            // FittedBox : le libellé rétrécit au lieu de déborder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1A237E)
                        : Colors.grey.shade500,
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