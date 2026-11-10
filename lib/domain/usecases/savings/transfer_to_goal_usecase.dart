import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';

class TransferToGoalResult {
  final bool success;
  final String? message;
  const TransferToGoalResult({required this.success, this.message});
}

class TransferToGoalUseCase {
  final FirebaseFirestore _db;
  TransferToGoalUseCase(this._db);

  Future<TransferToGoalResult> execute({
    required String walletId,
    required String goalId,
    required String userId,
    required double montant,
  }) async {
    try {
      final batch = _db.batch();

      final walletRef = _db.collection('wallets').doc(walletId);
      final goalRef = _db.collection('savings_goals').doc(goalId);
      final transRef = _db.collection('transactions').doc();

      // 1. Retirer du wallet
      batch.update(walletRef, {
        'solde': FieldValue.increment(-montant),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Ajouter à l'objectif
      batch.update(goalRef, {
        'montantActuel': FieldValue.increment(montant),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Créer la transaction
      batch.set(transRef, {
        'uid': userId,
        'montant': montant,
        'type': 'virement',
        'categorieLabel': 'Épargne',
        'categorieEmoji': '💰',
        'dateTransaction': FieldValue.serverTimestamp(),
        'description': 'Virement vers objectif',
        'walletId': walletId,
        'goalId': goalId,
      });

      await batch.commit();
      Logger.success('✅ Virement effectué: $montant');
      return const TransferToGoalResult(success: true);
    } catch (e) {
      Logger.error('❌ Erreur virement: $e');
      return TransferToGoalResult(success: false, message: e.toString());
    }
  }
}
