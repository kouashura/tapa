// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';

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
  final bool isSmall;
  final double contentMaxWidth;

  _Metrics(BoxConstraints c)
      : isTablet = c.maxWidth >= 600,
        isSmall = c.maxWidth < 360,
        contentMaxWidth = c.maxWidth >= 900
            ? 680
            : (c.maxWidth >= 600 ? 600 : double.infinity);
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

  static const Color _mtn = Color(0xFFFFCC00);
  static const Color _orange = Color(0xFFFF7900);
  static const Color _wave = Color(0xFF1DC8F2);

  // ============================================
  // NAVIGATION & DONNÉES
  // ============================================

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  void _refreshData() {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.invalidate(walletListProvider(userId));
      ref.invalidate(transactionListProvider(userId));
    }
  }

  Future<void> _pushAndRefresh(String route) async {
    await context.push(route);
    if (mounted) _refreshData();
  }

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

    final walletsAsync = ref.watch(walletListProvider(userId));
    final transactionsAsync = ref.watch(transactionListProvider(userId));

    return Scaffold(
      backgroundColor: TAPAColors.navy,
      body: walletsAsync.when(
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
                    size: 48, color: TAPAColors.gold),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de charger vos données',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TAPAColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TAPAColors.gold,
                    foregroundColor: TAPAColors.navy,
                  ),
                  onPressed: _refreshData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
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

              final totalRevenus = transactions
                  .where((t) => t.isRevenu)
                  .fold(0.0, (s, t) => s + t.montant);
              final totalDepenses = transactions
                  .where((t) => t.isDepense)
                  .fold(0.0, (s, t) => s + t.montant);
              final total = totalRevenus - totalDepenses;

              final categoriesPresentes = _categoriesConnues
                  .where((c) => wallets.any((w) => _categorieDe(w) == c))
                  .toList();
              final aDesAutres =
              wallets.any((w) => _categorieDe(w) == 'Autres');
              final onglets = [
                'Tous',
                ...categoriesPresentes,
                if (aDesAutres) 'Autres',
              ];

              if (!onglets.contains(_categorieSelectionnee)) {
                _categorieSelectionnee = 'Tous';
              }

              final walletsFiltres = _categorieSelectionnee == 'Tous'
                  ? wallets
                  : wallets
                  .where((w) => _categorieDe(w) == _categorieSelectionnee)
                  .toList();

              final comptesParOnglet = <String, int>{
                for (final o in onglets)
                  o: o == 'Tous'
                      ? wallets.length
                      : wallets.where((w) => _categorieDe(w) == o).length,
              };

              final recentes = transactions.take(10).toList();

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                color: TAPAColors.gold,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Barre du haut épinglée (hauteur fixe, contenu simple)
                    SliverAppBar(
                      pinned: true,
                      elevation: 0,
                      toolbarHeight: 60,
                      backgroundColor: TAPAColors.navy,
                      surfaceTintColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      titleSpacing: 20,
                      title: _logo(),
                      actions: [
                        _buildCoachButton(context),
                        _roundIconButton(
                          Icons.notifications_outlined,
                              () {
                            // TODO: Ouvrir les notifications
                          },
                        ),
                        _avatar(prenom),
                      ],
                    ),

                    // Bandeau solde
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(maxWidth: m.contentMaxWidth),
                          child: _headerSolde(
                            prenom: prenom,
                            monnaie: monnaie,
                            total: total,
                            revenus: totalRevenus,
                            depenses: totalDepenses,
                            isSmall: m.isSmall,
                          ),
                        ),
                      ),
                    ),

                    // Contenu principal
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
                              maxWidth: m.contentMaxWidth,
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _quickActions(),
                                  const SizedBox(height: 24),

                                  _sectionTitle('Mes portefeuilles'),
                                  const SizedBox(height: 12),
                                  if (onglets.length > 1) ...[
                                    _filtresCategories(
                                        onglets, comptesParOnglet),
                                    const SizedBox(height: 12),
                                  ],
                                  _listeWallets(
                                    walletsFiltres,
                                    monnaie,
                                    m.isSmall ? 150 : 176,
                                  ),
                                  const SizedBox(height: 24),

                                  _graphiqueDepenses(monnaie, transactions),

                                  _sectionTitle(
                                    'Transactions récentes',
                                    actionLabel: 'Voir tout',
                                    onAction: () => context.go('/history'),
                                  ),
                                  const SizedBox(height: 12),
                                  _listeTransactions(recentes, monnaie),
                                ],
                              ),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================
  // BARRE DU HAUT
  // ============================================

  Widget _logo() {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'TAPA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TAPAColors.gold,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: ' Invest',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: TAPAColors.white,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: TAPAColors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _avatar(String prenom) {
    return GestureDetector(
      onTap: () => _navigateTo('/profile', 5),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [TAPAColors.gold, TAPAColors.gold.withOpacity(0.4)],
            ),
          ),
          child: CircleAvatar(
            radius: 16,
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
    );
  }

  Widget _buildCoachButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/coach'),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            Icon(Icons.auto_awesome, size: 14, color: TAPAColors.navy),
            SizedBox(width: 4),
            Text(
              'Coach',
              maxLines: 1,
              style: TextStyle(
                color: TAPAColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BANDEAU SOLDE
  // ============================================

  Widget _headerSolde({
    required String prenom,
    required String monnaie,
    required double total,
    required double revenus,
    required double depenses,
    required bool isSmall,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour${prenom.isNotEmpty ? ', $prenom' : ''} 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde total · $monnaie',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: TAPAColors.gold.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _soldeVisible
                            ? Fmt.montant(total, monnaie: monnaie)
                            : '••••••••',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isSmall ? 28 : 34,
                          fontWeight: FontWeight.w800,
                          color: TAPAColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _soldeVisible = !_soldeVisible),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _soldeVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  'Revenus',
                  _soldeVisible
                      ? Fmt.montant(revenus, monnaie: monnaie)
                      : '•••',
                  TAPAColors.green,
                  Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniCard(
                  'Dépenses',
                  _soldeVisible
                      ? Fmt.montant(depenses, monnaie: monnaie)
                      : '•••',
                  TAPAColors.red,
                  Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String label, String valeur, Color color, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valeur,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTIONS RAPIDES (remplacent les 3 boutons flottants)
  // ============================================

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.add_rounded,
            label: 'Ajouter',
            highlighted: true,
            onTap: () => _pushAndRefresh('/add-transaction'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionTile(
            icon: Icons.document_scanner_outlined,
            label: 'Scanner',
            onTap: () => _pushAndRefresh('/scanner'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionTile(
            icon: Icons.mic_none_rounded,
            label: 'Vocal',
            onTap: () => _pushAndRefresh('/voice-transaction'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Transférer',
            onTap: () => _pushAndRefresh('/transfer'),
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TAPAColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: TAPAColors.navy.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlighted
                    ? TAPAColors.navy
                    : TAPAColors.navy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: highlighted ? TAPAColors.gold : TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TITRES DE SECTION
  // ============================================

  Widget _sectionTitle(String title,
      {String? actionLabel, VoidCallback? onAction}) {
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TAPAColors.navy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                actionLabel,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  color: TAPAColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================
  // FILTRES PAR CATÉGORIE
  // ============================================

  Widget _filtresCategories(List<String> onglets, Map<String, int> comptes) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: onglets.length,
        itemBuilder: (ctx, i) => _ongletCategorie(
          onglets[i],
          _categorieSelectionnee == onglets[i],
          comptes[onglets[i]] ?? 0,
        ),
      ),
    );
  }

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
      case 'Cash':
        return TAPAColors.green;
      case 'MTN':
        return _mtn;
      case 'Orange':
        return _orange;
      case 'Wave':
        return _wave;
      case 'Autres':
        return TAPAColors.purple;
      default:
        return TAPAColors.navy;
    }
  }

  Widget _ongletCategorie(String label, bool selected, int count) {
    final couleur = _couleurCategorie(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _categorieSelectionnee = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.only(left: 6, right: 12),
          decoration: BoxDecoration(
            color: selected ? TAPAColors.navy : TAPAColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? TAPAColors.navy : TAPAColors.border,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: TAPAColors.navy.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? TAPAColors.gold.withOpacity(0.2)
                      : couleur.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconeCategorie(label),
                  size: 14,
                  color: selected ? TAPAColors.gold : couleur,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? TAPAColors.gold : TAPAColors.navy,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.15)
                        : couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white70 : TAPAColors.navy,
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
  // PORTEFEUILLES
  // ============================================

  Widget _listeWallets(
      List<WalletModel> wallets, String monnaie, double cardWidth) {
    if (wallets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TAPAColors.border, width: 0.8),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: TAPAColors.textHint),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun portefeuille dans cette catégorie',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: TAPAColors.textSecond, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 118,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: wallets.length,
        itemBuilder: (ctx, i) => _walletCard(wallets[i], monnaie, cardWidth),
      ),
    );
  }

  Widget _walletCard(WalletModel w, String monnaie, double cardWidth) {
    final nom = w.nom.toLowerCase();
    final isMtn = nom.contains('mtn');
    final isOrange = nom.contains('orange');
    final isWave = nom.contains('wave');
    final Color? brand =
    isMtn ? _mtn : (isOrange ? _orange : (isWave ? _wave : null));
    final hasBrand = brand != null;

    final badgeText = isMtn ? 'MTN' : (isOrange ? 'OR' : (isWave ? 'WV' : null));
    final badgeTextColor = isMtn ? const Color(0xFF003366) : Colors.white;

    return GestureDetector(
      onLongPress: () => _modifierSolde(w, monnaie),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasBrand ? brand.withOpacity(0.13) : TAPAColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: w.estPresqueVide
                ? TAPAColors.red
                : (hasBrand ? brand.withOpacity(0.55) : TAPAColors.border),
            width: w.estPresqueVide || hasBrand ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasBrand ? brand : TAPAColors.navy).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasBrand ? brand : TAPAColors.goldLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: badgeText != null
                        ? Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: badgeTextColor,
                      ),
                    )
                        : Text(w.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const Spacer(),
                if (w.estPresqueVide)
                  const Icon(Icons.warning_rounded,
                      size: 16, color: TAPAColors.red),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  w.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TAPAColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _soldeVisible
                        ? Fmt.montant(w.solde, monnaie: monnaie)
                        : '•••••',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: w.estPresqueVide
                          ? TAPAColors.red
                          : TAPAColors.navy,
                    ),
                  ),
                ),
              ],
            ),
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
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: TAPAColors.goldLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(w.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modifier ${w.nom}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: TAPAColors.navy,
                          ),
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
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.navy,
                        foregroundColor: TAPAColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        // ignore: unused_local_variable
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
        ),
      ),
    );
  }

  // ============================================
  // GRAPHIQUE DES DÉPENSES
  // ============================================

  Widget _graphiqueDepenses(String monnaie, List<TransactionModel> txs) {
    if (txs.isEmpty) return const SizedBox();

    final now = DateTime.now();
    final transactionsMois = txs
        .where((tx) =>
    tx.dateTransaction.month == now.month &&
        tx.dateTransaction.year == now.year &&
        tx.isDepense)
        .toList();

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: TAPAColors.amberLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart_rounded,
                      size: 18, color: TAPAColors.amber),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Dépenses du mois',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Fmt.montant(total, monnaie: monnaie),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barre répartie : une seule ligne résume la répartition
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (int i = 0; i < top.length; i++)
                      Expanded(
                        flex: ((total > 0 ? top[i].value / total : 0) * 1000)
                            .round()
                            .clamp(1, 1000),
                        child: Container(color: colors[i % colors.length]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...top.asMap().entries.map((e) {
              final pct = total > 0 ? e.value.value / total : 0.0;
              final color = colors[e.key % colors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: e.key == top.length - 1 ? 0 : 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          Fmt.montant(e.value.value, monnaie: monnaie),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${(pct * 100).round()}%',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TRANSACTIONS
  // ============================================

  Widget _listeTransactions(List<TransactionModel> txs, String monnaie) {
    if (txs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TAPAColors.border, width: 0.8),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: TAPAColors.navy.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 30, color: TAPAColors.navy),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucune transaction',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ajoutez votre première dépense ou revenu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: TAPAColors.textSecond),
            ),
          ],
        ),
      );
    }

    return Container(
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
        children: [
          for (int i = 0; i < txs.length; i++)
            _txTile(txs[i], i == txs.length - 1, monnaie),
        ],
      ),
    );
  }

  Widget _txTile(TransactionModel tx, bool isLast, String monnaie) {
    final couleur = tx.isRevenu ? TAPAColors.green : TAPAColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tx.isRevenu ? TAPAColors.greenLight : TAPAColors.redLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                tx.categorieEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.categorieLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.dateRelative(tx.dateTransaction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TAPAColors.textSecond,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${tx.isRevenu ? "+" : "-"}${Fmt.montant(tx.montant, monnaie: monnaie)}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: couleur,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BARRE DE NAVIGATION INFÉRIEURE
  // ============================================

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