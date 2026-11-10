// lib/presentation/providers/echeances/echeances_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_echeance_repository.dart';
import '../../../data/repositories/echeance_repository_impl.dart';
import '../../../domain/usecases/echeances/get_echeances_usecase.dart';
import '../../../domain/usecases/echeances/watch_echeances_usecase.dart';
import '../../../domain/usecases/echeances/create_echeance_usecase.dart';
import '../../../domain/usecases/echeances/update_echeance_usecase.dart';
import '../../../domain/usecases/echeances/delete_echeance_usecase.dart';
import '../../../domain/usecases/echeances/marquer_payee_usecase.dart';
import '../app_state.dart';
import '../../../core/utils/logger.dart';

final echeanceRepositoryProvider = Provider<IEcheanceRepository>((ref) {
  return EcheanceRepositoryImpl();
});

final getEcheancesUseCaseProvider = Provider<GetEcheancesUseCase>((ref) {
  return GetEcheancesUseCase(ref.watch(echeanceRepositoryProvider));
});

final watchEcheancesUseCaseProvider = Provider<WatchEcheancesUseCase>((ref) {
  return WatchEcheancesUseCase(ref.watch(echeanceRepositoryProvider));
});

final createEcheanceUseCaseProvider = Provider<CreateEcheanceUseCase>((ref) {
  return CreateEcheanceUseCase(ref.watch(echeanceRepositoryProvider));
});

final updateEcheanceUseCaseProvider = Provider<UpdateEcheanceUseCase>((ref) {
  return UpdateEcheanceUseCase(ref.watch(echeanceRepositoryProvider));
});

final deleteEcheanceUseCaseProvider = Provider<DeleteEcheanceUseCase>((ref) {
  return DeleteEcheanceUseCase(ref.watch(echeanceRepositoryProvider));
});

final marquerPayeeUseCaseProvider = Provider<MarquerPayeeUseCase>((ref) {
  return MarquerPayeeUseCase(ref.watch(echeanceRepositoryProvider));
});

final echeancesListProvider =
    StreamProvider.family<List<EcheanceModel>, String>(
  (ref, uid) {
    final useCase = ref.watch(watchEcheancesUseCaseProvider);
    return useCase.execute(uid);
  },
);

final getEcheancesProvider = FutureProvider.family<GetEcheancesResult, String>(
  (ref, uid) async {
    final useCase = ref.watch(getEcheancesUseCaseProvider);
    return await useCase.execute(uid);
  },
);

final createEcheanceProvider =
    FutureProvider.family<CreateEcheanceResult, CreateEcheanceParams>(
  (ref, params) async {
    final useCase = ref.watch(createEcheanceUseCaseProvider);
    final result = await useCase.execute(params);

    if (result.success && result.echeance != null) {
      Logger.success('Echeance creee: ${result.echeance!.id}');
      ref
          .read(echeancesStateProvider.notifier)
          .addEcheanceLocally(result.echeance!);
    } else {
      Logger.error('Erreur creation echeance: ${result.message}');
    }

    return result;
  },
);

final updateEcheanceProvider =
    FutureProvider.family<UpdateEcheanceResult, EcheanceModel>(
  (ref, echeance) async {
    final useCase = ref.watch(updateEcheanceUseCaseProvider);
    final result = await useCase.execute(echeance);

    if (result.success && result.echeance != null) {
      Logger.success('Echeance mise a jour: ${result.echeance!.id}');
      ref
          .read(echeancesStateProvider.notifier)
          .updateEcheanceLocally(result.echeance!);
    } else {
      Logger.error('Erreur mise a jour echeance: ${result.message}');
    }

    return result;
  },
);

final deleteEcheanceProvider =
    FutureProvider.family<DeleteEcheanceResult, String>(
        (ref, echeanceId) async {
  final useCase = ref.watch(deleteEcheanceUseCaseProvider);
  final result = await useCase.execute(echeanceId);

  if (result.success) {
    Logger.success('Echeance supprimee: $echeanceId');
    ref.read(echeancesStateProvider.notifier).deleteEcheanceLocally(echeanceId);
  } else {
    Logger.error('Erreur suppression echeance: ${result.message}');
  }

  return result;
});

