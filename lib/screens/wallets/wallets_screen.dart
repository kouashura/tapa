// lib/presentation/screens/wallets/wallets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../data/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  final List<Map<String, String>> _types = [
    {'id':'cash','label':'Cash','emoji':'💵'},
    {'id':'wave','label':'Wave','emoji':'🌊'},
    {'id':'orange','label':'Orange Money','emoji':'🟠'},
    {'id':'mtn','label':'MTN MoMo','emoji':'🟡'},
    {'id':'moov','label':'Moov Money','emoji':'🔵'},
    {'id':'banque','label':'Banque','emoji':'🏦'},
    {'id':'tresor','label':'Trésor Pay','emoji':'💎'},
    {'id':'free','label':'Free Money','emoji':'🟣'},
    {'id':'autre','label':'Autre','emoji':'💳'},
  ];

  // TODO: Remplacer par un provider pour les wallets
  List<WalletModel> _wallets = [];

  @override
  void initState() {
    super.initState();
    _chargerWallets();
  }

  Future<void> _chargerWallets() async {
    // TODO: Utiliser un provider
    // final wallets = await ref.read(walletListProvider.future);
    // setState(() => _wallets = wallets);
  }

  void _ajouter() {
    // TODO: Implémenter avec un provider
  }

  void _modifier(WalletModel w) {
    // TODO: Implémenter avec un provider
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final monnaie = ref.watch(userMonnaieProvider);
    final total = _wallets.fold(0.0, (sum, w) => sum + w.solde);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
          title: const Text('Mes portefeuilles'),
          backgroundColor: TAPAColors.navy,
          foregroundColor: TAPAColors.white,
          actions: [
            IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: TAPAColors.gold),
                onPressed: _ajouter),
          ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TAPAColors.navy,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Text('TOTAL DISPONIBLE',
                  style: TextStyle(fontSize: 11,
                      color: Colors.white54,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(Fmt.montant(total, monnaie: monnaie),
                  style: const TextStyle(fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.white)),
              Text('${_wallets.length} portefeuilles',
                  style: const TextStyle(fontSize: 12,
                      color: Colors.white38)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._wallets.map((w) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: TAPAColors.border, width: 0.5)),
            child: Row(children: [
              Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: TAPAColors.background,
                      borderRadius:
                      BorderRadius.circular(12)),
                  child: Center(child: Text(w.emoji,
                      style: const TextStyle(
                          fontSize: 22)))),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(w.nom,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TAPAColors.navy)),
                    Text(Fmt.montant(w.solde,
                        monnaie: monnaie),
                        style: const TextStyle(
                            fontSize: 13,
                            color: TAPAColors.textSecond)),
                  ])),
              IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: TAPAColors.navy, size: 20),
                  onPressed: () => _modifier(w)),
            ]),
          )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: _ajouter,
              icon: const Icon(Icons.add),
              label: const Text(
                  'Ajouter un portefeuille')),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}