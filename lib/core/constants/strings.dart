// lib/core/constants/strings.dart

class AppStrings {
  // ============================================
  // TITRES DE L'APPLICATION
  // ============================================
  static const String appName = 'TAPA Invest';
  static const String appSubtitle = 'Le budget simple pour tous.';
  static const String appSlogan = 'Votre coach financier intelligent';

  // ============================================
  // ÉCRAN DE CHARGEMENT (Splash)
  // ============================================
  static const String splashTitle = 'TAPA Invest';
  static const String splashSubtitle = 'Le budget simple pour tous.';
  static const String splashLoading = 'Chargement...';

  // ============================================
  // ONBOARDING
  // ============================================
  static const String onboardingTitle1 = 'Bienvenue sur TAPA Invest';
  static const String onboardingSubtitle1 =
      'LE COACH FINANCIER DE CHAQUE AFRICAIN';
  static const String onboardingDesc1 =
      'Prenez le contrôle de votre argent et construisez votre avenir financier pas à pas.';

  static const String onboardingTitle2 =
      'Tous vos portefeuilles en un seul endroit';
  static const String onboardingSubtitle2 =
      'WAVE · ORANGE MONEY · MTN · MOOV · CASH · BANQUE';
  static const String onboardingDesc2 =
      'Centralisez tous vos comptes et suivez chaque FCFA peu importe où il se trouve.';

  static const String onboardingTitle3 =
      'Investissez et protégez votre famille';
  static const String onboardingSubtitle3 = 'FCP ET ASSURANCE VIE SONAM VIE';
  static const String onboardingDesc3 =
      'Faites fructifier votre épargne et protégez vos proches avec nos partenaires agréés.';

  static const String onboardingButtonNext = 'Suivant';
  static const String onboardingButtonStart = 'Commencer maintenant';
  static const String onboardingButtonSkip = 'Passer';

  // ============================================
  // AUTHENTIFICATION
  // ============================================
  static const String authWelcome = 'Bienvenue !';
  static const String authNameQuestion = 'Comment tu t\'appelles ?';
  static const String authPhoneHint = 'ex : 0748684403';
  static const String authPhoneLabel = 'Numéro WhatsApp *';
  static const String authNameHint = 'ex : Kouassi, Marie...';
  static const String authNameLabel = 'Prénom';
  static const String authPhoneInfo = 'Numéro utilisé pour te contacter';
  static const String authMonnaieQuestion = 'Quelle monnaie tu utilises ?';
  static const String authMonnaieSubtitle =
      'Tu pourras changer ça dans les réglages.';
  static const String authCreateAccount = 'Créer mon compte';
  static const String authContinue = 'Continuer';

  static const String authPinTitle = 'Choisis ton code PIN';
  static const String authPinSubtitle = 'Code PIN à 4 chiffres';
  static const String authPinConfirmTitle = 'Confirme ton code PIN';
  static const String authPinLoginTitle = 'Entre ton code PIN';
  static const String authPinLoginSubtitle =
      'Entrez votre code PIN à 4 chiffres';

  // ============================================
  // ACTIVATION
  // ============================================
  static const String activationTitle = 'Obtenir l\'accès à vie';
  static const String activationPrice = 'Paiement unique de 5 000 FCFA';
  static const String activationFeatures =
      '✅ Toutes les fonctionnalités à vie\n✅ Toutes les mises à jour futures\n✅ Support prioritaire\n✅ Accès aux nouvelles fonctionnalités';
  static const String activationPayButton = 'Payer maintenant — 5 000 FCFA';
  static const String activationWhatsAppButton =
      'Demander une clé par WhatsApp';
  static const String activationKeyTitle = 'J\'ai déjà ma clé d\'accès';
  static const String activationKeyHint =
      'Entre la clé reçue après ton paiement';
  static const String activationKeyPlaceholder = 'TB-2026-XXXXXXXX';
  static const String activationActivateButton = 'Activer mon accès';

  // ============================================
  // ACCUEIL (HOME)
  // ============================================
  static const String homeGreeting = 'Bonjour';
  static const String homeTotalBalance = 'Solde total';
  static const String homeRevenue = 'Revenus';
  static const String homeExpense = 'Dépenses';
  static const String homeWallets = 'Mes portefeuilles';
  static const String homeTransactions = 'Transactions';
  static const String homeSeeAll = 'Voir tout';
  static const String homeEmptyTransactions = 'Aucune transaction';
  static const String homeEmptyWallets = 'Aucun portefeuille';
  static const String homeTransfer = 'Transférer';

