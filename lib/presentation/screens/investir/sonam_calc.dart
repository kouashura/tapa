// lib/presentation/screens/investir/sonam_calc.dart
// Calcul aligné sur la grille officielle SONAM (taux 4 %, chargement 4 %).

import 'dart:math' as math;

class SonamCalc {
  SonamCalc._();

  static const double tauxAnnuel = 0.04;
  static const double tauxFrais = 0.04;

  /// Capital garanti au terme : annuité payable d'avance,
  /// taux mensuel équivalent, sur 96 % de la cotisation.
  static double capitalGaranti(double cotisationMensuelle, int dureeAns) {
    final im = math.pow(1 + tauxAnnuel, 1 / 12) - 1;
    final n = dureeAns * 12;
    final facteur = ((math.pow(1 + im, n) - 1) / im) * (1 + im);
    return (cotisationMensuelle * (1 - tauxFrais) * facteur).roundToDouble();
  }

  static String formatMontant(double montant) {
    final s = montant.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$s FCFA';
  }
}
