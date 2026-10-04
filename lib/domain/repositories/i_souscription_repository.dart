// lib/domain/repositories/i_souscription_repository.dart

import 'dart:async';
import '../../data/models/models.dart';

abstract class ISouscriptionRepository {
  // Methodes utilisateur
  Stream<List<SouscriptionModel>> getUserSouscriptions(String uid);
  Future<List<SouscriptionModel>> getSouscriptionsOnce(String uid);
  Future<SouscriptionModel?> getSouscriptionById(String reference);

  // Methodes admin
  Future<List<SouscriptionModel>> getAllSouscriptions();
  Stream<List<SouscriptionModel>> watchAllSouscriptions();
  Future<void> updateSouscriptionStatut(String reference, String statut);
}
