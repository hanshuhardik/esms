import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/master_item_model.dart';
import '../repositories/master_repository.dart';

class MasterState {
  final List<MasterItemModel> items;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  static const Object _unset = Object();

  const MasterState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  MasterState copyWith({
    List<MasterItemModel>? items,
    bool? isLoading,
    String? searchQuery,
    Object? errorMessage = _unset,
  }) {
    return MasterState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

final masterProvider =
    StateNotifierProvider.family<MasterNotifier, MasterState, String>(
      (ref, collection) => MasterNotifier(collection),
    );

class MasterNotifier extends StateNotifier<MasterState> {
  MasterNotifier(this.collection) : super(const MasterState());

  final String collection;

  StreamSubscription<List<MasterItemModel>>? _subscription;

  bool _loaded = false;

  void loadItems({bool forceReload = false}) {
    if (_loaded && !forceReload) return;

    _loaded = true;

    state = state.copyWith(isLoading: true, errorMessage: null);

    _subscription?.cancel();

    _subscription = MasterRepository.getItems(collection).listen(
      (items) {
        state = state.copyWith(
          items: items,
          isLoading: false,
          errorMessage: null,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _messageForError(error),
        );
        _loaded = false;
      },
    );
  }

  void updateSearch(String value) {
    state = state.copyWith(searchQuery: value.trim());
  }

  List<MasterItemModel> get filteredItems {
    if (state.searchQuery.isEmpty) {
      return state.items;
    }

    final query = state.searchQuery.toLowerCase();

    return state.items.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  }

  String _messageForError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return error.toString();
  }

  Future<String?> addItem(MasterItemModel item) async {
    final result = await MasterRepository.addItem(collection, item);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> updateItem(MasterItemModel item) async {
    final result = await MasterRepository.updateItem(collection, item);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  Future<String?> deleteItem(String id) async {
    final result = await MasterRepository.deleteItem(collection, id);

    if (result.isFailure) {
      return result.error;
    }

    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
