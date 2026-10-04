// lib/presentation/providers/souscriptions/souscriptions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_souscription_repository.dart';
import '../../../data/repositories/souscription_repository_impl.dart';
import '../../../domain/usecases/souscriptions/get_souscriptions_usecase.dart';
import '../../../domain/usecases/souscriptions/admin_souscriptions_usecase.dart';
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


// ============================================
// PROVIDERS ADMIN (toutes les souscriptions)
// ============================================

final getAllSouscriptionsUseCaseProvider = Provider<GetAllSouscriptionsUseCase>((ref) {
  return GetAllSouscriptionsUseCase(ref.watch(souscriptionRepositoryProvider));
});

final watchAllSouscriptionsUseCaseProvider = Provider<WatchAllSouscriptionsUseCase>((ref) {
  return WatchAllSouscriptionsUseCase(ref.watch(souscriptionRepositoryProvider));
});

final updateSouscriptionStatutUseCaseProvider = Provider<UpdateSouscriptionStatutUseCase>((ref) {
  return UpdateSouscriptionStatutUseCase(ref.watch(souscriptionRepositoryProvider));
});

final allSouscriptionsStreamProvider = StreamProvider<List<SouscriptionModel>>((ref) {
  final useCase = ref.watch(watchAllSouscriptionsUseCaseProvider);
  return useCase.execute();
});

final adminSouscriptionsStateProvider =
    StateNotifierProvider<AdminSouscriptionsNotifier, AdminSouscriptionsState>((ref) {
  return AdminSouscriptionsNotifier(ref);
});

class AdminSouscriptionsState {
  final List<SouscriptionModel> souscriptions;
  final bool isLoading;
  final String? error;
  final String filtre;
  final double montantTotal;
  final int totalEnCours;
  final int totalPayees;
  final int totalAnnulees;

  const AdminSouscriptionsState({
    this.souscriptions = const [],
    this.isLoading = false,
    this.error,
    this.filtre = 'toutes',
    this.montantTotal = 0,
    this.totalEnCours = 0,
    this.totalPayees = 0,
    this.totalAnnulees = 0,
  });

  AdminSouscriptionsState copyWith({
    List<SouscriptionModel>? souscriptions,
    bool? isLoading,
    String? error,
    String? filtre,
    double? montantTotal,
    int? totalEnCours,
    int? totalPayees,
    int? totalAnnulees,
  }) {
    return AdminSouscriptionsState(
      souscriptions: souscriptions ?? this.souscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filtre: filtre ?? this.filtre,
      montantTotal: montantTotal ?? this.montantTotal,
      totalEnCours: totalEnCours ?? this.totalEnCours,
      totalPayees: totalPayees ?? this.totalPayees,
      totalAnnulees: totalAnnulees ?? this.totalAnnulees,
    );
  }

  List<SouscriptionModel> get souscriptionsFiltrees {
    if (filtre == 'toutes') return souscriptions;
    if (filtre == 'en_cours') return souscriptions.where((s) => s.estEnCours).toList();
    if (filtre == 'payee') return souscriptions.where((s) => s.estPayee).toList();
    if (filtre == 'annulee') return souscriptions.where((s) => s.estAnnulee).toList();
    return souscriptions;
  }
}

class AdminSouscriptionsNotifier extends StateNotifier<AdminSouscriptionsState> {
  final Ref _ref;

  AdminSouscriptionsNotifier(this._ref) : super(const AdminSouscriptionsState());

  void setFiltre(String filtre) {
    state = state.copyWith(filtre: filtre);
  }

  Future<void> loadAllSouscriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final useCase = _ref.read(getAllSouscriptionsUseCaseProvider);
      final result = await useCase.execute();

      if (result.success) {
        state = AdminSouscriptionsState(
          souscriptions: result.souscriptions,
          montantTotal: result.montantTotal,
          totalEnCours: result.totalEnCours,
          totalPayees: result.totalPayees,
          totalAnnulees: result.totalAnnulees,
          filtre: state.filtre,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateStatut(String reference, String statut) async {
    try {
      final useCase = _ref.read(updateSouscriptionStatutUseCaseProvider);
      final result = await useCase.execute(reference, statut);

      if (result.success) {
        await loadAllSouscriptions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void reset() {
    state = const AdminSouscriptionsState();
  }
}
