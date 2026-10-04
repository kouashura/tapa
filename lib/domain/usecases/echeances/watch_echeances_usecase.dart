// lib/domain/usecases/echeances/watch_echeances_usecase.dart

import '../../repositories/i_echeance_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/logger.dart';

class WatchEcheancesUseCase {
  final IEcheanceRepository _repository;

  WatchEcheancesUseCase(this._repository);

  Stream<List<EcheanceModel>> execute(String uid) {
    Logger.info('Ecoute des echeances pour: $uid');
    return _repository.getUserEcheances(uid);
  }
}
