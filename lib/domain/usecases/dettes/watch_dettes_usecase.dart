// lib/domain/usecases/dettes/watch_dettes_usecase.dart

import '../../repositories/i_debt_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/logger.dart';

class WatchDettesUseCase {
  final IDebtRepository _repository;

  WatchDettesUseCase(this._repository);

  Stream<List<DetteModel>> execute(String uid) {
    Logger.info('Ecoute des dettes pour: $uid');
    return _repository.getUserDettes(uid);
  }
}
