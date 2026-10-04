// lib/domain/usecases/souscriptions/get_souscriptions_usecase.dart

import '../../repositories/i_souscription_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class GetSouscriptionsResult {
  final List<SouscriptionModel> souscriptions;
  final bool success;
  final String? message;
  final double montantTotal;
  final int totalEnCours;
  final int totalPayees;

  const GetSouscriptionsResult({
    this.souscriptions = const [],
    this.success = false,
    this.message,
    this.montantTotal = 0,
    this.totalEnCours = 0,
    this.totalPayees = 0,
  });

  factory GetSouscriptionsResult.success(List<SouscriptionModel> souscriptions) {
    double montantTotal = 0;
    int totalEnCours = 0;
    int totalPayees = 0;

    for (final s in souscriptions) {
      montantTotal += s.montant;
      if (s.estEnCours) totalEnCours++;
      if (s.estPayee) totalPayees++;
    }

    return GetSouscriptionsResult(
      souscriptions: souscriptions,
      success: true,
      montantTotal: montantTotal,
      totalEnCours: totalEnCours,
      totalPayees: totalPayees,
    );
  }

  factory GetSouscriptionsResult.error(String message) {
    return GetSouscriptionsResult(success: false, message: message);
  }

  factory GetSouscriptionsResult.empty() {
    return const GetSouscriptionsResult(souscriptions: [], success: true);
  }
}

class GetSouscriptionsUseCase {
  final ISouscriptionRepository _repository;

  GetSouscriptionsUseCase(this._repository);

  Future<GetSouscriptionsResult> execute(String uid) async {
    try {
      Logger.info('Recuperation des souscriptions pour: $uid');

      if (uid.isEmpty) {
        return GetSouscriptionsResult.error('Utilisateur non identifie.');
      }

      final souscriptions = await _repository.getSouscriptionsOnce(uid);

      if (souscriptions.isEmpty) {
        Logger.info('Aucune souscription trouvee');
        return GetSouscriptionsResult.empty();
      }

      Logger.success('${souscriptions.length} souscriptions recuperees');
      return GetSouscriptionsResult.success(souscriptions);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur recuperation souscriptions: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetSouscriptionsResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return GetSouscriptionsResult.error(
        'Erreur lors de la recuperation des souscriptions.',
      );
    }
  }
}

class WatchSouscriptionsUseCase {
  final ISouscriptionRepository _repository;

  WatchSouscriptionsUseCase(this._repository);

  Stream<List<SouscriptionModel>> execute(String uid) {
    Logger.info('Ecoute des souscriptions pour: $uid');
    return _repository.getUserSouscriptions(uid);
  }
}
