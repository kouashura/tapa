// lib/data/repositories/debt_repository_impl.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../models/models.dart'; // ✅ Utiliser models.dart
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/date_parser.dart';

/// Implémentation du repository des dettes
class DebtRepositoryImpl implements IDebtRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  DebtRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource =
            firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Stream<List<DetteModel>> getUserDettes(String uid) {
    return _firestoreDatasource.listenToDettes(uid).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DetteModel(
          id: doc.id,
          uid: data['uid'] ?? '',
          type: data['type'] ?? '',
          montantTotal: (data['montantTotal'] as num?)?.toDouble() ?? 0,
          montantRembourse: (data['montantRembourse'] as num?)?.toDouble() ?? 0,
          modalite: data['modalite'] ?? '',
          periodesMois: data['periodesMois'] ?? 1,
          dateDebut: parseFirestoreDate(data['dateDebut']),
          dateFin: parseFirestoreDate(data['dateFin']),
          dateCreation: parseFirestoreDate(data['dateCreation']),
          remboursements: [],
        );
      }).toList();
    });
  }

  @override
  Future<List<DetteModel>> getDettesOnce(String uid) async {
    try {
      return await _firestoreDatasource
          .getDettes(uid); // ✅ Retourne List<DetteModel>
    } catch (e) {
      Logger.error('❌ Erreur récupération dettes: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addDette(DetteModel dette) async {
    try {
      await _firestoreDatasource.saveDette(dette);
      Logger.info('📝 Dette ajoutée: ${dette.id}');
    } catch (e) {
      Logger.error('❌ Erreur ajout dette: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> updateDette(DetteModel dette) async {
    try {
      await _firestoreDatasource.saveDette(dette);
      Logger.info('📝 Dette mise à jour: ${dette.id}');
    } catch (e) {
      Logger.error('❌ Erreur mise à jour dette: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> deleteDette(String detteId) async {
    try {
      await _firestoreDatasource.deleteDette(detteId);
      Logger.info('🗑️ Dette supprimée: $detteId');
    } catch (e) {
      Logger.error('❌ Erreur suppression dette: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> addRemboursement(
      String detteId, RemboursementModel remboursement) async {
    try {
      // ✅ RÉCUPÉRER LA DETTE PAR SON ID (au lieu du uid)
      final detteDoc = await FirebaseFirestore.instance
          .collection('dettes')
          .doc(detteId)
          .get();
      if (!detteDoc.exists) {
        throw const DatabaseFailure(
          message: 'Dette non trouvée.',
          code: 'DEBT_NOT_FOUND',
        );
      }

      final dette = DetteModel.fromMap(
        {...detteDoc.data()!, 'id': detteDoc.id},
        detteDoc.id,
      );

      // ✅ 1. Récupérer le portefeuille pour vérifier le solde
      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(remboursement.walletId)
          .get();

      if (!walletDoc.exists) {
        throw const DatabaseFailure(
          message: 'Portefeuille non trouvé.',
          code: 'WALLET_NOT_FOUND',
        );
      }

      final walletSolde = (walletDoc.data()!['solde'] as num).toDouble();

      if (walletSolde < remboursement.montant) {
        throw const DatabaseFailure(
          message: 'Solde insuffisant dans ce portefeuille.',
          code: 'INSUFFICIENT_FUNDS',
        );
      }

      final updatedRemboursements =
          List<RemboursementModel>.from(dette.remboursements)
            ..add(remboursement);

      final updatedDette = DetteModel(
        id: dette.id,
        uid: dette.uid,
        type: dette.type,
        montantTotal: dette.montantTotal,
        montantRembourse: dette.montantRembourse + remboursement.montant,
        modalite: dette.modalite,
        periodesMois: dette.periodesMois,
        dateDebut: dette.dateDebut,
        dateFin: dette.dateFin,
        dateCreation: dette.dateCreation,
        remboursements: updatedRemboursements,
      );

      // ✅ 2. Sauvegarder la dette
      await _firestoreDatasource.saveDette(updatedDette);

      // ✅ 3. Déduire le montant du portefeuille
      await FirebaseFirestore.instance
          .collection('wallets')
          .doc(remboursement.walletId)
          .update({
        'solde': FieldValue.increment(-remboursement.montant),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('📝 Remboursement ajouté: ${remboursement.montant}');
      Logger.info('💰 Portefeuille débité: ${remboursement.montant}');
    } catch (e) {
      Logger.error('❌ Erreur ajout remboursement: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}
