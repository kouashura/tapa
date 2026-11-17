// lib/screens/investir/investir_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'sonam_offres_screen.dart';

class InvestirScreen extends ConsumerStatefulWidget {
  const InvestirScreen({super.key});

  @override
  ConsumerState<InvestirScreen> createState() => _InvestirScreenState();
}

class _InvestirScreenState extends ConsumerState<InvestirScreen> {
  int _selectedIndex = 1;

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final paddingSize = isSmall ? 12.0 : (isTablet ? 24.0 : 16.0);
    final titleSize = isSmall ? 16.0 : (isTablet ? 22.0 : 18.0);
    final subtitleSize = isSmall ? 11.0 : (isTablet ? 15.0 : 13.0);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Investir & Protéger'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(paddingSize),
        children: [
          // Bannière d'accueil
          Container(
            padding: EdgeInsets.all(paddingSize + 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TAPAColors.navy, Color(0xFF14274E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faites fructifier votre argent',
                  style: TextStyle(
                    color: TAPAColors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Investissez dans des fonds certifiés et\nprotégez votre famille avec une assurance vie.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: subtitleSize,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),



          // ✅ PARTENAIRE UNIQUE : SONAM
          _grandBouton(
            context: context,
            titre: 'SONAM Assurances',
            sousTitre:
                'Assurance vie, épargne\net contrats.',
            emoji: '',
            couleur: const Color(0xFF3A0A4D), // Couleur violette SONAM
            couleurBg: const Color(0xFFF3E5F5),
            badgeCouleur: const Color(0xFF3A0A4D),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SonamOffresScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section avantages
          const Text(
            'Pourquoi investir avec TAPA ?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy,
            ),
          ),
          const SizedBox(height: 12),

          _avantage('🔒', 'Sécurité', 'Partenaires agréés et certifiés'),
          _avantage('💰', 'Rentabilité', 'Rendements attractifs sur le marché'),
          _avantage('📱', 'Simplicité', 'Tout se fait depuis votre téléphone'),
          _avantage('🤝', 'Accompagnement', 'Support 7j/7 sur WhatsApp'),

          const SizedBox(height: 20),

          // Avertissement
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TAPAColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: TAPAColors.textSecond,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Les investissements sont soumis aux risques du marché. '
                    'TAPA Invest facilite la mise en relation avec ses partenaires agréés.',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: TAPAColors.textSecond,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _grandBouton({
    required BuildContext context,
    required String titre,
    required String sousTitre,
    required String emoji,
    required Color couleur,
    required Color couleurBg,
    String? badge,
    Color? badgeCouleur,
    required VoidCallback onTap,
  }) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final fontSize = isSmall ? 13.0 : (isTablet ? 17.0 : 15.0);
    final subFontSize = isSmall ? 11.0 : (isTablet ? 14.0 : 12.0);
    final iconSize = isSmall ? 50.0 : (isTablet ? 70.0 : 60.0);
    final paddingSize = isSmall ? 14.0 : (isTablet ? 24.0 : 20.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(paddingSize),
        decoration: BoxDecoration(
          color: couleurBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: couleur.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: emoji.isEmpty
                    ? Image.asset(
                        'assets/logos/sonam_logo.png',
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.shield, color: couleur, size: iconSize * 0.5);
                        },
                      )
                    : Text(
                        emoji,
                        style: TextStyle(fontSize: iconSize * 0.45),
                      ),
              ),
            ),
            SizedBox(width: isSmall ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null && badge.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeCouleur?.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: isSmall ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: badgeCouleur,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    titre,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: couleur,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sousTitre,
                    style: TextStyle(
                      fontSize: subFontSize,
                      color: TAPAColors.textSecond,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isSmall ? 14 : 16,
              color: couleur.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avantage(String emoji, String titre, String desc) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final emojiSize = isSmall ? 18.0 : 22.0;
    final titleSize = isSmall ? 12.0 : 13.0;
    final descSize = isSmall ? 10.5 : 11.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: emojiSize),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: descSize,
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
                        colors: [Color(0xFF1F3A5F), Color(0xFF152A47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1F3A5F).withOpacity(0.35),
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
                color:
                    isActive ? const Color(0xFF1F3A5F) : Colors.grey.shade500,
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
