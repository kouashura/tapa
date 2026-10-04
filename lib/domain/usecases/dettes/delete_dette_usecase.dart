// lib/domain/usecases/dettes/delete_dette_usecase.dart

import '../../repositories/i_debt_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class DeleteDetteResult {
  final bool success;
  final String? message;

  const DeleteDetteResult({
    required this.success,
    this.message,
  });

  factory DeleteDetteResult.success() {
    return const DeleteDetteResult(success: true);
  }

  factory DeleteDetteResult.error(String message) {
    return DeleteDetteResult(success: false, message: message);
  }
}

class DeleteDetteUseCase {
  final IDebtRepository _repository;

  DeleteDetteUseCase(this._repository);

  Future<DeleteDetteResult> execute(String detteId) async {
    try {
      Logger.info('Suppression dette: $detteId');

      if (detteId.isEmpty) {
        return DeleteDetteResult.error('ID de dette manquant.');
      }

      await _repository.deleteDette(detteId);

      Logger.success('Dette supprimee: $detteId');
      return DeleteDetteResult.success();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur suppression dette: ${failure.message}');

      if (failure is DatabaseFailure) {
        return DeleteDetteResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return DeleteDetteResult.error(
        'Erreur lors de la suppression de la dette.',
      );
    }
  }
}
