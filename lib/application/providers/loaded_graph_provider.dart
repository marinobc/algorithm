import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/graph_storage_service.dart';

/// Provider managing the active SavedGraphItem metadata loaded into the editor.
class LoadedGraphItemNotifier extends Notifier<SavedGraphItem?> {
  @override
  SavedGraphItem? build() => null;

  void setLoadedItem(SavedGraphItem? item) {
    state = item;
  }
}

final loadedGraphItemProvider =
    NotifierProvider<LoadedGraphItemNotifier, SavedGraphItem?>(() {
      return LoadedGraphItemNotifier();
    });
