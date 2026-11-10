// lib/domain/usecases/echeances/create_echeance_usecase.dart

import 'package:uuid/uuid.dart';
import '../../repositories/i_echeance_repository.dart';
import '../../../data/models/models.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/logger.dart';

class CreateEcheanceParams {
  final String uid;
  final String titre;
  final String description;
  final double montant;
  final DateTime dateEcheance;
  final String type;
  final String descriptionRecurrence;
  final String descriptionRappel;

  const CreateEcheanceParams({
    required this.uid,
    required this.titre,
    required this.description,
    required this.montant,
    required this.dateEcheance,
    required this.type,
    this.descriptionRecurrence = '',
    this.descriptionRappel = '',
  });
}

class CreateEcheanceResult {
  final bool success;
  final EcheanceModel? echeance;
  final String? message;

  const CreateEcheanceResult({
    required this.success,
    this.echeance,
    this.message,
  });

  factory CreateEcheanceResult.success(EcheanceModel echeance) {
    return CreateEcheanceResult(success: true, echeance: echeance);
  }

  factory CreateEcheanceResult.error(String message) {
    return CreateEcheanceResult(success: false, message: message);
  }
}

class CreateEcheanceUseCase {
  final IEcheanceRepository _repository;
  final _uuid = const Uuid();

  CreateEcheanceUseCase(this._repository);

  Future<CreateEcheanceResult> execute(CreateEcheanceParams params) async {
    try {
      Logger.info('Creation echeance: ${params.titre}');

      if (params.uid.isEmpty) {
        return CreateEcheanceResult.error('Utilisateur non identifie.');
      }

      if (params.titre.isEmpty) {
        return CreateEcheanceResult.error('Le titre est obligatoire.');
      }

      if (params.montant <= 0) {
        return CreateEcheanceResult.error(
            'Le montant doit etre superieur a 0.');
      }

      final now = DateTime.now();
      final echeance = EcheanceModel(
        id: _uuid.v4(),
        uid: params.uid,
        titre: params.titre,
        description: params.description,
        montant: params.montant,
        dateEcheance: params.dateEcheance,
        type: params.type,
        statut: 'en_attente',
        descriptionRecurrence: params.descriptionRecurrence,
        descriptionRappel: params.descriptionRappel,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.addEcheance(echeance);

      Logger.success('Echeance creee: ${echeance.id}');
      return CreateEcheanceResult.success(echeance);
    } catch (e) {
      final failure = ErrorHandler().handleException(e);
      Logger.error('Erreur creation echeance: ${failure.message}');

      if (failure is DatabaseFailure) {
        return CreateEcheanceResult.error(
          'Erreur de base de donnees. Veuillez reessayer.',
        );
      }

      return CreateEcheanceResult.error(
        'Erreur lors de la creation de l echeance.',
      );
    }
  }
}
