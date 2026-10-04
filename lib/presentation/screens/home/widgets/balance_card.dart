// lib/presentation/screens/home/widgets/balance_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../../core/utils/formatters.dart';

/// Carte affichant le solde total avec indicateurs de revenus/dépenses
class BalanceCard extends ConsumerWidget {
  final double totalBalance;
  final double totalRevenus;
  final double totalDepenses;
  final bool isSoldeVisible;
  final VoidCallback onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalRevenus,
    required this.totalDepenses,
    required this.isSoldeVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monnaie = ref.watch(userMonnaieProvider);
    final prenom = ref.watch(userPrenomProvider);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final fontSize = isSmall ? 12.5 : 14.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4A), TAPAColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salutation
          Text(
            'Bonjour${prenom.isNotEmpty ? ', $prenom' : ''} !',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Solde total
          Row(
            children: [
              Expanded(
                child: Text(
                  isSoldeVisible
                      ? Fmt.montant(totalBalance, monnaie: monnaie)
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
                onTap: onToggleVisibility,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSoldeVisible
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

          // Monnaie
          Text(
            'Solde total · $monnaie',
            style: TextStyle(
              fontSize: 12,
              color: TAPAColors.gold.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Mini cartes Revenus / Dépenses
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
    );
  }

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
                  style: const TextStyle(fontSize: 9.5, color: Colors.white60),
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
}