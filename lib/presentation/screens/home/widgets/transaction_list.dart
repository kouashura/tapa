// lib/presentation/screens/home/widgets/transaction_list.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/models/models.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../core/theme/app_theme.dart';

/// Liste des transactions récentes
class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<WalletModel> wallets;
  final String monnaie;
  final int maxItems;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.wallets,
    required this.monnaie,
    this.maxItems = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    final titleSize = isSmall ? 15.0 : 17.0;
    final displayedTransactions = transactions.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            children: [
              Text(
                'Transactions',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: TAPAColors.navy,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/history'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: TAPAColors.navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 10,
                      color: TAPAColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste
        if (displayedTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: TAPAColors.textHint,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(
                      color: TAPAColors.textSecond,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TAPAColors.border,
                width: 0.5,
              ),
            ),
            child: Column(
              children: displayedTransactions
                  .asMap()
                  .entries
                  .map(
                    (e) => _transactionTile(
                  e.value,
                  e.key == displayedTransactions.length - 1,
                  wallets,
                  monnaie,
                ),
              )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _transactionTile(
      TransactionModel tx,
      bool isLast,
      List<WalletModel> wallets,
      String monnaie,
      ) {
    final wallet = wallets.isNotEmpty
        ? wallets.first
        : WalletModel(
      id: '',
      uid: '',
      nom: 'Inconnu',
      emoji: '💰',
      type: 'compte',
      solde: 0,
      monnaie: monnaie,
      description: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
          bottom: BorderSide(color: TAPAColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tx.isRevenu ? TAPAColors.greenLight : TAPAColors.redLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                tx.categorieEmoji,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.categorieLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy,
                  ),
                ),
                Text(
                  '${wallet.emoji} ${wallet.nom} · ${Fmt.dateRelative(tx.dateTransaction)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: TAPAColors.textSecond,
                  ),
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(
                    tx.note!,
                    style: TextStyle(
                      fontSize: 9,
                      color: TAPAColors.textSecond.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Montant
          Text(
            '${tx.isRevenu ? "+" : "-"}${Fmt.montant(tx.montant, monnaie: monnaie)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tx.isRevenu ? TAPAColors.green : TAPAColors.red,
            ),
          ),
        ],
      ),
    );
  }
}