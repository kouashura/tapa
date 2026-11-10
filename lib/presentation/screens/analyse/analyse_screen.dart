// lib/screens/analyse/analyse_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart'; // ✅ CHEMIN CORRIGÉ
import '../../../services/db_service_mysql.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import 'dart:math' as math;

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({super.key});
  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DBService _db = DBService();

  // ✅ Cache pour les transactions
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Charger toutes les transactions une fois
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allTransactions = await _db.getTransactions();
    } catch (e) {
      print('Erreur chargement transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ CORRIGÉ : Obtenir transactions du mois
  List<TransactionModel> _txDuMois(int mois, int annee) {
    return _allTransactions
        .where((t) =>
            t.dateTransaction.month == mois &&
            t.dateTransaction.year == annee &&
            t.isDepense)
        .toList();
  }

  // ✅ CORRIGÉ : Obtenir transactions de l'année
  List<TransactionModel> _txAnnee(int annee) {
    return _allTransactions
        .where((t) => t.dateTransaction.year == annee && t.isDepense)
        .toList();
  }

  // Grouper par categorie
  Map<String, double> _parCategorie(List<TransactionModel> txs) {
    final map = <String, double>{};
    for (final tx in txs) {
      map[tx.categorieLabel] = (map[tx.categorieLabel] ?? 0) + tx.montant;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  // Grouper par mois
  Map<int, double> _parMois(int annee) {
    final map = <int, double>{};
    for (int m = 1; m <= 12; m++) {
      map[m] = 0;
    }
    final transactions = _txAnnee(annee);
    for (final tx in transactions) {
      map[tx.dateTransaction.month] =
          (map[tx.dateTransaction.month] ?? 0) + tx.montant;
    }
    return map;
  }

  // Calcul regle 50/30/20
  Map<String, double> _calcul5030(List<TransactionModel> txs) {
    final cats = _db.getCategories();
    double essentielle = 0, loisir = 0, epargne = 0, nonclasse = 0;
    for (final tx in txs) {
      final catList =
          cats.where((c) => c['label'] == tx.categorieLabel).toList();
      final cat = catList.isNotEmpty ? catList.first : <String, dynamic>{};
      final type = cat['typeBudget'] as String? ?? '';
      switch (type) {
        case 'essentielle':
          essentielle += tx.montant;
          break;
        case 'loisir':
          loisir += tx.montant;
          break;
        case 'epargne':
          epargne += tx.montant;
          break;
        default:
          nonclasse += tx.montant;
      }
    }
    return {
      'essentielle': essentielle,
      'loisir': loisir,
      'epargne': epargne,
      'nonclasse': nonclasse,
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TAPAColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        backgroundColor: TAPAColors.background,
        appBar: AppBar(
            title: const Text('Analyse financiere'),
            backgroundColor: TAPAColors.navy,
            foregroundColor: TAPAColors.white,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => context.pop()),
            bottom: TabBar(
                controller: _tabController,
                indicatorColor: TAPAColors.gold,
                labelColor: TAPAColors.gold,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Mensuel'),
                  Tab(text: 'Annuel'),
                  Tab(text: '50/30/20'),
                ])),
        body: TabBarView(controller: _tabController, children: [
          _vueMensuelle(now, monnaie),
          _vueAnnuelle(now, monnaie),
          _vue503020(now, monnaie),
        ]));
  }

  // VUE MENSUELLE
  Widget _vueMensuelle(DateTime now, String monnaie) {
    final txMoisCourant = _txDuMois(now.month, now.year);
    final txMoisPrecedent = _txDuMois(now.month == 1 ? 12 : now.month - 1,
        now.month == 1 ? now.year - 1 : now.year);

    final totalCourant = txMoisCourant.fold(0.0, (s, t) => s + t.montant);
    final totalPrecedent = txMoisPrecedent.fold(0.0, (s, t) => s + t.montant);
    final evolution = totalPrecedent > 0
        ? ((totalCourant - totalPrecedent) / totalPrecedent * 100)
        : 0.0;

    final parCat = _parCategorie(txMoisCourant);
    final parCatPrec = _parCategorie(txMoisPrecedent);
    final total = totalCourant > 0 ? totalCourant : 1;

    final colors = [
      TAPAColors.red,
      TAPAColors.gold,
      TAPAColors.purple,
      TAPAColors.green,
      TAPAColors.navy,
      const Color(0xFFE67E22),
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Resume mois
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [TAPAColors.navy, Color(0xFF14274E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Depenses ${_nomMois(now.month)} ${now.year}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(Fmt.montant(totalCourant, monnaie: monnaie),
                style: const TextStyle(
                    color: TAPAColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(evolution <= 0 ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: evolution <= 0 ? TAPAColors.green : TAPAColors.red),
              const SizedBox(width: 4),
              Text(
                  '${evolution >= 0 ? '+' : ''}${evolution.toStringAsFixed(1)}% vs mois precedent',
                  style: TextStyle(
                      fontSize: 12,
                      color: evolution <= 0 ? TAPAColors.green : TAPAColors.red,
                      fontWeight: FontWeight.w600)),
            ]),
          ])),
      const SizedBox(height: 20),

      // Camembert
      if (parCat.isNotEmpty) ...[
        const Text('Repartition par categorie',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy)),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                  painter: _PiePainter(parCat.values.toList(), colors))),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  children:
                      parCat.entries.take(5).toList().asMap().entries.map((e) {
            final pct = e.value.value / total * 100;
            final color = colors[e.key % colors.length];
            return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(e.value.key,
                          style: const TextStyle(
                              fontSize: 11, color: TAPAColors.navy),
                          overflow: TextOverflow.ellipsis)),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ]));
          }).toList())),
        ]),
        const SizedBox(height: 20),
      ],

      // Comparaison avec mois precedent
      const Text('Comparaison avec le mois precedent',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
      const SizedBox(height: 12),
      ...parCat.entries.take(6).toList().asMap().entries.map((e) {
        final catLabel = e.value.key;
        final montantCourant = e.value.value;
        final montantPrec = parCatPrec[catLabel] ?? 0;
        final diff = montantPrec > 0
            ? ((montantCourant - montantPrec) / montantPrec * 100)
            : 0.0;
        final color = colors[e.key % colors.length];
        return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.border, width: 0.5)),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(catLabel,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TAPAColors.navy))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Fmt.montant(montantCourant, monnaie: monnaie),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.navy)),
                if (montantPrec > 0)
                  Row(children: [
                    Icon(diff <= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 11,
                        color: diff <= 0 ? TAPAColors.green : TAPAColors.red),
                    Text('${diff.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color:
                                diff <= 0 ? TAPAColors.green : TAPAColors.red)),
                  ]),
              ]),
            ]));
      }),
    ]);
  }

  // VUE ANNUELLE
  Widget _vueAnnuelle(DateTime now, String monnaie) {
    final parMois = _parMois(now.year);
    final txAnnee = _txAnnee(now.year);
    final totalAnnee = txAnnee.fold(0.0, (s, t) => s + t.montant);
    final parCat = _parCategorie(txAnnee);
    final maxMois =
        parMois.values.isEmpty ? 1.0 : parMois.values.reduce(math.max);

    final colors = [
      TAPAColors.red,
      TAPAColors.gold,
      TAPAColors.purple,
      TAPAColors.green,
      TAPAColors.navy,
      const Color(0xFFE67E22),
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [TAPAColors.navy, Color(0xFF14274E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total depenses ${now.year}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(Fmt.montant(totalAnnee, monnaie: monnaie),
                style: const TextStyle(
                    color: TAPAColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                'Moyenne mensuelle: ${Fmt.montant(totalAnnee / 12, monnaie: monnaie)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
      const SizedBox(height: 20),

      // Graphique barres mensuel
      const Text('Evolution mensuelle',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
      const SizedBox(height: 12),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: TAPAColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TAPAColors.border, width: 0.5)),
          child: Column(children: [
            SizedBox(
                height: 150,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(12, (i) {
                      final mois = i + 1;
                      final val = parMois[mois] ?? 0;
                      final hauteur = maxMois > 0 ? (val / maxMois * 130) : 0.0;
                      final isCurrentMonth = mois == now.month;
                      return Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            Container(
                                height: hauteur,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: isCurrentMonth
                                        ? TAPAColors.gold
                                        : TAPAColors.navy.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4))),
                          ]));
                    }))),
            const SizedBox(height: 8),
            Row(
                children: List.generate(
                    12,
                    (i) => Expanded(
                        child: Text(_nomMoisCourt(i + 1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 8,
                                color: i + 1 == now.month
                                    ? TAPAColors.gold
                                    : TAPAColors.textHint,
                                fontWeight: i + 1 == now.month
                                    ? FontWeight.w700
                                    : FontWeight.normal))))),
          ])),
      const SizedBox(height: 20),

      // Top categories annuelles
      const Text('Top categories annuelles',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TAPAColors.navy)),
      const SizedBox(height: 12),
      ...parCat.entries.take(6).toList().asMap().entries.map((e) {
        final pct = totalAnnee > 0 ? e.value.value / totalAnnee * 100 : 0.0;
        final color = colors[e.key % colors.length];
        return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.border, width: 0.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(e.value.key,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.navy)),
                const Spacer(),
                Text(Fmt.montant(e.value.value, monnaie: monnaie),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(width: 8),
                Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: color)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: TAPAColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(color))),
            ]));
      }),
    ]);
  }

  // VUE 50/30/20
  Widget _vue503020(DateTime now, String monnaie) {
    final txMois = _txDuMois(now.month, now.year);
    final totalMois = txMois.fold(0.0, (s, t) => s + t.montant);
    final repartition = _calcul5030(txMois);

    final essentielle = repartition['essentielle'] ?? 0;
    final loisir = repartition['loisir'] ?? 0;
    final epargne = repartition['epargne'] ?? 0;
    final nonclasse = repartition['nonclasse'] ?? 0;

    final pctEss = totalMois > 0 ? essentielle / totalMois * 100 : 0.0;
    final pctLoi = totalMois > 0 ? loisir / totalMois * 100 : 0.0;
    final pctEpa = totalMois > 0 ? epargne / totalMois * 100 : 0.0;

    // Alertes depassement
    final alerteEss = pctEss > 50;
    final alerteLoi = pctLoi > 30;
    final alerteEpa = pctEpa < 20 && epargne > 0;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Explication regle
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: TAPAColors.navy, borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Regle 50 / 30 / 20',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TAPAColors.gold)),
            const SizedBox(height: 8),
            _regleItem(
                '50%', 'Essentielles', 'Loyer, nourriture, factures, sante'),
            _regleItem('30%', 'Loisirs', 'Sorties, habits, divertissement'),
            _regleItem('20%', 'Epargne', 'Investissement, objectifs, avenir'),
          ])),
      const SizedBox(height: 20),

      // Alertes
      if (alerteEss || alerteLoi || alerteEpa) ...[
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: TAPAColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.red.withOpacity(0.3))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: TAPAColors.red, size: 18),
                SizedBox(width: 8),
                Text('Alertes budget',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TAPAColors.red)),
              ]),
              const SizedBox(height: 8),
              if (alerteEss)
                Text(
                    'Depenses essentielles: ${pctEss.toStringAsFixed(1)}% (max 50%)',
                    style:
                        const TextStyle(fontSize: 12, color: TAPAColors.red)),
              if (alerteLoi)
                Text('Loisirs: ${pctLoi.toStringAsFixed(1)}% (max 30%)',
                    style:
                        const TextStyle(fontSize: 12, color: TAPAColors.red)),
              if (alerteEpa)
                Text(
                    'Epargne insuffisante: ${pctEpa.toStringAsFixed(1)}% (min 20%)',
                    style:
                        const TextStyle(fontSize: 12, color: TAPAColors.red)),
            ])),
        const SizedBox(height: 16),
      ],

      // Jauges 50/30/20
      _jaugeBudget(
          'Essentielles', essentielle, pctEss, 50, TAPAColors.navy, monnaie),
      const SizedBox(height: 10),
      _jaugeBudget('Loisirs', loisir, pctLoi, 30, TAPAColors.gold, monnaie),
      const SizedBox(height: 10),
      _jaugeBudget('Epargne', epargne, pctEpa, 20, TAPAColors.green, monnaie),
      if (nonclasse > 0) ...[
        const SizedBox(height: 10),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TAPAColors.border)),
            child: Row(children: [
              const Icon(Icons.help_outline,
                  size: 16, color: TAPAColors.textSecond),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Non classe: ${Fmt.montant(nonclasse, monnaie: monnaie)} - Classez vos categories pour une meilleure analyse',
                      style: const TextStyle(
                          fontSize: 11.5, color: TAPAColors.textSecond))),
            ])),
      ],
      const SizedBox(height: 20),
    ]);
  }

  Widget _regleItem(String pct, String label, String desc) {
    return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Container(
              width: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: TAPAColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(pct,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.gold))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.white)),
            Text(desc,
                style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ]),
        ]));
  }

  Widget _jaugeBudget(String label, double montant, double pct, double cible,
      Color color, String monnaie) {
    final depasse = pct > cible;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TAPAColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: depasse ? TAPAColors.red : TAPAColors.border,
                width: depasse ? 1.5 : 0.5)),
        child: Column(children: [
          Row(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TAPAColors.navy)),
            const Spacer(),
            Text(Fmt.montant(montant, monnaie: monnaie),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: (depasse ? TAPAColors.red : color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: depasse ? TAPAColors.red : color))),
          ]),
          const SizedBox(height: 8),
          Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: TAPAColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        depasse ? TAPAColors.red : color))),
            Positioned(
                left: cible / 100 * (MediaQuery.of(context).size.width - 76),
                child: Container(
                    width: 2,
                    height: 10,
                    color: TAPAColors.navy.withOpacity(0.4))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('Objectif: $cible%',
                style: const TextStyle(
                    fontSize: 10, color: TAPAColors.textSecond)),
            const Spacer(),
            if (depasse)
              Text('Depasse de ${(pct - cible).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 10,
                      color: TAPAColors.red,
                      fontWeight: FontWeight.w600)),
          ]),
        ]));
  }

  String _nomMois(int m) {
    const mois = [
      '',
      'Janvier',
      'Fevrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Aout',
      'Septembre',
      'Octobre',
      'Novembre',
      'Decembre'
    ];
    return mois[m];
  }

  String _nomMoisCourt(int m) {
    const mois = [
      '',
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D'
    ];
    return mois[m];
  }
}

class _PiePainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  _PiePainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0.0, (s, v) => s + v);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -math.pi / 2;
    for (int i = 0; i < data.length; i++) {
      final sweep = data[i] / total * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweep, true, Paint()..color = colors[i % colors.length]);
      startAngle += sweep;
    }
    canvas.drawCircle(center, radius * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
