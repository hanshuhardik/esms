import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_textfield.dart';
import '../models/bill_model.dart';
import '../repositories/billing_repository.dart';
import '../../returns/repositories/return_repository.dart';

class EditBillScreen extends StatefulWidget {
  final BillModel bill;

  const EditBillScreen({required this.bill, super.key});

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  late final TextEditingController _discountController;
  late final TextEditingController _amountPaidController;
  late final TextEditingController _phoneController;
  late final TextEditingController _takenByController;
  late BillPaymentStatus _paymentStatus;
  String? _errorMessage;
  bool _isSaving = false;
  bool _hasProcessedReturn = false;
  bool _returnsChecked = false;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.bill.discount.toString(),
    );
    _amountPaidController = TextEditingController(
      text: widget.bill.amountPaid.toString(),
    );
    _phoneController = TextEditingController(
      text: widget.bill.customerPhone ?? '',
    );
    _takenByController = TextEditingController(text: widget.bill.takenBy);
    _paymentStatus = widget.bill.paymentStatus;
    _loadReturnStatus();
  }

  Future<void> _loadReturnStatus() async {
    final result = await ReturnRepository.getCustomerReturns([widget.bill.id]);
    if (!mounted) return;
    setState(() {
      _hasProcessedReturn = result.isSuccess && result.data?.isNotEmpty == true;
      _returnsChecked = true;
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _amountPaidController.dispose();
    _phoneController.dispose();
    _takenByController.dispose();
    super.dispose();
  }

  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;

  double get _total => BillModel.calculateTotal(
    subtotal: widget.bill.subtotal,
    discount: _discount,
  );

  double get _amountPaid {
    return switch (_paymentStatus) {
      BillPaymentStatus.paid => _total,
      BillPaymentStatus.due => 0,
      BillPaymentStatus.partial =>
        double.tryParse(_amountPaidController.text.trim()) ?? 0,
    };
  }

  double get _amountDue => (_total - _amountPaid).clamp(0.0, _total).toDouble();

  void _onPaymentStatusChanged(BillPaymentStatus? value) {
    if (value == null) return;
    setState(() {
      _paymentStatus = value;
      _errorMessage = null;
      if (value == BillPaymentStatus.paid) {
        _amountPaidController.text = _total.toStringAsFixed(2);
      } else if (value == BillPaymentStatus.due) {
        _amountPaidController.text = '0';
      }
    });
  }

  String? _validate() {
    if (_discount < 0 || _discount > widget.bill.subtotal) {
      return 'Discount must be between zero and the subtotal.';
    }
    if (_amountPaid < 0 || _amountPaid > _total) {
      return 'Amount paid must be between zero and the new total.';
    }
    if (_paymentStatus == BillPaymentStatus.partial &&
        (_amountPaid <= 0 || _amountPaid >= _total)) {
      return 'Partial payment must be greater than zero and less than the total.';
    }
    if (_paymentStatus == BillPaymentStatus.paid && _amountPaid != _total) {
      return 'Paid status requires the full amount to be paid.';
    }
    if (_paymentStatus == BillPaymentStatus.due && _amountPaid != 0) {
      return 'Due status requires an amount paid of zero.';
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await BillingRepository.updateBill(
      billId: widget.bill.id,
      discount: _discount,
      amountPaid: _amountPaid,
      paymentStatus: _paymentStatus,
      customerPhone: _phoneController.text,
      takenBy: _takenByController.text,
    );
    if (!mounted) return;

    if (result.isFailure || result.data == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = result.error ?? 'Failed to update bill.';
      });
      return;
    }

    Navigator.of(context).pop(result.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReadOnlySummary(bill: widget.bill),
          const SizedBox(height: 16),
          PrimaryTextField(
            controller: _discountController,
            labelText: 'Discount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving && _returnsChecked && !_hasProcessedReturn,
            onChanged: (_) => setState(() {}),
          ),
          if (_hasProcessedReturn) ...[
            const SizedBox(height: 8),
            const Text(
              'Discount cannot be changed after a return has been processed for this bill.',
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<BillPaymentStatus>(
            initialValue: _paymentStatus,
            decoration: const InputDecoration(labelText: 'Payment Status'),
            items: BillPaymentStatus.values
                .map(
                  (status) => DropdownMenuItem<BillPaymentStatus>(
                    value: status,
                    child: Text(status.label),
                  ),
                )
                .toList(),
            onChanged: _isSaving ? null : _onPaymentStatusChanged,
          ),
          if (_paymentStatus == BillPaymentStatus.partial) ...[
            const SizedBox(height: 12),
            PrimaryTextField(
              controller: _amountPaidController,
              labelText: 'Amount Paid',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_isSaving,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),
          PrimaryTextField(
            controller: _phoneController,
            labelText: 'Customer Phone (Optional)',
            keyboardType: TextInputType.phone,
            enabled: !_isSaving,
          ),
          const SizedBox(height: 12),
          PrimaryTextField(
            controller: _takenByController,
            labelText: 'Taken By (Optional)',
            enabled: !_isSaving,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'New total',
                    value: AppFormatters.currency(_total),
                  ),
                  _SummaryRow(
                    label: 'Paid',
                    value: AppFormatters.currency(_amountPaid),
                  ),
                  _SummaryRow(
                    label: 'Due',
                    value: AppFormatters.currency(_amountDue),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Save Changes',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySummary extends StatelessWidget {
  final BillModel bill;

  const _ReadOnlySummary({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bill.billNumber,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Subtotal: ${AppFormatters.currency(bill.subtotal)}'),
            const SizedBox(height: 4),
            const Text('Products and quantities cannot be edited.'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
