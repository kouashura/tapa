import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/db_service_mysql.dart';
import '../../../core/utils/formatters.dart';

class AssuranceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> produit;
  const AssuranceDetailScreen({super.key, required this.produit});

  @override
  Widget build(BuildContext context) {
    final db = DBService();
    final user = db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final couleur = Color(produit['couleurValue'] as int);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: Text(produit['nom'] as String),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: couleur.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: couleur.withOpacity(0.2))),
                child: Column(children: [
                  Text(produit['emoji'] as String,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(produit['nom'] as String,
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: couleur)),
                  Text(produit['description'] as String,
                      style: const TextStyle(fontSize: 13,
                          color: TAPAColors.textSecond),
                      textAlign: TextAlign.center),
                ])),
            const SizedBox(height: 20),

            // Informations clés
            _infoCard('Garantie', produit['garantie'] as String, Icons.shield_outlined),
            _infoCard('Durée', produit['duree'] as String, Icons.timer_outlined),
            _infoCard(
              'Prime mensuelle',
              '${Fmt.montant((produit['primeMin'] as int).toDouble(), monnaie: monnaie)} - ${Fmt.montant((produit['primeMax'] as int).toDouble(), monnaie: monnaie)}',
              Icons.attach_money_outlined,
            ),

            const SizedBox(height: 16),
            const Text('Avantages',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy)),
            const SizedBox(height: 8),
            ...(produit['avantages'] as List<String>).map((avantage) =>
                Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: TAPAColors.goldLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.check_circle,
                          color: couleur, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(avantage,
                          style: const TextStyle(
                              fontSize: 13,
                              color: TAPAColors.navy))),
                    ]))),
            const SizedBox(height: 20),

            // Bouton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Ouvrir WhatsApp pour souscription
                },
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Souscrire via WhatsApp'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TAPAColors.border, width: 0.5)),
        child: Row(children: [
          Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: TAPAColors.goldLight,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: TAPAColors.gold, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: TAPAColors.textSecond)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: TAPAColors.navy)),
              ])),
        ]));
  }
}