// lib/data/repositories/tarif_repository_impl.dart

import 'dart:async';
import '../../domain/repositories/i_tarif_repository.dart';
import '../models/models.dart';
import '../datasources/remote/firebase/firebase_firestore_datasource.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/logger.dart';

class TarifRepositoryImpl implements ITarifRepository {
  final FirebaseFirestoreDatasource _firestoreDatasource;

  TarifRepositoryImpl({
    FirebaseFirestoreDatasource? firestoreDatasource,
  }) : _firestoreDatasource =
            firestoreDatasource ?? FirebaseFirestoreDatasource();

  @override
  Future<TarifConfigModel?> getTarifsConfig() async {
    try {
      return await _firestoreDatasource.getTarifsConfig();
    } catch (e) {
      Logger.error('Erreur recuperation tarifs: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Future<void> saveTarifsConfig(TarifConfigModel tarifConfig) async {
    try {
      await _firestoreDatasource.saveTarifsConfig(tarifConfig);
    } catch (e) {
      Logger.error('Erreur sauvegarde tarifs: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  @override
  Stream<TarifConfigModel?> listenToTarifsConfig() {
    return _firestoreDatasource.listenToTarifsConfig();
  }
}
