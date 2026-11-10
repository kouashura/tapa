// lib/presentation/screens/home/widgets/expense_chart.dart

import 'package:flutter/material.dart';
import '../../../../../data/models/models.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';

/// Graphique des dépenses du mois par catégorie
class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String monnaie;

  const ExpenseChart({
    super.key,
    required this.transactions,
    required this.monnaie,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final transactionsMois = transactions
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TAPAColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: TAPAColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: TAPAColors.amberLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  size: 14,
                  color: TAPAColors.amber,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Dépenses du mois',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TAPAColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${now.month}/${now.year}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: TAPAColors.textSecond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...top.toList().asMap().entries.map((e) {
            final pct = total > 0 ? e.value.value / total : 0.0;
            final Color color = colors[e.key % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        e.value.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.montant(e.value.value, monnaie: monnaie),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: TAPAColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
