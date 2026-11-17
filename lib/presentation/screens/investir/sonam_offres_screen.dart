import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SonamOffresScreen extends StatelessWidget {
  const SonamOffresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Offres SONAM'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/investir'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête SONAM
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0A4D), // Violet SONAM
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/logos/sonam_logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.shield, size: 40, color: Colors.white);
                  },
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'SONAM Assurances Vie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildMenuItem(
            context,
            title: 'Assurance Auto',
            subtitle: 'Protégez votre véhicule avec une couverture adaptée.',
            icon: '🚗',
            route: '/investir/assurance', // ⚠️ Assure-toi que cette route existe
          ),
          _buildMenuItem(
            context,
            title: 'Épargne de Précaution',
            subtitle: 'Faites fructifier votre épargne avec un taux garanti de 4%.',
            icon: '💰',
            route: '/investir/sonam',
          ),
          _buildMenuItem(
            context,
            title: 'Mes Contrats',
            subtitle: 'Consultez vos contrats et effectuez vos paiements.',
            icon: '📄',
            route: '/investir/sonam/contrats',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required String title, required String subtitle, required String icon, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => context.go(route),
      ),
    );
  }
}
