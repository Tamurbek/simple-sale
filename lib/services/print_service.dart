import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class PrintService {
  static Future<void> printReceipt({
    required List<SaleItem> items,
    required double total,
    required String registerName,
    String? printerName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('SIMPLE SALE POS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.Divider(),
              pw.Text('Kassa: $registerName'),
              pw.Text('Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nomi'),
                  pw.Text('Soni'),
                  pw.Text('Narxi'),
                ],
              ),
              pw.Divider(),
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(item.productName)),
                    pw.Text('${item.quantity}'),
                    pw.Text('${item.price.toStringAsFixed(0)}'),
                  ],
                ),
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('JAMI:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${total.toStringAsFixed(0)} so\'m', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Xaridingiz uchun rahmat!')),
            ],
          );
        },
      ),
    );

    if (printerName != null) {
      final printers = await Printing.listPrinters();
      final printer = printers.firstWhere((p) => p.name == printerName, orElse: () => printers.first);
      await Printing.directPrintPdf(printer: printer, onLayout: (format) => doc.save());
    } else {
      await Printing.layoutPdf(onLayout: (format) => doc.save());
    }
  }

  static Future<List<Printer>> getPrinters() async {
    return await Printing.listPrinters();
  }
}
