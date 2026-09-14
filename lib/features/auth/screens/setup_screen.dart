import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/shop_service.dart';
import '../../../shared/models/shop_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/setup_validator.dart';
import '../repositories/auth_repository.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthRepository.currentUser;
    if (user == null) {
      setState(
        () => _error =
            'Initial owner setup must be provisioned by a trusted backend before shop setup can be completed.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final shop = ShopModel(
      id: 'default',
      shopName: _name.text.trim(),
      ownerName: _owner.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      gstEnabled: false,
      currency: 'INR',
      billPrefix: 'BILL',
      purchaseOrderPrefix: 'PO',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ShopService.createShop(shop);
      if (mounted) context.go(AppRoutes.dashboard);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'permission-denied'
              ? 'Only the initial owner can complete shop setup.'
              : 'Unable to save shop setup. Check your connection and try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to save shop setup. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initial Shop Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Configure shops/default',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'A trusted backend must provision the initial owner account. This form never creates Auth users or stores passwords.',
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Colors.red[700])),
                  const SizedBox(height: 12),
                ],
                PrimaryTextField(
                  controller: _name,
                  labelText: 'Shop name',
                  validator: SetupValidator.validateShopName,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _owner,
                  labelText: 'Owner name',
                  enabled: !_saving,
                  validator: SetupValidator.validateShopName,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _phone,
                  labelText: 'Shop phone',
                  keyboardType: TextInputType.phone,
                  validator: SetupValidator.validatePhone,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _email,
                  labelText: 'Shop email',
                  keyboardType: TextInputType.emailAddress,
                  validator: SetupValidator.validateEmail,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _address,
                  labelText: 'Shop address',
                  maxLines: 3,
                  enabled: !_saving,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Save setup',
                  onPressed: _save,
                  isLoading: _saving,
                ),
                TextButton(
                  onPressed: _saving ? null : () => context.go(AppRoutes.login),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
