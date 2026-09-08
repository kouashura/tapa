// lib/screens/investir/assurance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class AssuranceScreen extends ConsumerStatefulWidget {
  const AssuranceScreen({super.key});

  @override
  ConsumerState<AssuranceScreen> createState() => _AssuranceScreenState();
}

class _AssuranceScreenState extends ConsumerState<AssuranceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1;

  static const List<Map<String, dynamic>> produitsAssuranceVie = [
    {
      'id': 'assurance_deces',
      'nom': 'Assurance Décès',
      'emoji': '🛡️',
      'description': 'Protégez votre famille en cas de décès. Vos proches reçoivent un capital garanti.',
      'primeMin': 5000,
      'primeMax': 50000,
      'garantie': 'Capital décès jusqu\'à 10 000 000 FCFA',
      'duree': '1 an renouvelable',
      'couleurValue': 0xFF1A237E,
      'avantages': ['Souscription rapide', 'Pas de visite médicale', 'Capital versé en 72h', 'Bénéficiaire au choix'],
    },
    {
      'id': 'assurance_epargne',
      'nom': 'Assurance Épargne',
      'emoji': '💰',
      'description': 'Épargnez tout en étant protégé. Constituez un capital garanti à terme.',
      'primeMin': 10000,
      'primeMax': 100000,
      'garantie': 'Capital garanti + rendement annuel',
      'duree': '5 à 20 ans',
      'couleurValue': 0xFFC9A227,
      'avantages': ['Rendement garanti', 'Protection décès incluse', 'Retrait partiel possible', 'Déductible fiscalement'],
    },
    {
      'id': 'assurance_education',
      'nom': 'Assurance Éducation',
      'emoji': '🎓',
      'description': 'Garantissez l\'avenir scolaire de vos enfants. Un capital est versé à chaque rentrée.',
      'primeMin': 5000,
      'primeMax': 30000,
      'garantie': 'Capital versé à chaque rentrée scolaire',
      'duree': 'Jusqu\'à la majorité de l\'enfant',
      'couleurValue': 0xFF3498DB,
      'avantages': ['Versements programmés', 'Protection parents incluse', 'Continue si parent décède', 'Adapté au rythme africain'],
    },
  ];

  static const List<Map<String, dynamic>> produitsAssuranceAuto = [
    {
      'id': 'assurance_auto_tiers',
      'nom': 'Assurance Auto Tiers',
      'emoji': '🚗',
      'description': 'Protection minimale obligatoire pour votre véhicule. Couvre les dommages causés à autrui.',
      'primeMin': 15000,
      'primeMax': 45000,
      'garantie': 'Responsabilité civile jusqu\'à 50 000 000 FCFA',
      'duree': '1 an renouvelable',
      'couleurValue': 0xFF1A237E,
      'avantages': ['Prix abordable', 'Protection légale', 'Assistance 24/7', 'Paiement mensuel possible'],
    },
    {
      'id': 'assurance_auto_tous_risques',
      'nom': 'Assurance Auto Tous Risques',
      'emoji': '🚙',
      'description': 'Protection complète pour votre véhicule. Couvre les dommages, le vol et les accidents.',
      'primeMin': 45000,
      'primeMax': 120000,
      'garantie': 'Couverture complète - vol, incendie, dommages',
      'duree': '1 an renouvelable',
      'couleurValue': 0xFF1A237E,
      'avantages': ['Couverture complète', 'Assistance dépannage', 'Véhicule de remplacement', 'Protection conducteur'],
    },
    {
      'id': 'assurance_auto_bonus',
      'nom': 'Assurance Auto Bonus',
      'emoji': '🏆',
      'description': 'Récompensez votre bonne conduite ! Tarifs préférentiels pour les conducteurs responsables.',
      'primeMin': 20000,
      'primeMax': 60000,
      'garantie': 'Bonus de 10% par an sans accident',
      'duree': '1 an renouvelable',
      'couleurValue': 0xFF1A237E,
      'avantages': ['Réduction jusqu\'à 50%', 'Conduite responsable', 'Paiement trimestriel', 'Assistance routière'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = ref.watch(userMonnaieProvider);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final paddingSize = isSmall ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Assurances'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assurance Vie'),
            Tab(text: 'Assurance Auto'),
          ],
          indicatorColor: TAPAColors.gold,
          labelColor: TAPAColors.gold,
          unselectedLabelColor: Colors.white54,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssuranceList(
            context,
            produitsAssuranceVie,
            monnaie,
            isSmall,
            isTablet,
            paddingSize,
            false,
          ),
          _buildAssuranceList(
            context,
            produitsAssuranceAuto,
            monnaie,
            isSmall,
            isTablet,
            paddingSize,
            true,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAssuranceList(
      BuildContext context,
      List<Map<String, dynamic>> produits,
      String monnaie,
      bool isSmall,
      bool isTablet,
      double paddingSize,
      bool isAuto,
      ) {
    final titleSize = isSmall ? 14.0 : (isTablet ? 20.0 : 16.0);

    return ListView(
      padding: EdgeInsets.all(paddingSize),
      children: [
        // Partenaire
        Container(
          padding: EdgeInsets.all(paddingSize),
          decoration: BoxDecoration(
            color: TAPAColors.navy.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: TAPAColors.navy.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isSmall ? 40 : 48,
                height: isSmall ? 40 : 48,
                decoration: BoxDecoration(
                  color: TAPAColors.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isAuto ? '🚗' : '🛡️',
                    style: TextStyle(fontSize: isSmall ? 18 : 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuto ? 'SONAM AUTO' : 'SONAM VIE',
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        color: TAPAColors.navy,
                      ),
                    ),
                    Text(
                      isAuto
                          ? 'Partenaire assurance auto de TAPA Budget'
                          : 'Partenaire assurance de TAPA Budget',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                    const Text(
                      'Agréé CIMA — Côte d\'Ivoire',
                      style: TextStyle(
                        fontSize: 11,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Titre
        Text(
          isAuto ? 'Assurance Auto' : 'Assurance Vie',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy,
          ),
        ),
        const SizedBox(height: 12),

        // Liste des produits
        ...produits.map((p) {
          final couleur = Color(p['couleurValue'] as int);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(paddingSize),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TAPAColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                      width: isSmall ? 36 : 44,
                      height: isSmall ? 36 : 44,
                      decoration: BoxDecoration(
                        color: couleur.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          p['emoji'] as String,
                          style: TextStyle(fontSize: isSmall ? 16 : 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['nom'] as String,
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: TAPAColors.navy,
                            ),
                          ),
                          Text(
                            p['duree'] as String,
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 11.5,
                              color: TAPAColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isSmall ? 12 : 14,
                      color: couleur.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p['description'] as String,
                  style: TextStyle(
                    fontSize: isSmall ? 11.5 : 12.5,
                    color: TAPAColors.textSecond,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: isSmall ? 12 : 14,
                        color: couleur,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p['garantie'] as String,
                          style: TextStyle(
                            fontSize: isSmall ? 10 : 11.5,
                            fontWeight: FontWeight.w600,
                            color: couleur,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Prime: ${Fmt.montant((p['primeMin'] as int).toDouble(), monnaie: monnaie)} '
                      'à ${Fmt.montant((p['primeMax'] as int).toDouble(), monnaie: monnaie)} / mois',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy,
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton "OBTENIR UN DEVIS" (uniquement pour Assurance Auto)
                if (isAuto)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final produitNom = p['nom'] as String;
                        context.push('/devis-auto/$produitNom');
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text(
                        'Obtenir un devis',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.gold,
                        foregroundColor: TAPAColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

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