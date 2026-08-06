// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Fmt {
  static String montant(double val, {String monnaie = 'FCFA'}) {
    final n = NumberFormat('#,###', 'fr_FR')
        .format(val.round())
        .replaceAll(',', ' ');
    return '$n $monnaie';
  }

  static String nombre(double val) {
    return NumberFormat('#,###', 'fr_FR')
        .format(val.round())
        .replaceAll(',', ' ');
  }

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

  static String dateCourte(DateTime d) =>
      '${d.day}/${d.month}';

  static String dateComplete(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  static String genId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
