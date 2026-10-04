// lib/presentation/providers/dettes/dettes_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_debt_repository.dart';
import '../../../data/repositories/debt_repository_impl.dart';
import '../../../domain/usecases/dettes/get_dettes_usecase.dart';
import '../../../domain/usecases/dettes/watch_dettes_usecase.dart';
import '../../../domain/usecases/dettes/create_dette_usecase.dart';
import '../../../domain/usecases/dettes/update_dette_usecase.dart';
import '../../../domain/usecases/dettes/delete_dette_usecase.dart';
import '../../../domain/usecases/dettes/rembourser_dette_usecase.dart';
import '../app_state.dart';
import '../../../core/utils/logger.dart';

// ============================================
// PROVIDERS REPOSITORY & USE CASES
// ============================================

final debtRepositoryProvider = Provider<IDebtRepository>((ref) {
  return DebtRepositoryImpl();
});

final getDettesUseCaseProvider = Provider<GetDettesUseCase>((ref) {
  return GetDettesUseCase(ref.watch(debtRepositoryProvider));
});

final watchDettesUseCaseProvider = Provider<WatchDettesUseCase>((ref) {
  return WatchDettesUseCase(ref.watch(debtRepositoryProvider));
});

final createDetteUseCaseProvider = Provider<CreateDetteUseCase>((ref) {
  return CreateDetteUseCase(ref.watch(debtRepositoryProvider));
});

final updateDetteUseCaseProvider = Provider<UpdateDetteUseCase>((ref) {
  return UpdateDetteUseCase(ref.watch(debtRepositoryProvider));
});

final deleteDetteUseCaseProvider = Provider<DeleteDetteUseCase>((ref) {
  return DeleteDetteUseCase(ref.watch(debtRepositoryProvider));
});

final rembourserDetteUseCaseProvider = Provider<RembourserDetteUseCase>((ref) {
  return RembourserDetteUseCase(ref.watch(debtRepositoryProvider));
});

// ============================================
// STREAM PROVIDERS (Temps reel)
// ============================================

final dettesListProvider = StreamProvider.family<List<DetteModel>, String>(
  (ref, uid) {
    final useCase = ref.watch(watchDettesUseCaseProvider);
    return useCase.execute(uid);
  },
);

// ============================================
// FUTURE PROVIDERS (Actions)
// ============================================

final getDettesProvider = FutureProvider.family<GetDettesResult, String>(
  (ref, uid) async {
    final useCase = ref.watch(getDettesUseCaseProvider);
    return await useCase.execute(uid);
  },
);

final createDetteProvider =
    FutureProvider.family<CreateDetteResult, CreateDetteParams>(
  (ref, params) async {
    final useCase = ref.watch(createDetteUseCaseProvider);
    final result = await useCase.execute(params);

    if (result.success && result.dette != null) {
      Logger.success('Dette creee: ${result.dette!.id}');
      ref.read(dettesStateProvider.notifier).addDetteLocally(result.dette!);
    } else {
      Logger.error('Erreur creation dette: ${result.message}');
    }

    return result;
  },
);

final updateDetteProvider =
    FutureProvider.family<UpdateDetteResult, DetteModel>(
  (ref, dette) async {
    final useCase = ref.watch(updateDetteUseCaseProvider);
    final result = await useCase.execute(dette);

    if (result.success && result.dette != null) {
      Logger.success('Dette mise a jour: ${result.dette!.id}');
      ref.read(dettesStateProvider.notifier).updateDetteLocally(result.dette!);
    } else {
      Logger.error('Erreur mise a jour dette: ${result.message}');
    }

    return result;
  },
);

final deleteDetteProvider =
    FutureProvider.family<DeleteDetteResult, String>((ref, detteId) async {
  final useCase = ref.watch(deleteDetteUseCaseProvider);
  final result = await useCase.execute(detteId);

  if (result.success) {
    Logger.success('Dette supprimee: $detteId');
    ref.read(dettesStateProvider.notifier).deleteDetteLocally(detteId);
  } else {
    Logger.error('Erreur suppression dette: ${result.message}');
  }

  return result;
});

