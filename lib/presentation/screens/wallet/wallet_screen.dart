// lib/presentation/screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/paiement_pro_service.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import 'package:tapa_budget/presentation/providers/payment_wallet_provider.dart';
import '../../../data/models/models.dart'; // Pour WalletModel

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _montantController = TextEditingController();
  WalletModel? _selectedWallet; // ✅ Portefeuille sélectionné
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(walletStateProvider.notifier).loadWallets(user.id);
      }
    });
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _ajouterFonds() async {
    // ✅ 1. Vérifier que l'utilisateur et son téléphone sont présents
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showSnackBar('Utilisateur non connecté');
      return;
    }

    // ✅ 2. Vérifier le portefeuille sélectionné
    if (_selectedWallet == null) {
      _showSnackBar('Sélectionnez un portefeuille');
      return;
    }

    // ✅ 3. Vérifier le montant
    final montantText = _montantController.text.trim();
    if (montantText.isEmpty) {
      _showSnackBar('Saisissez un montant');
      return;
    }

    final montant = int.tryParse(montantText);
    if (montant == null || montant < 500) {
      _showSnackBar('Montant minimum: 500 FCFA');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paiementPro = PaiementProService();
      final success = await paiementPro.payerAvecPaiementPro(
        amount: montant,
        description: 'Rechargement wallet ${_selectedWallet!.nom}',
        referenceNumber: 'WALLET-${DateTime.now().millisecondsSinceEpoch}',
        customerEmail: currentUser.email.isNotEmpty
            ? currentUser.email
            : 'client@tapa.com',
        customerFirstName: currentUser.prenom,
        customerLastname: currentUser.prenom,
        // ✅ Si le profil n'a pas de numéro, on met un placeholder.
        // L'utilisateur saisira son vrai numéro sur la page PaiementPro.
        customerPhoneNumber: currentUser.phoneNumber.trim().isNotEmpty
            ? currentUser.phoneNumber
            : '+2250700000000',
        channel: 'WAVE',
        notificationURL: 'https://wallet-notify.tapa-invest.workers.dev',
        returnURL: 'tapa://wallet/success',
        // ✅ On passe l'ID du portefeuille ET le montant pour que le webhook sache quoi créditer
        returnContext:
            '{"userId":"${currentUser.id}", "walletId":"${_selectedWallet!.id}", "amount":$montant}',
      );

      if (success && mounted) {
        // ✅ OPTIMISTE : On met à jour le solde immédiatement pour l'utilisateur
        // (Le webhook fera la vraie mise à jour Firestore en arrière-plan)
        // ✅ On invalide le provider pour forcer le rechargement depuis Firestore
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(walletListProvider(currentUser.id));
        }
        _showSnackBar(
          '✅ Paiement initié. Votre wallet sera crédité.',
          isSuccess: true,
        );
        _montantController.clear();

        // ✅ Redirection vers l'accueil après un court délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/home');
        });
      } else if (mounted) {
        // ✅ Gestion d'erreur : le paiement n'a pas pu être lancé
        _showSnackBar(
          '❌ Impossible d\'ouvrir la page de paiement. Vérifiez votre connexion.',
        );
      }
    } catch (e) {
      // Afficher le message exact (ex: "Erreur ouverture navigateur: ...")
      _showSnackBar('❌ ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MÉTHODE RETIRER DES FONDS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _retirerFonds() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showSnackBar('Utilisateur non connecté');
      return;
    }

    final montantCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: currentUser.phoneNumber);
    String operator = 'WAVE';
    bool isLoading = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Retirer des fonds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                    hintText: 'Ex: 5000',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro (+225XXXXXXXXXX)',
                    hintText: '+2250700000000',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: operator,
                  decoration: const InputDecoration(labelText: 'Opérateur'),
                  items: const [
                    DropdownMenuItem(value: 'WAVE', child: Text('Wave')),
                    DropdownMenuItem(
                        value: 'ORANGE', child: Text('Orange Money')),
                    DropdownMenuItem(value: 'MTN', child: Text('MTN MoMo')),
                    DropdownMenuItem(value: 'MOOV', child: Text('Moov Flooz')),
                  ],
                  onChanged: (v) => setDialogState(() => operator = v!),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Frais de retrait : 1,5% + 100 FCFA (Wave) ou 250 FCFA (Orange/MTN/Moov)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final montant = int.tryParse(montantCtrl.text) ?? 0;
                      if (montant < 500) {
                        _showSnackBar('Montant minimum : 500 FCFA');
                        return;
                      }
                      if (!phoneCtrl.text.startsWith('+225')) {
                        _showSnackBar('Format : +225XXXXXXXXXX');
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final response = await http
                            .post(
                              Uri.parse(
                                  'https://tapa-budget-server.onrender.com/api/withdraw'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'userId': currentUser.id,
                                'amount': montant,
                                'phone': phoneCtrl.text,
                                'operator': operator,
                              }),
                            )
                            .timeout(const Duration(seconds: 90));

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          Navigator.pop(ctx, data);
                        } else {
                          final data = jsonDecode(response.body);
                          _showSnackBar(data['error'] ?? 'Erreur serveur');
                        }
                      } on TimeoutException {
                        _showSnackBar(
                            'Le serveur met du temps à répondre. Veuillez patienter et réessayer.');
                      } catch (e) {
                        _showSnackBar('Erreur réseau: $e');
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      _showSnackBar(
        '✅ Demande enregistrée. Traitement sous 48h maximum.',
        isSuccess: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : TAPAColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final walletState = ref.watch(walletStateProvider);
    final walletBalanceAsync = ref.watch(userWalletBalanceProvider(userId));

    // Mettre à jour la sélection par défaut si la liste change
    if (_selectedWallet == null && walletState.wallets.isNotEmpty) {
      _selectedWallet = walletState.wallets.first;
    }

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mon Wallet'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/home'), // ✅ Retour à l'accueil
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé du solde
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D1444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solde disponible ',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // ✅ Affichage du solde RÉEL depuis user_wallet
                  walletBalanceAsync.when(
                    loading: () => const SizedBox(
                      height: 38,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: TAPAColors.gold, strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Erreur: $err',
                      style:
                          const TextStyle(color: TAPAColors.red, fontSize: 12),
                    ),
                    data: (solde) => Text(
                      '${solde.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: TAPAColors.gold,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Utilisable pour vos paiements',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Liste des portefeuilles
            if (walletState.isLoading)
              const Center(
                  child: CircularProgressIndicator(color: TAPAColors.gold))
            else if (walletState.wallets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Aucun portefeuille.\nAjoutez des fonds pour créer votre premier wallet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...walletState.wallets.map((wallet) {
                final isSelected = _selectedWallet?.id == wallet.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedWallet = wallet),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TAPAColors.navy.withOpacity(0.05)
                          : TAPAColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected ? TAPAColors.navy : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(wallet.emoji,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.nom.isNotEmpty
                                    ? wallet.nom
                                    : 'Mon wallet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? TAPAColors.navy
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                wallet.description.isNotEmpty
                                    ? wallet.description
                                    : wallet.type,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${wallet.solde.toStringAsFixed(0)} ${wallet.monnaie}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: TAPAColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Section Ajout de fonds
            const Text(
              'Ajouter des fonds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TAPAColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: 'Ex: 5000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: TAPAColors.surface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Montant minimum: 500 FCFA',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // ✅ Carte d'information sur les frais et le partenariat
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: TAPAColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TAPAColors.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: TAPAColors.navy.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icône de sécurité
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TAPAColors.navy.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_person_rounded,
                        color: TAPAColors.navy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Textes
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frais de transaction : 1%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.navy,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'En partenariat sécurisé avec PaiementPro',
                          style: TextStyle(
                            fontSize: 11,
                            color: TAPAColors.textSecond,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge "Sécurisé"
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: TAPAColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user,
                            size: 12, color: TAPAColors.green),
                        SizedBox(width: 4),
                        Text(
                          'Sécurisé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: TAPAColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _ajouterFonds,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: TAPAColors.navy,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: const Text(
                  'Payer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAPAColors.gold,
                  foregroundColor: TAPAColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Bouton Retirer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _retirerFonds,
                icon: const Icon(Icons.money_off_csred_rounded),
                label: const Text(
                  'Retirer des fonds',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TAPAColors.navy,
                  side: const BorderSide(color: TAPAColors.navy, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
