// lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // ============================================
  // COULEURS PRINCIPALES (déjà dans TAPAColors)
  // ============================================
  // Ces couleurs sont déjà définies dans lib/theme/app_theme.dart
  // On les garde ici pour référence ou pour des valeurs complémentaires

  static const Color primaryNavy = Color(0xFF1A237E);
  static const Color primaryGold = Color(0xFFC9A227);
  static const Color primaryGoldLight = Color(0xFFFEF3C7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);

  // ============================================
  // COULEURS D'ÉTAT
  // ============================================
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFEAFAF1);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEC);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEAF2F8);
  static const Color purple = Color(0xFF8E44AD);
  static const Color purpleLight = Color(0xFFF4ECF7);

  // ============================================
  // TEXTES
  // ============================================
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // ============================================
  // BORDURES
  // ============================================
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // ============================================
  // TAILLES DE TEXTE
  // ============================================
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeDisplay = 30.0;

  // ============================================
  // TAILLES D'ESPACEMENT
  // ============================================
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 24.0;
  static const double spacingXXXLarge = 32.0;

  // ============================================
  // RAYONS DE BORDURE
  // ============================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusRound = 999.0;

  // ============================================
  // OMBRES
  // ============================================
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================
  // PÉRIODES DE TEMPS
  // ============================================
  static const int dureeEssaiJours = 10;
  static const int prixAccesVie = 5000;
  static const int pinCodeLength = 4;
  static const int otpCodeLength = 6;
  static const int otpValiditeMinutes = 10;

  // ============================================
  // MONNAIES SUPPORTÉES
  // ============================================
  static const List<Map<String, String>> monnaies = [
    {'symbole': 'FCFA', 'nom': 'Franc CFA', 'pays': 'Côte d\'Ivoire, Sénégal, etc.'},
    {'symbole': 'NGN', 'nom': 'Naira', 'pays': 'Nigeria'},
    {'symbole': 'GHS', 'nom': 'Cedi', 'pays': 'Ghana'},
    {'symbole': 'EUR', 'nom': 'Euro', 'pays': 'Europe'},
    {'symbole': 'USD', 'nom': 'Dollar', 'pays': 'États-Unis'},
    {'symbole': 'GBP', 'nom': 'Livre Sterling', 'pays': 'Royaume-Uni'},
  ];

  // ============================================
  // PAYS SUPPORTÉS
  // ============================================
  static const List<Map<String, String>> pays = [
    {'code': 'CI', 'nom': 'Côte d\'Ivoire', 'indicatif': '+225', 'flag': '🇨🇮', 'monnaie': 'FCFA'},
    {'code': 'SN', 'nom': 'Sénégal', 'indicatif': '+221', 'flag': '🇸🇳', 'monnaie': 'FCFA'},
    {'code': 'BF', 'nom': 'Burkina Faso', 'indicatif': '+226', 'flag': '🇧🇫', 'monnaie': 'FCFA'},
    {'code': 'ML', 'nom': 'Mali', 'indicatif': '+223', 'flag': '🇲🇱', 'monnaie': 'FCFA'},
    {'code': 'BJ', 'nom': 'Bénin', 'indicatif': '+229', 'flag': '🇧🇯', 'monnaie': 'FCFA'},
    {'code': 'TG', 'nom': 'Togo', 'indicatif': '+228', 'flag': '🇹🇬', 'monnaie': 'FCFA'},
    {'code': 'NG', 'nom': 'Nigeria', 'indicatif': '+234', 'flag': '🇳🇬', 'monnaie': 'NGN'},
    {'code': 'GH', 'nom': 'Ghana', 'indicatif': '+233', 'flag': '🇬🇭', 'monnaie': 'GHS'},
    {'code': 'FR', 'nom': 'France', 'indicatif': '+33', 'flag': '🇫🇷', 'monnaie': 'EUR'},
    {'code': 'US', 'nom': 'États-Unis', 'indicatif': '+1', 'flag': '🇺🇸', 'monnaie': 'USD'},
  ];

  // ============================================
  // CATÉGORIES PAR DÉFAUT
  // ============================================
  static const List<Map<String, dynamic>> categoriesDepense = [
    {'id': 'nourriture', 'label': 'Alimentation', 'emoji': '🍽️'},
    {'id': 'transport', 'label': 'Transport', 'emoji': '🚗'},
    {'id': 'logement', 'label': 'Logement', 'emoji': '🏠'},
    {'id': 'sante', 'label': 'Santé', 'emoji': '🏥'},
    {'id': 'education', 'label': 'Éducation', 'emoji': '📚'},
    {'id': 'loisirs', 'label': 'Loisirs', 'emoji': '🎮'},
    {'id': 'tontine', 'label': 'Tontine', 'emoji': '🤝'},
    {'id': 'factures', 'label': 'Factures', 'emoji': '📄'},
    {'id': 'shopping', 'label': 'Shopping', 'emoji': '🛍️'},
    {'id': 'restaurant', 'label': 'Restaurant', 'emoji': '🍜'},
    {'id': 'telephone', 'label': 'Téléphone', 'emoji': '📱'},
    {'id': 'autre', 'label': 'Autre', 'emoji': '📌'},
  ];

  static const List<Map<String, dynamic>> categoriesRevenu = [
    {'id': 'salaire', 'label': 'Salaire', 'emoji': '💰'},
    {'id': 'business', 'label': 'Business', 'emoji': '📈'},
    {'id': 'freelance', 'label': 'Freelance', 'emoji': '💻'},
    {'id': 'investissement', 'label': 'Investissement', 'emoji': '📊'},
    {'id': 'tontine', 'label': 'Tontine', 'emoji': '🤝'},
    {'id': 'cadeau', 'label': 'Cadeau', 'emoji': '🎁'},
    {'id': 'remboursement', 'label': 'Remboursement', 'emoji': '🔄'},
    {'id': 'interet', 'label': 'Intérêt', 'emoji': '🏦'},
    {'id': 'autre', 'label': 'Autre revenu', 'emoji': '💵'},
  ];

  // ============================================
  // FORMAT DE CLÉ TAPA
  // ============================================
  static const String formatCle = 'TB-2026-XXXXXXXX';
  static const String regexCle = r'^TB-2026-[A-Z0-9]{8}$';

  // ============================================
  // NUMÉROS DE CONTACT
  // ============================================
  static const String whatsAppNumber = '+2250160254102';
  static const String supportEmail = 'contact@tapa-budget.com';
  static const String websiteUrl = 'https://tapa-budget.com';
  static const String boutiqueUrl = 'https://tapa-budget.com/boutique';

  // ============================================
  // MESSAGES D'ERREUR
  // ============================================
  static const String errorGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorNetwork = 'Problème de connexion. Vérifiez votre réseau.';
  static const String errorTimeout = 'Délai dépassé. Veuillez réessayer.';
  static const String errorServer = 'Erreur serveur. Veuillez réessayer plus tard.';
  static const String errorAuth = 'Session expirée. Veuillez vous reconnecter.';
  static const String errorPinIncorrect = 'Code PIN incorrect. Réessayez.';
  static const String errorPinBlocked = 'PIN bloqué. Réessayez dans 5 minutes.';
  static const String errorFieldRequired = 'Ce champ est requis.';
  static const String errorInvalidEmail = 'Email invalide.';
  static const String errorInvalidPhone = 'Numéro de téléphone invalide.';
  static const String errorAmountMin = 'Le montant minimum est de 500 FCFA.';
  static const String errorInsufficientBalance = 'Solde insuffisant.';

  // ============================================
  // MESSAGES DE SUCCÈS
  // ============================================
  static const String successTransaction = '✅ Transaction enregistrée !';
  static const String successWalletCreated = '✅ Portefeuille créé !';
  static const String successBudgetCreated = '✅ Budget créé !';
  static const String successGoalCreated = '✅ Objectif créé !';
  static const String successDebtCreated = '✅ Dette ajoutée !';
  static const String successPayment = '✅ Paiement effectué !';
  static const String successPinChanged = '✅ PIN modifié !';
  static const String successProfileUpdated = '✅ Profil mis à jour !';

  // ============================================
  // NOMS DE ROUTES
  // ============================================
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeInscription = '/inscription';
  static const String routeVerifyPhone = '/verify-phone';
  static const String routePinSetup = '/pin-setup';
  static const String routePinLogin = '/pin-login';
  static const String routeActivation = '/activation';
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';
  static const String routeWallets = '/wallets';
  static const String routeAddTransaction = '/add-transaction';
  static const String routeHistory = '/history';
  static const String routeBudget = '/budget';
  static const String routeSavings = '/savings';
  static const String routeDebts = '/dettes';
  static const String routeEcheances = '/echeances';
  static const String routeReports = '/rapports';
  static const String routeScore = '/score';
  static const String routeAnalyse = '/analyse';
  static const String routeCoach = '/coach';
  static const String routeGuide = '/guide';
}