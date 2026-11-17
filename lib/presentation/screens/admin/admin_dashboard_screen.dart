import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminWithdrawsProvider);
    await Future.wait([
      ref.read(adminUsersProvider.future),
      ref.read(adminWithdrawsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final withdrawsAsync = ref.watch(adminWithdrawsProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tableau de bord',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vue d'ensemble en temps reel",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Utilisateurs',
                    value: usersAsync.when(
                      data: (u) => '${u.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    color: const Color(0xFF8E44AD),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments,
                    label: 'Retraits en attente',
                    value: withdrawsAsync.when(
                      data: (w) => '${w.length}',
                      loading: () => '...',
                      error: (_, __) => '!',
                    ),
                    color: TAPAColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAdminCard(
              context,
              title: 'Demandes de retrait',
              subtitle: 'Gerer les paiements sortants',
              icon: Icons.account_balance_wallet,
              color: TAPAColors.red,
              onTap: () => context.push('/admin/withdraws'),
            ),
            _buildAdminCard(
              context,
              title: 'Tarifs Assurance Auto',
              subtitle: 'Configurer les primes et garanties',
              icon: Icons.monetization_on,
              color: TAPAColors.gold,
              onTap: () => context.push('/admin/tarifs'),
            ),
            _buildAdminCard(
              context,
              title: 'Souscriptions',
              subtitle: 'Valider ou annuler les contrats',
              icon: Icons.receipt_long,
              color: const Color(0xFF27AE60),
              onTap: () => context.push('/admin/souscriptions'),
            ),
            _buildAdminCard(
              context,
              title: 'Utilisateurs',
              subtitle: 'Consulter la liste des clients',
              icon: Icons.people,
              color: const Color(0xFF8E44AD),
              onTap: () => context.push('/admin/users'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: TAPAColors.navy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
