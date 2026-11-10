// lib/core/utils/date_parser.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse une date qui peut etre String, Timestamp, ou DateTime
/// et retourne un DateTime. Gere les donnees anciennes (String) et nouvelles (Timestamp).
DateTime parseFirestoreDate(dynamic value, {DateTime? fallback}) {
  if (value == null) return fallback ?? DateTime.now();

  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }

  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  return fallback ?? DateTime.now();
}

/// Variante qui peut retourner null
DateTime? parseFirestoreDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
