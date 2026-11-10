import 'dart:convert';

class CryptoService {
  static const String _key = 'TAPA_BUDGET_2026_CI';

  static String genererHash(String walletId, double montant, String categorieId,
      String type, DateTime date) {
    final data = '$walletId|$montant|$categorieId|$type'
        '|${date.toIso8601String()}|$_key';
    return _hash(data);
  }

  static bool verifierHash(String hash, String walletId, double montant,
      String categorieId, String type, DateTime date) {
    return hash == genererHash(walletId, montant, categorieId, type, date);
  }

  static String _hash(String input) {
    final bytes = utf8.encode(input);

    // Utiliser deux hash 32 bits pour la compatibilité JavaScript
    int h1 = 0x811c9dc5; // FNV-1a 32-bit offset basis
    int h2 = 0x811c9dc5;

    for (final b in bytes) {
      h1 ^= b;
      h1 = (h1 * 0x01000193) & 0xFFFFFFFF; // FNV-1a 32-bit prime

      h2 ^= b;
      h2 = (h2 * 0x01000193) & 0xFFFFFFFF;
    }

    // Combiner les deux parties
    final p1 = h1.toRadixString(16).padLeft(8, '0');
    final p2 = h2.toRadixString(16).padLeft(8, '0');
    final extra = bytes.fold(0, (a, b) => a + b);
    final p3 = extra.toRadixString(16).padLeft(8, '0');

    return '$p1$p2$p3';
  }

  static Map<String, dynamic> analyserCoherence(double totalRevenus,
      double totalDepenses, int nbTransactions, int nbMois) {
    int score = 100;
    final alertes = <String>[];

    if (totalRevenus <= 0 && totalDepenses <= 0) {
      return {
        'score': 50,
        'alertes': ['Aucune transaction enregistree.'],
        'fiable': false,
      };
    }

    if (totalRevenus > 0) {
      final ratio = totalDepenses / totalRevenus;
      if (ratio > 10) {
        score -= 40;
        alertes
            .add('Dépenses 10x supérieures aux revenus. Incohérence détectée.');
      } else if (ratio > 5) {
        score -= 20;
        alertes.add('Dépenses tres elevees par rapport aux revenus.');
      } else if (ratio > 2) {
        score -= 10;
        alertes.add('Dépenses supérieures au double des revenus.');
      }
    }

    final revMensuel = nbMois > 0 ? totalRevenus / nbMois : totalRevenus;
    if (revMensuel > 10000000) {
      score -= 25;
      alertes.add('Revenus mensuels tres eleves. Verification recommandee.');
    } else if (revMensuel > 5000000) {
      score -= 10;
      alertes.add('Revenus eleves. Justificatifs recommandes.');
    }

    if (totalRevenus == 0 && totalDepenses > 1000000) {
      score -= 30;
      alertes.add('Dépenses importantes sans revenus declares.');
    }

    score = score.clamp(0, 100);
    return {
      'score': score,
      'alertes': alertes,
      'fiable': score >= 60,
    };
  }
}
