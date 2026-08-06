import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/pdf_service.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});
  @override
  State<RapportsScreen> createState() =>
      _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  bool _loading = false;

  Future<void> _generer(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'),
            backgroundColor: TAPAColors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final debutSemaine =
        now.subtract(Duration(days: now.weekday - 1));
    const mois = ['','Janvier','Fevrier','Mars',
      'Avril','Mai','Juin','Juillet','Aout',
      'Septembre','Octobre','Novembre','Decembre'];

    final moisPrecedent = now.month == 1 ? 12 : now.month - 1;
    final anneePrecedente = now.month == 1
        ? now.year - 1 : now.year;

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Rapports financiers'),
        backgroundColor: TAPAColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/profile'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: TAPAColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TAPAColors.navy,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Column(children: [
                    Icon(Icons.picture_as_pdf,
                      color: TAPAColors.gold, size: 32),
                    SizedBox(height: 8),
                    Text('Rapports PDF',
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.white)),
                    SizedBox(height: 4),
                    Text(
                      'Genere et partage tes rapports financiers',
                      style: TextStyle(fontSize: 12,
                        color: Colors.white54),
                      textAlign: TextAlign.center),
                  ])),
                const SizedBox(height: 20),
                const Text('RAPPORT JOURNALIER',
                  style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.textSecond,
                    letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _rapportCard(
                  icon: Icons.today,
                  titre: 'Rapport du jour',
                  sousTitre: "Aujourd'hui — ${now.day} ${mois[now.month]} ${now.year}",
                  color: TAPAColors.navy,
                  onTap: () => _generer(
                    () => PdfService.rapportJour(now))),
                const SizedBox(height: 16),
                const Text('RAPPORT HEBDOMADAIRE',
                  style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.textSecond,
                    letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _rapportCard(
                  icon: Icons.date_range,
                  titre: 'Rapport de la semaine',
                  sousTitre: 'Du ${debutSemaine.day} ${mois[debutSemaine.month]} au ${now.day} ${mois[now.month]} ${now.year}',
                  color: TAPAColors.purple,
                  onTap: () => _generer(
                    () => PdfService.rapportSemaine(debutSemaine))),
                const SizedBox(height: 16),
                const Text('RAPPORT MENSUEL',
                  style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.textSecond,
                    letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _rapportCard(
                  icon: Icons.calendar_month,
                  titre: 'Rapport ${mois[now.month]} ${now.year}',
                  sousTitre: 'Bilan complet avec analyse budgetaire',
                  color: TAPAColors.green,
                  onTap: () => _generer(
                    () => PdfService.rapportMensuel(
                      now.month, now.year))),
                const SizedBox(height: 8),
                _rapportCard(
                  icon: Icons.history,
                  titre: 'Rapport mois precedent',
                  sousTitre: '${mois[moisPrecedent]} $anneePrecedente',
                  color: TAPAColors.amber,
                  onTap: () => _generer(
                    () => PdfService.rapportMensuel(
                      moisPrecedent, anneePrecedente))),
                const SizedBox(height: 40),
              ]));
  }

  Widget _rapportCard({
    required IconData icon,
    required String titre,
    required String sousTitre,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TAPAColors.navy)),
              Text(sousTitre,
                style: const TextStyle(fontSize: 11,
                  color: TAPAColors.textSecond)),
            ])),
          const Icon(Icons.share,
            color: TAPAColors.green, size: 20),
        ])));
  }
}