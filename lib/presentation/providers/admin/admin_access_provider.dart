import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  print('🔍 isAdmin user=${user?.email} role="${user?.role}"');
  if (user != null) {
    print(
      '🔍 isAdmin test: "${user.role}" == "admin" ? ${user.role == 'admin'}',
    );
  }

  if (user == null) return false;
  return user.role == 'admin';
});
