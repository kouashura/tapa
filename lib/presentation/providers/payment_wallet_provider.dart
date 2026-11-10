import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider qui écoute en temps réel le solde du Wallet de Paiement
/// Stocké dans la collection Firestore `user_wallet/{userId}`.
final userWalletBalanceProvider =
    StreamProvider.family<double, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(0.0);

  return FirebaseFirestore.instance
      .collection('user_wallet')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return 0.0;
    final data = snapshot.data() as Map<String, dynamic>;
    return (data['solde'] as num?)?.toDouble() ?? 0.0;
  });
});

/// Provider pour récupérer le document complet (si tu as besoin d'autres infos)
final userWalletDocProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('user_wallet')
      .doc(userId)
      .snapshots()
      .map((snapshot) => snapshot.data());
});
