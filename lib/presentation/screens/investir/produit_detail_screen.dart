import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ProduitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> produit;
  const ProduitDetailScreen({super.key, required this.produit});
  @override
  State<ProduitDetailScreen> createState() => _ProduitDetailScreenState();
}

class _ProduitDetailScreenState extends State<ProduitDetailScreen> {
  final _montantCtrl = TextEditingController();

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  void _confirmerSouscription() {
    final montant = double.tryParse(_montantCtrl.text);
    final montantMin = widget.produit['montantMin'] as int;
    if (montant == null || montant < montantMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Montant minimum: $montantMin FCFA'),
          backgroundColor: TAPAColors.red));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demande envoyee'),
        content: Text(
          'Ta demande de souscription de '
          '${montant.toStringAsFixed(0)} FCFA sur '
          '${widget.produit['nom']} a ete enregistree. '
          'Notre partenaire te contactera pour finaliser '
          'l operation.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('OK')),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produit;
    final couleur = Color(p['couleurValue'] as int);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: Text(p['nom'] as String),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18)),
            child: Center(child: Text(p['icone'] as String,
              style: const TextStyle(fontSize: 32))))),
          const SizedBox(height: 16),
          Center(child: Text(p['nom'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TAPAColors.navy))),
          const SizedBox(height: 6),
          Center(child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
            child: Text('Profil ${p['profil']}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: couleur)))),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: _statCard(
              'Rendement vise', p['rendement'] as String,
              Icons.trending_up, TAPAColors.green)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(
              'Duree conseillee', p['duree'] as String,
              Icons.calendar_today_outlined, TAPAColors.navy)),
          ]),
          const SizedBox(height: 20),

          const Text('A propos de ce fonds',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
          const SizedBox(height: 8),
          Text(p['description'] as String,
            style: const TextStyle(
              fontSize: 13.5,
              color: TAPAColors.textSecond,
              height: 1.6)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TAPAColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Montant a investir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TAPAColors.navy)),
                const SizedBox(height: 4),
                Text(
                  'Minimum: ${p['montantMin']} FCFA',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TAPAColors.textSecond)),
                const SizedBox(height: 12),
                TextField(
                  controller: _montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ex: ${p['montantMin']}',
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmerSouscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAPAColors.navy,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14)),
                    child: const Text('Souscrire maintenant',
                      style: TextStyle(
                        color: TAPAColors.gold,
                        fontWeight: FontWeight.w700)))),
              ])),
          const SizedBox(height: 16),
          const Row(children: [
            Icon(Icons.shield_outlined,
              size: 16, color: TAPAColors.textSecond),
            SizedBox(width: 6),
            Expanded(child: Text(
              'Fonds gere par notre partenaire agree. '
              'Capital soumis a fluctuation du marche.',
              style: TextStyle(
                fontSize: 11, color: TAPAColors.textSecond))),
          ]),
          const SizedBox(height: 20),
        ]));
  }

  Widget _statCard(String label, String value, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TAPAColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TAPAColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(
            fontSize: 10.5, color: TAPAColors.textSecond)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: TAPAColors.navy)),
        ]));
  }
}
