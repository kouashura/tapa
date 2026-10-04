// lib/domain/usecases/echeances/update_echeance_usecase.dart

import '../../repositories/i_echeance_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class UpdateEcheanceResult {
  final bool success;
  final EcheanceModel? echeance;
  final String? message;

  const UpdateEcheanceResult({
    required this.success,
    this.echeance,
    this.message,
  });

  factory UpdateEcheanceResult.success(EcheanceModel echeance) {
    return UpdateEcheanceResult(success: true, echeance: echeance);
  }

  factory UpdateEcheanceResult.error(String message) {
    return UpdateEcheanceResult(success: false, message: message);
  }
}

class UpdateEcheanceUseCase {
  final IEcheanceRepository _repository;

  UpdateEcheanceUseCase(this._repository);

  Future<UpdateEcheanceResult> execute(EcheanceModel echeance) async {
    try {
      Logger.info('Mise a jour echeance: ${echeance.id}');

      if (echeance.id.isEmpty) {
        return UpdateEcheanceResult.error('ID d echeance manquant.');
      }

      final updated = echeance.copyWith(updatedAt: DateTime.now());
      await _repository.updateEcheance(updated);

      Logger.success('Echeance mise a jour: ${updated.id}');
      return UpdateEcheanceResult.success(updated);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur mise a jour echeance: ${failure.message}');

      if (failure is DatabaseFailure) {
        return UpdateEcheanceResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return UpdateEcheanceResult.error(
        'Erreur lors de la mise a jour de l echeance.',
      );
    }
  }
}
