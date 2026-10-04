// lib/domain/usecases/echeances/delete_echeance_usecase.dart

import '../../repositories/i_echeance_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class DeleteEcheanceResult {
  final bool success;
  final String? message;

  const DeleteEcheanceResult({
    required this.success,
    this.message,
  });

  factory DeleteEcheanceResult.success() {
    return const DeleteEcheanceResult(success: true);
  }

  factory DeleteEcheanceResult.error(String message) {
    return DeleteEcheanceResult(success: false, message: message);
  }
}

class DeleteEcheanceUseCase {
  final IEcheanceRepository _repository;

  DeleteEcheanceUseCase(this._repository);

  Future<DeleteEcheanceResult> execute(String echeanceId) async {
    try {
      Logger.info('Suppression echeance: $echeanceId');

      if (echeanceId.isEmpty) {
        return DeleteEcheanceResult.error('ID d echeance manquant.');
      }

      await _repository.deleteEcheance(echeanceId);

      Logger.success('Echeance supprimee: $echeanceId');
      return DeleteEcheanceResult.success();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur suppression echeance: ${failure.message}');

      if (failure is DatabaseFailure) {
        return DeleteEcheanceResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return DeleteEcheanceResult.error(
        'Erreur lors de la suppression de l echeance.',
      );
    }
  }
}
