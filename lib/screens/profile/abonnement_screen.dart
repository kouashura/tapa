import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/link_service.dart';

class AbonnementScreen extends StatelessWidget {
  const AbonnementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Accès à vie'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: TAPAColors.navy,
                borderRadius:
                BorderRadius.circular(20)),
            child: Column(children: [
              Container(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                    color: TAPAColors.gold
                        .withOpacity(0.2),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                        color: TAPAColors.gold
                            .withOpacity(0.4))),
                child: const Text(
                    'Accès à vie · Paiement unique',
                    style: TextStyle(
                        color: TAPAColors.gold,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              const Text('5 000',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.white)),
              const Text('FCFA',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white60)),
              const SizedBox(height: 6),
              const Text(
                  'Paiement unique · '
                      'Toutes les mises à jour incluses',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                    color: TAPAColors.border,
                    width: 0.5)),
            child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text('Ce qui est inclus',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy)),
                  const SizedBox(height: 12),
                  ...[
                    'Portefeuilles illimités',
                    'Saisie rapide des transactions',
                    'Historique complet',
                    'Objectifs d\'épargne',
                    'Transferts entre portefeuilles',
                    'Notifications éducatives',
                    'Alertes solde bas',
                    'Toutes les mises à jour',
                    'Support WhatsApp',
                  ].map((f) => Padding(
                    padding: const EdgeInsets
                        .symmetric(vertical: 5),
                    child: Row(children: [
                      Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                              color:
                              TAPAColors.greenLight,
                              shape: BoxShape.circle),
                          child: const Icon(
                              Icons.check,
                              size: 13,
                              color: TAPAColors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f,
                          style: const TextStyle(
                              fontSize: 13,
                              color:
                              TAPAColors.textPrimary))),
                    ]),
                  )),
                ]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                LinkService.ouvrirBoutique(),
            icon: const Icon(
                Icons.shopping_bag_outlined,
                color: TAPAColors.gold),
            label: const Text(
                'Obtenir mon accès — 5 000 FCFA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: TAPAColors.greenLight,
                borderRadius:
                BorderRadius.circular(12)),
            child: const Column(children: [
              Row(children: [
                Icon(Icons.info_outline,
                    color: TAPAColors.green,
                    size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                    'Comment ça marche',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.green))),
              ]),
              SizedBox(height: 8),
              Text(
                  '1. Clique sur le bouton\n'
                      '2. Paie via Wave ou Orange Money\n'
                      '3. Tu reçois une clé d\'accès\n'
                      '4. Envoie-la sur WhatsApp',
                  style: TextStyle(
                      fontSize: 12,
                      color: TAPAColors.green,
                      height: 1.7)),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                LinkService.ouvrirWhatsApp(
                    message:
                    'Bonjour TAPA Budget ! '
                        'Je souhaite obtenir mon '
                        'accès à vie (5 000 FCFA).'),
            icon: const Icon(
                Icons.message_outlined),
            label: const Text(
                'Une question ? WhatsApp'),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}