import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../../master/models/master_item_model.dart';
import '../../master/providers/master_provider.dart';
import '../models/product_model.dart';

class ProductForm extends ConsumerStatefulWidget {
  final String saveLabel;
  final ProductModel? initialProduct;
  final Future<String?> Function(ProductModel product) onSave;
  final VoidCallback? onSaved;

  const ProductForm({
    super.key,
    required this.saveLabel,
    required this.onSave,
    this.initialProduct,
    this.onSaved,
  });

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _supplierController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  ProductUnit _selectedUnit = ProductUnit.piece;
  ProductStatus _selectedStatus = ProductStatus.active;
  String? _selectedBrandId;
  String? _selectedCategoryId;
  String? _selectedLocationId;

  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    final product = widget.initialProduct;

    _nameController.text = product?.name ?? '';
    _skuController.text = product?.sku ?? '';
    _purchasePriceController.text =
        product?.purchasePrice.toStringAsFixed(2) ?? '';
    _sellingPriceController.text =
        product?.sellingPrice.toStringAsFixed(2) ?? '';
    _stockController.text = product?.stockQuantity.toString() ?? '';
    _minimumStockController.text = product?.minimumStock.toString() ?? '';
    _supplierController.text = product?.supplierId ?? '';
    _barcodeController.text = product?.barcode ?? '';
    _imageUrlController.text = product?.imageUrl ?? '';

    _selectedUnit = product?.unit ?? ProductUnit.piece;
    _selectedStatus = product?.status ?? ProductStatus.active;
    _selectedBrandId = product?.brandId;
    _selectedCategoryId = product?.categoryId;
    _selectedLocationId = product?.locationId;

    Future.microtask(() {
      ref
          .read(masterProvider(FirestoreCollections.brands).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.categories).notifier)
          .loadItems();
      ref
          .read(masterProvider(FirestoreCollections.locations).notifier)
          .loadItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minimumStockController.dispose();
    _supplierController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  double get _purchasePrice =>
      double.tryParse(_purchasePriceController.text.trim()) ?? 0;

  double get _sellingPrice =>
      double.tryParse(_sellingPriceController.text.trim()) ?? 0;

  double get _profitAmount => _sellingPrice - _purchasePrice;

  double get _profitPercentage {
    if (_purchasePrice <= 0) {
      return 0;
    }

    return (_profitAmount / _purchasePrice) * 100;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final brandId = _selectedBrandId;
    final categoryId = _selectedCategoryId;
    final locationId = _selectedLocationId;

    if (brandId == null || categoryId == null || locationId == null) {
      setState(() {
        _errorText = 'Select brand, category, and location.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final now = DateTime.now();
    final initialProduct = widget.initialProduct;
    final product = (initialProduct ?? _createNewProduct(now)).copyWith(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      brandId: brandId,
      categoryId: categoryId,
      unit: _selectedUnit,
      purchasePrice: _purchasePrice,
      sellingPrice: _sellingPrice,
      stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
      minimumStock: int.tryParse(_minimumStockController.text.trim()) ?? 0,
      supplierId: _supplierController.text.trim(),
      locationId: locationId,
      barcode: _normalizeOptional(_barcodeController.text),
      imageUrl: _normalizeOptional(_imageUrlController.text),
      status: _selectedStatus,
      updatedAt: now,
    );

    final errorMessage = await widget.onSave(product);

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

  ProductModel _createNewProduct(DateTime now) {
    return ProductModel(
      id: const Uuid().v4(),
      sku: '',
      name: '',
      brandId: '',
      categoryId: '',
      unit: ProductUnit.piece,
      purchasePrice: 0,
      sellingPrice: 0,
      stockQuantity: 0,
      minimumStock: 0,
      supplierId: '',
      locationId: '',
      barcode: null,
      imageUrl: null,
      status: ProductStatus.active,
      createdAt: now,
      updatedAt: now,
    );
  }

  String? _normalizeOptional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _requiredTextValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _numberValidator(String? value, {required bool allowZero}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'This field is required';
    }

    final parsed = double.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed < 0 || (!allowZero && parsed == 0)) {
      return allowZero
          ? 'Value cannot be negative'
          : 'Value must be greater than zero';
    }

    return null;
  }

  String? _integerValidator(String? value, {required bool allowZero}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'This field is required';
    }

    final parsed = int.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid whole number';
    }

    if (parsed < 0 || (!allowZero && parsed == 0)) {
      return allowZero
          ? 'Value cannot be negative'
          : 'Value must be greater than zero';
    }

    return null;
  }

  String? _dropdownValue(List<MasterItemModel> items, String? value) {
    if (value == null) {
      return null;
    }

    for (final item in items) {
      if (item.id == value) {
        return value;
      }
    }

    return null;
  }

  Widget _sectionTitle(String text) {
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

  Widget _buildDropdownField({
    required String label,
    required List<MasterItemModel> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedValue = _dropdownValue(items, value);

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }

        return null;
      },
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProfitCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _MetricBlock(
                label: 'Profit Amount',
                value: AppFormatters.currency(_profitAmount),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricBlock(
                label: 'Profit Percentage',
                value: '${_profitPercentage.toStringAsFixed(2)}%',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(masterProvider(FirestoreCollections.brands));
    final categoryState = ref.watch(
      masterProvider(FirestoreCollections.categories),
    );
    final locationState = ref.watch(
      masterProvider(FirestoreCollections.locations),
    );

    final loadingMasters =
        brandState.isLoading ||
        categoryState.isLoading ||
        locationState.isLoading;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loadingMasters) ...[
              const LoadingWidget(message: 'Loading master data...'),
              const SizedBox(height: 16),
            ],
            _sectionTitle('General Information'),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _nameController,
              labelText: 'Product Name',
              validator: (value) =>
                  _requiredTextValidator(value, 'Product name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _skuController,
              labelText: 'SKU (Optional)',
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Brand',
              items: brandState.items,
              value: _selectedBrandId,
              onChanged: (value) {
                setState(() {
                  _selectedBrandId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Category',
              items: categoryState.items,
              value: _selectedCategoryId,
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductUnit>(
              initialValue: _selectedUnit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: ProductUnit.values
                  .map(
                    (unit) => DropdownMenuItem<ProductUnit>(
                      value: unit,
                      child: Text(unit.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedUnit = value;
                });
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('Pricing'),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _purchasePriceController,
              labelText: 'Purchase Price',
              keyboardType: TextInputType.number,
              validator: (value) => _numberValidator(value, allowZero: false),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _sellingPriceController,
              labelText: 'Selling Price',
              keyboardType: TextInputType.number,
              validator: (value) => _numberValidator(value, allowZero: false),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildProfitCard(),
            const SizedBox(height: 20),
            _sectionTitle('Inventory'),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _stockController,
              labelText: 'Current Stock',
              keyboardType: TextInputType.number,
              validator: (value) => _integerValidator(value, allowZero: true),
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _minimumStockController,
              labelText: 'Minimum Stock',
              keyboardType: TextInputType.number,
              validator: (value) => _integerValidator(value, allowZero: true),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Location',
              items: locationState.items,
              value: _selectedLocationId,
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('Optional Information'),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _supplierController,
              labelText: 'Supplier ID (Optional)',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _barcodeController,
              labelText: 'Barcode (Optional)',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _imageUrlController,
              labelText: 'Image URL (Optional)',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ProductStatus.values
                  .map(
                    (status) => DropdownMenuItem<ProductStatus>(
                      value: status,
                      child: Text(status.name.toUpperCase()),
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
              onPressed: _saving ? null : _saveProduct,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
