import 'package:flutter/material.dart';

import '../../../shared/widgets/primary_textfield.dart';

class AddMasterDialog extends StatefulWidget {
  final String title;
  final String saveLabel;
  final String initialValue;
  final Future<String?> Function(String value) onSave;

  const AddMasterDialog({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<AddMasterDialog> createState() => _AddMasterDialogState();
}

class _AddMasterDialogState extends State<AddMasterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = _controller.text.trim();

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final errorMessage = await widget.onSave(value);

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _loading = false;
      _errorText = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryTextField(
              controller: _controller,
              labelText: 'Name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a name';
                }

                return null;
              },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.saveLabel),
        ),
      ],
    );
  }
}
