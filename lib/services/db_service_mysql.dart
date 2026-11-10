// lib/services/db_service_mysql.dart

import 'firebase_service.dart';
import '../data/models/models.dart';
import '../core/utils/logger.dart';
import 'pin_security.dart';

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

  Future<bool> verifyPin(String pin) async {
    final result = await _firebase.verifyPin(pin);
    return result.success;
  }

  Future<PinCheckResult> verifyPinDetailed(String pin) async {
    return await _firebase.verifyPin(pin);
  }

  String? getCurrentUserId() => _firebase.getCurrentUserId();
  bool get isLoggedIn => _firebase.isLoggedIn;
  Future<bool> hasPin() async => await _firebase.hasPin();

  // ============================================
  // TRANSACTIONS
  // ============================================

  Future<List<TransactionModel>> getTransactions() async =>
      await _firebase.getTransactions();
  Future<void> addTransaction(TransactionModel transaction) async =>
      await _firebase.addTransaction(transaction);
  Future<void> updateTransaction(
          TransactionModel oldTx, TransactionModel newTx) async =>
      await _firebase.updateTransaction(oldTx, newTx);
  Future<void> deleteTransaction(TransactionModel transaction) async =>
      await _firebase.deleteTransaction(transaction);

  // ============================================
  // PORTEFEUILLES
  // ============================================

  Future<List<WalletModel>> getWallets() async => await _firebase.getWallets();
  Future<void> saveWallet(WalletModel wallet) async =>
      await _firebase.saveWallet(wallet);

  // ============================================
  // CATÉGORIES
  // ============================================

  List<Map<String, dynamic>> getCategories() => _firebase.getCategories();

  /// ✅ NOUVELLE MÉTHODE : Recharge les catégories depuis Firestore
  Future<List<Map<String, dynamic>>> reloadCategoriesFromFirestore() =>
      _firebase.reloadCategoriesFromFirestore();

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

  Future<void> deleteCategory(String categoryId) async =>
      await _firebase.deleteCategory(categoryId);

  // ============================================
  // ÉCHÉANCES
  // ============================================

  List<EcheanceModel> getEcheances() => _firebase.getEcheances();
  Future<void> saveEcheance(EcheanceModel echeance) async =>
      await _firebase.saveEcheance(echeance);
  Future<void> supprimerEcheance(String id) async =>
      await _firebase.supprimerEcheance(id);

  // ============================================
  // ÉPARGNE PROGRAMMÉE
  // ============================================

  List<EpargneProgrammeeModel> getEpargnesProgrammees() =>
      _firebase.getEpargnesProgrammees();
  Future<void> saveEpargneProgrammee(EpargneProgrammeeModel epargne) async =>
      await _firebase.saveEpargneProgrammee(epargne);
  Future<void> supprimerEpargneProgrammee(String id) async =>
      await _firebase.supprimerEpargneProgrammee(id);
  Future<void> effectuerDepotEpargne(EpargneProgrammeeModel epargne) async =>
      await _firebase.effectuerDepotEpargne(epargne);

  // ============================================
  // OBJECTIFS ÉPARGNE
  // ============================================

  List<SavingsGoalModel> getSavingsGoals() => _firebase.getSavingsGoals();
  Future<void> addSavingsGoal(SavingsGoalModel goal) async =>
      await _firebase.addSavingsGoal(goal);

  // ============================================
  // DETTES
  // ============================================

  List<DetteModel> getDettes() => _firebase.getDettes();

  // ============================================
  // BUDGET
  // ============================================

  Future<BudgetMensuel?> getBudget(int mois, int annee) async =>
      await _firebase.getBudget(mois, annee);
  Future<double> getTotalDepensesReelles(int mois, int annee) async =>
      await _firebase.getTotalDepensesReelles(mois, annee);
  Future<double> getTotalRevenusReels(int mois, int annee) async =>
      await _firebase.getTotalRevenusReels(mois, annee);
  Future<double> getDepensesReellesByCategorie(
          String categorieId, int mois, int annee) async =>
      await _firebase.getDepensesReellesByCategorie(categorieId, mois, annee);
  Future<void> saveBudget(BudgetMensuel budget) async =>
      await _firebase.saveBudget(budget);
  Future<void> deleteBudget(int mois, int annee) async =>
      await _firebase.deleteBudget(mois, annee);

  // ============================================
  // ONBOARDING
  // ============================================

  bool get onboardingVu => _firebase.onboardingVu;
  Future<void> marquerOnboardingVu() async =>
      await _firebase.marquerOnboardingVu();

  // ============================================
  // NOTIFICATIONS
  // ============================================

  bool get notificationsActivees => _firebase.notificationsActivees;
  Future<void> setNotifications(bool value) async =>
      await _firebase.setNotifications(value);

  // ============================================
  // GESTION DE L'ESSAI GRATUIT ET ACCÈS
  // ============================================

  bool get essaiGratuitExpire => _firebase.essaiGratuitExpire;
  Future<bool> isEssaiGratuitExpire() async =>
      await _firebase.isEssaiGratuitExpire();
  int get joursRestantsEssai => _firebase.joursRestantsEssai;
  bool get aAccesAVie => _firebase.aAccesAVie;
  bool get isRootUser => _firebase.isRootUser;

  Future<void> sauvegarderDateInscription(DateTime date) async {
    await _firebase.sauvegarderDateInscription(date);
  }

  Future<void> activerAccesVie(String cle) async {
    await _firebase.activerAccesVie(cle);
  }

  bool verifierCle(String cle) => _firebase.verifierCle(cle);

  // ============================================
  // STATISTIQUES - ✅ CORRIGÉ
  // ============================================

  Future<Map<String, dynamic>> getStatistics() async =>
      await _firebase.getStatistics();

  // ============================================
  // NETTOYAGE
  // ============================================

  Future<void> clearAll() async => await _firebase.clearAll();
  Future<void> clear() async => await _firebase.clear();

  // ============================================
  // AUTRES
  // ============================================

  Future<void> initDefaultWallets() async {}
  Future<void> addWallet(WalletModel wallet) async =>
      await _firebase.saveWallet(wallet);
  Future<void> updateWallet(WalletModel wallet) async =>
      await _firebase.saveWallet(wallet);
  Future<void> deleteWallet(String walletId) async {}
}
