// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Fmt {
  /// Formate un montant avec séparateur de milliers et devise
  static String montant(double val, {String monnaie = 'FCFA'}) {
    final n =
        NumberFormat('#,###', 'fr_FR').format(val.round()).replaceAll(',', ' ');
    return '$n $monnaie';
  }

  /// Formate un nombre avec séparateur de milliers
  static String nombre(double val) {
    return NumberFormat('#,###', 'fr_FR')
        .format(val.round())
        .replaceAll(',', ' ');
  }

  /// Affiche une date passée sous forme relative (ex: "Il y a 2h", "Hier")
  static String dateRelative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${d.day}/${d.month}/${d.year}';
  }

  /// ✅ NOUVELLE MÉTHODE : Affiche une date future sous forme relative
  /// (ex: "Dans 30 jours", "Dans 2 mois", "Demain")
  static String dateFuture(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now); // ✅ Sens inverse : d - now

    if (diff.isNegative) {
      // Si la date est passée, utiliser dateRelative
      return dateRelative(d);
    }

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    }
    if (diff.inMinutes < 60) {
      return 'Dans ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Dans ${diff.inHours}h';
    }
    if (diff.inDays == 1) {
      return 'Demain';
    }
    if (diff.inDays < 7) {
      return 'Dans ${diff.inDays} jours';
    }
    if (diff.inDays < 30) {
      final semaines = (diff.inDays / 7).round();
      return 'Dans $semaines semaine${semaines > 1 ? 's' : ''}';
    }
    if (diff.inDays < 365) {
      final mois = (diff.inDays / 30).round();
      return 'Dans $mois mois';
    }
    final annees = (diff.inDays / 365).round();
    return 'Dans $annees an${annees > 1 ? 's' : ''}';
  }

  /// Affiche une date courte (ex: "15/10")
  static String dateCourte(DateTime d) => '${d.day}/${d.month}';

  /// Affiche une date complète (ex: "15/10/2026")
  static String dateComplete(DateTime d) => '${d.day}/${d.month}/${d.year}';

  /// Affiche une date complète avec mois en lettres (ex: "15 octobre 2026")
  static String dateLongue(DateTime d) {
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  /// Génère un ID unique basé sur le timestamp
  static String genId() => DateTime.now().millisecondsSinceEpoch.toString();
}
