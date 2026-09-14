import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/shop_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/shop_model.dart';
import '../models/bill_model.dart';

class BillReceiptService {
  BillReceiptService._();

  static final NumberFormat _pdfCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static Future<Uint8List> buildPdf(
    BillModel bill, {
    ShopModel? shopOverride,
  }) async {
    final shop = shopOverride ?? await ShopService.getShop();
    final logoData = await rootBundle.load(
      'assets/images/mehta_electricals_logo.png',
    );
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        maxPages: 20,
        build: (context) => [
          _buildHeader(shop, logo, bill),
          pw.SizedBox(height: 14),
          _buildBillInformation(bill),
          pw.SizedBox(height: 14),
          _buildItemsTable(bill),
          pw.SizedBox(height: 10),
          _buildTotals(bill),
          pw.SizedBox(height: 14),
          _buildPaymentInformation(bill),
          pw.SizedBox(height: 20),
          _buildTermsAndFooter(shop),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> printBill(BillModel bill) async {
    final bytes = await buildPdf(bill);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareBill(BillModel bill) async {
    final bytes = await buildPdf(bill);
    await Printing.sharePdf(bytes: bytes, filename: '${bill.billNumber}.pdf');
  }

  static pw.Widget _buildHeader(
    ShopModel? shop,
    pw.ImageProvider logo,
    BillModel bill,
  ) {
    final shopName = shop?.shopName.trim().isNotEmpty == true
        ? shop!.shopName.toUpperCase()
        : 'MEHTA ELECTRICALS & ELECTRONICS';
    final address = shop?.address.trim() ?? '';
    final phone = shop?.phone.trim().isNotEmpty == true
        ? shop!.phone.trim()
        : '9470526459';

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3.8),
        1: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(logo, width: 58),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (address.isNotEmpty)
                        pw.Text(
                          address,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      pw.Text(
                        'Mobile: $phone',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      if ((shop?.email ?? '').trim().isNotEmpty)
                        pw.Text(
                          'Email: ${shop!.email.trim()}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Bill No: ${bill.billNumber}'),
                pw.Text('Date: ${AppFormatters.date(bill.createdAt)}'),
                pw.Text(
                  'Time: ${DateFormat('hh:mm a').format(bill.createdAt)}',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBillInformation(BillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey500),
          bottom: pw.BorderSide(color: PdfColors.grey500),
        ),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              _Label('BILLED TO'),
              _Value(
                bill.customerName?.trim().isNotEmpty == true
                    ? bill.customerName!
                    : 'Walk-in Customer',
              ),
              _Label('PAYMENT MODE'),
              _Value(bill.paymentMethod.label),
            ],
          ),
          pw.TableRow(
            children: [
              _Label('PHONE'),
              _Value(bill.customerPhone ?? ''),
              _Label('BILLED BY'),
              _Value(bill.createdBy),
            ],
          ),
          pw.TableRow(
            children: [
              _Label('TAKEN BY'),
              _Value(
                bill.takenBy.trim().isEmpty ? 'Walk-in Customer' : bill.takenBy,
              ),
              _Value(''),
              _Value(''),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(BillModel bill) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(4.4),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.7),
        4: const pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _Cell('#', bold: true),
            _Cell('Item', bold: true),
            _Cell('Qty', bold: true, align: pw.TextAlign.right),
            _Cell('Rate (Rs.)', bold: true, align: pw.TextAlign.right),
            _Cell('Amount (Rs.)', bold: true, align: pw.TextAlign.right),
          ],
        ),
        ...bill.items.asMap().entries.map(
          (entry) => pw.TableRow(
            children: [
              _Cell('${entry.key + 1}'),
              _Cell(_formatBillItemName(entry.value.productName)),
              _Cell('${entry.value.quantity}', align: pw.TextAlign.right),
              _Cell(
                _pdfCurrency(entry.value.sellingPrice),
                align: pw.TextAlign.right,
              ),
              _Cell(
                _pdfCurrency(entry.value.lineTotal),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotals(BillModel bill) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', bill.subtotal),
            if (bill.discount > 0) _totalRow('Less', bill.discount),
            pw.Divider(),
            _totalRow('Total Payable', bill.total, bold: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPaymentInformation(BillModel bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              _Label('PAYMENT STATUS'),
              _Value(bill.paymentStatus.label),
              _Label('PAYMENT METHOD'),
              _Value(bill.paymentMethod.label),
            ],
          ),
          pw.TableRow(
            children: [
              _Label('PAID'),
              _Value(_pdfCurrency(bill.amountPaid)),
              _Label('DUE'),
              _Value(_pdfCurrency(bill.amountDue)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTermsAndFooter(ShopModel? shop) {
    final phone = shop?.phone.trim().isNotEmpty == true
        ? shop!.phone.trim()
        : '9470526459';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TERMS & RETURN POLICY',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          '1. Returns or exchanges are accepted only within 30 days from the date of purchase shown on this bill.\n'
          '2. This bill must be presented at the time of return or exchange; no return will be entertained without it.\n'
          '3. Items must be unused, in original condition and original packaging to be eligible for return.\n'
          '4. Electrical items found defective at the time of purchase will be replaced or repaired as per manufacturer warranty; no cash refund on used/installed items.\n'
          '5. This is a computer-generated bill and does not require a signature.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for shopping with Mehta Electricals & Electronics!\n'
          'For any queries regarding this bill, please call us at $phone.\n'
          'A receipt copy may also be shared to the customer\'s phone.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _totalRow(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            _pdfCurrency(value),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _pdfCurrency(double value) => _pdfCurrencyFormat.format(value);

  static String _formatBillItemName(String productName) {
    final trimmed = productName.trim();
    if (trimmed.isEmpty) {
      return 'Product';
    }

    final hasExplicitBrand = trimmed.contains('(') && trimmed.contains(')');
    if (hasExplicitBrand) {
      final prefix = trimmed.substring(0, trimmed.indexOf('(')).trim();
      final suffix = trimmed
          .substring(trimmed.indexOf('(') + 1, trimmed.lastIndexOf(')'))
          .trim();
      if (prefix.isEmpty) {
        return suffix;
      }
      if (suffix.isEmpty) {
        return prefix;
      }
      return '$prefix ($suffix)';
    }

    return trimmed;
  }
}

class _Cell extends pw.StatelessWidget {
  final String value;
  final bool bold;
  final pw.TextAlign align;

  _Cell(this.value, {this.bold = false, this.align = pw.TextAlign.left});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

class _Label extends pw.StatelessWidget {
  final String value;

  _Label(this.value);

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }
}

class _Value extends pw.StatelessWidget {
  final String value;

  _Value(this.value);

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}
