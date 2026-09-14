import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/supplier_model.dart';
import '../models/supplier_validator.dart';
import '../providers/supplier_provider.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const SupplierFormScreen({this.supplierId, super.key});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _gst = TextEditingController();
  bool _active = true;
  bool _loaded = false;
  String? _error;

  bool get _isEditing => widget.supplierId != null;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _gst.dispose();
    super.dispose();
  }

  void _populate(SupplierModel supplier) {
    if (_loaded) return;
    _loaded = true;
    _name.text = supplier.name;
    _contact.text = supplier.contactPerson;
    _phone.text = supplier.phone;
    _email.text = supplier.email;
    _address.text = supplier.address;
    _gst.text = supplier.gstNumber;
    _active = supplier.isActive;
  }

  Future<void> _save(UserModel? user, SupplierModel? existing) async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) {
      setState(() => _error = 'You must be signed in to manage suppliers.');
      return;
    }

    final now = DateTime.now();
    final supplier = SupplierModel(
      id: existing?.id ?? '',
      name: _name.text.trim(),
      contactPerson: _contact.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      gstNumber: _gst.text.trim(),
      isActive: _active,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() => _error = null);
    final notifier = ref.read(supplierNotifierProvider.notifier);
    final error = existing == null
        ? await notifier.create(supplier, user)
        : await notifier.update(supplier, user);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Supplier added' : 'Supplier updated',
          ),
        ),
      );
      context.pop();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).valueOrNull;
    debugPrint('SUPPLIER AUTH USER: $authUser');
    final existingAsync = _isEditing
        ? ref.watch(supplierDetailsProvider(widget.supplierId!))
        : const AsyncValue<SupplierModel?>.data(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Supplier' : 'Add Supplier'),
      ),
      body: existingAsync.when(
        loading: () => const LoadingWidget(message: 'Loading supplier...'),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (existing) {
          if (existing != null) _populate(existing);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Colors.red[700])),
                  const SizedBox(height: 12),
                ],
                PrimaryTextField(
                  controller: _name,
                  labelText: 'Supplier name',
                  validator: SupplierValidator.validateName,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _contact,
                  labelText: 'Contact person',
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _phone,
                  labelText: 'Phone',
                  keyboardType: TextInputType.phone,
                  validator: SupplierValidator.validatePhone,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _email,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: SupplierValidator.validateEmail,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _address,
                  labelText: 'Address',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(controller: _gst, labelText: 'GSTIN'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: _isEditing ? 'Save changes' : 'Add supplier',
                  isLoading: ref.watch(supplierNotifierProvider).isLoading,
                  onPressed: () => _save(authUser, existing),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
