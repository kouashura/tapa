// lib/services/db_service_mysql.dart

import 'firebase_service.dart';
import '../models/models.dart';
import '../models/budget_model.dart';
import '../models/echeance_model.dart';
import '../models/epargne_programmee_model.dart';
import '../core/utils/logger.dart';

class DBService {
  static final FirebaseService _firebase = FirebaseService();
  static DBService? _instance;

  factory DBService() {
    _instance ??= DBService._internal();
    return _instance!;
  }

  DBService._internal();

  // ============================================
  // UTILISATEUR
  // ============================================

  Map<String, dynamic>? getUser() => _firebase.getUser();
  Future<void> saveUser(UserModel user) async => await _firebase.saveUser(user);
  Future<void> savePin(String pin) async => await _firebase.savePin(pin);
  bool verifyPin(String pin) => _firebase.verifyPin(pin);
  String? getCurrentUserId() => _firebase.getCurrentUserId();
  bool get isLoggedIn => _firebase.isLoggedIn;

  // ============================================
  // TRANSACTIONS
  // ============================================

  List<TransactionModel> getTransactions() => _firebase.getTransactions();
  Future<void> addTransaction(TransactionModel transaction) async => await _firebase.addTransaction(transaction);
  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async => await _firebase.updateTransaction(oldTx, newTx);
  Future<void> deleteTransaction(TransactionModel transaction) async => await _firebase.deleteTransaction(transaction);

  // ============================================
  // PORTEFEUILLES
  // ============================================

  List<WalletModel> getWallets() => _firebase.getWallets();
  Future<void> saveWallet(WalletModel wallet) async => await _firebase.saveWallet(wallet);

  // ============================================
  // CATÉGORIES
  // ============================================

  List<Map<String, dynamic>> getCategories() => _firebase.getCategories();

  Future<void> addCategory(Map<String, dynamic> category) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final categoryWithUser = {
        ...category,
        'uid': userId,
      };

      await _firebase.addCategory(categoryWithUser);
      Logger.info('✅ Catégorie ajoutée: ${category['label']}');
    } catch (e) {
      Logger.error('❌ Erreur addCategory: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async => await _firebase.deleteCategory(categoryId);

  // ============================================
  // ÉCHÉANCES
  // ============================================

  List<EcheanceModel> getEcheances() => _firebase.getEcheances();
  Future<void> saveEcheance(EcheanceModel echeance) async => await _firebase.saveEcheance(echeance);
  Future<void> supprimerEcheance(String id) async => await _firebase.supprimerEcheance(id);

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  List<EpargneProgrammeeModel> getEpargnesProgrammees() => _firebase.getEpargnesProgrammees();
  Future<void> saveEpargneProgrammee(EpargneProgrammeeModel epargne) async => await _firebase.saveEpargneProgrammee(epargne);
  Future<void> supprimerEpargneProgrammee(String id) async => await _firebase.supprimerEpargneProgrammee(id);
  Future<void> effectuerDepotEpargne(EpargneProgrammeeModel epargne) async => await _firebase.effectuerDepotEpargne(epargne);

  // ============================================
  // OBJECTIFS ÉPARGNE
  // ============================================

  List<SavingsGoalModel> getSavingsGoals() => _firebase.getSavingsGoals();
  Future<void> addSavingsGoal(SavingsGoalModel goal) async => await _firebase.addSavingsGoal(goal);

  // ============================================
  // DETTES
  // ============================================

  List<DetteModel> getDettes() => _firebase.getDettes();

  // ============================================
  // BUDGET
  // ============================================

  Future<BudgetMensuel?> getBudget(int mois, int annee) async => await _firebase.getBudget(mois, annee);
  Future<double> getTotalDepensesReelles(int mois, int annee) async => await _firebase.getTotalDepensesReelles(mois, annee);
  Future<double> getTotalRevenusReels(int mois, int annee) async => await _firebase.getTotalRevenusReels(mois, annee);
  Future<double> getDepensesReellesByCategorie(String categorieId, int mois, int annee) async => await _firebase.getDepensesReellesByCategorie(categorieId, mois, annee);
  Future<void> saveBudget(BudgetMensuel budget) async => await _firebase.saveBudget(budget);
  Future<void> deleteBudget(int mois, int annee) async => await _firebase.deleteBudget(mois, annee);

  // ============================================
  // ONBOARDING
  // ============================================

  bool get onboardingVu => _firebase.onboardingVu;
  Future<void> marquerOnboardingVu() async => await _firebase.marquerOnboardingVu();

  // ============================================
  // NOTIFICATIONS
  // ============================================

  bool get notificationsActivees => _firebase.notificationsActivees;
  Future<void> setNotifications(bool value) async => await _firebase.setNotifications(value);

  // ============================================
  // GESTION DE L'ESSAI GRATUIT ET ACCÈS - CORRIGÉ
  // ============================================

  /// Vérifie si l'essai gratuit est expiré (version synchrone)
  bool get essaiGratuitExpire {
    return _firebase.essaiGratuitExpire;
  }

  /// Vérifie si l'essai gratuit est expiré (version asynchrone avec Firestore)
  Future<bool> isEssaiGratuitExpire() async {
    return await _firebase.isEssaiGratuitExpire();
  }

  /// Nombre de jours restants pour l'essai gratuit
  int get joursRestantsEssai {
    return _firebase.joursRestantsEssai;
  }

  /// Vérifie si l'utilisateur a l'accès à vie
  bool get aAccesAVie {
    return _firebase.aAccesAVie;
  }

  /// Vérifie si l'utilisateur a un accès root
  bool get isRootUser {
    return _firebase.isRootUser;
  }

  /// Sauvegarde la date d'inscription
  Future<void> sauvegarderDateInscription(DateTime date) async {
    await _firebase.sauvegarderDateInscription(date);
  }

  /// Active l'accès à vie avec une clé
  Future<void> activerAccesVie(String cle) async {
    await _firebase.activerAccesVie(cle);
  }

  /// Vérifie si une clé est valide (root ou standard)
  bool verifierCle(String cle) {
    return _firebase.verifierCle(cle);
  }

  // ============================================
  // STATISTIQUES
  // ============================================

  Future<Map<String, dynamic>> getStatistics() async => await _firebase.getStatistics();

  // ============================================
  // NETTOYAGE
  // ============================================

  Future<void> clearAll() async => await _firebase.clearAll();
  Future<void> clear() async => await _firebase.clear();

  // ============================================
  // AUTRES
  // ============================================

  Future<void> initDefaultWallets() async {}
  Future<void> addWallet(WalletModel wallet) async => await _firebase.saveWallet(wallet);
  Future<void> updateWallet(WalletModel wallet) async => await _firebase.saveWallet(wallet);
  Future<void> deleteWallet(String walletId) async {}
}