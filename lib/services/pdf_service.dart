import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/models.dart';
import 'score_service.dart';
import 'db_service_mysql.dart';
import '../core/utils/formatters.dart';

class PdfService {
  static final DBService _db = DBService();
  static const _mois = [
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

  static Future<void> rapportJour(DateTime date) async {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final prenom = user?['prenom'] ?? '';
    final tel = user?['telephone'] ?? '';

    // ✅ CORRECTION : Ajouter await et utiliser _db
    final allTx = await _db.getTransactions();
    final txs = allTx
        .where((t) =>
            t.dateTransaction.year == date.year &&
            t.dateTransaction.month == date.month &&
            t.dateTransaction.day == date.day)
        .toList();
    final dep = txs.where((t) => t.isDepense).toList();
    final rev = txs.where((t) => t.isRevenu).toList();
    final tDep = dep.fold(0.0, (s, t) => s + t.montant);
    final tRev = rev.fold(0.0, (s, t) => s + t.montant);
    final dateStr = '${date.day} ${_mois[date.month]} ${date.year}';

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
              _entete('RAPPORT FINANCIER JOURNALIER', prenom, tel),
              _sousTitre(dateStr),
              pw.SizedBox(height: 20),
              _statsRow(tRev, tDep, tRev - tDep, monnaie),
              pw.SizedBox(height: 24),
              if (rev.isNotEmpty) ...[
                _sectionTitre('REVENUS', PdfColors.green800),
                _tableTx(rev, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (dep.isNotEmpty) ...[
                _sectionTitre('DEPENSES', PdfColors.red800),
                _tableTx(dep, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (txs.isEmpty)
                pw.Center(child: pw.Text('Aucune transaction ce jour.')),
              pw.SizedBox(height: 24),
              _rapportEcrit(tRev, tDep, monnaie),
              pw.SizedBox(height: 20),
              _pied(),
            ]));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'TAPA_Rapport_Jour_$dateStr.pdf');
  }

  static Future<void> rapportSemaine(DateTime debut) async {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final prenom = user?['prenom'] ?? '';
    final tel = user?['telephone'] ?? '';
    final fin = debut.add(const Duration(days: 6));

    // ✅ CORRECTION : Ajouter await et utiliser _db
    final allTx = await _db.getTransactions();
    final txs = allTx
        .where((t) =>
            t.dateTransaction
                .isAfter(debut.subtract(const Duration(days: 1))) &&
            t.dateTransaction.isBefore(fin.add(const Duration(days: 1))))
        .toList();
    final dep = txs.where((t) => t.isDepense).toList();
    final rev = txs.where((t) => t.isRevenu).toList();
    final tDep = dep.fold(0.0, (s, t) => s + t.montant);
    final tRev = rev.fold(0.0, (s, t) => s + t.montant);
    final periodeStr =
        'Du ${debut.day} au ${fin.day} ${_mois[fin.month]} ${fin.year}';

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
              _entete('RAPPORT FINANCIER HEBDOMADAIRE', prenom, tel),
              _sousTitre(periodeStr),
              pw.SizedBox(height: 20),
              _statsRow(tRev, tDep, tRev - tDep, monnaie),
              pw.SizedBox(height: 24),
              if (rev.isNotEmpty) ...[
                _sectionTitre('REVENUS DE LA SEMAINE', PdfColors.green800),
                _tableTx(rev, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (dep.isNotEmpty) ...[
                _sectionTitre('DEPENSES DE LA SEMAINE', PdfColors.red800),
                _tableTx(dep, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (txs.isEmpty)
                pw.Center(child: pw.Text('Aucune transaction cette semaine.')),
              pw.SizedBox(height: 24),
              _rapportEcrit(tRev, tDep, monnaie),
              pw.SizedBox(height: 20),
              _pied(),
            ]));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'TAPA_Rapport_Semaine.pdf');
  }

  static Future<void> rapportMensuel(int mois, int annee) async {
    final user = _db.getUser();
    final monnaie = user?['monnaie'] ?? 'FCFA';
    final prenom = user?['prenom'] ?? '';
    final tel = user?['telephone'] ?? '';

    // ✅ CORRECTION : Ajouter await et utiliser _db
    final allTx = await _db.getTransactions();
    final txs = allTx
        .where((t) =>
            t.dateTransaction.month == mois && t.dateTransaction.year == annee)
        .toList();
    final dep = txs.where((t) => t.isDepense).toList();
    final rev = txs.where((t) => t.isRevenu).toList();
    final tDep = dep.fold(0.0, (s, t) => s + t.montant);
    final tRev = rev.fold(0.0, (s, t) => s + t.montant);

    final budget = await _db.getBudget(mois, annee);

    final premiereDate = txs.isNotEmpty
        ? txs
            .map((t) => t.dateTransaction)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime(annee, mois, 1);
    final derniereDate = txs.isNotEmpty
        ? txs
            .map((t) => t.dateTransaction)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime(annee, mois, 30);

    final periodeStr =
        '${_mois[mois]} $annee — Du ${premiereDate.day} au ${derniereDate.day} ${_mois[mois]}';

    final Map<String, double> parCat = {};
    for (final t in dep) {
      parCat[t.categorieLabel] = (parCat[t.categorieLabel] ?? 0) + t.montant;
    }
    final catSorted = parCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<pw.TableRow> lignesBudget = [];
    if (budget != null) {
      for (final l in budget.depenses) {
        final reel =
            await _db.getDepensesReellesByCategorie(l.categorieId, mois, annee);
        final ecart = l.montantPrevu - reel;
        final ecartStr = ecart >= 0
            ? '+${Fmt.montant(ecart, monnaie: monnaie)}'
            : Fmt.montant(ecart, monnaie: monnaie);
        lignesBudget.add(pw.TableRow(children: [
          _cell('${l.categorieEmoji} ${l.categorieLabel}'),
          _cell(Fmt.montant(l.montantPrevu, monnaie: monnaie)),
          _cell(Fmt.montant(reel, monnaie: monnaie)),
          _cellColor(
              ecartStr, ecart >= 0 ? PdfColors.green800 : PdfColors.red800),
        ]));
      }
    }

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
              _entete('RAPPORT BUDGETAIRE MENSUEL', prenom, tel),
              _sousTitre(periodeStr),
              pw.SizedBox(height: 20),
              _statsRow(tRev, tDep, tRev - tDep, monnaie),
              pw.SizedBox(height: 24),
              if (budget != null) ...[
                _sectionTitre(
                    'BUDGET PREVISIONNEL VS REEL', PdfColors.blueGrey800),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(
                              color: PdfColors.blueGrey800),
                          children: [
                            _cellHeader('Catégorie'),
                            _cellHeader('Prévu'),
                            _cellHeader('Réel'),
                            _cellHeader('Ecart'),
                          ]),
                      ...lignesBudget,
                    ]),
                pw.SizedBox(height: 20),
              ],
              if (rev.isNotEmpty) ...[
                _sectionTitre('REVENUS DU MOIS', PdfColors.green800),
                _tableTx(rev, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (dep.isNotEmpty) ...[
                _sectionTitre('DEPENSES DU MOIS', PdfColors.red800),
                _tableTx(dep, monnaie),
                pw.SizedBox(height: 16),
              ],
              if (catSorted.isNotEmpty) ...[
                _sectionTitre('DEPENSES PAR CATEGORIE', PdfColors.orange800),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(
                              color: PdfColors.orange800),
                          children: [
                            _cellHeader('Catégorie'),
                            _cellHeader('Montant'),
                            _cellHeader('Pourcentage'),
                          ]),
                      ...catSorted.map((e) {
                        final pct = tDep > 0
                            ? '${(e.value / tDep * 100).round()}%'
                            : '0%';
                        return pw.TableRow(children: [
                          _cell(e.key),
                          _cell(Fmt.montant(e.value, monnaie: monnaie)),
                          _cell(pct),
                        ]);
                      }),
                    ]),
                pw.SizedBox(height: 20),
              ],
              _rapportEcrit(tRev, tDep, monnaie),
              pw.SizedBox(height: 20),
              _pied(),
            ]));
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'TAPA_Rapport_${_mois[mois]}_$annee.pdf');
  }

  static Future<void> rapportScore(DBService db) async {
    final user = db.getUser();
    final prenom = user?['prenom'] ?? '';
    final tel = user?['telephone'] ?? '';
    final monnaie = user?['monnaie'] ?? 'FCFA';

    final score = await ScoreService.calculer(db);

    final now = DateTime.now();
    final mois = [
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
    final dateStr = '${now.day} ${mois[now.month]} ${now.year}';

    PdfColor scoreColor;
    if (score.scoreTotal >= 80) {
      scoreColor = PdfColors.green800;
    } else if (score.scoreTotal >= 60)
      scoreColor = PdfColors.blue800;
    else if (score.scoreTotal >= 40)
      scoreColor = PdfColors.orange800;
    else
      scoreColor = PdfColors.red800;

    // ✅ CORRECTION : Ajouter await
    final allTx = await db.getTransactions();
    final totalRev =
        allTx.where((t) => t.isRevenu).fold(0.0, (s, t) => s + t.montant);
    final totalDep =
        allTx.where((t) => t.isDepense).fold(0.0, (s, t) => s + t.montant);
    final totalSolde = totalRev - totalDep;

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
              _entete('RAPPORT SCORE TAPA', prenom, tel),
              _sousTitre('Genere le $dateStr'),
              pw.SizedBox(height: 20),
              pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                      borderRadius: pw.BorderRadius.circular(12)),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(children: [
                          pw.Text('SCORE TAPA',
                              style: const pw.TextStyle(
                                  fontSize: 11, color: PdfColors.grey300)),
                          pw.SizedBox(height: 8),
                          pw.Text('${score.scoreTotal}/100',
                              style: pw.TextStyle(
                                  fontSize: 32,
                                  fontWeight: pw.FontWeight.bold,
                                  color: scoreColor)),
                          pw.SizedBox(height: 4),
                          pw.Text(score.niveau,
                              style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: scoreColor)),
                        ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _scoreRow('Revenus', score.scoreRevenus, 20),
                              _scoreRow('Dépenses', score.scoreDepenses, 20),
                              _scoreRow('Épargne', score.scoreEpargne, 20),
                              _scoreRow('Dettes', score.scoreDettes, 20),
                              _scoreRow(
                                  'Régularité', score.scoreRegularite, 20),
                            ]),
                      ])),
              pw.SizedBox(height: 20),
              _sectionTitre('APERCU FINANCIER', PdfColors.blueGrey800),
              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(
                            color: PdfColors.blueGrey700),
                        children: [
                          _cellHeader('Indicateur'),
                          _cellHeader('Valeur'),
                          _cellHeader('Période'),
                        ]),
                    pw.TableRow(children: [
                      _cell('Total Revenus'),
                      _cell(Fmt.montant(totalRev, monnaie: monnaie)),
                      _cell('Depuis inscription'),
                    ]),
                    pw.TableRow(children: [
                      _cell('Total Dépenses'),
                      _cell(Fmt.montant(totalDep, monnaie: monnaie)),
                      _cell('Depuis inscription'),
                    ]),
                    pw.TableRow(children: [
                      _cell('Solde total'),
                      _cell(Fmt.montant(totalSolde, monnaie: monnaie)),
                      _cell('Actuel'),
                    ]),
                    pw.TableRow(children: [
                      _cell('Transactions'),
                      _cell(allTx.length.toString()),
                      _cell('Total'),
                    ]),
                    pw.TableRow(children: [
                      _cell('Objectifs épargne'),
                      _cell(db.getSavingsGoals().length.toString()),
                      _cell('Actifs'),
                    ]),
                    pw.TableRow(children: [
                      _cell('Dettes en cours'),
                      _cell(db
                          .getDettes()
                          .where((d) => !d.estSolde)
                          .length
                          .toString()),
                      _cell('Actives'),
                    ]),
                  ]),
              pw.SizedBox(height: 20),
              if (score.pointsForts.isNotEmpty) ...[
                _sectionTitre('POINTS FORTS', PdfColors.green800),
                ...score.pointsForts.map((p) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(children: [
                      pw.Text('+ ',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800)),
                      pw.Expanded(
                          child: pw.Text(p,
                              style: const pw.TextStyle(fontSize: 10))),
                    ]))),
                pw.SizedBox(height: 16),
              ],
              if (score.conseils.isNotEmpty) ...[
                _sectionTitre('AXES D AMELIORATION', PdfColors.orange800),
                ...score.conseils.map((c) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(children: [
                      pw.Text('> ',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange800)),
                      pw.Expanded(
                          child: pw.Text(c,
                              style: const pw.TextStyle(fontSize: 10))),
                    ]))),
                pw.SizedBox(height: 16),
              ],
              pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NOTE IMPORTANTE',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            'Ce score est base sur les donnees auto-declarees par '
                            'l utilisateur dans TAPA Invest. Il est fourni a titre '
                            'indicatif et educatif. Pour une evaluation officielle, '
                            'des donnees vérifiees par des tiers sont nécessaires.',
                            style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                                lineSpacing: 3)),
                      ])),
              pw.SizedBox(height: 20),
              _sectionTitre('ANALYSE DE FIABILITE', PdfColors.blueGrey800),
              pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                      color:
                          score.estFiable ? PdfColors.green50 : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                          color: score.estFiable
                              ? PdfColors.green800
                              : PdfColors.red800)),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(children: [
                          pw.Text(
                              score.estFiable
                                  ? 'SCORE FIABLE'
                                  : 'INCOHERENCES DETECTEES',
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: score.estFiable
                                      ? PdfColors.green800
                                      : PdfColors.red800)),
                          pw.Spacer(),
                          pw.Text('Cohérence: ${score.scoreCoherence}/100',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: score.estFiable
                                      ? PdfColors.green800
                                      : PdfColors.red800)),
                        ]),
                        pw.SizedBox(height: 6),
                        pw.Text(
                            score.estFiable
                                ? 'Les donnees saisies par l utilisateur sont coherentes. '
                                    'Aucune anomalie majeure détectée.'
                                : 'Des incohérences ont ete détectées dans les donnees. '
                                    'Une verification supplementaire est recommandee.',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: score.estFiable
                                    ? PdfColors.green900
                                    : PdfColors.red900,
                                lineSpacing: 3)),
                        if (score.alertesCoherence.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          ...score.alertesCoherence.map((a) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(children: [
                                pw.Text('! ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red800)),
                                pw.Expanded(
                                    child: pw.Text(a,
                                        style: const pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.red900))),
                              ]))),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Row(children: [
                          pw.Text('Transactions signees: ',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(score.txAvecHash.toString(),
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800)),
                          pw.Text('   Non signees: ',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.Text(score.txSansHash.toString(),
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.orange800)),
                        ]),
                      ])),
              pw.SizedBox(height: 20),
              _pied(),
            ]));

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: '${'Score_TAPA_' + prenom}.pdf');
  }

  static pw.Widget _scoreRow(String label, int score, int max) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(children: [
          pw.SizedBox(
              width: 80,
              child: pw.Text(label,
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.white))),
          pw.SizedBox(width: 8),
          pw.Text('$score/$max',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        ]));
  }

  static pw.Widget _entete(String titre, String prenom, String tel) {
    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('TAPA Invest',
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900)),
          pw.Text('Le budget simple pour tous.',
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(prenom,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(tel,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text('Document genere automatiquement',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ]),
      ]),
      pw.SizedBox(height: 8),
      pw.Divider(color: PdfColors.blueGrey800, thickness: 2),
      pw.SizedBox(height: 8),
      pw.Text(titre,
          style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800)),
    ]);
  }

  static pw.Widget _sousTitre(String texte) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(texte,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)));
  }

  static pw.Widget _statsRow(
      double rev, double dep, double solde, String monnaie) {
    return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _statItem('REVENUS', Fmt.montant(rev, monnaie: monnaie),
                  PdfColors.green800),
              _statItem('DEPENSES', Fmt.montant(dep, monnaie: monnaie),
                  PdfColors.red800),
              _statItem('SOLDE', Fmt.montant(solde, monnaie: monnaie),
                  solde >= 0 ? PdfColors.green800 : PdfColors.red800),
            ]));
  }

  static pw.Widget _statItem(String label, String valeur, PdfColor color) {
    return pw.Column(children: [
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      pw.SizedBox(height: 4),
      pw.Text(valeur,
          style: pw.TextStyle(
              fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }

  static pw.Widget _sectionTitre(String titre, PdfColor color) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(titre,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)));
  }

  static pw.Widget _tableTx(List<TransactionModel> txs, String monnaie) {
    return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              children: [
                _cellHeader('Date'),
                _cellHeader('Catégorie'),
                _cellHeader('Montant'),
              ]),
          ...txs.map((t) {
            final dateStr =
                '${t.dateTransaction.day}/${t.dateTransaction.month}/${t.dateTransaction.year}';
            final signe = t.isRevenu ? '+' : '-';
            final montantStr =
                '$signe${Fmt.montant(t.montant, monnaie: monnaie)}';
            return pw.TableRow(children: [
              _cell(dateStr),
              _cell(t.categorieLabel),
              _cellColor(montantStr,
                  t.isRevenu ? PdfColors.green800 : PdfColors.red800),
            ]);
          }),
        ]);
  }

  static pw.Widget _rapportEcrit(double rev, double dep, String monnaie) {
    String titre;
    String message;
    PdfColor bgColor;
    PdfColor textColor;

    if (dep > rev) {
      titre = 'ANALYSE : DEPASSEMENT BUDGETAIRE';
      bgColor = PdfColors.red50;
      textColor = PdfColors.red900;
      final diff = Fmt.montant(dep - rev, monnaie: monnaie);
      message = 'Vous etes en dépassement de $diff. '
          'Soit vous avez mal budgetise, soit vous avez dépense '
          'au-dela de vos previsions. Cette habitude peut '
          'fragiliser votre situation financiere. '
          'Analysez vos dépenses par catégorie.';
    } else if ((dep - rev).abs() < 1000) {
      titre = 'ANALYSE : BUDGET EQUILIBRE';
      bgColor = PdfColors.orange50;
      textColor = PdfColors.orange900;
      message = 'Vous équilibrez votre budget, c est bien ! '
          'Cependant, une dépense imprévue pourrait vous faire '
          'basculer dans le deficit. Essayez d épargner '
          'au moins 10% de vos revenus chaque mois.';
    } else {
      titre = 'ANALYSE : BONNE GESTION FINANCIERE';
      bgColor = PdfColors.green50;
      textColor = PdfColors.green900;
      final excedent = Fmt.montant(rev - dep, monnaie: monnaie);
      message = 'Félicitations ! Vous avez un excedent de $excedent. '
          'Vous etes sur le bon chemin vers votre liberté financiere. '
          'Investissez ou épargnez cet excedent pour vos objectifs.';
    }

    return pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: textColor, width: 0.5)),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(titre,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor)),
              pw.SizedBox(height: 8),
              pw.Text(message,
                  style: pw.TextStyle(
                      fontSize: 10, color: textColor, lineSpacing: 4)),
            ]));
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)));
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)));
  }

  static pw.Widget _cellColor(String text, PdfColor color) {
    return pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)));
  }

  static pw.Widget _pied() {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: 6),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('TAPA Invest — Le budget simple pour tous.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text('Document confidentiel',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ]),
    ]);
  }
}
