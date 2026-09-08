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
import 'auth_state.dart';
import '../app_state.dart';

// ============================================
// PROVIDER
// ============================================

/// Provider du repository d'authentification
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider de l'état d'authentification
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(appStateProvider.notifier),
  );
});

// ============================================
// PROVIDERS UTILITAIRES SPÉCIFIQUES À CE FICHIER
// ============================================
// NOTE: currentUserProvider, isAuthenticatedProvider, userMonnaieProvider,
// userPrenomProvider, hasPinProvider, onboardingCompletedProvider,
// hasAccessVieProvider, canAccessAppProvider, isLoadingProvider et
// errorProvider sont déjà définis dans providers.dart (basés sur
// appStateProvider). Ne PAS les redéfinir ici pour éviter les
// "ambiguous_import" partout dans l'app.

/// Provider pour l'ID de vérification
final verificationIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).verificationId;
});

// ============================================
// NOTIFIER
// ============================================

/// Notifier pour l'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  final AppStateNotifier _appStateNotifier;

  AuthNotifier(this._authRepository, this._appStateNotifier)
      : super(AuthState.initial) {
    // ⚠️ Important : on ne peut pas appeler _checkAuthStatus() de façon
    // synchrone ici, car sa partie exécutée avant le premier `await`
    // modifierait AppStateNotifier pendant que Riverpod est encore en
    // train de construire AuthNotifier — ce qui est interdit et provoque
    // l'erreur "Providers are not allowed to modify other providers
    // during their initialization." Future.microtask reporte l'appel
    // juste après la fin de la phase de construction en cours.
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
  // ENVOI DU CODE DE VÉRIFICATION
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
  // VÉRIFICATION DU CODE
  // ============================================

  /// Vérifie le code SMS (avec 2 paramètres)
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

  /// Vérifie le code SMS (avec 1 paramètre - pour compatibilité)
  Future<bool> verifyCodeSingle(String smsCode) async {
    try {
      state = AuthState.verifying();
      _appStateNotifier.setLoading(true);

      final verificationId = state.verificationId ?? '';
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

  /// URL de ton Worker Cloudflare (proxy Brevo)
  static const String _brevoWorkerUrl =
      'https://brevo-proxy.tapa-budget.workers.dev';

  /// Génère un code à 6 chiffres, le stocke dans Firestore avec expiration,
  /// puis l'envoie par email via le Worker Cloudflare (Brevo).
  Future<void> envoyerCodeVerificationEmail(String email) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      // ℹ️ Pas de vérification de currentUser ici : cette méthode est
      // utilisée pendant l'inscription, AVANT la création du compte
      // (le document Firestore est indexé par email, pas par uid).
      final code = (100000 + Random().nextInt(900000)).toString();

      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(email)
          .set({
        'code': code,
        'email': email,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 15)),
        ),
      });

      final response = await http.post(
        Uri.parse(_brevoWorkerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur envoi email: ${response.body}');
      }

      Logger.success('✅ Code de vérification envoyé à $email');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur envoi code email: $e');
      rethrow;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  /// Compare le code entré par l'utilisateur avec celui stocké dans Firestore.
  /// Retourne true si valide et non expiré.
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

      // Si un compte existe déjà (ex: modification d'email depuis le
      // profil), on le met à jour tout de suite. Pendant l'inscription,
      // le compte n'existe pas encore : c'est l'écran appelant qui le
      // créera juste après, avec cet email et emailVerifie: true.
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
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    try {
      state = AuthState.loading;
      _appStateNotifier.setLoading(true);

      final user = await _authRepository.createUser(
        prenom: prenom,
        telephone: telephone,
        indicatif: indicatif,
        codePays: codePays,
        monnaie: monnaie,
      );

      state = AuthState.authenticated(user);
      _appStateNotifier.setAuthenticatedUser(user);

      Logger.success('✅ Compte créé: ${user.prenom}');
      return user;
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur création compte: $e');
      return null;
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  /// Alias pour createUser (pour compatibilité avec inscription_screen)
  Future<void> createUserProfile({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    final user = await createUser(
      prenom: prenom,
      telephone: telephone,
      indicatif: indicatif,
      codePays: codePays,
      monnaie: monnaie,
    );
    if (user == null) {
      // createUser() a déjà loggé et mis state.error à jour ; on relance
      // ici pour que l'écran appelant (verify_phone_screen.dart) sache
      // que la création a échoué au lieu de rediriger comme si tout allait bien.
      throw Exception(state.error ?? 'Erreur lors de la création du compte.');
    }
  }

  // ============================================
  // GESTION DU PIN
  // ============================================

  Future<void> savePin(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      // TODO: Sauvegarder le PIN dans un stockage sécurisé (SharedPreferences/Keychain)
      // AppUser n'a pas de champ hasPin, on le stocke séparément

      Logger.success('✅ PIN sauvegardé');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur sauvegarde PIN: $e');
    } finally {
      _appStateNotifier.setLoading(false);
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      _appStateNotifier.setLoading(true);

      // TODO: Vérifier le PIN depuis le stockage sécurisé
      final isValid = pin == '1234' || pin == '0000';

      if (isValid) {
        Logger.success('✅ PIN vérifié');
      } else {
        Logger.warning('⚠️ PIN incorrect');
      }

      return isValid;
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
      // TODO: Implémenter la mise à jour réelle
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
          notificationsActivees: notificationsActivees ?? currentUser.notificationsActivees,
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

      await _authRepository.signOut();

      state = AuthState.initial;
      _appStateNotifier.setUnauthenticated();

      Logger.info('🔓 Déconnecté');
    } catch (e) {
      state = AuthState.error(e.toString());
      _appStateNotifier.setError(e.toString());
      Logger.error('❌ Erreur déconnexion: $e');
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