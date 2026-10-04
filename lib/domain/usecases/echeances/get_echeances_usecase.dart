// lib/domain/usecases/echeances/get_echeances_usecase.dart

import '../../repositories/i_echeance_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class GetEcheancesResult {
  final List<EcheanceModel> echeances;
  final bool success;
  final String? message;
  final int totalEnRetard;
  final double montantTotal;
  final double montantEnRetard;

  const GetEcheancesResult({
    this.echeances = const [],
    this.success = false,
    this.message,
    this.totalEnRetard = 0,
    this.montantTotal = 0,
    this.montantEnRetard = 0,
  });

  factory GetEcheancesResult.success(List<EcheanceModel> echeances) {
    int totalEnRetard = 0;
    double montantTotal = 0;
    double montantEnRetard = 0;

    for (final e in echeances) {
      montantTotal += e.montant;
      if (e.estEnRetard) {
        totalEnRetard++;
        montantEnRetard += e.montant;
      }
    }

    return GetEcheancesResult(
      echeances: echeances,
      success: true,
      totalEnRetard: totalEnRetard,
      montantTotal: montantTotal,
      montantEnRetard: montantEnRetard,
    );
  }

  factory GetEcheancesResult.error(String message) {
    return GetEcheancesResult(success: false, message: message);
  }

  factory GetEcheancesResult.empty() {
    return const GetEcheancesResult(echeances: [], success: true);
  }
}

class GetEcheancesUseCase {
  final IEcheanceRepository _repository;

  GetEcheancesUseCase(this._repository);

  Future<GetEcheancesResult> execute(String uid) async {
    try {
      Logger.info('Recuperation des echeances pour: $uid');

      if (uid.isEmpty) {
        return GetEcheancesResult.error('Utilisateur non identifie.');
      }

      final echeances = await _repository.getEcheancesOnce(uid);

      if (echeances.isEmpty) {
        Logger.info('Aucune echeance trouvee');
        return GetEcheancesResult.empty();
      }

      Logger.success('${echeances.length} echeances recuperees');
      return GetEcheancesResult.success(echeances);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur recuperation echeances: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetEcheancesResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return GetEcheancesResult.error(
        'Erreur lors de la recuperation des echeances.',
      );
    }
  }
}