  // ============================================
  // PORTEFEUILLES
  // ============================================
  static const String walletTitle = 'Mes portefeuilles';
  static const String walletTotal = 'TOTAL DISPONIBLE';
  static const String walletAdd = 'Ajouter un portefeuille';
  static const String walletName = 'Nom du portefeuille';
  static const String walletNameHint = 'Ex: Mon compte Wave';
  static const String walletType = 'Type de portefeuille';
  static const String walletBalance = 'Solde initial';
  static const String walletBalanceHint = '0';
  static const String walletDescription = 'Description (optionnel)';
  static const String walletDescriptionHint = 'Ex: Compte principal';
  static const String walletCreate = 'Créer le portefeuille';
  static const String walletDelete = 'Supprimer';
  static const String walletEdit = 'Modifier';

  // ============================================
  // TRANSACTIONS
  // ============================================
  static const String transactionAdd = 'Nouvelle transaction';
  static const String transactionExpense = 'Dépense';
  static const String transactionRevenue = 'Revenu';
  static const String transactionAmount = 'Montant *';
  static const String transactionCategory = 'Catégorie *';
  static const String transactionWallet = 'Portefeuille *';
  static const String transactionDate = 'Date de la transaction';
  static const String transactionNote = 'Note (optionnelle)';
  static const String transactionNoteHint = 'ex : Courses supermarché';
  static const String transactionSave = 'Enregistrer';
  static const String transactionSaveRevenue = 'Enregistrer le revenu';
  static const String transactionSaveExpense = 'Enregistrer la dépense';
  static const String transactionHistory = 'Historique';
  static const String transactionVoice = 'Dictee vocale';
  static const String transactionScan = 'Scanner un reçu';
  static const String transactionTransfer = 'Transfert';

  // ============================================
  // BUDGET
  // ============================================
  static const String budgetTitle = 'Budget';
  static const String budgetCreate = 'Créer le budget';
  static const String budgetEdit = 'Modifier';
  static const String budgetEmpty = 'Aucun budget ce mois-ci';
  static const String budgetEmptyHint =
      'Créez le budget de {mois} pour suivre vos dépenses et revenus au fil du mois';
  static const String budgetIncome = 'Revenus prévus';
  static const String budgetExpense = 'Dépenses prévues';
  static const String budgetCategories = 'Catégories';
  static const String budgetMonthly = 'SUIVI MENSUEL';
  static const String budgetExceeded = 'Budget dépassé';

  // ============================================
  // ÉPARGNE
  // ============================================
  static const String savingsTitle = 'Enveloppe';
  static const String savingsTotal = 'TOTAL ÉPARGNÉ';
  static const String savingsGoals = 'Objectifs d\'enveloppe';
  static const String savingsProgrammed = 'Enveloppe programmée';
  static const String savingsAdd = 'Nouvel objectif';
  static const String savingsName = 'Nom de l\'objectif *';
  static const String savingsNameHint = 'ex : Rentrée scolaire';
  static const String savingsAmount = 'Montant à atteindre *';
  static const String savingsAmountHint = '100 000';
  static const String savingsDeadline = 'Date limite (optionnel)';
  static const String savingsWallet = 'Portefeuille dédié *';
  static const String savingsCreate = 'Créer mon objectif';
  static const String savingsEmpty = 'Commencez à épargner';
  static const String savingsEmptyHint =
      'Créez un objectif ou une épargne programmée pour atteindre vos projets plus vite';

  // ============================================
  // DETTES
  // ============================================
  static const String debtTitle = 'Mes dettes';
  static const String debtAdd = 'Ajouter une dette';
  static const String debtTotal = 'Solde net';
  static const String debtFilterAll = 'Toutes';
  static const String debtFilterDebts = 'Dettes';
  static const String debtFilterCredits = 'Créances';
  static const String debtEmpty = 'Aucune dette enregistrée';
  static const String debtEmptyHint =
      'Ajoutez vos dettes et créances pour suivre vos remboursements facilement.';
  static const String debtPaid = 'Soldé';
  static const String debtPending = 'En attente';
  static const String debtRepay = 'Rembourser';
  static const String debtDelete = 'Supprimer';

