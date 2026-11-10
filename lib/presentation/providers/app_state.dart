// lib/presentation/providers/app_state.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart'; // ✅ Utiliser models.dart

/// État global de l'application
class AppState {
  // ============================================
  // AUTHENTIFICATION
  // ============================================
  final AppUser? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  // ============================================
  // ONBOARDING
  // ============================================
  final bool onboardingCompleted;

  // ============================================
  // PIN
  // ============================================
  final bool hasPin;
  final bool isPinLocked;
  final int pinAttempts;

  // ============================================
  // ACCÈS
  // ============================================
  final bool hasAccessVie;
  final bool isRoot;
  final bool essaiExpire;

  // ============================================
  // THEME
  // ============================================
  final bool isDarkMode;

  // ============================================
  // NOTIFICATIONS
  // ============================================
  final bool notificationsEnabled;

  const AppState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
    this.hasPin = false,
    this.isPinLocked = false,
    this.pinAttempts = 0,
    this.hasAccessVie = false,
    this.isRoot = false,
    this.essaiExpire = false,
    this.isDarkMode = false,
    this.notificationsEnabled = true,
  });

  // ============================================
  // COPIE
  // ============================================

  AppState copyWith({
    AppUser? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
    bool? hasPin,
    bool? isPinLocked,
    int? pinAttempts,
    bool? hasAccessVie,
    bool? isRoot,
    bool? essaiExpire,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) {
    return AppState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      hasPin: hasPin ?? this.hasPin,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinAttempts: pinAttempts ?? this.pinAttempts,
      hasAccessVie: hasAccessVie ?? this.hasAccessVie,
      isRoot: isRoot ?? this.isRoot,
      essaiExpire: essaiExpire ?? this.essaiExpire,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Vérifie si l'utilisateur est complètement authentifié
  bool get isFullyAuthenticated {
    return isAuthenticated && currentUser != null;
  }

  /// Vérifie si l'utilisateur est root
  bool get isRootUser => isRoot;

  /// Vérifie si l'utilisateur a accès à l'application
  bool get canAccessApp {
    return isRoot || hasAccessVie || !essaiExpire;
  }

  /// Récupère le nom d'affichage de l'utilisateur
  String get displayName {
    if (currentUser != null) {
      return currentUser!.prenom;
    }
    return 'Utilisateur';
  }

  /// Récupère la monnaie de l'utilisateur
  String get monnaie {
    return currentUser?.monnaie ?? 'FCFA';
  }

  /// Vérifie si l'utilisateur doit faire l'onboarding
  bool get needsOnboarding {
    return isAuthenticated && !onboardingCompleted;
  }

  /// Vérifie si l'utilisateur doit créer un PIN
  bool get needsPin {
    return isAuthenticated && !hasPin;
  }

  /// Vérifie si l'utilisateur doit aller à l'activation
  bool get needsActivation {
    return isAuthenticated && !canAccessApp;
  }

  /// État initial
  static const AppState initial = AppState();

  /// État chargement
  static const AppState loading = AppState(isLoading: true);

  /// État authentifié
  factory AppState.authenticated(AppUser user) {
    return AppState(
      currentUser: user,
      isAuthenticated: true,
      onboardingCompleted: user.onboardingVu,
    );
  }

  /// État avec erreur
  factory AppState.error(String error) {
    return AppState(
      error: error,
      isLoading: false,
    );
  }
}

// ============================================
// PROVIDER DE L'ÉTAT GLOBAL
// ============================================

/// Provider de l'état global de l'application
final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// ============================================
// NOTIFIER DE L'ÉTAT GLOBAL
// ============================================

/// Notifier pour l'état global
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.initial);

  // ============================================
  // AUTHENTIFICATION
  // ============================================

  /// Définit l'utilisateur authentifié
  void setAuthenticatedUser(AppUser user) {
    state = state.copyWith(
      currentUser: user,
      isAuthenticated: true,
      isLoading: false,
      onboardingCompleted: user.onboardingVu,
    );
  }

  /// Définit l'utilisateur non authentifié
  void setUnauthenticated() {
    state = AppState.initial;
  }

  /// Définit l'état de chargement
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Définit une erreur
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ============================================
  // ONBOARDING
  // ============================================

  /// Marque l'onboarding comme terminé
  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }

  // ============================================
  // PIN
  // ============================================

  /// Définit le PIN comme existant
  void setPinExists(bool exists) {
    state = state.copyWith(hasPin: exists);
  }

  /// Définit l'état du PIN
  void setPinState({
    bool? hasPin,
    bool? isPinLocked,
    int? pinAttempts,
  }) {
    state = state.copyWith(
      hasPin: hasPin ?? state.hasPin,
      isPinLocked: isPinLocked ?? state.isPinLocked,
      pinAttempts: pinAttempts ?? state.pinAttempts,
    );
  }

  // ============================================
  // ACCÈS
  // ============================================

  /// Définit l'accès à vie
  void setAccessVie(bool hasAccess) {
    state = state.copyWith(hasAccessVie: hasAccess);
  }

  /// Définit le statut root
  void setRootUser(bool isRoot) {
    state = state.copyWith(isRoot: isRoot);
  }

  /// Définit l'expiration de l'essai
  void setEssaiExpire(bool expired) {
    state = state.copyWith(essaiExpire: expired);
  }

  // ============================================
  // THEME
  // ============================================

  /// Bascule le thème sombre
  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  /// Définit le thème sombre
  void setDarkMode(bool darkMode) {
    state = state.copyWith(isDarkMode: darkMode);
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Définit les notifications
  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  // ============================================
  // UTILITAIRES
  // ============================================

  /// Réinitialise l'état
  void reset() {
    state = AppState.initial;
  }

  /// Met à jour le profil utilisateur
  void updateUser(AppUser user) {
    state = state.copyWith(currentUser: user);
  }
}
