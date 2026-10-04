// lib/presentation/providers/tarifs/tarifs_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/i_tarif_repository.dart';
import '../../../data/repositories/tarif_repository_impl.dart';
import '../../../domain/usecases/tarifs/get_tarifs_usecase.dart';
import '../../../core/utils/logger.dart';

final tarifRepositoryProvider = Provider<ITarifRepository>((ref) {
  return TarifRepositoryImpl();
});

final getTarifsUseCaseProvider = Provider<GetTarifsUseCase>((ref) {
  return GetTarifsUseCase(ref.watch(tarifRepositoryProvider));
});

final saveTarifsUseCaseProvider = Provider<SaveTarifsUseCase>((ref) {
  return SaveTarifsUseCase(ref.watch(tarifRepositoryProvider));
});

final watchTarifsUseCaseProvider = Provider<WatchTarifsUseCase>((ref) {
  return WatchTarifsUseCase(ref.watch(tarifRepositoryProvider));
});

final tarifsConfigProvider = FutureProvider<TarifConfigModel>((ref) async {
  final useCase = ref.watch(getTarifsUseCaseProvider);
  return await useCase.execute();
});

final tarifsStreamProvider = StreamProvider<TarifConfigModel?>((ref) {
  final useCase = ref.watch(watchTarifsUseCaseProvider);
  return useCase.execute();
});

final tarifsStateProvider =
    StateNotifierProvider<TarifsNotifier, TarifsState>((ref) {
  return TarifsNotifier(ref);
});

class TarifsState {
  final TarifConfigModel config;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  TarifsState({
    TarifConfigModel? config,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  }) : config = config ?? TarifConfigModel.defaut();

  TarifsState copyWith({
    TarifConfigModel? config,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return TarifsState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearMessages ? null : (error ?? this.error),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TarifsNotifier extends StateNotifier<TarifsState> {
  final Ref _ref;

  TarifsNotifier(this._ref) : super(TarifsState());

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final config = await _ref.read(tarifsConfigProvider.future);
      state = state.copyWith(config: config, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveConfig(TarifConfigModel newConfig, String updatedBy) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final updated = newConfig.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
      );
      final useCase = _ref.read(saveTarifsUseCaseProvider);
      final success = await useCase.execute(updated);
      if (success) {
        state = state.copyWith(
          config: updated,
          isSaving: false,
          successMessage: 'Tarifs sauvegardes',
        );
        _ref.invalidate(tarifsConfigProvider);
        return true;
      } else {
        state = state.copyWith(isSaving: false, error: 'Erreur sauvegarde');
        return false;
      }
    } catch (e) {
      Logger.error('Erreur sauvegarde tarifs: $e');
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void updateLocalConfig(TarifConfigModel newConfig) {
    state = state.copyWith(config: newConfig, clearMessages: true);
  }

  void reset() {
    state = TarifsState();
  }
}
