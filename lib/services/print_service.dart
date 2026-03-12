import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';

class PrintService {
  static Future<void> printReceipt({
    required List<SaleItem> items,
    required double total,
    required String registerName,
    String? printerName,
    String? ipAddress,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SIMPLE SALE POS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              pw.Divider(),
              pw.Text('Kassa: $registerName'),
              pw.Text(
                'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Nomi'), pw.Text('Soni'), pw.Text('Narxi')],
              ),
              pw.Divider(),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item.productName)),
                      pw.Text('${item.quantity}'),
                      pw.Text(item.price.toStringAsFixed(0)),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'JAMI:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${total.toStringAsFixed(0)} so\'m',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
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
      final printer = printers.firstWhere(
        (p) => p.name == printerName,
        orElse: () => printers.first,
      );
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => doc.save(),
      );
    }

    if (ipAddress != null && ipAddress.isNotEmpty) {
      try {
        final socket = await Socket.connect(
          ipAddress,
          9100,
          timeout: const Duration(seconds: 3),
        );
        final commands = _generateEscPosCommands(items, total, registerName);
        socket.add(commands);
        await socket.flush();
        socket.destroy();
      } catch (e) {
        print('IP Printer error: $e');
      }
    }
  }

  static List<int> _generateEscPosCommands(
    List<SaleItem> items,
    double total,
    String registerName,
  ) {
    List<int> bytes = [];

    // init printer
    bytes.addAll([0x1B, 0x40]);

    // Chararacter set selection (optional, usually default works for latin)

    // Align center
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Title
    bytes.addAll([0x1B, 0x45, 0x01]); // bold on
    bytes.addAll([0x1D, 0x21, 0x11]); // double size
    bytes.addAll(utf8.encode('SIMPLE SALE POS\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // normal size
    bytes.addAll([0x1B, 0x45, 0x00]); // bold off

    bytes.addAll([0x1B, 0x61, 0x00]); // Align left

    bytes.addAll(utf8.encode('--------------------------------\n'));
    bytes.addAll(utf8.encode('Kassa: $registerName\n'));
    bytes.addAll(
      utf8.encode(
        'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n',
      ),
    );
    bytes.addAll(utf8.encode('--------------------------------\n'));

    for (var item in items) {
      bytes.addAll(utf8.encode('${item.productName}\n'));
      bytes.addAll(
        utf8.encode(
          '${item.quantity} x ${item.price.toStringAsFixed(0)} = ${(item.quantity * item.price).toStringAsFixed(0)}\n',
        ),
      );
    }

    bytes.addAll(utf8.encode('--------------------------------\n'));
    bytes.addAll([0x1B, 0x61, 0x01]); // Align center

    bytes.addAll([0x1B, 0x45, 0x01]); // bold on
    bytes.addAll([0x1D, 0x21, 0x01]); // double height
    bytes.addAll(utf8.encode('JAMI: ${total.toStringAsFixed(0)} so\'m\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // normal size
    bytes.addAll([0x1B, 0x45, 0x00]); // bold off

    bytes.addAll(utf8.encode('\nXaridingiz uchun rahmat!\n\n\n\n\n'));

    // Cut paper (partial cut)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  static Future<List<Printer>> getPrinters() async {
    return await Printing.listPrinters();
  }
}
