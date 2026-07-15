import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_search_bar.dart';
import '../master_config.dart';
import '../models/master_item_model.dart';
import '../providers/master_provider.dart';
import '../widgets/add_master_dialog.dart';
import '../widgets/master_list_tile.dart';

class MasterListScreen extends ConsumerStatefulWidget {
  final MasterConfig config;

  const MasterListScreen({super.key, required this.config});

  @override
  ConsumerState<MasterListScreen> createState() => _MasterListScreenState();
}

class _MasterListScreenState extends ConsumerState<MasterListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(masterProvider(widget.config.collection).notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(masterProvider(widget.config.collection));

    final notifier = ref.read(
      masterProvider(widget.config.collection).notifier,
    );

    final items = notifier.filteredItems;
    final hasSearchQuery = state.searchQuery.isNotEmpty;
    final isFilteredEmpty =
        hasSearchQuery && items.isEmpty && state.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.config.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(notifier),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PrimarySearchBar(
              controller: _searchController,
              hintText: widget.config.searchHint,
              onChanged: notifier.updateSearch,
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.items.isNotEmpty) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],
            if (state.errorMessage != null && state.items.isNotEmpty) ...[
              _ErrorBanner(
                message: state.errorMessage!,
                onRetry: () => notifier.loadItems(forceReload: true),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? LoadingWidget(
                      message:
                          'Loading ${widget.config.title.toLowerCase()}...',
                    )
                  : state.errorMessage != null && state.items.isEmpty
                  ? EmptyState(
                      icon: Icons.error_outline,
                      title:
                          'Unable to load ${widget.config.title.toLowerCase()}',
                      subtitle: 'Check your connection and try again.',
                    )
                  : items.isEmpty
                  ? EmptyState(
                      icon: isFilteredEmpty
                          ? Icons.search_off
                          : Icons.folder_open,
                      title: isFilteredEmpty
                          ? 'No matches found'
                          : widget.config.emptyTitle,
                      subtitle: isFilteredEmpty
                          ? 'Try a different search term.'
                          : widget.config.emptySubtitle,
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return MasterListTile(
                          item: item,
                          onEdit: () => _showEditDialog(notifier, item),
                          onDelete: () => _confirmDelete(notifier, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(MasterNotifier notifier) async {
    await showDialog(
      context: context,
      builder: (_) => AddMasterDialog(
        title: widget.config.addDialogTitle,
        saveLabel: 'Save',
        initialValue: '',
        onSave: (value) async {
          final item = MasterItemModel(
            id: value.trim().toLowerCase().replaceAll(' ', '_'),
            name: value.trim(),
            createdAt: DateTime.now(),
          );

          return notifier.addItem(item);
        },
      ),
    );
  }

  Future<void> _showEditDialog(
    MasterNotifier notifier,
    MasterItemModel item,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AddMasterDialog(
        title: widget.config.editDialogTitle,
        saveLabel: 'Update',
        initialValue: item.name,
        onSave: (value) async {
          return notifier.updateItem(item.copyWith(name: value.trim()));
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    MasterNotifier notifier,
    MasterItemModel item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final errorMessage = await notifier.deleteItem(item.id);

      if (!mounted) {
        return;
      }

      if (errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
