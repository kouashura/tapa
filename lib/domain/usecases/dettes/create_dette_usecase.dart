// lib/domain/usecases/dettes/create_dette_usecase.dart

import 'package:uuid/uuid.dart';
import '../../repositories/i_debt_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class CreateDetteParams {
  final String uid;
  final String type;
  final double montantTotal;
  final String modalite;
  final int periodesMois;
  final DateTime dateDebut;
  final DateTime dateFin;

  const CreateDetteParams({
    required this.uid,
    required this.type,
    required this.montantTotal,
    required this.modalite,
    required this.periodesMois,
    required this.dateDebut,
    required this.dateFin,
  });
}

class CreateDetteResult {
  final bool success;
  final DetteModel? dette;
  final String? message;

  const CreateDetteResult({
    required this.success,
    this.dette,
    this.message,
  });

  factory CreateDetteResult.success(DetteModel dette) {
    return CreateDetteResult(success: true, dette: dette);
  }

  factory CreateDetteResult.error(String message) {
    return CreateDetteResult(success: false, message: message);
  }
}

class CreateDetteUseCase {
  final IDebtRepository _repository;
  final _uuid = const Uuid();

  CreateDetteUseCase(this._repository);

  Future<CreateDetteResult> execute(CreateDetteParams params) async {
    try {
      Logger.info('Creation dette: ${params.montantTotal} ${params.type}');

      if (params.uid.isEmpty) {
        return CreateDetteResult.error('Utilisateur non identifie.');
      }

      if (params.montantTotal <= 0) {
        return CreateDetteResult.error('Le montant doit etre superieur a 0.');
      }

      final dette = DetteModel(
        id: _uuid.v4(),
        uid: params.uid,
        type: params.type,
        montantTotal: params.montantTotal,
        montantRembourse: 0,
        modalite: params.modalite,
        periodesMois: params.periodesMois,
        dateDebut: params.dateDebut,
        dateFin: params.dateFin,
        dateCreation: DateTime.now(),
        remboursements: const [],
      );

      await _repository.addDette(dette);

      Logger.success('Dette creee: ${dette.id}');
      return CreateDetteResult.success(dette);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur creation dette: ${failure.message}');

      if (failure is DatabaseFailure) {
        return CreateDetteResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return CreateDetteResult.error('Erreur lors de la creation de la dette.');
    }
  }
}
