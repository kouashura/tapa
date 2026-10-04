// lib/screens/wallets/wallets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/utils/formatters.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final monnaie = ref.watch(userMonnaieProvider);
    final userId = user?.id ?? '';

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final walletsAsync = ref.watch(walletListProvider(userId));

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mes portefeuilles'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: TAPAColors.gold),
            onPressed: () async {
              final result = await context.push('/wallets/add');
              if (result == true) {
                ref.invalidate(walletListProvider(userId));
              }
            },
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TAPAColors.gold),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Erreur: $err',
              style: const TextStyle(color: TAPAColors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (wallets) {
          final total = wallets.fold(0.0, (sum, w) => sum + w.solde);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Carte total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TAPAColors.navy,
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
                        color: TAPAColors.white,
                      ),
                    ),
                    Text(
                      '${wallets.length} portefeuille${wallets.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Liste des wallets
              if (wallets.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: TAPAColors.textSecond),
                        SizedBox(height: 12),
                        Text(
                          'Aucun portefeuille',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ajoutez votre premier portefeuille',
                          style: TextStyle(color: TAPAColors.textSecond),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...wallets.map((w) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TAPAColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: TAPAColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: TAPAColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(w.emoji,
                                  style: const TextStyle(fontSize: 22)),
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
                                    color: TAPAColors.navy,
                                  ),
                                ),
                                Text(
                                  Fmt.montant(w.solde, monnaie: monnaie),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: TAPAColors.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: TAPAColors.navy, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Modification à venir'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )),

              const SizedBox(height: 16),

              // Bouton Ajouter
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await context.push('/wallets/add');
                  if (result == true) {
                    ref.invalidate(walletListProvider(userId));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un portefeuille'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TAPAColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: TAPAColors.navy),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
