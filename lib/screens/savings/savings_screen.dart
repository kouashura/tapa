// lib/screens/savings/savings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/auth_provider.dart';
// ✅ IMPORT DEPUIS lib/models/
import '../../models/models.dart';
import '../../models/epargne_programmee_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  int _selectedIndex = 2;
  List<SavingsGoalModel> _goals = [];
  List<EpargneProgrammeeModel> _epargnes = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    // TODO: Remplacer par des providers
    // _goals = await ref.read(savingsGoalListProvider.future);
    // _epargnes = await ref.read(epargneProgrammeeListProvider.future);
    setState(() {});
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final totalEpargne = _goals.fold<double>(0.0, (sum, g) => sum + g.montantActuel);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Épargne'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: TAPAColors.gold),
            onPressed: () async {
              await context.push('/savings/add');
              _charger();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TAPAColors.navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL ÉPARGNÉ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Fmt.montant(totalEpargne, monnaie: monnaie),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_goals.length} objectifs · ${_epargnes.length} programmées',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_goals.isNotEmpty) ...[
            const Text(
              'Objectifs d\'épargne',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            ..._goals.map((g) => _goalCard(g, monnaie)),
            const SizedBox(height: 16),
          ],
          if (_epargnes.isNotEmpty) ...[
            const Text(
              'Épargne programmée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            ..._epargnes.map((e) => _epargneCard(e, monnaie)),
            const SizedBox(height: 16),
          ],
          if (_goals.isEmpty && _epargnes.isEmpty) ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.savings_outlined, size: 48, color: TAPAColors.textSecond),
                  SizedBox(height: 12),
                  Text(
                    'Commencez à épargner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TAPAColors.navy,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Créez un objectif ou une épargne programmée',
                    style: TextStyle(color: TAPAColors.textSecond),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _goalCard(SavingsGoalModel goal, String monnaie) {
    final progress = goal.montantCible > 0
        ? (goal.montantActuel / goal.montantCible).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAPAColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy,
                  ),
                ),
              ),
              Text(
                Fmt.montant(goal.montantActuel, monnaie: monnaie),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: TAPAColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(TAPAColors.gold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Objectif: ${Fmt.montant(goal.montantCible, monnaie: monnaie)}',
            style: const TextStyle(
              fontSize: 11,
              color: TAPAColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }

  Widget _epargneCard(EpargneProgrammeeModel epargne, String monnaie) {
    final progress = epargne.montantObjectif > 0
        ? (epargne.montantEpargne / epargne.montantObjectif).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: epargne.termine
              ? TAPAColors.green
              : TAPAColors.border,
          width: epargne.termine ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      epargne.titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TAPAColors.navy,
                      ),
                    ),
                    if (epargne.verrouille) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, size: 14, color: TAPAColors.red),
                    ],
                    if (epargne.termine) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle, size: 14, color: TAPAColors.green),
                    ],
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: TAPAColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                epargne.termine ? TAPAColors.green : TAPAColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Fmt.montant(epargne.montantEpargne, monnaie: monnaie)} / ${Fmt.montant(epargne.montantObjectif, monnaie: monnaie)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: TAPAColors.textSecond,
                ),
              ),
              Text(
                epargne.descriptionFrequence,
                style: const TextStyle(
                  fontSize: 11,
                  color: TAPAColors.textSecond,
                ),
              ),
            ],
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