// lib/presentation/providers/auth/auth_provider.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../domain/repositories/i_auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/logger.dart';
import '../../../services/pin_security.dart';
import '../../../data/datasources/local/hive_service.dart';
import '../../../data/datasources/local/shared_preferences_service.dart';
import 'auth_state.dart';
import '../app_state.dart';

// ============================================
// PROVIDER
// ============================================

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(appStateProvider.notifier),
  );
});

final verificationIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).verificationId;
});

// ============================================
// NOTIFIER
// ============================================

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  final AppStateNotifier _appStateNotifier;

  AuthNotifier(this._authRepository, this._appStateNotifier)
      : super(AuthState.initial) {
    Future.microtask(_checkAuthStatus);
  }

  // ============================================
  // VÉRIFICATION DE L'AUTHENTIFICATION
  // ============================================

  Future<void> _checkAuthStatus() async {
    try {
      state = AuthState.loading;
      _appStateNotifier.setLoading(true);

      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
          _appStateNotifier.setAuthenticatedUser(user);
          Logger.info('👤 Utilisateur authentifié: ${user.prenom}');
        } else {
          state = AuthState.initial;
          _appStateNotifier.setUnauthenticated();
        }
      } else {
        state = AuthState.initial;
        _appStateNotifier.setUnauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur vérification auth: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // ENVOI DU CODE DE VÉRIFICATION SMS
  // ============================================

  Future<void> sendVerificationCode(String phoneNumber) async {
    try {
      state = AuthState.verifying();
      _appStateNotifier.setLoading(true);

      await _authRepository.sendVerificationCode(phoneNumber);

      state = AuthState.codeSent('pending');
      Logger.info('📱 Code envoyé à $phoneNumber');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur envoi code: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // VÉRIFICATION DU CODE SMS
  // ============================================

  Future<AppUser?> verifyCode(String verificationId, String smsCode) async {
    try {
      state = AuthState.verifying();
      _appStateNotifier.setLoading(true);

      final user = await _authRepository.verifyPhoneNumber(
        verificationId,
        smsCode,
      );

      state = AuthState.authenticated(user);
      _appStateNotifier.setAuthenticatedUser(user);

      Logger.success('✅ Code vérifié: ${user.prenom}');
      return user;
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur vérification: $e');
      return null;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<bool> verifyCodeSingle(String smsCode) async {
    try {
      // ⚠️ On capture verificationId AVANT de changer le state,
      // sinon verifying() l'écrase par null.
      final verificationId = state.verificationId ?? '';

      state = AuthState.verifying();
      _appStateNotifier.setLoading(true);

      final user = await _authRepository.verifyPhoneNumber(
        verificationId,
        smsCode,
      );

      state = AuthState.authenticated(user);
      _appStateNotifier.setAuthenticatedUser(user);

      Logger.success('✅ Code vérifié: ${user.prenom}');
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur vérification: $e');
      return false;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // VÉRIFICATION EMAIL (Brevo + Cloudflare Worker)
  // ============================================

  static const String _brevoWorkerUrl =
      'https://brevo-proxy.tapa-budget.workers.dev';

  Future<void> envoyerCodeVerificationEmail(String email) async {
    // ✅ Envoi du code par EMAIL via Brevo (backend Render)
    final cleanEmail = email.trim();
    
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      final code = (100000 + Random().nextInt(900000)).toString();

      // 1. Sauvegarder le code dans Firestore
      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(cleanEmail)
          .set({
        'code': code,
        'email': cleanEmail,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 15)),
        ),
      });

      // 2. Appeler TON backend Render (qui a la clé Brevo)
      final response = await http.post(
        Uri.parse('https://tapa-budget-server.onrender.com/api/send-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'code': code,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur envoi SMS: ${response.body}');
      }

      Logger.success('✅ Code de vérification envoyé par EMAIL à $cleanEmail');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur envoi code SMS: $e');
      rethrow;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<bool> verifierCodeEmail(String email, String codeEntre) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      final doc = await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(email)
          .get();

      if (!doc.exists) {
        Logger.warning('⚠️ Aucune demande de vérification trouvée');
        return false;
      }

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        Logger.warning('⚠️ Code expiré');
        return false;
      }

      if (data['code'] != codeEntre) {
        Logger.warning('⚠️ Code incorrect');
        return false;
      }

      final currentUser = state.user;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          dernierActive: DateTime.now(),
          email: email,
          emailVerifie: true,
        );

        await _authRepository.updateUser(updatedUser);

        state = AuthState.authenticated(updatedUser);
        _appStateNotifier.updateUser(updatedUser);
      }

      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(email)
          .delete();

      Logger.success('✅ Email vérifié avec succès');
      return true;
    } catch (e) {
      Logger.error('❌ Erreur vérification code email: $e');
      return false;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // INSCRIPTION / CRÉATION DE COMPTE
  // ============================================

  Future<AppUser?> createUser({
    required String prenom,
    required String email,
    required String codePays,
    required String monnaie,
  }) async {
    try {
      state = AuthState.loading;
      _appStateNotifier.setLoading(true);

      final user = await _authRepository.createUser(
        prenom: prenom,
        email: email,
        codePays: codePays,
        monnaie: monnaie,
      );

      state = AuthState.authenticated(user);
      _appStateNotifier.setAuthenticatedUser(user);

      Logger.success('Compte cree: ${user.prenom}');
      return user;
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('Erreur creation compte: $e');
      return null;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<void> createUserProfile({
    required String prenom,
    required String email,
    required String codePays,
    required String monnaie,
  }) async {
    final user = await createUser(
      prenom: prenom,
      email: email,
      codePays: codePays,
      monnaie: monnaie,
    );
    if (user == null) {
      throw Exception(state.error ?? 'Erreur lors de la creation du compte.');
    }
  }

  // ============================================
  // GESTION DU PIN
  // ============================================

  Future<void> savePin(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      Logger.info('🔍 Vérification PIN pour userId: ${firebase_auth.FirebaseAuth.instance.currentUser?.uid}');
      final userId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      await PinSecurity.savePin(userId, pin);

      _appStateNotifier.setPinExists(true);

      Logger.success('✅ PIN sauvegardé pour $userId');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur sauvegarde PIN: $e');
      rethrow;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      // Identité : Firebase si dispo, sinon identifiant local persistant.
      // → le PIN reste vérifiable même si le token Firebase a expiré.
      String userId;
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
      } else {
        userId = await PinSecurity.getOrCreateLocalUserId();
        Logger.warning('⚠️ Firebase absent, fallback identité locale');
      }

      final result = await PinSecurity.verifyPin(userId, pin);

      if (result.success) {
        Logger.success('✅ PIN vérifié');

        // Recharger l'utilisateur pour synchroniser le state
        // (sinon home lira user == null).
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
          _appStateNotifier.setAuthenticatedUser(user);
        }
      } else {
        Logger.warning('⚠️ PIN incorrect: ${result.message}');
        // On peut exposer le message au state pour l'UI
        state = state.copyWith(error: result.message);
      }

      return result.success;
    } catch (e) {
      Logger.error('❌ Erreur vérification PIN: $e');
      return false;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // ONBOARDING
  // ============================================

  Future<void> markOnboardingAsSeen() async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      final currentUser = state.user;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          onboardingVu: true,
          dernierActive: DateTime.now(),
        );

        await _authRepository.updateUser(updatedUser);

        state = AuthState.authenticated(updatedUser);
        _appStateNotifier.updateUser(updatedUser);

        Logger.success('✅ Onboarding marqué comme vu');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur markOnboardingAsSeen: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // WALLET
  // ============================================

  void updateWalletParams(Map<String, dynamic> params) {
    try {
      Logger.info('📊 Mise à jour wallet params: $params');
    } catch (e) {
      Logger.error('❌ Erreur updateWalletParams: $e');
    }
  }

  // ============================================
  // MISE À JOUR DU PROFIL
  // ============================================

  Future<void> updateUserProfile({
    String? prenom,
    String? monnaie,
    String? codePays,
    bool? notificationsActivees,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      final currentUser = state.user;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          prenom: prenom ?? currentUser.prenom,
          monnaie: monnaie ?? currentUser.monnaie,
          codePays: codePays ?? currentUser.codePays,
          notificationsActivees:
              notificationsActivees ?? currentUser.notificationsActivees,
          dernierActive: DateTime.now(),
        );

        await _authRepository.updateUser(updatedUser);

        state = AuthState.authenticated(updatedUser);
        _appStateNotifier.updateUser(updatedUser);

        Logger.success('✅ Profil mis à jour');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur mise à jour profil: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      await _authRepository.updateUser(user);

      state = AuthState.authenticated(user);
      _appStateNotifier.updateUser(user);

      Logger.success('✅ Profil mis à jour');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur mise à jour profil: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  // ============================================
  // DÉCONNEXION
  // ============================================

  Future<void> logout() async {
    try {
      state = AuthState.loading;
      _appStateNotifier.setLoading(true);

      // 1. Deconnecter Firebase Auth
      await _authRepository.signOut();

      // 2. Vider Hive (donnees locales)
      try {
        final hive = HiveService();
        await hive.clearAll();
      } catch (e) {
        Logger.error('Erreur nettoyage Hive: $e');
      }

      // 3. Vider SharedPreferences (sauf PIN)
      try {
        final prefs = SharedPreferencesService();
        await prefs.clearUserData();
      } catch (e) {
        Logger.error('Erreur nettoyage SharedPrefs: $e');
      }

      // 4. Reset AppState
      state = AuthState.initial;
      _appStateNotifier.setUnauthenticated();

      Logger.info('🔓 Deconnecte + cache nettoye');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur deconnexion: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      state = AuthState.loading;
      _appStateNotifier.setLoading(true);

      await _authRepository.deleteAccount();

      state = AuthState.initial;
      _appStateNotifier.setUnauthenticated();

      Logger.info('🗑️ Compte supprimé');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur suppression compte: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
    _appStateNotifier.clearError();
  }

  void reset() {
    state = AuthState.initial;
    _appStateNotifier.setUnauthenticated();
    Logger.info('🔄 État réinitialisé');
  }
}
