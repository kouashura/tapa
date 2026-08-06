// lib/presentation/screens/wallets/wallets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../../data/models/wallet_model.dart';  // ✅ Import correct
import '../../../core/utils/formatters.dart';
import 'add_wallet_screen.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  void _ajouter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddWalletScreen()),
    );
  }

  void _modifier(BuildContext context, WalletModel w) {
    // TODO: Implémenter l'écran de modification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifier: ${w.nom}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final monnaie = ref.watch(userMonnaieProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter')),
      );
    }

    final walletsAsync = ref.watch(walletListProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mes portefeuilles'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFC107)),
            onPressed: () => _ajouter(context),
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur de chargement : $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (wallets) {
          final total = wallets.fold(0.0, (sum, w) => sum + w.solde);

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(walletListProvider(user.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Carte total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL DISPONIBLE',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Fmt.montant(total, monnaie: monnaie),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${wallets.length} portefeuilles',
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Message si aucun portefeuille
                if (wallets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun portefeuille pour le moment',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Appuyez sur le bouton + pour en ajouter',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Liste des portefeuilles
                ...wallets.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(w.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.nom,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              Fmt.montant(w.solde, monnaie: monnaie),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFF1A237E), size: 20),
                        onPressed: () => _modifier(context, w),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _ajouter(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un portefeuille'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}