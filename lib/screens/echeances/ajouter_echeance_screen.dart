import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/echeance_model.dart';
import '../../services/db_service_mysql.dart';
import '../../services/notification_service.dart';
import '../../core/utils/formatters.dart';

class AjouterEcheanceScreen extends StatefulWidget {
  const AjouterEcheanceScreen({super.key});
  @override
  State<AjouterEcheanceScreen> createState() =>
      _AjouterEcheanceScreenState();
}

class _AjouterEcheanceScreenState extends State<AjouterEcheanceScreen> {
  final _titreCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _db = DBService();

  DateTime _dateChoisie = DateTime.now().add(const Duration(days: 7));
  String _frequence = 'unique';
  int _rappelAvant = 120;
  bool _dateSelectionnee = false;

  static const List<Map<String, dynamic>> _rappelOptions = [
    {'label': '1 heure avant', 'valeur': 1},
    {'label': '3 heures avant', 'valeur': 3},
    {'label': '6 heures avant', 'valeur': 6},
    {'label': '10 heures avant', 'valeur': 10},
    {'label': '1 jour avant', 'valeur': 24},
    {'label': '2 jours avant', 'valeur': 48},
    {'label': '3 jours avant', 'valeur': 72},
    {'label': '5 jours avant', 'valeur': 120},
    {'label': '1 semaine avant', 'valeur': 168},
  ];

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateChoisie,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),

      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: TAPAColors.navy,
            onPrimary: TAPAColors.white,
            onSurface: TAPAColors.navy)),
        child: child!));
    if (d != null) {
      setState(() {
        _dateChoisie = d;
        _dateSelectionnee = true;
      });
    }
  }

  Future<void> _enregistrer() async {
    final titre = _titreCtrl.text.trim();
    final montant = double.tryParse(_montantCtrl.text);

    if (titre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entrez un titre'),
        backgroundColor: TAPAColors.red));
      return;
    }
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entrez un montant valide'),
        backgroundColor: TAPAColors.red));
      return;
    }
    if (!_dateSelectionnee) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Choisissez une date'),
        backgroundColor: TAPAColors.red));
      return;
    }

    String type;
    int? jourDuMois;
    int? jourDeLaSemaine;
    DateTime? datePrecise;

    switch (_frequence) {
      case 'mensuelle':
        type = 'mensuelle';
        jourDuMois = _dateChoisie.day;
        break;
      case 'hebdomadaire':
        type = 'hebdomadaire';
        jourDeLaSemaine = _dateChoisie.weekday;
        break;
      default:
        type = 'unique';
        datePrecise = _dateChoisie;
    }

    final echeance = EcheanceModel(
      id: Fmt.genId(),
      titre: titre,
      montant: montant,
      type: type,
      jourDuMois: jourDuMois,
      jourDeLaSemaine: jourDeLaSemaine,
      datePrecise: datePrecise,
      rappelAvant: _rappelAvant,
      emoji: 'echeance',
    );

    await _db.saveEcheance(echeance);
    await NotificationService.programmerEcheance(echeance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Echeance ajoutee !'),
        backgroundColor: TAPAColors.green));
      context.pop();
    }
  }

  String _nomJour(int weekday) {
    const jours = ['', 'Lundi', 'Mardi', 'Mercredi',
      'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return jours[weekday];
  }

  @override
  Widget build(BuildContext context) {
    final monnaie = _db.getUser()?['monnaie'] ?? 'FCFA';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle echeance'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // Titre
          TextField(
            controller: _titreCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Titre de l echeance',
              hintText: 'Ex: Scolarite enfants, Loyer, CIE...',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 14),

          // Montant
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: monnaie,
              hintText: 'Ex: 100000',
              prefixIcon: const Icon(Icons.attach_money_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 24),

          // Calendrier
          const Text('Date de l echeance',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _choisirDate,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _dateSelectionnee
                  ? TAPAColors.navy
                  : TAPAColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _dateSelectionnee
                    ? TAPAColors.navy
                    : TAPAColors.border,
                  width: _dateSelectionnee ? 0 : 1)),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _dateSelectionnee
                      ? TAPAColors.gold.withOpacity(0.2)
                      : TAPAColors.goldLight,
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.calendar_month,
                    color: TAPAColors.gold, size: 26)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateSelectionnee
                        ? '${_dateChoisie.day}/${_dateChoisie.month}/${_dateChoisie.year}'
                        : 'Choisir la date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dateSelectionnee
                          ? TAPAColors.white
                          : TAPAColors.navy)),
                    if (_dateSelectionnee)
                      Text(
                        _nomJour(_dateChoisie.weekday),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60)),
                  ])),
                Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: _dateSelectionnee
                    ? Colors.white54
                    : TAPAColors.textHint),
              ])),
            ),
          const SizedBox(height: 24),

          // Frequence (visible seulement apres avoir choisi une date)
          if (_dateSelectionnee) ...[
            const Text('Frequence',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: TAPAColors.navy)),
            const SizedBox(height: 10),

            _freqCard(
              'unique',
              'Une seule fois',
              'Le ${_dateChoisie.day}/${_dateChoisie.month}/${_dateChoisie.year} uniquement',
              Icons.looks_one_outlined),
            const SizedBox(height: 8),
            _freqCard(
              'mensuelle',
              'Tous les mois',
              'Le ${_dateChoisie.day} de chaque mois',
              Icons.repeat_outlined),
            const SizedBox(height: 8),
            _freqCard(
              'hebdomadaire',
              'Chaque semaine',
              'Chaque ${_nomJour(_dateChoisie.weekday)}',
              Icons.view_week_outlined),
            const SizedBox(height: 24),
          ],

          // Rappel
          const Text('Me rappeler',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _rappelAvant,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.notifications_outlined,
                color: TAPAColors.gold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            items: _rappelOptions.map((o) => DropdownMenuItem<int>(
              value: o['valeur'] as int,
              child: Text(o['label'] as String))).toList(),
            onChanged: (v) =>
              setState(() => _rappelAvant = v ?? 120)),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _enregistrer,
            style: ElevatedButton.styleFrom(
              backgroundColor: TAPAColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Enregistrer l echeance',
              style: TextStyle(
                color: TAPAColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w700))),
          const SizedBox(height: 20),
        ]));
  }

  Widget _freqCard(String val, String titre,
      String sous, IconData icon) {
    final isActive = _frequence == val;
    return GestureDetector(
      onTap: () => setState(() => _frequence = val),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
            ? TAPAColors.navy.withOpacity(0.06)
            : TAPAColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? TAPAColors.navy : TAPAColors.border,
            width: isActive ? 2 : 0.5)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isActive
                ? TAPAColors.navy
                : TAPAColors.navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20,
              color: isActive
                ? TAPAColors.gold
                : TAPAColors.navy)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive
                    ? TAPAColors.navy
                    : TAPAColors.navy)),
              Text(sous,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: TAPAColors.textSecond)),
            ])),
          if (isActive)
            const Icon(Icons.check_circle,
              color: TAPAColors.navy, size: 22),
        ])));
  }
}
