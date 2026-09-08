// lib/data/datasources/remote/firebase/firebase_auth_datasource.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../models/models.dart';

/// Datasource pour l'authentification Firebase
class FirebaseAuthDatasource {
  static final FirebaseAuthDatasource _instance =
  FirebaseAuthDatasource._internal();

  factory FirebaseAuthDatasource() => _instance;

  FirebaseAuthDatasource._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // UTILISATEUR COURANT
  // ============================================

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // ============================================
  // ENVOI DE CODE DE VÉRIFICATION
  // ============================================

  /// Envoie un code de vérification par SMS avec callbacks complets
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required void Function(String verificationId, int? forceResendingToken) onCodeSent,
    required void Function(FirebaseAuthException) onError,
    void Function(PhoneAuthCredential)? onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted ?? (credential) async {
          await _auth.signInWithCredential(credential);
          Logger.success('✅ Auto-vérification réussie');
        },
        verificationFailed: (error) {
          Logger.error('❌ Erreur vérification SMS: ${error.message}');
          onError(error);
        },
        codeSent: (verificationId, forceResendingToken) {
          Logger.info('📱 Code SMS envoyé: ${verificationId.substring(0, 10)}...');
          onCodeSent(verificationId, forceResendingToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          Logger.warning('⚠️ Timeout auto-récupération: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      Logger.error('❌ Erreur sendVerificationCode: $e');
      if (e is FirebaseAuthException) {
        onError(e);
      } else {
        onError(FirebaseAuthException(
          code: 'unknown',
          message: e.toString(),
        ));
      }
    }
  }

  /// Version simplifiée pour l'envoi de code
  Future<void> sendVerificationCodeSimple(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
          Logger.success('✅ Auto-vérification réussie');
        },
        verificationFailed: (error) {
          Logger.error('❌ Erreur vérification SMS: ${error.message}');
          throw Exception(error.message);
        },
        codeSent: (verificationId, forceResendingToken) {
          Logger.info('📱 Code SMS envoyé: $verificationId');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          Logger.warning('⚠️ Timeout auto-récupération: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      Logger.error('❌ Erreur envoi SMS: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // VÉRIFICATION DU CODE
  // ============================================

  /// Connecte avec des credentials PhoneAuth
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      Logger.success('✅ Connexion réussie: ${result.user?.uid}');
      return result;
    } catch (e) {
      Logger.error('❌ Erreur connexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Vérifie le code SMS et retourne l'utilisateur
  Future<AppUser?> verifyPhoneNumber(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      // Vérifier si l'utilisateur existe dans Firestore
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser.fromMap(data, firebaseUser.uid);
      }

      // Créer un nouvel utilisateur si pas trouvé
      return AppUser(
        id: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        prenom: '',
        monnaie: 'FCFA',
        codePays: 'CI',
        hasAccessVie: false,
        onboardingVu: false,
        notificationsActivees: true,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      Logger.error('❌ Erreur verifyPhoneNumber: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // CRÉATION D'UTILISATEUR
  // ============================================

  /// Crée un nouvel utilisateur dans Firestore
  Future<AppUser> createUser({
    required String prenom,
    required String telephone,
    required String indicatif,
    required String codePays,
    required String monnaie,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final user = AppUser(
        id: firebaseUser.uid,
        phoneNumber: telephone,
        prenom: prenom,
        monnaie: monnaie,
        codePays: codePays,
        hasAccessVie: false,
        onboardingVu: false,
        notificationsActivees: true,
        createdAt: DateTime.now(),
        dernierActive: DateTime.now(),
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
      Logger.info('✅ Utilisateur créé: ${user.prenom}');
      return user;
    } catch (e) {
      Logger.error('❌ Erreur createUser: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // MISE À JOUR D'UTILISATEUR
  // ============================================

  /// Met à jour un utilisateur dans Firestore
  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
      Logger.info('📝 Utilisateur mis à jour: ${user.prenom}');
    } catch (e) {
      Logger.error('❌ Erreur updateUser: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  // ============================================
  // RÉCUPÉRATION D'UTILISATEUR
  // ============================================

  /// Récupère l'utilisateur complet (Firebase + Firestore)
  Future<AppUser?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return AppUser.fromMap(data, firebaseUser.uid);
    } catch (e) {
      Logger.error('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  // ============================================
  // DÉCONNEXION ET SUPPRESSION
  // ============================================

  /// Déconnecte l'utilisateur
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.success('🔓 Déconnexion réussie');
    } catch (e) {
      Logger.error('❌ Erreur déconnexion: $e');
      throw ErrorHandler().handleException(e);
    }
  }

  /// Supprime le compte Firebase et Firestore
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw const AuthFailure(
          message: 'Aucun utilisateur connecté.',
          code: 'NO_USER',
        );
      }

      // Supprimer les données Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // Supprimer le compte Firebase
      await firebaseUser.delete();

      Logger.success('🗑️ Compte supprimé avec succès');
    } catch (e) {
      Logger.error('❌ Erreur deleteAccount: $e');
      throw ErrorHandler().handleException(e);
    }
  }
}