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
    String? orgName,
    String? orgAddress,
    String? instagram,
    String? logoPath,
  }) async {
    final doc = pw.Document();
    
    pw.MemoryImage? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  height: 60,
                  child: pw.Image(logoImage),
                ),
              pw.SizedBox(height: 5),
              pw.Text(
                (orgName ?? 'SIMPLE SALE').toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (orgAddress != null && orgAddress.isNotEmpty)
                pw.Text(
                  orgAddress,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 0.5),
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Kassa: $registerName', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('Nomi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Text('Soni', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Narxi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Jami', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 2),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 10))),
                      pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(item.price.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 10)),
                      pw.Text((item.quantity * item.price).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'JAMI SUMMA:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                  pw.Text(
                    '${total.toStringAsFixed(0)} so\'m',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              if (instagram != null && instagram.isNotEmpty) ...[
                pw.Center(child: pw.Text('Instagram: @$instagram', style: const pw.TextStyle(fontSize: 9))),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'https://instagram.com/$instagram',
                    width: 60,
                    height: 60,
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
              pw.Center(
                child: pw.Text(
                  'Xaridingiz uchun rahmat!',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
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
        final commands = _generateEscPosCommands(
          items, 
          total, 
          registerName, 
          orgName: orgName, 
          orgAddress: orgAddress, 
          instagram: instagram
        );
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
    String registerName, {
    String? orgName,
    String? orgAddress,
    String? instagram,
  }) {
    List<int> bytes = [];

    // init printer
    bytes.addAll([0x1B, 0x40]);

    // Chararacter set selection (optional, usually default works for latin)

    // Align center
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Title
    bytes.addAll([0x1B, 0x45, 0x01]); // bold on
    bytes.addAll([0x1D, 0x21, 0x11]); // double size
    bytes.addAll(utf8.encode('${orgName ?? 'SIMPLE SALE'}\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // normal size
    bytes.addAll([0x1B, 0x45, 0x00]); // bold off
    
    if (orgAddress != null && orgAddress.isNotEmpty) {
      bytes.addAll(utf8.encode('$orgAddress\n'));
    }

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

    if (instagram != null && instagram.isNotEmpty) {
      bytes.addAll(utf8.encode('\nInstagram: @$instagram\n'));
    }

    bytes.addAll(utf8.encode('\nXaridingiz uchun rahmat!\n\n\n\n\n'));

    // Cut paper (partial cut)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  static Future<List<Printer>> getPrinters() async {
    return await Printing.listPrinters();
  }
}
