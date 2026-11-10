// lib/domain/repositories/i_debt_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class IDebtRepository {
  Stream<List<DetteModel>> getUserDettes(String uid);
  Future<List<DetteModel>> getDettesOnce(String uid);
  Future<void> addDette(DetteModel dette);
  Future<void> updateDette(DetteModel dette);
  Future<void> deleteDette(String detteId);
  Future<void> addRemboursement(
      String detteId, RemboursementModel remboursement);
}
