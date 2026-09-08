// lib/domain/repositories/i_echeance_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class IEcheanceRepository {
  Stream<List<EcheanceModel>> getUserEcheances(String uid);
  Future<List<EcheanceModel>> getEcheancesOnce(String uid);
  Future<void> addEcheance(EcheanceModel echeance);
  Future<void> updateEcheance(EcheanceModel echeance);
  Future<void> deleteEcheance(String echeanceId);
  Future<void> marquerPayee(String echeanceId);
  Future<List<EcheanceModel>> getEcheancesEnRetard(String uid);
}
