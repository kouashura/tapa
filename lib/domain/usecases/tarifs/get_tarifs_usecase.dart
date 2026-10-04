// lib/domain/usecases/tarifs/get_tarifs_usecase.dart

import '../../repositories/i_tarif_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class GetTarifsUseCase {
  final ITarifRepository _repository;

  GetTarifsUseCase(this._repository);

  Future<TarifConfigModel> execute() async {
    try {
      final config = await _repository.getTarifsConfig();
      if (config == null) {
        Logger.info('Aucune config, utilisation des valeurs par defaut');
        return TarifConfigModel.defaut();
      }
      return config;
    } catch (e) {
      Logger.error('Erreur recuperation tarifs: $e');
      return TarifConfigModel.defaut();
    }
  }
}

class SaveTarifsUseCase {
  final ITarifRepository _repository;

  SaveTarifsUseCase(this._repository);

  Future<bool> execute(TarifConfigModel config) async {
    try {
      await _repository.saveTarifsConfig(config);
      return true;
    } catch (e) {
      Logger.error('Erreur sauvegarde tarifs: $e');
      return false;
    }
  }
}

class WatchTarifsUseCase {
  final ITarifRepository _repository;

  WatchTarifsUseCase(this._repository);

  Stream<TarifConfigModel?> execute() {
    return _repository.listenToTarifsConfig();
  }
}
