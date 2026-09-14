import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/inventory_enums.dart';
import '../providers/inventory_provider.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final String productId;
  final String title;
  final StockDirection? fixedDirection;

  const StockAdjustmentScreen({
    super.key,
    required this.productId,
    required this.title,
    this.fixedDirection,
  });

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  StockDirection _selectedDirection = StockDirection.increase;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDirection = widget.fixedDirection ?? StockDirection.increase;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  int? _projectedStock(int currentStock) {
    if (_quantity <= 0) {
      return null;
    }

    final delta = _selectedDirection == StockDirection.increase
        ? _quantity
        : -_quantity;
    final value = currentStock + delta;

    return value < 0 ? null : value;
  }

  Future<void> _submit(int currentStock) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final projectedStock = _projectedStock(currentStock);
    if (projectedStock == null) {
      setState(() {
        _errorText = 'Adjustment would make stock negative.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final errorMessage = await ref
        .read(inventoryProvider.notifier)
        .adjustStock(
          productId: widget.productId,
          quantity: _quantity,
          direction: _selectedDirection,
          reason: _reasonController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      context.pop();
      return;
    }

    setState(() {
      _saving = false;
      _errorText = errorMessage;
    });
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _quantityValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed <= 0) {
      return 'Enter a valid quantity';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(inventoryProductProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: productAsync.when(
        loading: () => const LoadingWidget(message: 'Loading product...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load product',
              subtitle: error.toString(),
            ),
          ),
        ),
        data: (product) {
          final currentStock = product.stockQuantity;
          final projectedStock = _projectedStock(currentStock);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Current Stock: $currentStock'),
                        const SizedBox(height: 8),
                        Text(
                          projectedStock == null
                              ? 'Projected Stock: --'
                              : 'Projected Stock: $projectedStock',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.fixedDirection == null) ...[
                  DropdownButtonFormField<StockDirection>(
                    initialValue: _selectedDirection,
                    decoration: const InputDecoration(
                      labelText: 'Adjustment Type',
                    ),
                    items: StockDirection.values
                        .map(
                          (direction) => DropdownMenuItem<StockDirection>(
                            value: direction,
                            child: Text(direction.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedDirection = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                PrimaryTextField(
                  controller: _quantityController,
                  labelText: 'Quantity',
                  keyboardType: TextInputType.number,
                  validator: _quantityValidator,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                PrimaryTextField(
                  controller: _reasonController,
                  labelText: 'Reason',
                  validator: (value) => _requiredValidator(value, 'Reason'),
                ),
                const SizedBox(height: 16),
                PrimaryTextField(
                  controller: _notesController,
                  labelText: 'Notes (Optional)',
                  maxLines: 3,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Adjustment',
                  onPressed: _saving ? null : () => _submit(currentStock),
                  isLoading: _saving,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
