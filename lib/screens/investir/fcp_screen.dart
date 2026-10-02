import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class InvestirFCPScreen extends StatefulWidget {
  const InvestirFCPScreen({super.key});
  @override
  State<InvestirFCPScreen> createState() => _InvestirFCPScreenState();
}

class _InvestirFCPScreenState extends State<InvestirFCPScreen> {
  static const double montantTotalInvesti = 250000;
  static const double evolutionPct = 4.2;

  static const List<Map<String, dynamic>> produits = [
    {
      'id': 'fcp_securite',
      'nom': 'FCP Securite',
      'icone': '🛡️',
      'profil': 'Prudent',
      'rendement': '4% - 6% / an',
      'couleurValue': 0xFF2ECC71,
      'description':
          'Place ton argent sur des obligations d Etat et titres '
          'securises. Ideal pour debuter en investissement sans '
          'prendre de risque important.',
      'montantMin': 10000,
      'duree': 'A partir de 6 mois',
    },
    {
      'id': 'fcp_equilibre',
      'nom': 'FCP Equilibre',
      'icone': '⚖️',
      'profil': 'Equilibre',
      'rendement': '6% - 9% / an',
      'couleurValue': 0xFFC9A227,
      'description':
          'Un mix entre obligations et actions cotees a la BRVM. '
          'Bon compromis entre securite et performance.',
      'montantMin': 25000,
      'duree': 'A partir de 12 mois',
    },
    {
      'id': 'fcp_croissance',
      'nom': 'FCP Croissance',
      'icone': '🚀',
      'profil': 'Dynamique',
      'rendement': '9% - 14% / an',
      'couleurValue': 0xFF9B59B6,
      'description':
          'Majoritairement investi en actions BRVM a fort '
          'potentiel. Pour les investisseurs prets a accepter '
          'plus de variations pour viser une meilleure performance.',
      'montantMin': 50000,
      'duree': 'A partir de 24 mois',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Investir'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => context.push('/investir/portefeuille'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [TAPAColors.navy, Color(0xFF14274E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Mon portefeuille',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.white54),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '${montantTotalInvesti.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: TAPAColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TAPAColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.trending_up,
                          size: 13, color: TAPAColors.green),
                        const SizedBox(width: 3),
                        Text('+${evolutionPct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: TAPAColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                      ])),
                    const SizedBox(width: 8),
                    const Text('depuis le debut',
                      style: TextStyle(
                        color: Colors.white54, fontSize: 11)),
                  ]),
                ]))),

          const SizedBox(height: 24),
          const Text('Nos produits partenaires',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
          const SizedBox(height: 4),
          const Text(
            'Investis ton epargne dans des fonds geres par '
            'des professionnels agrees.',
            style: TextStyle(
              fontSize: 13, color: TAPAColors.textSecond)),
          const SizedBox(height: 16),

          ...produits.map((p) => _carteProduit(context, p)),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TAPAColors.border)),
            child: Row(children: [
              const Icon(Icons.info_outline,
                size: 18, color: TAPAColors.textSecond),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Les fonds sont geres par notre partenaire agree. '
                'TAPA Invest facilite uniquement la mise en relation.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: TAPAColors.textSecond,
                  height: 1.4))),
            ])),
          const SizedBox(height: 24),
        ]));
  }

  Widget _carteProduit(BuildContext context, Map<String, dynamic> p) {
    final couleur = Color(p['couleurValue'] as int);
    return GestureDetector(
      onTap: () => context.push('/investir/produit/${p['id']}',
        extra: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TAPAColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TAPAColors.border, width: 0.5)),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(p['icone'] as String,
              style: const TextStyle(fontSize: 24)))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['nom'] as String,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(p['profil'] as String,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: couleur))),
                const SizedBox(width: 6),
                Text(p['rendement'] as String,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TAPAColors.textSecond)),
              ]),
            ])),
          const Icon(Icons.arrow_forward_ios,
            size: 14, color: TAPAColors.textHint),
        ])));
  }
}
