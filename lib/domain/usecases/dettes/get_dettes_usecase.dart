// lib/domain/usecases/dettes/get_dettes_usecase.dart

import '../../repositories/i_debt_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class GetDettesResult {
  final List<DetteModel> dettes;
  final bool success;
  final String? message;
  final double totalDettes;
  final double totalCreances;
  final double totalRestant;

  const GetDettesResult({
    this.dettes = const [],
    this.success = false,
    this.message,
    this.totalDettes = 0,
    this.totalCreances = 0,
    this.totalRestant = 0,
  });

  factory GetDettesResult.success(List<DetteModel> dettes) {
    double totalDettes = 0;
    double totalCreances = 0;
    double totalRestant = 0;

    for (final d in dettes) {
      if (d.type == 'dette') {
        totalDettes += d.montantRestant;
      } else {
        totalCreances += d.montantRestant;
      }
      totalRestant += d.montantRestant;
    }

    return GetDettesResult(
      dettes: dettes,
      success: true,
      totalDettes: totalDettes,
      totalCreances: totalCreances,
      totalRestant: totalRestant,
    );
  }

  factory GetDettesResult.error(String message) {
    return GetDettesResult(success: false, message: message);
  }

  factory GetDettesResult.empty() {
    return const GetDettesResult(dettes: [], success: true);
  }
}

class GetDettesUseCase {
  final IDebtRepository _repository;

  GetDettesUseCase(this._repository);

  Future<GetDettesResult> execute(String uid) async {
    try {
      Logger.info('Recuperation des dettes pour: $uid');

      if (uid.isEmpty) {
        return GetDettesResult.error('Utilisateur non identifie.');
      }

      final dettes = await _repository.getDettesOnce(uid);

      if (dettes.isEmpty) {
        Logger.info('Aucune dette trouvee');
        return GetDettesResult.empty();
      }

      Logger.success('${dettes.length} dettes recuperees');
      return GetDettesResult.success(dettes);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur recuperation dettes: ${failure.message}');

      if (failure is DatabaseFailure) {
        return GetDettesResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return GetDettesResult.error(
        'Erreur lors de la recuperation des dettes.',
      );
    }
  }
}
