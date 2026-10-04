// lib/domain/usecases/echeances/marquer_payee_usecase.dart

import '../../repositories/i_echeance_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class MarquerPayeeResult {
  final bool success;
  final String? message;

  const MarquerPayeeResult({
    required this.success,
    this.message,
  });

  factory MarquerPayeeResult.success() {
    return const MarquerPayeeResult(success: true);
  }

  factory MarquerPayeeResult.error(String message) {
    return MarquerPayeeResult(success: false, message: message);
  }
}

class MarquerPayeeUseCase {
  final IEcheanceRepository _repository;

  MarquerPayeeUseCase(this._repository);

  Future<MarquerPayeeResult> execute(String echeanceId) async {
    try {
      Logger.info('Marquage payee: $echeanceId');

      if (echeanceId.isEmpty) {
        return MarquerPayeeResult.error('ID d echeance manquant.');
      }

      await _repository.marquerPayee(echeanceId);

      Logger.success('Echeance marquee payee: $echeanceId');
      return MarquerPayeeResult.success();
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur marquage payee: ${failure.message}');

      if (failure is DatabaseFailure) {
        return MarquerPayeeResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return MarquerPayeeResult.error(
        'Erreur lors du marquage de l echeance.',
      );
    }
  }
}
