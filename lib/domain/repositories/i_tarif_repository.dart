// lib/domain/repositories/i_tarif_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class ITarifRepository {
  Future<TarifConfigModel?> getTarifsConfig();
  Future<void> saveTarifsConfig(TarifConfigModel tarifConfig);
  Stream<TarifConfigModel?> listenToTarifsConfig();
}
