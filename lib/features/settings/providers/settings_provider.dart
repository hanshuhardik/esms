import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/shop_model.dart';
import '../../../shared/models/user_model.dart';
import '../repositories/settings_repository.dart';

class SettingsState {
  final ShopModel? settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    ShopModel? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await SettingsRepository.getSettings();

    if (result.isSuccess) {
      state = state.copyWith(settings: result.data, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.error);
    }
  }

  Future<bool> updateSettings({
    required ShopModel settings,
    required UserModel currentUser,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await SettingsRepository.updateSettings(
      settings: settings,
      currentUser: currentUser,
    );

    if (result.isSuccess) {
      state = state.copyWith(settings: result.data, isSaving: false);
      return true;
    }

    state = state.copyWith(isSaving: false, errorMessage: result.error);
    return false;
  }
}