  // ============================================
  // PROFIL
  // ============================================
  static const String profileTitle = 'Profil';
  static const String profileAccount = 'MON COMPTE';
  static const String profileSupport = 'SUPPORT';
  static const String profileSession = 'SESSION';
  static const String profileDanger = 'DANGER';
  static const String profileMyWallets = 'Mes portefeuilles';
  static const String profileMyCategories = 'Mes catégories';
  static const String profileMyName = 'Mon prénom';
  static const String profileMyCurrency = 'Ma monnaie';
  static const String profileScore = 'Mon Score TAPA';
  static const String profileGuide = "Guide d'utilisation";
  static const String profileReports = 'Rapports financiers PDF';
  static const String profileAnalyse = 'Analyse financière';
  static const String profileSupportContact = 'Contacter le support';
  static const String profileLogout = 'Se déconnecter';
  static const String profileLogoutSubtitle =
      'Tes données restent sauvegardées';
  static const String profileReset = 'Réinitialiser mon compte';
  static const String profileResetSubtitle =
      'Efface toutes les données définitivement';
  static const String profilePremium = 'Accès à vie';
  static const String profilePremiumSubtitle = '5 000 FCFA - Paiement unique';
  static const String profilePremiumActive = '✅ Accès à vie activé';
  static const String profileRoot = '👑 Accès Root (Admin)';
  static const String profileRootSubtitle = 'Accès illimité - Mode développeur';

  // ============================================
  // RAPPORTS
  // ============================================
  static const String reportTitle = 'Rapports financiers';
  static const String reportDaily = 'Rapport journalier';
  static const String reportWeekly = 'Rapport hebdomadaire';
  static const String reportMonthly = 'Rapport mensuel';
  static const String reportPreviousMonth = 'Rapport mois précédent';
  static const String reportGenerate = 'Générer';
  static const String reportShare = 'Partager';

  // ============================================
  // SCORE TAPA
  // ============================================
  static const String scoreTitle = 'Score TAPA';
  static const String scoreLevels = 'Niveaux';
  static const String scoreExcellent = 'Excellent';
  static const String scoreGood = 'Bon';
  static const String scoreAverage = 'Moyen';
  static const String scoreLow = 'Faible';
  static const String scoreInsufficient = 'Insuffisant';
  static const String scoreCriteria = 'DÉTAIL PAR CRITÈRE';
  static const String scoreStrengths = 'VOS POINTS FORTS';
  static const String scoreTips = 'COMMENT AMÉLIORER VOTRE SCORE';
  static const String scoreExport = 'Exporter mon Score PDF';
  static const String scoreExportSubtitle =
      'Partagez ce document avec votre banque ou microfinance.';

  // ============================================
  // COACH IA
  // ============================================
  static const String coachTitle = 'TAPA Coach';
  static const String coachSubtitle = 'Coach financier personnel';
  static const String coachWelcome =
      'Bonjour {name} ! 👋\n\nJe suis TAPA Coach, votre assistant financier personnel.';
  static const String coachPlaceholder = 'Posez votre question...';
  static const String coachThinking = 'TAPA Coach réfléchit...';
  static const String coachSuggestion1 = '💰 Comment épargner ?';
  static const String coachSuggestion2 = '📊 Analyser mon budget';
  static const String coachSuggestion3 = '🛡️ Assurance vie';
  static const String coachSuggestion4 = '📈 Investir en BRVM';
  static const String coachSuggestion5 = '🧠 Mindset financier';
  static const String coachSuggestion6 = '💳 Gérer mes dettes';

  // ============================================
  // ÉCHÉANCES
  // ============================================
  static const String echeanceTitle = 'Mes échéances';
  static const String echeanceAdd = 'Nouvelle échéance';
  static const String echeanceTitleLabel = 'Titre de l\'échéance';
  static const String echeanceTitleHint =
      'Ex: Scolarité enfants, Loyer, CIE...';
  static const String echeanceAmount = 'Montant';
  static const String echeanceAmountHint = 'Ex: 100000';
  static const String echeanceDate = 'Date de l\'échéance';
  static const String echeanceFrequency = 'Fréquence';
  static const String echeanceFrequencyOnce = 'Une seule fois';
  static const String echeanceFrequencyMonthly = 'Tous les mois';
  static const String echeanceFrequencyWeekly = 'Chaque semaine';
  static const String echeanceReminder = 'Me rappeler';
  static const String echeanceSave = 'Enregistrer l\'échéance';
  static const String echeanceEmpty = 'Aucune échéance';
  static const String echeanceEmptyHint =
      'Ajoutez vos échéances pour recevoir des rappels automatiques.';

