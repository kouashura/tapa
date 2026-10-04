// lib/domain/usecases/souscriptions/admin_souscriptions_usecase.dart

import '../../repositories/i_souscription_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class GetAllSouscriptionsResult {
  final List<SouscriptionModel> souscriptions;
  final bool success;
  final String? message;
  final double montantTotal;
  final int totalEnCours;
  final int totalPayees;
  final int totalAnnulees;

  const GetAllSouscriptionsResult({
    this.souscriptions = const [],
    this.success = false,
    this.message,
    this.montantTotal = 0,
    this.totalEnCours = 0,
    this.totalPayees = 0,
    this.totalAnnulees = 0,
  });

  factory GetAllSouscriptionsResult.success(List<SouscriptionModel> souscriptions) {
    double montantTotal = 0;
    int totalEnCours = 0;
    int totalPayees = 0;
    int totalAnnulees = 0;

    for (final s in souscriptions) {
      montantTotal += s.montant;
      if (s.estEnCours) totalEnCours++;
      if (s.estPayee) totalPayees++;
      if (s.estAnnulee) totalAnnulees++;
    }

    return GetAllSouscriptionsResult(
      souscriptions: souscriptions,
      success: true,
      montantTotal: montantTotal,
      totalEnCours: totalEnCours,
      totalPayees: totalPayees,
      totalAnnulees: totalAnnulees,
    );
  }

  factory GetAllSouscriptionsResult.error(String message) {
    return GetAllSouscriptionsResult(success: false, message: message);
  }
}

class GetAllSouscriptionsUseCase {
  final ISouscriptionRepository _repository;

  GetAllSouscriptionsUseCase(this._repository);

  Future<GetAllSouscriptionsResult> execute() async {
    try {
      Logger.info('Recuperation de toutes les souscriptions (admin)');
      final souscriptions = await _repository.getAllSouscriptions();

      if (souscriptions.isEmpty) {
        Logger.info('Aucune souscription');
        return GetAllSouscriptionsResult.success([]);
      }

      Logger.success('${souscriptions.length} souscriptions recuperees');
      return GetAllSouscriptionsResult.success(souscriptions);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur recuperation souscriptions: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetAllSouscriptionsResult.error('Erreur de base de donnees.');
      }
      return GetAllSouscriptionsResult.error('Erreur de recuperation.');
    }
  }
}

class WatchAllSouscriptionsUseCase {
  final ISouscriptionRepository _repository;

  WatchAllSouscriptionsUseCase(this._repository);

  Stream<List<SouscriptionModel>> execute() {
    return _repository.watchAllSouscriptions();
  }
}

class UpdateSouscriptionStatutResult {
  final bool success;
  final String? message;

  const UpdateSouscriptionStatutResult({
    required this.success,
    this.message,
  });

  factory UpdateSouscriptionStatutResult.success() {
    return const UpdateSouscriptionStatutResult(success: true);
  }

  factory UpdateSouscriptionStatutResult.error(String message) {
    return UpdateSouscriptionStatutResult(success: false, message: message);
  }
}

class UpdateSouscriptionStatutUseCase {
  final ISouscriptionRepository _repository;

  UpdateSouscriptionStatutUseCase(this._repository);

  Future<UpdateSouscriptionStatutResult> execute(
      String reference, String statut) async {
    try {
      Logger.info('Mise a jour statut $reference -> $statut');
      await _repository.updateSouscriptionStatut(reference, statut);
      Logger.success('Statut mis a jour');
      return UpdateSouscriptionStatutResult.success();
    } catch (e) {
      Logger.error('Erreur mise a jour statut: $e');
      return UpdateSouscriptionStatutResult.error('Erreur');
    }
  }
}
