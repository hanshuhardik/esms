import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  ExpenseCategory? _category;
  ExpensePaymentMethod? _paymentMethod;
  DateTime? _expenseDate;
  ExpenseModel? _loadedExpense;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId == null) {
      _expenseDate = DateTime.now();
      _dateController.text = AppFormatters.date(_expenseDate!);
      _paymentMethod = ExpensePaymentMethod.cash;
      _category = ExpenseCategory.miscellaneous;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _populateFields(ExpenseModel expense) {
    _loadedExpense = expense;
    _titleController.text = expense.title;
    _descriptionController.text = expense.description ?? '';
    _amountController.text = expense.amount.toStringAsFixed(2);
    _category = expense.category;
    _paymentMethod = expense.paymentMethod;
    _expenseDate = expense.expenseDate;
    _dateController.text = AppFormatters.date(expense.expenseDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _expenseDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _expenseDate = picked;
        _dateController.text = AppFormatters.date(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final category = _category;
    final paymentMethod = _paymentMethod;
    final expenseDate = _expenseDate;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final validationError =
        ExpenseModel.validateAmount(amount) ??
        ExpenseModel.validateCategory(category) ??
        ExpenseModel.validatePaymentMethod(paymentMethod) ??
        ExpenseModel.validateDate(expenseDate);

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final now = DateTime.now();
    final existing = _loadedExpense;
    final expense = ExpenseModel(
      id: widget.expenseId ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      amount: amount,
      category: category!,
      paymentMethod: paymentMethod!,
      expenseDate: expenseDate!,
      createdBy: existing?.createdBy ?? '',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = await ref
        .read(expenseProvider.notifier)
        .saveExpense(expense: expense, isEdit: widget.expenseId != null);

    if (!mounted) {
      return;
    }

    if (result.isFailure || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Unable to save expense.')),
      );
      return;
    }

    if (widget.expenseId == null) {
      context.go(AppRoutes.expenseDetails(result.data!.id));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final isEdit = widget.expenseId != null;

    if (isEdit) {
      final expenseAsync = ref.watch(expenseDetailsProvider(widget.expenseId!));

      if (expenseAsync.isLoading) {
        return const Scaffold(
          body: LoadingWidget(message: 'Loading expense...'),
        );
      }

      if (expenseAsync.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Expense')),
          body: Center(child: Text(expenseAsync.error.toString())),
        );
      }

      if (expenseAsync.hasValue && !_initialized) {
        _populateFields(expenseAsync.value!);
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Expense' : 'Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PrimaryTextField(
              controller: _titleController,
              labelText: 'Title',
              validator: ExpenseModel.validateTitle,
            ),
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return ExpenseModel.validateAmount(amount);
              },
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategory.values
                  .map(
                    (category) => DropdownMenuItem<ExpenseCategory>(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              validator: ExpenseModel.validateCategory,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpensePaymentMethod>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: ExpensePaymentMethod.values
                  .map(
                    (method) => DropdownMenuItem<ExpensePaymentMethod>(
                      value: method,
                      child: Text(method.label),
                    ),
                  )
                  .toList(),
              validator: ExpenseModel.validatePaymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              validator: (_) => ExpenseModel.validateDate(_expenseDate),
              decoration: const InputDecoration(labelText: 'Expense Date'),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: isEdit ? 'Update Expense' : 'Save Expense',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : _saveExpense,
            ),
          ],
        ),
      ),
    );
  }
}