final marquerPayeeProvider =
    FutureProvider.family<MarquerPayeeResult, String>((ref, echeanceId) async {
  final useCase = ref.watch(marquerPayeeUseCaseProvider);
  final result = await useCase.execute(echeanceId);

  if (result.success) {
    Logger.success('Echeance marquee payee: $echeanceId');
    final uid = ref.read(appStateProvider).currentUser?.id ?? '';
    ref.read(echeancesStateProvider.notifier).loadEcheances(uid);
  } else {
    Logger.error('Erreur marquage payee: ${result.message}');
  }

  return result;
});

final echeancesStateProvider =
    StateNotifierProvider<EcheancesNotifier, EcheancesState>((ref) {
  return EcheancesNotifier(ref);
});

class EcheancesState {
  final List<EcheanceModel> echeances;
  final bool isLoading;
  final String? error;
  final int totalEnRetard;
  final double montantTotal;
  final double montantEnRetard;

  const EcheancesState({
    this.echeances = const [],
    this.isLoading = false,
    this.error,
    this.totalEnRetard = 0,
    this.montantTotal = 0,
    this.montantEnRetard = 0,
  });

  EcheancesState copyWith({
    List<EcheanceModel>? echeances,
    bool? isLoading,
    String? error,
    int? totalEnRetard,
    double? montantTotal,
    double? montantEnRetard,
  }) {
    return EcheancesState(
      echeances: echeances ?? this.echeances,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalEnRetard: totalEnRetard ?? this.totalEnRetard,
      montantTotal: montantTotal ?? this.montantTotal,
      montantEnRetard: montantEnRetard ?? this.montantEnRetard,
    );
  }

  List<EcheanceModel> get enAttente =>
      echeances.where((e) => e.statut == 'en_attente').toList();

  List<EcheanceModel> get payees =>
      echeances.where((e) => e.statut == 'payee').toList();

  List<EcheanceModel> get enRetard =>
      echeances.where((e) => e.estEnRetard).toList();

  List<EcheanceModel> get cetteSemaine {
    final now = DateTime.now();
    final dans7Jours = now.add(const Duration(days: 7));
    return echeances
        .where((e) =>
            e.statut != 'payee' &&
            e.dateEcheance.isAfter(now) &&
            e.dateEcheance.isBefore(dans7Jours))
        .toList();
  }
}

class EcheancesNotifier extends StateNotifier<EcheancesState> {
  final Ref _ref;

  EcheancesNotifier(this._ref) : super(const EcheancesState());

  Future<void> loadEcheances(String uid) async {
    if (uid.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _ref.read(getEcheancesProvider(uid).future);

      if (result.success) {
        state = EcheancesState(
          echeances: result.echeances,
          totalEnRetard: result.totalEnRetard,
          montantTotal: result.montantTotal,
          montantEnRetard: result.montantEnRetard,
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

  void addEcheanceLocally(EcheanceModel echeance) {
    final updated = [...state.echeances, echeance];
    _recalculerTotaux(updated);
  }

  void updateEcheanceLocally(EcheanceModel updatedEcheance) {
    final updated = state.echeances.map((e) {
      return e.id == updatedEcheance.id ? updatedEcheance : e;
    }).toList();
    _recalculerTotaux(updated);
  }

  void deleteEcheanceLocally(String echeanceId) {
    final updated = state.echeances.where((e) => e.id != echeanceId).toList();
    _recalculerTotaux(updated);
  }

  void _recalculerTotaux(List<EcheanceModel> echeances) {
    int totalEnRetard = 0;
    double montantTotal = 0;
    double montantEnRetard = 0;

    for (final e in echeances) {
      montantTotal += e.montant;
      if (e.estEnRetard) {
        totalEnRetard++;
        montantEnRetard += e.montant;
      }
    }

    state = state.copyWith(
      echeances: echeances,
      totalEnRetard: totalEnRetard,
      montantTotal: montantTotal,
      montantEnRetard: montantEnRetard,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const EcheancesState();
  }
}

final echeancesEnRetardCountProvider = Provider<int>((ref) {
  return ref.watch(echeancesStateProvider).totalEnRetard;
});

final echeancesCetteSemaineProvider = Provider<List<EcheanceModel>>((ref) {
  return ref.watch(echeancesStateProvider).cetteSemaine;
});

final echeanceByIdProvider = Provider.family<EcheanceModel?, String>((ref, id) {
  final state = ref.watch(echeancesStateProvider);
  try {
    return state.echeances.firstWhere((e) => e.id == id);
  } catch (e) {
    return null;
  }
});
