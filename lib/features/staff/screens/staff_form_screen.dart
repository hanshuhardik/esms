import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/role_definition.dart';
import '../providers/staff_provider.dart';

class StaffFormScreen extends ConsumerStatefulWidget {
  final String? staffUid;

  const StaffFormScreen({this.staffUid, super.key});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  UserRole _selectedRole = UserRole.staff;
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.staffUid != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Load existing staff data if editing
    if (_isEditing) {
      _loadStaffData();
    }
  }

  Future<void> _loadStaffData() async {
    final staffAsync = ref.read(staffMemberProvider(widget.staffUid!));

    staffAsync.whenData((staff) {
      if (staff != null && mounted) {
        _nameController.text = staff.name;
        _emailController.text = staff.email;
        _phoneController.text = staff.phone;
        setState(() {
          _selectedRole = staff.role;
          _isActive = staff.isActive;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    // Validate
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Name is required');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Phone is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(staffNotifierProvider.notifier);

      if (_isEditing) {
        // Update existing staff
        final success = await notifier.updateStaff(
          uid: widget.staffUid!,
          name: _nameController.text,
          phone: _phoneController.text,
          role: _selectedRole,
          isActive: _isActive,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff updated successfully')),
          );
          context.pop();
        }
      } else {
        // Create new staff
        // Note: In a real app, you'd create the Firebase Auth user via Cloud Function
        // For now, we're just creating the profile
        setState(
          () => _errorMessage =
              'Staff creation requires backend setup (Cloud Function). Contact admin.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Staff'), centerTitle: true),
        body: _buildForm(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff'), centerTitle: true),
      body: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Name
          Text('Name *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter staff name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          // Email
          Text('Email *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Enter email address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            enabled: !_isLoading && !_isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Email cannot be changed',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 16),

          // Phone
          Text('Phone *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Role
          Text('Role *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _RoleDropdown(
            selectedRole: _selectedRole,
            onChanged: (role) {
              if (role != null) {
                setState(() => _selectedRole = role);
              }
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          // Active Status (only shown when editing)
          if (_isEditing) ...[
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _isActive = value);
                    },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          PrimaryButton(
            text: _isEditing ? 'Update Staff' : 'Add Staff',
            isLoading: _isLoading,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isEditing
                  ? 'You can update staff details here. Email address cannot be changed.'
                  : 'To add new staff, a Cloud Function will create the Firebase Auth account. Please configure the backend first.',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final UserRole selectedRole;
  final Function(UserRole?) onChanged;
  final bool enabled;

  const _RoleDropdown({
    required this.selectedRole,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final roles = RoleDefinition.allRoles();

    return DropdownButtonFormField<UserRole>(
      initialValue: selectedRole,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      items: roles
          .map(
            (roleDef) => DropdownMenuItem(
              value: roleDef.role,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(roleDef.displayName),
                  Text(
                    roleDef.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
