// lib/presentation/providers/wallet/wallet_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_wallet_repository.dart';
import '../../../data/repositories/wallet_repository_impl.dart';
import '../../../domain/usecases/wallet/create_wallet_usecase.dart';
import '../../../domain/usecases/wallet/get_wallets_usecase.dart';
import '../../../domain/usecases/wallet/update_wallet_usecase.dart';
import '../../../domain/usecases/wallet/delete_wallet_usecase.dart';
import '../app_state.dart';
import '../../../core/utils/logger.dart';

// ============================================
// PROVIDERS REPOSITORY & USE CASES
// ============================================

/// Provider du repository des portefeuilles
final walletRepositoryProvider = Provider<IWalletRepository>((ref) {
  return WalletRepositoryImpl();
});

/// Provider du Use Case pour créer un portefeuille
final createWalletUseCaseProvider = Provider<CreateWalletUseCase>((ref) {
  return CreateWalletUseCase(ref.watch(walletRepositoryProvider));
});

/// Provider du Use Case pour récupérer les portefeuilles
final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>((ref) {
  return GetWalletsUseCase(ref.watch(walletRepositoryProvider));
});

/// Provider du Use Case pour écouter les portefeuilles
final watchWalletsUseCaseProvider = Provider<WatchWalletsUseCase>((ref) {
  return WatchWalletsUseCase(ref.watch(walletRepositoryProvider));
});

/// Provider du Use Case pour mettre à jour un portefeuille
final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>((ref) {
  return UpdateWalletUseCase(ref.watch(walletRepositoryProvider));
});

/// Provider du Use Case pour mettre à jour le solde
final updateWalletBalanceUseCaseProvider = Provider<UpdateWalletBalanceUseCase>((ref) {
  return UpdateWalletBalanceUseCase(ref.watch(walletRepositoryProvider));
});

/// Provider du Use Case pour supprimer un portefeuille
final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>((ref) {
  return DeleteWalletUseCase(ref.watch(walletRepositoryProvider));
});

// ============================================
// STREAM PROVIDERS (Temps réel)
// ============================================

/// Liste des portefeuilles en temps réel
final walletListProvider = StreamProvider.family<List<WalletModel>, String>((ref, uid) {
  final useCase = ref.watch(watchWalletsUseCaseProvider);
  return useCase.execute(uid);
});

// ============================================
// FUTURE PROVIDERS (Actions)
// ============================================

/// Provider pour créer un portefeuille
final createWalletProvider = FutureProvider.family<CreateWalletResult, CreateWalletParams>(
  (ref, params) async {
    final useCase = ref.watch(createWalletUseCaseProvider);
    final result = await useCase.execute(params);
    
    if (result.success) {
      Logger.success('✅ Portefeuille créé: ${result.wallet?.nom}');
      ref.read(walletStateProvider.notifier).addWalletLocally(result.wallet!);
    } else {
      Logger.error('❌ Erreur création portefeuille: ${result.message}');
    }
    
    return result;
  },
);

/// Provider pour récupérer les portefeuilles (une seule fois)
final getWalletsProvider = FutureProvider.family<GetWalletsResult, String>((ref, uid) async {
  final useCase = ref.watch(getWalletsUseCaseProvider);
  return await useCase.execute(uid);
});

/// Provider pour mettre à jour un portefeuille
final updateWalletProvider = FutureProvider.family<UpdateWalletResult, UpdateWalletParams>(
  (ref, params) async {
    final useCase = ref.watch(updateWalletUseCaseProvider);
    final result = await useCase.execute(params);
    
    if (result.success) {
      Logger.success('✅ Portefeuille mis à jour: ${result.wallet?.nom}');
      ref.read(walletStateProvider.notifier).updateWalletLocally(result.wallet!);
    } else {
      Logger.error('❌ Erreur mise à jour portefeuille: ${result.message}');
    }
    
    return result;
  },
);

