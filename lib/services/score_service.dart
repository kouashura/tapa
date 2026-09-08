import 'db_service_mysql.dart';
import 'crypto_service.dart';

class ScoreTAPA {
  final int scoreTotal;
  final int scoreRevenus;
  final int scoreDepenses;
  final int scoreEpargne;
  final int scoreDettes;
  final int scoreRegularite;
  final int scoreCoherence;
  final String niveau;
  final String emoji;
  final List<String> conseils;
  final List<String> pointsForts;
  final List<String> alertesCoherence;
  final bool estFiable;
  final int txAvecHash;
  final int txSansHash;

  ScoreTAPA({
    required this.scoreTotal,
    required this.scoreRevenus,
    required this.scoreDepenses,
    required this.scoreEpargne,
    required this.scoreDettes,
    required this.scoreRegularite,
    required this.scoreCoherence,
    required this.niveau,
    required this.emoji,
    required this.conseils,
    required this.pointsForts,
    required this.alertesCoherence,
    required this.estFiable,
    required this.txAvecHash,
    required this.txSansHash,
  });
}

class ScoreService {
  static Future<ScoreTAPA> calculer(DBService db) async {
    // ✅ CORRECTION: Ajouter await
    final txs = await await db.getTransactions();
    final revenus = txs.where((t) => t.isRevenu).toList();
    final depenses = txs.where((t) => t.isDepense).toList();
    final epargnes = db.getSavingsGoals();
    final dettes = db.getDettes();
    final now = DateTime.now();

    final totalRev = revenus.fold(0.0, (s, t) => s + t.montant);
    final totalDep = depenses.fold(0.0, (s, t) => s + t.montant);

    // 1. SCORE REVENUS (20 pts)
    int scoreRevenus = 0;
    if (totalRev > 0) scoreRevenus += 8;
    final revMois = revenus.where((t) =>
    t.dateTransaction.month == now.month && t.dateTransaction.year == now.year).toList();
    if (revMois.isNotEmpty) scoreRevenus += 6;
    final moisDernier = now.month == 1 ? 12 : now.month - 1;
    final anneeDerniere = now.month == 1 ? now.year - 1 : now.year;
    final revDernier = revenus.where((t) =>
    t.dateTransaction.month == moisDernier && t.dateTransaction.year == anneeDerniere).toList();
    if (revDernier.isNotEmpty) scoreRevenus += 6;

    // 2. SCORE DEPENSES (20 pts)
    int scoreDepenses = 0;
    if (totalRev > 0 && totalDep < totalRev) scoreDepenses += 10;
    else if (totalDep == 0) scoreDepenses += 5;
    final budget = await db.getBudget(now.month, now.year);
    if (budget != null) scoreDepenses += 6;
    if (budget != null && totalDep <= budget.totalDepensesPrevu) {
      scoreDepenses += 4;
    }

    // 3. SCORE EPARGNE (20 pts)
    int scoreEpargne = 0;
    if (epargnes.isNotEmpty) scoreEpargne += 8;
    final epargnesActives = epargnes.where(
            (e) => e.montantActuel < e.montantCible).toList();
    if (epargnesActives.isNotEmpty) scoreEpargne += 6;
    final epargnesAtteintes = epargnes.where(
            (e) => e.montantActuel >= e.montantCible).toList();
    if (epargnesAtteintes.isNotEmpty) scoreEpargne += 6;

    // 4. SCORE DETTES (20 pts)
    int scoreDettes = 20;
    if (dettes.isNotEmpty) {
      scoreDettes = 10;
      final dettesSoldees = dettes.where((d) => d.montantRestant <= 0).toList();
      final dettesEnAttente = dettes.where((d) => d.montantRestant > 0 && d.remboursements.isEmpty).toList();
      if (dettesSoldees.isNotEmpty) scoreDettes += 6;
      if (dettesEnAttente.isEmpty) scoreDettes += 4;
      if (dettesEnAttente.isNotEmpty) scoreDettes -= 2;
    }
    scoreDettes = scoreDettes.clamp(0, 20);

    // 5. SCORE REGULARITE (20 pts)
    int scoreRegularite = 0;
    if (txs.length >= 5) scoreRegularite += 5;
    if (txs.length >= 15) scoreRegularite += 5;
    if (txs.length >= 30) scoreRegularite += 5;
    final txsMois = txs.where((t) =>
    t.dateTransaction.month == now.month && t.dateTransaction.year == now.year).toList();
    if (txsMois.length >= 3) scoreRegularite += 5;

    // COHERENCE
    final moisDebut = txs.isNotEmpty
        ? txs.map((t) => t.dateTransaction).reduce((a, b) => a.isBefore(b) ? a : b)
        : now;
    final nbMois = ((now.difference(moisDebut).inDays) / 30)
        .ceil().clamp(1, 120);
    final coherence = CryptoService.analyserCoherence(
        totalRev, totalDep, txs.length, nbMois);
    final scoreCoherence = coherence['score'] as int;
    final alertesCoherence = List<String>.from(
        coherence['alertes'] as List);
    final estFiable = coherence['fiable'] as bool;

    // HASH VERIFICATION
    int txAvecHash = 0;
    int txSansHash = 0;
    for (final tx in txs) {
      txSansHash++;
    }

    // PENALITE COHERENCE
    int penalite = 0;
    if (scoreCoherence < 60) penalite = 20;
    else if (scoreCoherence < 80) penalite = 10;

    final total = (scoreRevenus + scoreDepenses +
        scoreEpargne + scoreDettes + scoreRegularite - penalite)
        .clamp(0, 100);

    // NIVEAU
    String niveau;
    String emoji;
    if (total >= 80) { niveau = 'Excellent'; emoji = '🟢'; }
    else if (total >= 60) { niveau = 'Bon'; emoji = '🔵'; }
    else if (total >= 40) { niveau = 'Moyen'; emoji = '🟡'; }
    else if (total >= 20) { niveau = 'Faible'; emoji = '🟠'; }
    else { niveau = 'Insuffisant'; emoji = '🔴'; }

    // CONSEILS
    final conseils = <String>[];
    final pointsForts = <String>[];

    if (scoreRevenus >= 14) {
      pointsForts.add('Vous enregistrez vos revenus regulierement.');
    } else {
      conseils.add('Enregistrez vos revenus chaque mois.');
    }
    if (scoreDepenses >= 14) {
      pointsForts.add('Vos dépenses sont bien controlees.');
    } else {
      conseils.add('Essayez de dépenser moins que vos revenus.');
    }
    if (budget != null) {
      pointsForts.add('Vous utilisez le budget prévisionnel.');
    } else {
      conseils.add('Crééz un budget prévisionnel mensuel.');
    }
    if (scoreEpargne >= 14) {
      pointsForts.add('Vous épargnez regulierement.');
    } else {
      conseils.add('Crééz un objectif d épargne.');
    }
    if (dettes.isEmpty) {
      pointsForts.add('Aucune dette. Tres bien !');
    } else if (dettes.any((d) => d.montantRestant > 0 && d.remboursements.isEmpty)) {
      conseils.add('Remboursez vos dettes en attente rapidement.');
    } else {
      pointsForts.add('Vous gerez bien vos dettes.');
    }
    if (scoreRegularite >= 15) {
      pointsForts.add('Vous utilisez l app regulierement.');
    } else {
      conseils.add('Utilisez l app quotidiennement.');
    }

    return ScoreTAPA(
      scoreTotal: total,
      scoreRevenus: scoreRevenus,
      scoreDepenses: scoreDepenses,
      scoreEpargne: scoreEpargne,
      scoreDettes: scoreDettes,
      scoreRegularite: scoreRegularite,
      scoreCoherence: scoreCoherence,
      niveau: niveau,
      emoji: emoji,
      conseils: conseils,
      pointsForts: pointsForts,
      alertesCoherence: alertesCoherence,
      estFiable: estFiable,
      txAvecHash: txAvecHash,
      txSansHash: txSansHash,
    );
  }
}