final rembourserDetteProvider =
    FutureProvider.family<RembourserDetteResult, RembourserDetteParams>(
  (ref, params) async {
    final useCase = ref.watch(rembourserDetteUseCaseProvider);
    final result = await useCase.execute(params);

    if (result.success && result.remboursement != null) {
      Logger.success('Remboursement: ${result.remboursement!.montant}');
      final uid = ref.read(appStateProvider).currentUser?.id ?? '';
      ref.read(dettesStateProvider.notifier).loadDettes(uid);
    } else {
      Logger.error('Erreur remboursement: ${result.message}');
    }

    return result;
  },
);

// ============================================
// NOTIFIER PROVIDER (Etat local des dettes)
// ============================================

final dettesStateProvider =
    StateNotifierProvider<DettesNotifier, DettesState>((ref) {
  return DettesNotifier(ref);
});

class DettesState {
  final List<DetteModel> dettes;
  final bool isLoading;
  final String? error;
  final double totalDettes;
  final double totalCreances;
  final double totalRestant;

  const DettesState({
    this.dettes = const [],
    this.isLoading = false,
    this.error,
    this.totalDettes = 0,
    this.totalCreances = 0,
    this.totalRestant = 0,
  });

  DettesState copyWith({
    List<DetteModel>? dettes,
    bool? isLoading,
    String? error,
    double? totalDettes,
    double? totalCreances,
    double? totalRestant,
  }) {
    return DettesState(
      dettes: dettes ?? this.dettes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalDettes: totalDettes ?? this.totalDettes,
      totalCreances: totalCreances ?? this.totalCreances,
      totalRestant: totalRestant ?? this.totalRestant,
    );
  }

  List<DetteModel> get dettesOnly =>
      dettes.where((d) => d.type == 'dette').toList();

  List<DetteModel> get creancesOnly =>
      dettes.where((d) => d.type == 'creance').toList();

  List<DetteModel> get dettesSoldees =>
      dettes.where((d) => d.estSolde).toList();

  List<DetteModel> get dettesEnCours =>
      dettes.where((d) => !d.estSolde).toList();
}

class DettesNotifier extends StateNotifier<DettesState> {
  final Ref _ref;

  DettesNotifier(this._ref) : super(const DettesState());

  Future<void> loadDettes(String uid) async {
    if (uid.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _ref.read(getDettesProvider(uid).future);

      if (result.success) {
        state = DettesState(
          dettes: result.dettes,
          totalDettes: result.totalDettes,
          totalCreances: result.totalCreances,
          totalRestant: result.totalRestant,
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

  void addDetteLocally(DetteModel dette) {
    final updatedDettes = [...state.dettes, dette];
    _recalculerTotaux(updatedDettes);
  }

  void updateDetteLocally(DetteModel updatedDette) {
    final updatedDettes = state.dettes.map((d) {
      return d.id == updatedDette.id ? updatedDette : d;
    }).toList();
    _recalculerTotaux(updatedDettes);
  }

  void deleteDetteLocally(String detteId) {
    final updatedDettes =
        state.dettes.where((d) => d.id != detteId).toList();
    _recalculerTotaux(updatedDettes);
  }

  void _recalculerTotaux(List<DetteModel> dettes) {
    double totalDettes = 0;
    double totalCreances = 0;
    double totalRestant = 0;

    for (final d in dettes) {
      if (d.type == 'dette') {
        totalDettes += d.montantRestant;
      } else {
        totalCreances += d.montantRestant;
      }
      totalRestant += d.montantRestant;
    }

    state = state.copyWith(
      dettes: dettes,
      totalDettes: totalDettes,
      totalCreances: totalCreances,
      totalRestant: totalRestant,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const DettesState();
  }
}

// ============================================
// PROVIDERS UTILITAIRES
// ============================================

final soldeNetDettesProvider = Provider<double>((ref) {
  final state = ref.watch(dettesStateProvider);
  return state.totalCreances - state.totalDettes;
});

final nombreDettesProvider = Provider<int>((ref) {
  final state = ref.watch(dettesStateProvider);
  return state.dettes.length;
});

final dettesEnCoursProvider = Provider<List<DetteModel>>((ref) {
  return ref.watch(dettesStateProvider).dettesEnCours;
});

final dettesSoldeesProvider = Provider<List<DetteModel>>((ref) {
  return ref.watch(dettesStateProvider).dettesSoldees;
});

final detteByIdProvider = Provider.family<DetteModel?, String>((ref, detteId) {
  final state = ref.watch(dettesStateProvider);
  try {
    return state.dettes.firstWhere((d) => d.id == detteId);
  } catch (e) {
    return null;
  }
});
