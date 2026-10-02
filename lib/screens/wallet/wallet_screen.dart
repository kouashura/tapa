// lib/screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/paiement_pro_service.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final TextEditingController _montantController = TextEditingController();
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
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Aucun utilisateur connecté');

      final paiementPro = PaiementProService();
      final success = await paiementPro.payerAvecPaiementPro(
        amount: montant,
        description: 'Rechargement wallet TAPA Invest',
        referenceNumber: 'WALLET-${DateTime.now().millisecondsSinceEpoch}',
        customerEmail: currentUser.email.isNotEmpty
            ? currentUser.email
            : 'client@tapa.com',
        customerFirstName: currentUser.prenom,
        customerLastname: currentUser.prenom,
        customerPhoneNumber: currentUser.phoneNumber,
        channel: 'WAVE',
        notificationURL: 'https://wallet-notify.tapa-invest.workers.dev',
        returnURL: 'tapa://wallet/success',
        returnContext: '{"userId":"${currentUser.id}"}',
      );

      if (success && mounted) {
        _showSnackBar(
          '✅ Paiement initié. Votre wallet sera crédité dès confirmation.',
          isSuccess: true,
        );
        _montantController.clear();
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    ref.watch(currentUserProvider);
    final walletState = ref.watch(walletStateProvider);

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Mon Wallet'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'Solde total',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${walletState.totalBalance.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: TAPAColors.gold,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${walletState.wallets.length} portefeuille(s)',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (walletState.isLoading)
              const Center(
                  child:
                      CircularProgressIndicator(color: TAPAColors.gold))
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TAPAColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(wallet.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.nom.isNotEmpty
                                  ? wallet.nom
                                  : 'Mon wallet',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TAPAColors.navy,
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
                );
              }),
            const SizedBox(height: 24),
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
                  'Payer avec PaiementPro',
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
          ],
        ),
      ),
    );
  }
}