  // ============================================
  // INVESTISSEMENT
  // ============================================
  static const String investTitle = 'Investir & Protéger';
  static const String investSubtitle = 'Faites fructifier votre argent';
  static const String investFCP = 'Fonds Communs de Placement';
  static const String investFCPSubtitle =
      'Faites fructifier votre épargne avec nos partenaires SGO agréés';
  static const String investAssurance = 'Assurance Vie';
  static const String investAssuranceSubtitle =
      'Protégez votre famille et construisez votre avenir sereinement';
  static const String investWhy = 'Pourquoi investir avec TAPA ?';
  static const String investSecurity = '🔒 Sécurité';
  static const String investSecuritySub = 'Partenaires agréés et certifiés';
  static const String investProfit = '💰 Rentabilité';
  static const String investProfitSub = 'Rendements attractifs sur le marché';
  static const String investSimple = '📱 Simplicité';
  static const String investSimpleSub = 'Tout se fait depuis votre téléphone';
  static const String investSupport = '🤝 Accompagnement';
  static const String investSupportSub = 'Support 7j/7 sur WhatsApp';

  // ============================================
  // ASSURANCE
  // ============================================
  static const String assuranceTitle = 'Assurances';
  static const String assuranceLife = 'Assurance Vie';
  static const String assuranceAuto = 'Assurance Auto';
  static const String assurancePartenaire = 'SONAM VIE';
  static const String assurancePartenaireAuto = 'SONAM AUTO';
  static const String assurancePartenaireSub =
      'Partenaire assurance de TAPA Invest';
  static const String assuranceDevis = 'Obtenir un devis';

  // ============================================
  // GUIDE
  // ============================================
  static const String guideTitle = "Guide d'utilisation";
  static const String guideSubtitle =
      'Apprenez à utiliser TAPA Invest efficacement';
  static const String guideDownload = 'Télécharger le guide PDF';
  static const String guideSection1 = 'Bienvenue dans TAPA Invest';
  static const String guideSection2 =
      'PREMIÈRE ÉTAPE : Configurez vos portefeuilles';
  static const String guideSection3 = 'DEUXIÈME ÉTAPE : Créez vos catégories';
  static const String guideSection4 = 'Ajouter une transaction';
  static const String guideSection5 = 'Scanner un reçu';
  static const String guideSection6 = 'Dictée vocale';
  static const String guideSection7 = 'Budget Prévisionnel';
  static const String guideSection8 = 'Gestion des Dettes';
  static const String guideSection9 = 'Rapports PDF';
  static const String guideSection10 = 'Score TAPA';
  static const String guideSection11 = 'Conseils pour bien démarrer';

  // ============================================
  // ERREURS ET CHARGEMENT
  // ============================================
  static const String errorTitle = 'Erreur';
  static const String errorTryAgain = 'Réessayer';
  static const String errorCancel = 'Annuler';
  static const String errorConfirm = 'Confirmer';
  static const String loading = 'Chargement...';
  static const String loadingPleaseWait = 'Veuillez patienter...';

  // ============================================
  // ACTIONS GÉNÉRALES
  // ============================================
  static const String actionSave = 'Enregistrer';
  static const String actionCancel = 'Annuler';
  static const String actionConfirm = 'Confirmer';
  static const String actionDelete = 'Supprimer';
  static const String actionEdit = 'Modifier';
  static const String actionAdd = 'Ajouter';
  static const String actionClose = 'Fermer';
  static const String actionBack = 'Retour';
  static const String actionNext = 'Suivant';
  static const String actionDone = 'Terminé';
  static const String actionSkip = 'Passer';
  static const String actionRetry = 'Réessayer';
  static const String actionCopy = 'Copier';
  static const String actionShare = 'Partager';
  static const String actionDownload = 'Télécharger';

  // ============================================
  // JOURS ET MOIS
  // ============================================
  static const List<String> months = [
    '',
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  static const List<String> monthsShort = [
    '',
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc'
  ];

  static const List<String> days = [
    '',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  static const List<String> daysShort = [
    '',
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim'
  ];
}
