// lib/domain/usecases/dettes/rembourser_dette_usecase.dart

import 'package:uuid/uuid.dart';
import '../../repositories/i_debt_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class RembourserDetteParams {
  final String detteId;
  final double montant;
  final String walletId;
  final String? note;

  const RembourserDetteParams({
    required this.detteId,
    required this.montant,
    required this.walletId,
    this.note,
  });
}

class RembourserDetteResult {
  final bool success;
  final RemboursementModel? remboursement;
  final String? message;

  const RembourserDetteResult({
    required this.success,
    this.remboursement,
    this.message,
  });

  factory RembourserDetteResult.success(RemboursementModel remboursement) {
    return RembourserDetteResult(success: true, remboursement: remboursement);
  }

  factory RembourserDetteResult.error(String message) {
    return RembourserDetteResult(success: false, message: message);
  }
}

class RembourserDetteUseCase {
  final IDebtRepository _repository;
  final _uuid = const Uuid();

  RembourserDetteUseCase(this._repository);

  Future<RembourserDetteResult> execute(RembourserDetteParams params) async {
    try {
      Logger.info('Remboursement dette: ${params.montant}');

      if (params.detteId.isEmpty) {
        return RembourserDetteResult.error('ID de dette manquant.');
      }

      if (params.montant <= 0) {
        return RembourserDetteResult.error(
          'Le montant doit etre superieur a 0.',
        );
      }

      final remboursement = RemboursementModel(
        id: _uuid.v4(),
        montant: params.montant,
        date: DateTime.now(),
        walletId: params.walletId,
        note: params.note,
      );

      await _repository.addRemboursement(params.detteId, remboursement);

      Logger.success('Remboursement ajoute: ${remboursement.id}');
      return RembourserDetteResult.success(remboursement);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur remboursement dette: ${failure.message}');

      if (failure is DatabaseFailure) {
        return RembourserDetteResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return RembourserDetteResult.error(
        'Erreur lors du remboursement de la dette.',
      );
    }
  }
}
