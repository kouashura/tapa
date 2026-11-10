// lib/presentation/providers/auth/auth_state.dart

import '../../../data/models/models.dart'; // ✅ Utiliser models.dart

/// État de l'authentification
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final bool isPhoneVerificationInProgress;
  final String? verificationId;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.isPhoneVerificationInProgress = false,
    this.verificationId,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    bool? isPhoneVerificationInProgress,
    String? verificationId,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      isPhoneVerificationInProgress:
          isPhoneVerificationInProgress ?? this.isPhoneVerificationInProgress,
      verificationId: verificationId ?? this.verificationId,
    );
  }

  /// État initial
  static const AuthState initial = AuthState();

  /// État de chargement
  static const AuthState loading = AuthState(isLoading: true);

  /// État authentifié
  factory AuthState.authenticated(AppUser user) {
    return AuthState(
      user: user,
      isAuthenticated: true,
    );
  }

  /// État avec erreur
  factory AuthState.error(String error) {
    return AuthState(
      error: error,
      isLoading: false,
    );
  }

  /// État de vérification en cours
  factory AuthState.verifying() {
    return const AuthState(
      isPhoneVerificationInProgress: true,
      isLoading: true,
    );
  }

  /// État avec code envoyé
  factory AuthState.codeSent(String verificationId) {
    return AuthState(
      verificationId: verificationId,
      isPhoneVerificationInProgress: false,
      isLoading: false,
    );
  }

  /// Vérifie si l'utilisateur a un PIN
  bool get hasPin {
    // Le PIN est vérifié séparément via PinSecurity
    return false;
  }
}