/// Provider pour mettre à jour le solde
final updateWalletBalanceProvider = FutureProvider.family<UpdateWalletResult, UpdateBalanceParams>(
  (ref, params) async {
    final useCase = ref.watch(updateWalletBalanceUseCaseProvider);
    final result = await useCase.execute(
      walletId: params.walletId,
      newBalance: params.newBalance,
    );
    
    if (result.success) {
      Logger.success('💰 Solde mis à jour: ${params.newBalance}');
      ref.read(walletStateProvider.notifier).updateWalletLocally(result.wallet!);
    } else {
      Logger.error('❌ Erreur mise à jour solde: ${result.message}');
    }
    
    return result;
  },
);

/// Provider pour supprimer un portefeuille
final deleteWalletProvider = FutureProvider.family<DeleteWalletResult, String>((ref, walletId) async {
  final useCase = ref.watch(deleteWalletUseCaseProvider);
  final result = await useCase.execute(walletId);
  
  if (result.success) {
    Logger.success('🗑️ Portefeuille supprimé: $walletId');
    ref.read(walletStateProvider.notifier).deleteWalletLocally(walletId);
  } else {
    Logger.error('❌ Erreur suppression portefeuille: ${result.message}');
  }
  
  return result;
});

// ============================================
// NOTIFIER PROVIDER (État local des portefeuilles)
// ============================================

/// Provider pour l'état des portefeuilles
final walletStateProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref);
});

/// État des portefeuilles
class WalletState {
  final List<WalletModel> wallets;
  final bool isLoading;
  final String? error;
  final double totalBalance;

  const WalletState({
    this.wallets = const [],
    this.isLoading = false,
    this.error,
    this.totalBalance = 0,
  });

  WalletState copyWith({
    List<WalletModel>? wallets,
    bool? isLoading,
    String? error,
    double? totalBalance,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }

  double calculateTotalBalance() {
    double total = 0;
    for (final w in wallets) {
      total += w.solde;
    }
    return total;
  }
}

/// Notifier pour l'état des portefeuilles
class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;

  WalletNotifier(this._ref) : super(const WalletState());

  Future<void> loadWallets(String uid) async {
    if (uid.isEmpty) return;

    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _ref.read(getWalletsProvider(uid).future);
      
      if (result.success) {
        state = state.copyWith(
          wallets: result.wallets,
          totalBalance: result.totalBalance,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void addWalletLocally(WalletModel wallet) {
    final updatedWallets = [...state.wallets, wallet];
    double newTotal = 0;
    for (final w in updatedWallets) {
      newTotal += w.solde;
    }
    state = state.copyWith(
      wallets: updatedWallets,
      totalBalance: newTotal,
    );
  }

  void updateWalletLocally(WalletModel updatedWallet) {
    final updatedWallets = state.wallets.map((w) {
      return w.id == updatedWallet.id ? updatedWallet : w;
    }).toList();
    
    double newTotal = 0;
    for (final w in updatedWallets) {
      newTotal += w.solde;
    }
    
    state = state.copyWith(
      wallets: updatedWallets,
      totalBalance: newTotal,
    );
  }

  void deleteWalletLocally(String walletId) {
    final updatedWallets = state.wallets.where((w) => w.id != walletId).toList();
    
    double newTotal = 0;
    for (final w in updatedWallets) {
      newTotal += w.solde;
    }
    
    state = state.copyWith(
      wallets: updatedWallets,
      totalBalance: newTotal,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const WalletState();
  }
}

// ============================================
// PARAMÈTRES
// ============================================

class UpdateBalanceParams {
  final String walletId;
  final double newBalance;

  const UpdateBalanceParams({
    required this.walletId,
    required this.newBalance,
  });
}

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

final totalBalanceProvider = Provider<double>((ref) {
  final state = ref.watch(walletStateProvider);
  return state.totalBalance;
});

final walletCountProvider = Provider<int>((ref) {
  final state = ref.watch(walletStateProvider);
  return state.wallets.length;
});

final walletsLoadedProvider = Provider<bool>((ref) {
  final state = ref.watch(walletStateProvider);
  return !state.isLoading && state.wallets.isNotEmpty;
});

final walletByIdProvider = Provider.family<WalletModel?, String>((ref, walletId) {
  final state = ref.watch(walletStateProvider);
  try {
    return state.wallets.firstWhere((w) => w.id == walletId);
  } catch (e) {
    return null;
  }
});
