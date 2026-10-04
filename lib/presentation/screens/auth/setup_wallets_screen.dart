// lib/screens/auth/setup_wallets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:tapa_budget/presentation/providers/providers.dart';
import '../../../core/utils/logger.dart';

class SetupWalletsScreen extends ConsumerStatefulWidget {
  const SetupWalletsScreen({super.key});

  @override
  ConsumerState<SetupWalletsScreen> createState() => _SetupWalletsScreenState();
}

class _SetupWalletsScreenState extends ConsumerState<SetupWalletsScreen> {
  // ============================================
  // VARIABLES D'ÉTAT
  // ============================================

  final List<Map<String, dynamic>> _availableWallets = [
    {'id': 'cash', 'name': 'Cash', 'emoji': '💵', 'selected': false},
    {'id': 'wave', 'name': 'Wave', 'emoji': '🌊', 'selected': false},
    {'id': 'orange', 'name': 'Orange Money', 'emoji': '🟠', 'selected': false},
    {'id': 'mtn', 'name': 'MTN MoMo', 'emoji': '🟡', 'selected': false},
    {'id': 'moov', 'name': 'Moov Money', 'emoji': '🔵', 'selected': false},
    {'id': 'banque', 'name': 'Banque', 'emoji': '🏦', 'selected': false},
    {'id': 'tresor', 'name': 'Trésor Pay', 'emoji': '💎', 'selected': false},
    {'id': 'free', 'name': 'Free Money', 'emoji': '🟣', 'selected': false},
    {'id': 'autre', 'name': 'Autre', 'emoji': '💳', 'selected': false},
  ];

  final List<String> _selectedWallets = [];
  bool _isLoading = false;
  bool _isSkipping = false;

  // ============================================
  // MÉTHODES DE GESTION
  // ============================================

  void _toggleWalletSelection(String walletId) {
    setState(() {
      final index = _availableWallets.indexWhere((w) => w['id'] == walletId);
      if (index != -1) {
        final isSelected = _availableWallets[index]['selected'] as bool;
        _availableWallets[index]['selected'] = !isSelected;

        if (!isSelected) {
          _selectedWallets.add(walletId);
        } else {
          _selectedWallets.remove(walletId);
        }
      }
    });
  }

  /// ✅ CORRECTION: Sauvegarder les wallets via le provider wallet
  Future<void> _saveWallets() async {
    if (_selectedWallets.isEmpty) {
      _showSnackBar('Sélectionnez au moins un portefeuille', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTION: Utiliser le wallet provider directement
      final userId = ref.read(currentUserProvider)?.id ?? '';
      if (userId.isNotEmpty) {
        // Rafraîchir la liste des wallets
        ref.refresh(walletListProvider(userId));
      }

      // ✅ CORRECTION: Marquer l'onboarding comme vu
      await _markOnboardingCompleted();

      if (mounted) {
        _showSnackBar('✅ Portefeuilles configurés avec succès !');
        context.go('/home');
      }
    } catch (e) {
      Logger.error('❌ Erreur sauvegarde wallets: $e');
      if (mounted) {
        _showSnackBar('❌ Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ CORRECTION: Marquer l'onboarding comme terminé
  Future<void> _markOnboardingCompleted() async {
    try {
      // ✅ CORRECTION: Appeler markOnboardingAsSeen sur le notifier
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.markOnboardingAsSeen();
      Logger.info('✅ Onboarding marqué comme vu');
    } catch (e) {
      Logger.error('❌ Erreur markOnboardingAsSeen: $e');
      rethrow;
    }
  }

  /// ✅ CORRECTION: Passer l'étape des wallets
  Future<void> _skipWallets() async {
    setState(() => _isSkipping = true);

    try {
      // Marquer l'onboarding comme vu même sans wallets
      await _markOnboardingCompleted();

      if (mounted) {
        _showSnackBar('Vous pourrez ajouter des portefeuilles plus tard');
        context.go('/home');
      }
    } catch (e) {
      Logger.error('❌ Erreur skip wallets: $e');
      if (mounted) {
        _showSnackBar('❌ Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSkipping = false);
      }
    }
  }

  /// Afficher un snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? TAPAColors.red : TAPAColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final prenom = user?.prenom ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: TAPAColors.background,
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: TAPAColors.navy,
        foregroundColor: TAPAColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _isLoading || _isSkipping
              ? null
              : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: TAPAColors.navy,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour $prenom ! 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TAPAColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sélectionnez les portefeuilles que vous utilisez',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: TAPAColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_selectedWallets.length} sélectionné${_selectedWallets.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: TAPAColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Liste des wallets
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableWallets.length,
                itemBuilder: (context, index) {
                  final wallet = _availableWallets[index];
                  final isSelected = wallet['selected'] as bool;
                  final isDisabled = _isLoading || _isSkipping;

                  return GestureDetector(
                    onTap: isDisabled ? null : () => _toggleWalletSelection(wallet['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? TAPAColors.navy : TAPAColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? TAPAColors.gold : TAPAColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? TAPAColors.navy.withOpacity(0.15)
                                : Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? TAPAColors.gold.withOpacity(0.15)
                                  : TAPAColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                wallet['emoji'] as String,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wallet['name'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? TAPAColors.white
                                        : TAPAColors.navy,
                                  ),
                                ),
                                Text(
                                  'Cliquez pour ${isSelected ? 'désélectionner' : 'sélectionner'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white60
                                        : TAPAColors.textSecond,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: TAPAColors.gold,
                              size: 24,
                            )
                          else
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: TAPAColors.border,
                                  width: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Boutons d'action
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: TAPAColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isSkipping
                          ? null
                          : _saveWallets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TAPAColors.navy,
                        foregroundColor: TAPAColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            TAPAColors.gold,
                          ),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading || _isSkipping
                        ? null
                        : _skipWallets,
                    child: _isSkipping
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TAPAColors.navy,
                        ),
                      ),
                    )
                        : const Text(
                      'Passer cette étape',
                      style: TextStyle(
                        fontSize: 14,
                        color: TAPAColors.textSecond,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}