import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(),
);

final adminUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getUsers();
});

final adminUserDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  return ref.watch(adminRepositoryProvider).getUserDetails(userId);
});

final adminWithdrawsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getWithdraws();
});
