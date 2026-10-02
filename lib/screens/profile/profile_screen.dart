// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/link_service.dart';
import '../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedIndex = 5;

  Future<void> _reinitialiser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Réinitialiser ?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Toutes tes données seront effacées :\n'
              '- Portefeuilles et soldes\n'
              '- Transactions\n'
              '- Objectifs épargne\n'
              '- Ton profil\n\n'
              'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authStateProvider.notifier).deleteAccount();
    if (mounted) context.go('/inscription');
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tes données restent sauvegardées.\n'
              'Tu pourras te reconnecter avec ton PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                  color: TAPAColors.navy, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/inscription');
  }

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final prenom = ref.watch(userPrenomProvider);
    final monnaie = ref.watch(userMonnaieProvider);

    Logger.info('👤 ProfileScreen - user: ${user?.prenom ?? "null"}');

    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: TAPAColors.navy,
            automaticallyImplyLeading: false,
            expandedHeight: 180,
            pinned: true,
            title: const Text('Profil'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: TAPAColors.navy,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: TAPAColors.gold,
                      child: Text(
                        prenom.isNotEmpty ? prenom[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: TAPAColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prenom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.white,
                      ),
                    ),
                    Text(
                      user?.phoneNumber ?? '',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    Text(
                      '💰 $monnaie',
                      style: const TextStyle(
                          fontSize: 12, color: TAPAColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // ---- Section Découvrir ----
              _menuItem(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF7B1FA2),
                bgColor: const Color(0xFFF3E8FB),
                title: 'Investir',
                subtitle: 'Place ton épargne dans des fonds partenaires',
                onTap: () => _navigateTo('/investir', 1),
              ),
              _menuItem(
                icon: Icons.alarm_outlined,
                iconColor: const Color(0xFFE67E22),
                bgColor: const Color(0xFFFEF9E7),
                title: 'Mes échéances',
                subtitle: 'Rappels automatiques pour tes échéances',
                onTap: () => context.push('/echeances'),
              ),

              // ---- Section Mon compte ----
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  'MON COMPTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // ✅ NOUVEAU : Mon Wallet
              _menuItem(
                icon: Icons.account_balance_wallet,
                iconColor: TAPAColors.gold,
                bgColor: Colors.amber.shade50,
                title: 'Mon Wallet',
                subtitle: 'Ajouter des fonds pour investir',
                onTap: () => context.push('/wallet'),
              ),
              _menuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Mes portefeuilles',
                subtitle: 'Ajouter, modifier, supprimer',
                onTap: () => context.push('/wallets'),
              ),
              _menuItem(
                icon: Icons.category_outlined,
                title: 'Mes catégories',
                subtitle: 'Dépenses et revenus',
                onTap: () => context.push('/categories'),
              ),
              _menuItem(
                icon: Icons.person_outline,
                title: 'Mon prénom',
                subtitle: prenom,
                onTap: () => context.push('/edit-profile'),
              ),
              _menuItem(
                icon: Icons.monetization_on_outlined,
                title: 'Ma monnaie',
                subtitle: monnaie,
                onTap: () => context.push('/edit-profile'),
              ),

              // ---- Section Support ----
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  'SUPPORT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              _menuItem(
                icon: Icons.star_outline,
                iconColor: TAPAColors.gold,
                bgColor: Colors.amber.shade50,
                title: 'Mon Score TAPA',
                subtitle: 'Voir ma santé financière',
                onTap: () => context.push('/score'),
              ),
              _menuItem(
                icon: Icons.menu_book_outlined,
                iconColor: Colors.blue,
                bgColor: const Color(0xFFE3F2FD),
                title: "Guide d'utilisation",
                subtitle: 'Apprendre à utiliser TAPA Invest',
                onTap: () => context.push('/guide'),
              ),
              _menuItem(
                icon: Icons.picture_as_pdf_outlined,
                iconColor: TAPAColors.red,
                bgColor: TAPAColors.redLight,
                title: 'Rapports financiers PDF',
                subtitle: 'Jour · Semaine · Mois',
                onTap: () => context.push('/rapports'),
              ),
              _menuItem(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF8E44AD),
                bgColor: const Color(0xFFF3E8FB),
                title: 'Analyse financière',
                subtitle: 'Mensuel, annuel et règle 50/30/20',
                onTap: () => context.push('/analyse'),
              ),
              _menuItem(
                icon: Icons.message_outlined,
                iconColor: const Color(0xFF25D366),
                bgColor: const Color(0xFFE8F8EE),
                title: 'Contacter le support',
                subtitle: 'WhatsApp - +225 01 60 25 41 02',
                onTap: () => LinkService.ouvrirWhatsApp(),
              ),

              // ---- Section Session ----
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  'SESSION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              _menuItem(
                icon: Icons.logout_rounded,
                iconColor: TAPAColors.navy,
                bgColor: const Color(0xFFE8ECF0),
                title: 'Se déconnecter',
                subtitle: 'Tes données restent sauvegardées',
                onTap: _deconnecter,
              ),

              // ---- Section Danger ----
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  'DANGER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.red,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              _menuItem(
                icon: Icons.refresh_rounded,
                iconColor: TAPAColors.red,
                bgColor: TAPAColors.redLight,
                title: 'Réinitialiser mon compte',
                subtitle: 'Efface toutes les données définitivement',
                onTap: _reinitialiser,
              ),

              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'TAPA Invest v1.0.0\nInvestir. Simplement. Grandir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey, height: 1.6),
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = TAPAColors.navy,
    Color bgColor = const Color(0xFFF0F2F8),
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TAPAColors.navy,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
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
                          color:
                              const Color(0xFF1A237E).withOpacity(0.35),
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
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1A237E)
                    : Colors.grey.shade500,
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
