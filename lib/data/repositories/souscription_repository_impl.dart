// lib/data/repositories/souscription_repository_impl.dart

import 'dart:async';
import '../../domain/repositories/i_souscription_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

class SouscriptionRepositoryImpl implements ISouscriptionRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  SouscriptionRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource =
            firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Stream<List<SouscriptionModel>> getUserSouscriptions(String uid) {
    return _firestoreDatasource.listenToSouscriptions(uid).map((snapshot) {
      return snapshot.docs
          .map((doc) => SouscriptionModel.fromMap(
                {...doc.data(), 'id': doc.id},
                doc.id,
              ))
          .toList();
    });
  }

  @override
  Future<List<SouscriptionModel>> getSouscriptionsOnce(String uid) async {
    try {
      return await _firestoreDatasource.getSouscriptions(uid);
    } catch (e) {
      Logger.error('Erreur recuperation souscriptions: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<SouscriptionModel?> getSouscriptionById(String reference) async {
    try {
      final souscriptions = await _firestoreDatasource.getSouscriptions(reference);
      if (souscriptions.isEmpty) return null;
      return souscriptions.firstWhere(
        (s) => s.reference == reference,
        orElse: () => souscriptions.first,
      );
    } catch (e) {
      Logger.error('Erreur recuperation souscription: $e');
      return null;
    }
  }
}
