import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PortefeuilleScreen extends StatefulWidget {
  const PortefeuilleScreen({super.key});
  @override
  State<PortefeuilleScreen> createState() => _PortefeuilleScreenState();
}

class _PortefeuilleScreenState extends State<PortefeuilleScreen> {
  // Donnees de demonstration
  static const double montantInvesti = 240000;
  static const double valeurActuelle = 250000;
  static const double evolutionPct = 4.2;

  static const List<Map<String, dynamic>> mesPositions = [
    {
      'nom': 'FCP Securite',
      'icone': '🛡️',
      'montant': 100000,
      'valeur': 103200,
      'couleurValue': 0xFF2ECC71,
    },
    {
      'nom': 'FCP Equilibre',
      'icone': '⚖️',
      'montant': 100000,
      'valeur': 105500,
      'couleurValue': 0xFFC9A227,
    },
    {
      'nom': 'FCP Croissance',
      'icone': '🚀',
      'montant': 40000,
      'valeur': 41300,
      'couleurValue': 0xFF9B59B6,
    },
  ];

  // Points pour le graphique d evolution (demo)
  static const List<double> evolutionPoints = [
    240000,
    241500,
    239800,
    243200,
    245600,
    244100,
    247800,
    249200,
    248000,
    250000,
  ];

  void _demanderRetrait() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
                decoration: const BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Demande de retrait',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: TAPAColors.navy)),
                  const SizedBox(height: 6),
                  Text(
                      'Solde disponible: ${valeurActuelle.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontSize: 12.5, color: TAPAColors.textSecond)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Montant a retirer',
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Demande de retrait envoyee. Traitement '
                                        'sous 48h ouvrees par notre partenaire.'),
                                    backgroundColor: TAPAColors.green,
                                    duration: Duration(seconds: 4)));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: TAPAColors.navy,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Confirmer la demande',
                              style: TextStyle(
                                  color: TAPAColors.gold,
                                  fontWeight: FontWeight.w700)))),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler',
                          style: TextStyle(color: TAPAColors.textSecond))),
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    const gainTotal = valeurActuelle - montantInvesti;

    return Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
            title: const Text('Mon portefeuille'),
            backgroundColor: TAPAColors.navy,
            foregroundColor: TAPAColors.white),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
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
                    const Text('Valeur actuelle',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('${valeurActuelle.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            color: TAPAColors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: TAPAColors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                              '+${gainTotal.toStringAsFixed(0)} FCFA '
                              '(+${evolutionPct.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                  color: TAPAColors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                        height: 80,
                        child: CustomPaint(
                            size: const Size(double.infinity, 80),
                            painter: _EvolutionPainter(evolutionPoints))),
                  ])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Investir plus'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.gold,
                        foregroundColor: TAPAColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
            const SizedBox(width: 10),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _demanderRetrait,
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: const Text('Retirer'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: TAPAColors.navy,
                        side: const BorderSide(color: TAPAColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
          const SizedBox(height: 24),
          const Text('Mes placements',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TAPAColors.navy)),
          const SizedBox(height: 12),
          ...mesPositions.map((pos) {
            final gain = (pos['valeur'] as int) - (pos['montant'] as int);
            final pct = gain / (pos['montant'] as int) * 100;
            final couleur = Color(pos['couleurValue'] as int);
            return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TAPAColors.border, width: 0.5)),
                child: Row(children: [
                  Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: couleur.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(pos['icone'] as String,
                              style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(pos['nom'] as String,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: TAPAColors.navy)),
                        Text('Investi: ${pos['montant']} FCFA',
                            style: const TextStyle(
                                fontSize: 11.5, color: TAPAColors.textSecond)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${pos['valeur']} FCFA',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy)),
                    Text('+${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.green)),
                  ]),
                ]));
          }),
          const SizedBox(height: 20),
        ]));
  }
}

class _EvolutionPainter extends CustomPainter {
  final List<double> points;
  _EvolutionPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minV) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
        fillPath, Paint()..color = const Color(0xFFC9A227).withOpacity(0.15));

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC9A227)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
