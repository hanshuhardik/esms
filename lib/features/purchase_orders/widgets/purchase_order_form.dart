import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/products/models/product_model.dart';
import '../../../features/products/providers/product_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../../suppliers/models/supplier_model.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderForm extends ConsumerStatefulWidget {
  final String saveLabel;
  final PurchaseOrderModel? initialOrder;
  final Future<String?> Function(PurchaseOrderModel order) onSave;
  final VoidCallback? onSaved;

  const PurchaseOrderForm({
    super.key,
    required this.saveLabel,
    required this.onSave,
    this.initialOrder,
    this.onSaved,
  });

  @override
  ConsumerState<PurchaseOrderForm> createState() => _PurchaseOrderFormState();
}

class _PurchaseOrderFormState extends ConsumerState<PurchaseOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final List<_DraftItem> _items = [];

  String? _selectedSupplierId;
  PurchaseOrderStatus _selectedStatus = PurchaseOrderStatus.ordered;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final order = widget.initialOrder;
    _notesController.text = order?.notes ?? '';
    _selectedSupplierId = order?.supplierId;
    _selectedStatus = order?.status ?? PurchaseOrderStatus.ordered;

    if (order?.items.isNotEmpty == true) {
      _items.addAll(order!.items.map(_DraftItem.fromModel));
    } else {
      _items.add(_DraftItem.empty());
    }

    Future.microtask(() {
      ref.read(productProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  ProductModel? _productById(String? productId, List<ProductModel> products) {
    if (productId == null) {
      return null;
    }

    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  SupplierModel? _supplierById(
    String? supplierId,
    List<SupplierModel> suppliers,
  ) {
    if (supplierId == null) {
      return null;
    }

    for (final supplier in suppliers) {
      if (supplier.id == supplierId) {
        return supplier;
      }
    }

    return null;
  }

  void _addItem() {
    setState(() {
      _items.add(_DraftItem.empty());
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      return;
    }

    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'PO-$year$month$day-${now.millisecondsSinceEpoch % 100000}';
  }

  double _readDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  int _readInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double _lineTotal(_DraftItem item, List<ProductModel> products) {
    final product = _productById(item.productId, products);
    if (product == null) {
      return 0;
    }

    final quantity = _readInt(item.quantityController);
    final price = _readDouble(item.unitCostController);
    final gst = _readDouble(item.gstPercentController);

    final subtotal = quantity * price;
    return subtotal + (subtotal * gst / 100);
  }

  void _seedDefaultsForProduct(_DraftItem item, ProductModel? product) {
    if (product == null) {
      return;
    }

    if (item.unitCostController.text.trim().isEmpty) {
      item.unitCostController.text = product.purchasePrice.toStringAsFixed(2);
    }

    if (item.gstPercentController.text.trim().isEmpty) {
      item.gstPercentController.text = '18';
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final supplierId = _selectedSupplierId;
    if (supplierId == null) {
      setState(() {
        _errorText = 'Select a supplier.';
      });
      return;
    }

    final productState = ref.read(productProvider);
    final suppliers = ref.read(suppliersProvider).valueOrNull ?? const [];
    final products = productState.products;
    final selectedSupplier = _supplierById(supplierId, suppliers);

    if (selectedSupplier == null) {
      setState(() {
        _errorText = 'Select a valid supplier.';
      });
      return;
    }

    final productIds = <String>{};
    final orderItems = <PurchaseOrderItemModel>[];
    for (final draftItem in _items) {
      final product = _productById(draftItem.productId, products);
      if (product == null) {
        setState(() {
          _errorText = 'Select a valid product for every line item.';
        });
        return;
      }

      if (!productIds.add(product.id)) {
        setState(() {
          _errorText = 'Each product can only appear once in an order.';
        });
        return;
      }

      final quantityOrdered = _readInt(draftItem.quantityController);
      final unitCost = _readDouble(draftItem.unitCostController);
      final gstPercent = _readDouble(draftItem.gstPercentController);

      if (quantityOrdered <= 0 || unitCost < 0 || gstPercent < 0) {
        setState(() {
          _errorText = 'Check the quantities and pricing for each line item.';
        });
        return;
      }

      orderItems.add(
        PurchaseOrderItemModel(
          id: draftItem.id,
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          quantityOrdered: quantityOrdered,
          quantityReceived: draftItem.initialReceivedQuantity,
          unitCost: unitCost,
          gstPercent: gstPercent,
          createdAt: draftItem.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final now = DateTime.now();
    final currentUser = AuthService.currentUser;
    final createdById =
        widget.initialOrder?.createdById ?? currentUser?.uid ?? 'unknown';
    final createdByName =
        widget.initialOrder?.createdByName ??
        (currentUser?.displayName?.trim().isNotEmpty == true
            ? currentUser!.displayName!.trim()
            : (currentUser?.email ?? 'Unknown Staff'));
    final subtotal = orderItems.fold<double>(
      0,
      (sum, item) => sum + item.lineSubtotal,
    );
    final gstAmount = orderItems.fold<double>(
      0,
      (sum, item) => sum + item.lineGstAmount,
    );
    final grandTotal = subtotal + gstAmount;

    final initialOrder = widget.initialOrder;
    final order =
        (initialOrder ??
                PurchaseOrderModel(
                  id: const Uuid().v4(),
                  orderNumber: _generateOrderNumber(),
                  supplierId: '',
                  supplierName: '',
                  status: _selectedStatus,
                  items: const [],
                  notes: null,
                  subtotal: 0,
                  gstAmount: 0,
                  grandTotal: 0,
                  createdById: createdById,
                  createdByName: createdByName,
                  receivedById: null,
                  receivedByName: null,
                  receivedAt: null,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              supplierId: supplierId,
              supplierName: selectedSupplier.name,
              status:
                  initialOrder?.status != null &&
                      initialOrder!.status.name != 'draft' &&
                      initialOrder.status.name != 'ordered' &&
                      initialOrder.status.name != 'cancelled'
                  ? initialOrder.status
                  : _selectedStatus,
              items: orderItems,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              subtotal: subtotal,
              gstAmount: gstAmount,
              grandTotal: grandTotal,
              createdById: createdById,
              createdByName: createdByName,
              updatedAt: now,
            );

    final errorMessage = await widget.onSave(order);

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      widget.onSaved?.call();
      return;
    }

    setState(() {
      _saving = false;
      _errorText = errorMessage;
    });
  }

  Widget _buildSectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSummaryCard(List<ProductModel> products) {
    final lineCount = _items.length;
    final totalAmount = _items.fold<double>(
      0,
      (sum, item) => sum + _lineTotal(item, products),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialOrder?.orderNumber ?? _generateOrderNumber(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Lines: $lineCount'),
            const SizedBox(height: 4),
            Text('Estimated Total: ${AppFormatters.currency(totalAmount)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, List<ProductModel> products) {
    final item = _items[index];
    final selectedProduct = _productById(item.productId, products);
    final lineTotal = _lineTotal(item, products);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Line ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: item.productId,
              decoration: const InputDecoration(labelText: 'Product'),
              items: products
                  .map(
                    (product) => DropdownMenuItem<String>(
                      value: product.id,
                      child: Text(
                        product.sku.isEmpty
                            ? product.name
                            : '${product.name} • ${product.sku}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  item.productId = value;
                  final product = _productById(value, products);
                  _seedDefaultsForProduct(item, product);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select a product';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryTextField(
                    controller: item.quantityController,
                    labelText: 'Quantity',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a valid quantity';
                      }

                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryTextField(
                    controller: item.unitCostController,
                    labelText: 'Unit Cost',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      if (price == null || price < 0) {
                        return 'Enter a valid price';
                      }

                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryTextField(
                    controller: item.gstPercentController,
                    labelText: 'GST %',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final gst = double.tryParse(value?.trim() ?? '');
                      if (gst == null || gst < 0) {
                        return 'Enter a valid GST value';
                      }

                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Line Total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.currency(lineTotal),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (selectedProduct != null) ...[
              const SizedBox(height: 12),
              Text(
                'Current product cost: ${AppFormatters.currency(selectedProduct.purchasePrice)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final products = productState.products;

    if ((productState.isLoading && products.isEmpty) ||
        (suppliersAsync.isLoading &&
            (suppliersAsync.valueOrNull ?? []).isEmpty)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.saveLabel)),
        body: const LoadingWidget(message: 'Loading purchase order data...'),
      );
    }

    final suppliers = suppliersAsync.valueOrNull ?? const [];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(products),
          const SizedBox(height: 16),
          _buildSectionTitle('Supplier'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSupplierId,
            decoration: const InputDecoration(labelText: 'Select Supplier'),
            items: suppliers
                .map(
                  (supplier) => DropdownMenuItem<String>(
                    value: supplier.id,
                    child: Text(
                      supplier.phone.isEmpty
                          ? supplier.name
                          : '${supplier.name} • ${supplier.phone}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSupplierId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Select a supplier';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Status'),
          const SizedBox(height: 8),
          if (widget.initialOrder == null ||
              !widget.initialOrder!.status.isSystemManaged)
            DropdownButtonFormField<PurchaseOrderStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Order Status'),
              items:
                  const [
                        PurchaseOrderStatus.draft,
                        PurchaseOrderStatus.ordered,
                        PurchaseOrderStatus.cancelled,
                      ]
                      .map(
                        (status) => DropdownMenuItem<PurchaseOrderStatus>(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedStatus = value;
                });
              },
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Status: ${widget.initialOrder!.status.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildSectionTitle('Line Items'),
          const SizedBox(height: 8),
          ...List.generate(
            _items.length,
            (index) => _buildItemCard(index, products),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Notes'),
          const SizedBox(height: 8),
          PrimaryTextField(
            controller: _notesController,
            labelText: 'Order Notes (Optional)',
            maxLines: 4,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            text: widget.saveLabel,
            onPressed: _saving ? null : _saveOrder,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _DraftItem {
  final String id;
  final DateTime createdAt;
  final TextEditingController quantityController;
  final TextEditingController unitCostController;
  final TextEditingController gstPercentController;
  String? productId;
  final int initialReceivedQuantity;

  _DraftItem({
    required this.id,
    required this.createdAt,
    required this.quantityController,
    required this.unitCostController,
    required this.gstPercentController,
    required this.productId,
    required this.initialReceivedQuantity,
  });

  factory _DraftItem.empty() {
    return _DraftItem(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      quantityController: TextEditingController(text: '1'),
      unitCostController: TextEditingController(),
      gstPercentController: TextEditingController(text: '18'),
      productId: null,
      initialReceivedQuantity: 0,
    );
  }

  factory _DraftItem.fromModel(PurchaseOrderItemModel item) {
    return _DraftItem(
      id: item.id,
      createdAt: item.createdAt,
      quantityController: TextEditingController(
        text: item.quantityOrdered.toString(),
      ),
      unitCostController: TextEditingController(
        text: item.unitCost.toStringAsFixed(2),
      ),
      gstPercentController: TextEditingController(
        text: item.gstPercent.toStringAsFixed(2),
      ),
      productId: item.productId,
      initialReceivedQuantity: item.quantityReceived,
    );
  }

  void dispose() {
    quantityController.dispose();
    unitCostController.dispose();
    gstPercentController.dispose();
  }
}
