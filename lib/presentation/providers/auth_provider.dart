// lib/presentation/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../data/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/datasources/firebase/firebase_firestore.dart';
import '../../services/firebase_service.dart';  // ✅ AJOUTÉ
import '../../core/utils/logger.dart';

// ============================================
// PROVIDERS
// ============================================

final firebaseServiceProvider = Provider<FirebaseFirestoreService>((ref) {
  return FirebaseFirestoreService();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(userRepositoryProvider),
    ref.watch(firebaseServiceProvider),
  );
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});

final userMonnaieProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.monnaie ?? 'FCFA';
});

final userPrenomProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.prenom ?? 'Utilisateur';
});

final hasAccesVieProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.hasAccesVie ?? false;
});

// ============================================
// STATE
// ============================================

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
}

// ============================================
// NOTIFIER
// ============================================

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final FirebaseFirestoreService _firebase;

  AuthNotifier(this._userRepository, this._firebase) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isAuth = await _userRepository.isAuthenticated();
      if (isAuth) {
        final user = await _userRepository.getCurrentUser();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        Logger.info('👤 Utilisateur authentifié: ${user?.prenom}');
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
        Logger.info('👤 Utilisateur non authentifié');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      Logger.error('❌ Erreur vérification auth: $e');
    }
  }

  // ============================================
  // INSCRIPTION PHONE
  // ============================================

  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      isPhoneVerificationInProgress: true,
      error: null,
    );

    try {
      await _firebase.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          Logger.info('✅ Vérification automatique réussie');
          await _handlePhoneAuth(credential);
        },
        verificationFailed: (exception) {
          Logger.error('❌ Échec vérification: ${exception.message}');
          state = state.copyWith(
            isLoading: false,
            error: exception.message,
            isPhoneVerificationInProgress: false,
          );
        },
        codeSent: (verificationId, resendToken) {
          Logger.info('📱 Code SMS envoyé');
          state = state.copyWith(
            isLoading: false,
            isPhoneVerificationInProgress: false,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          Logger.warning('⏰ Temps de récupération du code expiré');
          state = state.copyWith(
            isLoading: false,
            error: 'Temps écoulé. Réessayez.',
            isPhoneVerificationInProgress: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isPhoneVerificationInProgress: false,
      );
      Logger.error('❌ Erreur envoi code: $e');
    }
  }

  Future<void> verifyCode(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      state = state.copyWith(
        error: 'Aucune vérification en cours',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _handlePhoneAuth(credential);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Code invalide. Réessayez.',
      );
      Logger.error('❌ Code invalide: $e');
    }
  }

  Future<void> _handlePhoneAuth(firebase_auth.PhoneAuthCredential credential) async {
    try {
      Logger.info('🔍 _handlePhoneAuth - Authentification en cours...');

      await _firebase.signInWithCredential(credential);
      Logger.info('✅ _handlePhoneAuth - SignIn réussi');

      final firebaseUser = _firebase.currentUser;
      Logger.info('🔍 _handlePhoneAuth - Firebase UID: ${firebaseUser?.uid}');
      Logger.info('🔍 _handlePhoneAuth - Firebase Phone: ${firebaseUser?.phoneNumber}');

      // ✅ METTRE À JOUR L'UTILISATEUR DANS FIREBASE SERVICE
      if (firebaseUser != null) {
        await FirebaseService().setCurrentUser(firebaseUser);
        Logger.info('✅ _handlePhoneAuth - CurrentUser mis à jour dans FirebaseService');
      }

      await _userRepository.updateLastLogin();

      final user = await _userRepository.getCurrentUser();
      Logger.info('🔍 _handlePhoneAuth - getCurrentUser: ${user?.prenom ?? "null"}');

      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          isPhoneVerificationInProgress: false,
        );
        Logger.info('👤 Utilisateur existant connecté: ${user.prenom}');
      } else {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          isPhoneVerificationInProgress: false,
        );
        Logger.info('🆕 Nouvel utilisateur - attend création profil');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur d\'authentification: $e',
        isPhoneVerificationInProgress: false,
      );
      Logger.error('❌ Erreur _handlePhoneAuth: $e');
    }
  }

  // ============================================
  // PROFIL
  // ============================================

  Future<void> createUserProfile({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    Logger.info('🔍 createUserProfile - Début');
    Logger.info('🔍 createUserProfile - Prénom: $prenom, Téléphone: $telephone');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _userRepository.createUser(
        prenom: prenom,
        telephone: telephone,
        indicatif: indicatif,
        codePays: codePays,
        monnaie: monnaie,
      );

      Logger.info('🔍 createUserProfile - Utilisateur créé: ${user.prenom} (${user.id})');

      // ✅ VÉRIFICATION IMMÉDIATE
      Logger.info('🔍 createUserProfile - Vérification immédiate...');
      final checkUser = await _userRepository.getCurrentUser();

      if (checkUser == null) {
        Logger.error('❌ Utilisateur non trouvé après création !');
        Logger.error('❌ UID recherché: ${_firebase.currentUserId}');
      } else {
        Logger.success('✅ Vérification: Utilisateur trouvé dans Firestore');
        Logger.info('🔍 createUserProfile - Utilisateur vérifié: ${checkUser.prenom}');
      }

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      Logger.success('✅ Profil créé pour ${user.prenom}');
    } catch (e) {
      Logger.error('❌ Erreur création profil: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _userRepository.updateUser(user);
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      Logger.info('📝 Profil mis à jour');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      Logger.error('❌ Erreur mise à jour profil: $e');
    }
  }

  Future<void> updatePrenom(String prenom) async {
    Logger.info('🔍 updatePrenom - Nouveau prénom: $prenom');
    await _userRepository.updatePrenom(prenom);
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
      Logger.success('✅ Prénom mis à jour: $prenom');
    } else {
      Logger.error('❌ updatePrenom - Utilisateur non trouvé');
    }
  }

  Future<void> updateMonnaie(String monnaie) async {
    Logger.info('🔍 updateMonnaie - Nouvelle monnaie: $monnaie');
    await _userRepository.updateMonnaie(monnaie);
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
      Logger.success('✅ Monnaie mise à jour: $monnaie');
    } else {
      Logger.error('❌ updateMonnaie - Utilisateur non trouvé');
    }
  }

  Future<void> markOnboardingAsSeen() async {
    Logger.info('🔍 markOnboardingAsSeen');
    await _userRepository.markOnboardingAsSeen();
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
      Logger.success('✅ Onboarding marqué comme vu');
    } else {
      Logger.error('❌ markOnboardingAsSeen - Utilisateur non trouvé');
    }
  }

  Future<void> setNotifications(bool enabled) async {
    Logger.info('🔍 setNotifications - $enabled');
    await _userRepository.setNotificationsEnabled(enabled);
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
      Logger.success('✅ Notifications: $enabled');
    } else {
      Logger.error('❌ setNotifications - Utilisateur non trouvé');
    }
  }

  // ============================================
  // PIN
  // ============================================

  Future<void> savePin(String pin) async {
    Logger.info('🔍 savePin');
    await _userRepository.savePin(pin);
    final user = await _userRepository.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
      Logger.success('✅ PIN sauvegardé');
    } else {
      Logger.error('❌ savePin - Utilisateur non trouvé');
    }
  }

  Future<bool> verifyPin(String pin) async {
    Logger.info('🔍 verifyPin');
    return await _userRepository.verifyPin(pin);
  }

  Future<bool> hasPin() async {
    Logger.info('🔍 hasPin');
    return await _userRepository.hasPin();
  }

  // ============================================
  // DÉCONNEXION
  // ============================================

  Future<void> logout() async {
    Logger.info('🔍 logout');
    state = state.copyWith(isLoading: true);
    try {
      await _userRepository.signOut();

      // ✅ NETTOYER FIREBASE SERVICE
      await FirebaseService().setCurrentUser(null);

      state = const AuthState();
      Logger.info('🔓 Déconnecté');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      Logger.error('❌ Erreur déconnexion: $e');
    }
  }

  // ============================================
  // SUPPRESSION COMPTE
  // ============================================

  Future<void> deleteAccount() async {
    Logger.info('🔍 deleteAccount');
    state = state.copyWith(isLoading: true);
    try {
      await _userRepository.deleteUser();

      // ✅ NETTOYER FIREBASE SERVICE
      await FirebaseService().setCurrentUser(null);

      state = const AuthState();
      Logger.info('🗑️ Compte supprimé');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      Logger.error('❌ Erreur suppression compte: $e');
    }
  }

  // ============================================
  // RÉINITIALISATION
  // ============================================

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    state = const AuthState();
  }
}