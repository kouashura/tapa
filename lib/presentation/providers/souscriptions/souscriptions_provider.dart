// lib/presentation/providers/souscriptions/souscriptions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_souscription_repository.dart';
import '../../../data/repositories/souscription_repository_impl.dart';
import '../../../domain/usecases/souscriptions/get_souscriptions_usecase.dart';
import '../app_state.dart';
import '../../../core/utils/logger.dart';

final souscriptionRepositoryProvider = Provider<ISouscriptionRepository>((ref) {
  return SouscriptionRepositoryImpl();
});

final getSouscriptionsUseCaseProvider = Provider<GetSouscriptionsUseCase>((ref) {
  return GetSouscriptionsUseCase(ref.watch(souscriptionRepositoryProvider));
});

final watchSouscriptionsUseCaseProvider = Provider<WatchSouscriptionsUseCase>((ref) {
  return WatchSouscriptionsUseCase(ref.watch(souscriptionRepositoryProvider));
});

final souscriptionsListProvider =
    StreamProvider.family<List<SouscriptionModel>, String>((ref, uid) {
  final useCase = ref.watch(watchSouscriptionsUseCaseProvider);
  return useCase.execute(uid);
});

final getSouscriptionsProvider =
    FutureProvider.family<GetSouscriptionsResult, String>((ref, uid) async {
  final useCase = ref.watch(getSouscriptionsUseCaseProvider);
  return await useCase.execute(uid);
});

final souscriptionsStateProvider =
    StateNotifierProvider<SouscriptionsNotifier, SouscriptionsState>((ref) {
  return SouscriptionsNotifier(ref);
});

class SouscriptionsState {
  final List<SouscriptionModel> souscriptions;
  final bool isLoading;
  final String? error;
  final double montantTotal;
  final int totalEnCours;
  final int totalPayees;

  const SouscriptionsState({
    this.souscriptions = const [],
    this.isLoading = false,
    this.error,
    this.montantTotal = 0,
    this.totalEnCours = 0,
    this.totalPayees = 0,
  });

  SouscriptionsState copyWith({
    List<SouscriptionModel>? souscriptions,
    bool? isLoading,
    String? error,
    double? montantTotal,
    int? totalEnCours,
    int? totalPayees,
  }) {
    return SouscriptionsState(
      souscriptions: souscriptions ?? this.souscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      montantTotal: montantTotal ?? this.montantTotal,
      totalEnCours: totalEnCours ?? this.totalEnCours,
      totalPayees: totalPayees ?? this.totalPayees,
    );
  }

  List<SouscriptionModel> get enCours =>
      souscriptions.where((s) => s.estEnCours).toList();

  List<SouscriptionModel> get payees =>
      souscriptions.where((s) => s.estPayee).toList();
}

class SouscriptionsNotifier extends StateNotifier<SouscriptionsState> {
  final Ref _ref;

  SouscriptionsNotifier(this._ref) : super(const SouscriptionsState());

  Future<void> loadSouscriptions(String uid) async {
    if (uid.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _ref.read(getSouscriptionsProvider(uid).future);

      if (result.success) {
        state = SouscriptionsState(
          souscriptions: result.souscriptions,
          montantTotal: result.montantTotal,
          totalEnCours: result.totalEnCours,
          totalPayees: result.totalPayees,
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

  void reset() {
    state = const SouscriptionsState();
  }
}

final montantTotalSouscriptionsProvider = Provider<double>((ref) {
  return ref.watch(souscriptionsStateProvider).montantTotal;
});

final nombreSouscriptionsProvider = Provider<int>((ref) {
  return ref.watch(souscriptionsStateProvider).souscriptions.length;
});
