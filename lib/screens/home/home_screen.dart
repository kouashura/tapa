// lib/presentation/screens/home/home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../presentation/providers/wallet/wallet_provider.dart';
import '../../presentation/providers/transaction/transaction_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import '../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// ============================================
// MÉTRIQUES RESPONSIVES
// ============================================

class _Metrics {
  final bool isTablet;
  final double contentMaxWidth;
  final double horizontalPadding;

  _Metrics(BoxConstraints c)
      : isTablet = c.maxWidth >= 600,
        contentMaxWidth = c.maxWidth >= 900
            ? 640
            : (c.maxWidth >= 600 ? 560 : double.infinity),
        horizontalPadding = c.maxWidth >= 600 ? 8 : 0;
}

// ============================================
// ÉTAT DE L'ÉCRAN HOME
// ============================================

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _soldeVisible = true;
  String _categorieSelectionnee = 'Tous';
  int _selectedIndex = 0;

  static const List<String> _categoriesConnues = [
    'Banque',
    'Cash',
    'MTN',
    'Orange',
    'Wave',
  ];

  // ============================================
  // NAVIGATION
  // ============================================

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  void _refreshData() {
    // Rafraîchir les données via les providers
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.refresh(walletListProvider(userId));
      ref.refresh(transactionListProvider(userId));
    }
  }

  // ============================================
  // CATÉGORIE D'UN PORTEFEUILLE
  // ============================================

  String _categorieDe(WalletModel w) {
    final nom = w.nom.toLowerCase();
    for (final c in _categoriesConnues) {
      if (nom.contains(c.toLowerCase())) return c;
    }
    return 'Autres';
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final monnaie = ref.watch(userMonnaieProvider);
    final prenom = ref.watch(userPrenomProvider);
    final userId = user?.id ?? '';

    // ✅ RÉCUPÉRATION DES DONNÉES VIA RIVERPOD
    final walletsAsync = ref.watch(walletListProvider(userId));
    final transactionsAsync = ref.watch(transactionListProvider(userId));

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: TAPAColors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(color: TAPAColors.textSecond),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (wallets) {
          final transactions = transactionsAsync.when(
            data: (txs) => txs,
            loading: () => <TransactionModel>[],
            error: (_, __) => <TransactionModel>[],
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final m = _Metrics(constraints);
              final isSmall = constraints.maxWidth < 360;
              final fontSize = isSmall ? 12.5 : 14.0;
              final titleSize = isSmall ? 15.0 : 17.0;
              final cardWidth = isSmall ? 140.0 : 172.0;

              // ✅ CALCUL DES TOTAUX
              final totalRevenus = transactions
                  .where((t) => t.isRevenu)
                  .fold(0.0, (s, t) => s + t.montant);
              final totalDepenses = transactions
                  .where((t) => t.isDepense)
                  .fold(0.0, (s, t) => s + t.montant);
              final total = totalRevenus - totalDepenses;

              // ✅ CATÉGORIES DES PORTEFEUILLES
              final categoriesPresentes = _categoriesConnues
                  .where((c) => wallets.any((w) => _categorieDe(w) == c))
                  .toList();
              final aDesAutres = wallets.any((w) => _categorieDe(w) == 'Autres');
              final onglets = ['Tous', ...categoriesPresentes, if (aDesAutres) 'Autres'];

              if (!onglets.contains(_categorieSelectionnee)) {
                _categorieSelectionnee = 'Tous';
              }

              final walletsFiltres = _categorieSelectionnee == 'Tous'
                  ? wallets
                  : wallets.where((w) => _categorieDe(w) == _categorieSelectionnee).toList();

              final Map<String, int> comptesParOnglet = {
                for (final o in onglets)
                  o: o == 'Tous'
                      ? wallets.length
                      : wallets.where((w) => _categorieDe(w) == o).length,
              };

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                color: TAPAColors.gold,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ============================================
                    // SLIVER APP BAR
                    // ============================================
                    SliverAppBar(
                      expandedHeight: 252,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: TAPAColors.navy,
                      automaticallyImplyLeading: false,
                      actions: [
                        _buildCoachButton(context),
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: TAPAColors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              // TODO: Ouvrir les notifications
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _navigateTo('/profile', 5),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    TAPAColors.gold,
                                    TAPAColors.gold.withOpacity(0.4),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: TAPAColors.navy,
                                child: Text(
                                  prenom.isNotEmpty ? prenom[0].toUpperCase() : 'T',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: TAPAColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: ClipRect(
                          child: Stack(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1A2B4A),
                                      TAPAColors.navy,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -70,
                                right: -60,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: TAPAColors.gold.withOpacity(0.14),
                                    ),
                                    child: ClipOval(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 50,
                                          sigmaY: 50,
                                        ),
                                        child: const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: m.contentMaxWidth,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bonjour${prenom.isNotEmpty ? ', $prenom' : ''} !',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            color: Colors.white60,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _soldeVisible
                                                    ? Fmt.montant(total, monnaie: monnaie)
                                                    : '••••••••',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 26 : 30,
                                                  fontWeight: FontWeight.w800,
                                                  color: TAPAColors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(
                                                    () => _soldeVisible = !_soldeVisible,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  _soldeVisible
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: Colors.white54,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Solde total · $monnaie',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: TAPAColors.gold.withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _miniCard(
                                                'Revenus',
                                                Fmt.montant(totalRevenus, monnaie: monnaie),
                                                TAPAColors.green,
                                                Icons.trending_up_rounded,
                                                isSmall,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _miniCard(
                                                'Dépenses',
                                                Fmt.montant(totalDepenses, monnaie: monnaie),
                                                TAPAColors.red,
                                                Icons.trending_down_rounded,
                                                isSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      title:  RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'TAPA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: TAPAColors.gold,
                              ),
                            ),
                            TextSpan(
                              text: ' Budget',
                              style: TextStyle(
                                fontSize: 16,
                                color: TAPAColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ============================================
                    // CONTENU PRINCIPAL
                    // ============================================
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: TAPAColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: m.contentMaxWidth + 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),

                                // --- Portefeuilles ---
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Mes portefeuilles',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          color: TAPAColors.navy,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          await context.push('/transfer');
                                          _refreshData();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: TAPAColors.navy,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.swap_horiz_rounded,
                                                size: 12,
                                                color: TAPAColors.gold,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Transférer',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: TAPAColors.gold,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- Filtres catégories ---
                                if (onglets.length > 1)
                                  SizedBox(
                                    height: 42,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      itemCount: onglets.length,
                                      itemBuilder: (ctx, i) => _ongletCategorie(
                                        onglets[i],
                                        _categorieSelectionnee == onglets[i],
                                        comptesParOnglet[onglets[i]] ?? 0,
                                      ),
                                    ),
                                  ),

                                if (onglets.length > 1) const SizedBox(height: 10),

                                // --- Liste des portefeuilles ---
                                SizedBox(
                                  height: 72,
                                  child: walletsFiltres.isEmpty
                                      ? const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Center(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Aucun portefeuille',
                                          style: TextStyle(
                                            color: TAPAColors.textSecond,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    itemCount: walletsFiltres.length,
                                    itemBuilder: (ctx, i) => _walletCard(
                                      walletsFiltres[i],
                                      monnaie,
                                      cardWidth,
                                      isSmall,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // --- Graphique des dépenses ---
                                _graphiqueDepenses(monnaie, isSmall, transactions),

                                // --- Transactions ---
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Transactions',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          color: TAPAColors.navy,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => context.go('/history'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: TAPAColors.navy.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'Voir tout',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: TAPAColors.navy,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- Liste des transactions ---
                                if (transactions.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 36,
                                            color: TAPAColors.textHint,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Aucune transaction',
                                            style: TextStyle(
                                              color: TAPAColors.textSecond,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: TAPAColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: TAPAColors.border,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: transactions
                                          .take(10)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => _txTile(
                                          e.value,
                                          e.key == transactions.length - 1 ||
                                              e.key == 9,
                                          wallets,
                                          monnaie,
                                          isSmall,
                                        ),
                                      )
                                          .toList(),
                                    ),
                                  ),

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: () async {
              await context.push('/scanner');
              _refreshData();
            },
            mini: true,
            backgroundColor: Colors.green,
            elevation: 4,
            child: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'mic',
            onPressed: () async {
              await context.push('/voice-transaction');
              _refreshData();
            },
            mini: true,
            backgroundColor: Colors.amber,
            elevation: 4,
            child: const Icon(
              Icons.mic,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              await context.push('/add-transaction');
              _refreshData();
            },
            backgroundColor: const Color(0xFF1A237E),
            elevation: 6,
            child: const Icon(
              Icons.add,
              color: Colors.amber,
              size: 28,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ============================================

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

  // ============================================
  // WIDGET COACH BUTTON
  // ============================================

  Widget _buildCoachButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/coach'),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TAPAColors.gold, TAPAColors.gold.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: TAPAColors.gold.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯', style: TextStyle(fontSize: 12)),
            SizedBox(width: 4),
            Text(
              'Coach',
              style: TextStyle(
                color: TAPAColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WIDGET CATÉGORIE
  // ============================================

  IconData _iconeCategorie(String label) {
    switch (label) {
      case 'Tous':
        return Icons.apps_rounded;
      case 'Banque':
        return Icons.account_balance_rounded;
      case 'Cash':
        return Icons.payments_rounded;
      case 'MTN':
        return Icons.sim_card_rounded;
      case 'Orange':
        return Icons.wifi_tethering_rounded;
      case 'Wave':
        return Icons.waves_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _couleurCategorie(String label) {
    switch (label) {
      case 'Tous':
        return TAPAColors.navy;
      case 'Banque':
        return TAPAColors.navy;
      case 'Cash':
        return TAPAColors.green;
      case 'MTN':
        return const Color(0xFFFFCC00);
      case 'Orange':
        return const Color(0xFFFF7900);
      case 'Wave':
        return const Color(0xFF1DC8F2);
      default:
        return TAPAColors.purple;
    }
  }

  Widget _ongletCategorie(String label, bool selected, int count) {
    final Color couleur = _couleurCategorie(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _categorieSelectionnee = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.only(left: 6, right: 12, top: 4, bottom: 4),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [TAPAColors.navy, Color(0xFF1A2B4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : TAPAColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? TAPAColors.navy : TAPAColors.border,
              width: 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: TAPAColors.navy.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? TAPAColors.gold.withOpacity(0.18)
                      : couleur.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconeCategorie(label),
                  size: 12,
                  color: selected ? TAPAColors.gold : couleur,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? TAPAColors.gold : TAPAColors.navy,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.14)
                        : couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white70 : couleur,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGET MINI CARD
  // ============================================

  Widget _miniCard(
      String label,
      String valeur,
      Color color,
      IconData icone,
      bool isSmall,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9.5, color: Colors.white60),
                ),
                Text(
                  valeur,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGET PORTEFEUILLE
  // ============================================

  Widget _walletCard(
      WalletModel w,
      String monnaie,
      double cardWidth,
      bool isSmall,
      ) {
    final bool isMtn = w.nom.toLowerCase().contains('mtn');
    final bool isOrange = w.nom.toLowerCase().contains('orange');

    return GestureDetector(
      onLongPress: () => _modifierSolde(w, monnaie),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 10, left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isMtn
              ? const Color(0xFFFFCC00).withOpacity(0.15)
              : isOrange
              ? const Color(0xFFFF7900).withOpacity(0.15)
              : TAPAColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: w.estPresqueVide
                ? TAPAColors.red
                : isMtn
                ? const Color(0xFFFFCC00).withOpacity(0.5)
                : isOrange
                ? const Color(0xFFFF7900).withOpacity(0.5)
                : TAPAColors.border,
            width: w.estPresqueVide ? 1.5 : (isMtn || isOrange ? 1.5 : 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: (isMtn
                  ? const Color(0xFFFFCC00)
                  : isOrange
                  ? const Color(0xFFFF7900)
                  : TAPAColors.navy)
                  .withOpacity(isMtn || isOrange ? 0.12 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isMtn
                    ? const Color(0xFFFFCC00)
                    : isOrange
                    ? const Color(0xFFFF7900)
                    : TAPAColors.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isMtn
                    ? const Text(
                  'MTN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003366),
                  ),
                )
                    : isOrange
                    ? const Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  w.emoji,
                  style: TextStyle(fontSize: isSmall ? 14 : 17),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    w.nom,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMtn || isOrange
                          ? TAPAColors.navy
                          : TAPAColors.textSecond,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _soldeVisible
                        ? Fmt.montant(w.solde, monnaie: monnaie)
                        : '•••',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: w.estPresqueVide
                          ? TAPAColors.red
                          : isMtn
                          ? const Color(0xFF003366)
                          : isOrange
                          ? const Color(0xFFCC5500)
                          : TAPAColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (w.estPresqueVide)
              const Icon(Icons.warning_rounded, size: 12, color: TAPAColors.red)
            else
              const Icon(Icons.edit_outlined, size: 11, color: TAPAColors.textHint),
          ],
        ),
      ),
    );
  }

  void _modifierSolde(WalletModel w, String monnaie) {
    final ctrl = TextEditingController(text: w.solde.round().toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TAPAColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TAPAColors.goldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(w.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Modifier ${w.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau solde',
                  suffixText: monnaie,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nouveau = double.tryParse(ctrl.text) ?? w.solde;
                    // TODO: Implémenter la mise à jour du solde via provider
                    Navigator.pop(ctx);
                    _refreshData();
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: TAPAColors.textSecond),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // GRAPHIQUE DES DÉPENSES
  // ============================================

  Widget _graphiqueDepenses(
      String monnaie,
      bool isSmall,
      List<TransactionModel> txs,
      ) {
    if (txs.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final transactionsMois = txs.where((tx) =>
    tx.dateTransaction.month == now.month &&
        tx.dateTransaction.year == now.year &&
        tx.isDepense).toList();

    if (transactionsMois.isEmpty) return const SizedBox();

    final Map<String, double> par = {};
    for (final tx in transactionsMois) {
      par[tx.categorieLabel] = (par[tx.categorieLabel] ?? 0) + tx.montant;
    }
    final total = par.values.fold(0.0, (s, v) => s + v);
    final top = (par.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .toList();
    final List<Color> colors = [
      TAPAColors.red,
      TAPAColors.amber,
      TAPAColors.purple,
      TAPAColors.navy,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TAPAColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: TAPAColors.amberLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 14,
                  color: TAPAColors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Dépenses',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TAPAColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Mois',
                  style: TextStyle(
                    fontSize: 9,
                    color: TAPAColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...top.toList().asMap().entries.map((e) {
            final pct = total > 0 ? e.value.value / total : 0.0;
            final Color color = colors[e.key % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        e.value.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.montant(e.value.value, monnaie: monnaie),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: TAPAColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================
  // TUILE DE TRANSACTION
  // ============================================

  Widget _txTile(
      TransactionModel tx,
      bool isLast,
      List<WalletModel> wallets,
      String monnaie,
      bool isSmall,
      ) {
    final wallet = wallets.isNotEmpty
        ? wallets.first
        : WalletModel(
      id: '',
      uid: '',
      nom: 'Inconnu',
      emoji: '💰',
      type: 'compte',
      solde: 0,
      monnaie: monnaie,
      description: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: TAPAColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tx.isRevenu ? TAPAColors.greenLight : TAPAColors.redLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                tx.categorieEmoji,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.categorieLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                Text(
                  '${wallet.emoji} ${wallet.nom} · ${Fmt.dateRelative(tx.dateTransaction)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: TAPAColors.textSecond,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isRevenu ? "+" : "-"}${Fmt.montant(tx.montant, monnaie: monnaie)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tx.isRevenu ? TAPAColors.green : TAPAColors.red,
            ),
          ),
        ],
      ),
    );
  }
}