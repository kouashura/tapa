// lib/domain/models/tarif_assurance_auto.dart

import '../../data/models/models.dart';

/// Modèle de calcul du tarif d'assurance auto
///
/// La prime est calculée selon :
/// - La valeur du véhicule (basée sur marque + année)
/// - La puissance fiscale (CV)
/// - La durée souhaitée (mois)
///
/// Les tarifs peuvent être surchargés via Firestore (TarifConfigModel).
class TarifAssuranceAuto {
  /// Calcule la prime mensuelle en FCFA
  ///
  /// Si [config] est fourni, utilise les valeurs de la config (Firestore).
  /// Sinon, utilise les valeurs par défaut codées en dur.
  static int calculerPrimeMensuelle({
    required String marque,
    required String modele,
    required int annee,
    required int puissance,
    TarifConfigModel? config,
  }) {
    final cfg = config ?? TarifConfigModel.defaut();

    // 1. Base selon la marque
    final baseMarque = _baseMarque(marque, cfg);

    // 2. Coefficient selon l'âge du véhicule
    final ageVehicule = DateTime.now().year - annee;
    final coefAge = _coefAge(ageVehicule, cfg);

    // 3. Coefficient selon la puissance
    final coefPuissance = _coefPuissance(puissance, cfg);

    // 4. Calcul : base × coefAge × coefPuissance
    final prime = (baseMarque * coefAge * coefPuissance).round();

    // 5. Prime minimale
    final min = cfg.primeMinimum.toInt();
    return prime < min ? min : prime;
  }

  /// Calcule le montant total à payer
  static int calculerMontantTotal({
    required int primeMensuelle,
    required int nbMois,
  }) {
    return primeMensuelle * nbMois;
  }

  /// Base tarifaire selon la marque (FCFA/mois)
  static int _baseMarque(String marque, TarifConfigModel cfg) {
    final m = marque.toUpperCase().trim();

    if (_matchesAny(m,
        ['MERCEDES', 'BMW', 'AUDI', 'LEXUS', 'PORSCHE', 'JAGUAR', 'VOLVO'])) {
      return cfg.basePremium.toInt();
    }

    if (_matchesAny(m, [
      'TOYOTA',
      'HONDA',
      'NISSAN',
      'MAZDA',
      'VOLKSWAGEN',
      'FORD',
      'HYUNDAI',
      'KIA'
    ])) {
      return cfg.baseHautGamme.toInt();
    }

    if (_matchesAny(m, [
      'PEUGEOT',
      'RENAULT',
      'CITROEN',
      'SUZUKI',
      'DACIA',
      'FIAT',
      'OPEL',
      'CHEVROLET'
    ])) {
      return cfg.basePopulaire.toInt();
    }

    if (_matchesAny(
        m, ['CHERY', 'BYD', 'GEELY', 'MG', 'DFSK', 'JAC', 'LIFAN'])) {
      return cfg.baseChinoise.toInt();
    }

    return cfg.baseDefaut.toInt();
  }

  /// Coefficient selon l'âge du véhicule
  static double _coefAge(int age, TarifConfigModel cfg) {
    if (age <= 1) return cfg.coefAge0a1;
    if (age <= 3) return cfg.coefAge1a3;
    if (age <= 5) return cfg.coefAge3a5;
    if (age <= 10) return cfg.coefAge5a10;
    if (age <= 15) return cfg.coefAge10a15;
    return cfg.coefAge15Plus;
  }

  /// Coefficient selon la puissance fiscale
  static double _coefPuissance(int cv, TarifConfigModel cfg) {
    if (cv <= 4) return cfg.coefCv0a4;
    if (cv <= 6) return cfg.coefCv4a6;
    if (cv <= 8) return cfg.coefCv6a8;
    if (cv <= 10) return cfg.coefCv8a10;
    if (cv <= 13) return cfg.coefCv10a13;
    return cfg.coefCv13Plus;
  }

  /// Vérifie si la marque correspond à une des marques listées
  static bool _matchesAny(String marque, List<String> liste) {
    return liste.any((m) => marque.contains(m));
  }

  /// Formate un montant en FCFA
  static String formater(int montant) {
    final str = montant.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} FCFA';
  }
}
