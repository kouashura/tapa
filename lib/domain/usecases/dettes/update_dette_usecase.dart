// lib/domain/usecases/dettes/update_dette_usecase.dart

import '../../repositories/i_debt_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class UpdateDetteResult {
  final bool success;
  final DetteModel? dette;
  final String? message;

  const UpdateDetteResult({
    required this.success,
    this.dette,
    this.message,
  });

  factory UpdateDetteResult.success(DetteModel dette) {
    return UpdateDetteResult(success: true, dette: dette);
  }

  factory UpdateDetteResult.error(String message) {
    return UpdateDetteResult(success: false, message: message);
  }
}

class UpdateDetteUseCase {
  final IDebtRepository _repository;

  UpdateDetteUseCase(this._repository);

  Future<UpdateDetteResult> execute(DetteModel dette) async {
    try {
      Logger.info('Mise a jour dette: ${dette.id}');

      if (dette.id.isEmpty) {
        return UpdateDetteResult.error('ID de dette manquant.');
      }

      await _repository.updateDette(dette);

      Logger.success('Dette mise a jour: ${dette.id}');
      return UpdateDetteResult.success(dette);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur mise a jour dette: ${failure.message}');

      if (failure is DatabaseFailure) {
        return UpdateDetteResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return UpdateDetteResult.error(
        'Erreur lors de la mise a jour de la dette.',
      );
    }
  }
}
