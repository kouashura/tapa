// lib/services/migration_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

/// Service de migration pour corriger les données existantes
class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Migrer les dates d'inscription manquantes
  static Future<void> migrerDatesInscription() async {
    Logger.info('🔍 Début de la migration des dates d\'inscription...');

    try {
      final snapshot = await _firestore.collection('users').get();
      int count = 0;
      int updated = 0;

      for (final doc in snapshot.docs) {
        count++;
        final data = doc.data();
        final userId = doc.id;

        // Vérifier si la date d'inscription existe
        if (!data.containsKey('dateInscription') ||
            data['dateInscription'] == null) {
          String? dateStr;

          // Essayer d'utiliser la date de création
          if (data.containsKey('createdAt')) {
            final timestamp = data['createdAt'];
            if (timestamp is Timestamp) {
              dateStr = timestamp.toDate().toIso8601String();
            }
          }

          // Fallback : date actuelle
          dateStr ??= DateTime.now().toIso8601String();

          // Mettre à jour le document
          await doc.reference.update({
            'dateInscription': dateStr,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          updated++;
          Logger.info('✅ Migration pour $userId: dateInscription = $dateStr');
        }
      }

      Logger.success(
          '✅ Migration terminée ! $updated utilisateurs mis à jour sur $count.');
    } catch (e) {
      Logger.error('❌ Erreur migration: $e');
      rethrow;
    }
  }

  /// ✅ Vérifier et corriger les données d'un utilisateur spécifique
  static Future<void> verifierUtilisateur(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        Logger.warning('⚠️ Utilisateur $userId non trouvé');
        return;
      }

      final data = doc.data()!;
      Logger.info('📋 Données utilisateur $userId:');
      Logger.info('  - prenom: ${data['prenom']}');
      Logger.info(
          '  - dateInscription: ${data['dateInscription'] ?? 'MANQUANTE'}');
      Logger.info('  - createdAt: ${data['createdAt']}');
      Logger.info('  - hasAccessVie: ${data['hasAccessVie']}');
      Logger.info('  - onboardingVu: ${data['onboardingVu']}');

      // Si la date d'inscription est manquante, la corriger
      if (!data.containsKey('dateInscription') ||
          data['dateInscription'] == null) {
        String? dateStr;

        if (data.containsKey('createdAt')) {
          final timestamp = data['createdAt'];
          if (timestamp is Timestamp) {
            dateStr = timestamp.toDate().toIso8601String();
          }
        }

        dateStr ??= DateTime.now().toIso8601String();

        await doc.reference.update({
          'dateInscription': dateStr,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Logger.success('✅ Date d\'inscription corrigée pour $userId: $dateStr');
      }
    } catch (e) {
      Logger.error('❌ Erreur vérification utilisateur: $e');
    }
  }

  /// ✅ Afficher les statistiques des utilisateurs
  static Future<void> afficherStatistiques() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final total = snapshot.docs.length;
      int avecDate = 0;
      int sansDate = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('dateInscription') &&
            data['dateInscription'] != null) {
          avecDate++;
        } else {
          sansDate++;
        }
      }

      Logger.info('📊 STATISTIQUES UTILISATEURS:');
      Logger.info('  - Total: $total');
      Logger.info('  - Avec date d\'inscription: $avecDate');
      Logger.info('  - Sans date d\'inscription: $sansDate');
    } catch (e) {
      Logger.error('❌ Erreur statistiques: $e');
    }
  }

  /// ✅ Corriger la date d'inscription d'un utilisateur spécifique
  static Future<bool> corrigerDateInscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        Logger.warning('⚠️ Utilisateur $userId non trouvé');
        return false;
      }

      final data = doc.data()!;
      final dateStr = DateTime.now().toIso8601String();

      await doc.reference.update({
        'dateInscription': dateStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.success(
          '✅ Date d\'inscription mise à jour pour $userId: $dateStr');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur correction date: $e');
      return false;
    }
  }

  /// ✅ Réinitialiser l'essai gratuit d'un utilisateur
  static Future<bool> reinitialiserEssai(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        Logger.warning('⚠️ Utilisateur $userId non trouvé');
        return false;
      }

      final dateStr = DateTime.now().toIso8601String();

      await doc.reference.update({
        'dateInscription': dateStr,
        'hasAccessVie': false,
        'cleActivee': FieldValue.delete(),
        'accesType': FieldValue.delete(),
        'dateActivation': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.success('✅ Essai réinitialisé pour $userId');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur réinitialisation essai: $e');
      return false;
    }
  }

  /// ✅ Supprimer la date d'inscription d'un utilisateur (danger)
  static Future<bool> supprimerDateInscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        Logger.warning('⚠️ Utilisateur $userId non trouvé');
        return false;
      }

      await doc.reference.update({
        'dateInscription': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.warning('⚠️ Date d\'inscription supprimée pour $userId');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur suppression date: $e');
      return false;
    }
  }
}
