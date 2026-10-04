// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/link_service.dart';
import '../../../core/utils/logger.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedIndex = 5;

  // ============================================
  // ACTIONS (inchangées)
  // ============================================
  Future<void> _reinitialiser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Réinitialiser ?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Toutes tes données seront effacées :\n'
                '- Portefeuilles et soldes\n'
                '- Transactions\n'
                '- Objectifs épargne\n'
                '- Ton profil\n\n'
                'Cette action est irréversible.',
          ),
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

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final prenom = ref.watch(userPrenomProvider);
    final monnaie = ref.watch(userMonnaieProvider);

    Logger.info('👤 ProfileScreen - user: ${user?.prenom ?? "null"}');

    return Scaffold(
      backgroundColor: TAPAColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              prenom: prenom,
              phone: user?.phoneNumber ?? '',
              monnaie: monnaie,
            ),
            const SizedBox(height: 8),

            // ---- Section Découvrir ----
            _sectionTitle('DÉCOUVRIR'),
            _group([
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
            ]),

            // ---- Section Mon compte ----
            _sectionTitle('MON COMPTE'),
            _group([
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
            ]),

            // ---- Section Support ----
            _sectionTitle('SUPPORT'),
            _group([
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
              _menuItem(
                icon: Icons.receipt_long_outlined,
                iconColor: TAPAColors.gold,
                bgColor: const Color(0xFFFFF8E1),
                title: 'Historique des paiements',
                subtitle: 'Vos souscriptions et paiements',
                onTap: () => context.push('/historique-paiements'),
              ),
            ]),

            // ---- Section Session ----
            _sectionTitle('SESSION'),
            _group([
              _menuItem(
                icon: Icons.logout_rounded,
                iconColor: TAPAColors.navy,
                bgColor: const Color(0xFFE8ECF0),
                title: 'Se déconnecter',
                subtitle: 'Tes données restent sauvegardées',
                onTap: _deconnecter,
              ),
            ]),

            // ---- Section Admin (visible admin uniquement) ----
            if (user != null && user.email == 'kouassishura2025@gmail.com') ...[
              _sectionTitle('ADMIN', color: TAPAColors.gold),
              _group([
                _menuItem(
                  icon: Icons.admin_panel_settings,
                  iconColor: TAPAColors.gold,
                  bgColor: const Color(0xFFFFF8E1),
                  title: 'Administration des tarifs',
                  subtitle: 'Gerer les tarifs assurance auto',
                  onTap: () => context.push('/admin/tarifs'),
                ),
              ]),
            ],

            // ---- Section Danger ----
            _sectionTitle('DANGER', color: TAPAColors.red),
            _group([
              _menuItem(
                icon: Icons.refresh_rounded,
                iconColor: TAPAColors.red,
                bgColor: TAPAColors.redLight,
                title: 'Réinitialiser mon compte',
                subtitle: 'Efface toutes les données définitivement',
                onTap: _reinitialiser,
              ),
            ], borderColor: TAPAColors.red.withOpacity(0.25)),

            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'TAPA Invest v1.0.0\nInvestir. Simplement. Grandir.',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 11, color: Colors.grey, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ============================================
  // EN-TÊTE (hauteur adaptative : aucun débordement)
  // ============================================
  Widget _buildHeader({
    required String prenom,
    required String phone,
    required String monnaie,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar avec anneau doré
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      TAPAColors.gold,
                      TAPAColors.gold.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TAPAColors.gold.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: TAPAColors.navy,
                  child: Text(
                    prenom.isNotEmpty ? prenom[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Nom
              Text(
                prenom.isNotEmpty ? prenom : 'Utilisateur',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.white,
                  letterSpacing: 0.3,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
              const SizedBox(height: 14),
              // Badges (Wrap : passent à la ligne si l'écran est étroit)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: TAPAColors.gold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: TAPAColors.gold.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: TAPAColors.gold,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Accès gratuit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '💰 $monnaie',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // TITRE DE SECTION
  // ============================================
  Widget _sectionTitle(String title, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color == Colors.grey ? Colors.grey.shade600 : color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ============================================
  // GROUPE DE MENUS (une carte, séparateurs fins)
  // ============================================
  Widget _group(List<Widget> items, {Color? borderColor}) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i < items.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 0.8,
          indent: 66,
          endIndent: 14,
          color: Colors.grey.shade200,
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade200,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: Column(children: children),
        ),
      ),
    );
  }

  // ============================================
  // ÉLÉMENT DE MENU
  // ============================================
  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = TAPAColors.navy,
    Color bgColor = const Color(0xFFF0F2F8),
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TAPAColors.navy,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
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
              width: isActive ? 46 : 36,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(15),
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
                size: isActive ? 20 : 20,
                color: isActive ? Colors.amber : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1A237E)
                    : Colors.grey.shade500,
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