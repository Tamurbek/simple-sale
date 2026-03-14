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
    int width = 80,
    String? footerText,
    bool showLogo = true,
    bool showInstagram = true,
  }) async {
    final doc = pw.Document();
    
    pw.MemoryImage? logoImage;
    if (showLogo && logoPath != null && File(logoPath).existsSync()) {
      logoImage = pw.MemoryImage(File(logoPath).readAsBytesSync());
    }

    doc.addPage(
      pw.Page(
        pageFormat: width == 58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (showLogo && logoImage != null)
                pw.Container(
                  height: 60,
                  child: pw.Image(logoImage),
                ),
              pw.SizedBox(height: 5),
              pw.Text(
                (orgName ?? 'SIMPLE SALE').toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: width == 58 ? 11 : 14,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (orgAddress != null && orgAddress.isNotEmpty)
                pw.Text(
                  orgAddress,
                  style: pw.TextStyle(fontSize: width == 58 ? 8 : 10),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 0.5),
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Kassa: $registerName', style: pw.TextStyle(fontSize: width == 58 ? 8 : 10)),
                    pw.Text(
                      'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: width == 58 ? 8 : 10),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.productName.toUpperCase(),
                        style: pw.TextStyle(fontSize: width == 58 ? 8 : 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(item.price)}',
                            style: pw.TextStyle(fontSize: width == 58 ? 8 : 9),
                          ),
                          pw.Text(
                            NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(item.quantity * item.price),
                            style: pw.TextStyle(fontSize: width == 58 ? 9 : 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
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
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: width == 58 ? 10 : 12),
                  ),
                  pw.Text(
                    '${total.toStringAsFixed(0)} so\'m',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: width == 58 ? 11 : 14),
                  ),
                ],
              ),
              pw.Center(
                child: pw.Text(
                  footerText ?? 'Xaridingiz uchun rahmat!',
                  style: pw.TextStyle(fontSize: width == 58 ? 8 : 10, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 10),
              if (showInstagram && instagram != null && instagram.isNotEmpty) ...[
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 5),
                pw.Center(child: pw.Text('Instagram: @$instagram', style: pw.TextStyle(fontSize: width == 58 ? 8 : 9))),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'https://instagram.com/$instagram',
                    width: width == 58 ? 40 : 50,
                    height: width == 58 ? 40 : 50,
                  ),
                ),
              ],
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
          instagram: instagram,
          width: width,
          footerText: footerText,
          showInstagram: showInstagram,
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
    int width = 80,
    String? footerText,
    bool showInstagram = true,
  }) {
    List<int> bytes = [];
    int maxChars = width == 58 ? 32 : 42;
    String divider = '-' * maxChars;

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

    bytes.addAll(utf8.encode('$divider\n'));
    bytes.addAll(utf8.encode('Kassa: $registerName\n'));
    bytes.addAll(
      utf8.encode(
        'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n',
      ),
    );
    bytes.addAll(utf8.encode('$divider\n'));

    for (var item in items) {
      // Product Name (Upper Case for clarity)
      bytes.addAll(utf8.encode('${item.productName.toUpperCase()}\n'));
      
      // Quantity x Price and Total on the same line
      String qtyPrice = ' ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${item.price.toStringAsFixed(0)}';
      String totalItem = (item.quantity * item.price).toStringAsFixed(0);
      
      // Simple padding
      int spaces = maxChars - qtyPrice.length - totalItem.length;
      if (spaces < 1) spaces = 1;
      
      bytes.addAll(utf8.encode(qtyPrice + (' ' * spaces) + totalItem + '\n'));
    }

    bytes.addAll(utf8.encode('$divider\n'));
    bytes.addAll([0x1B, 0x61, 0x01]); // Align center

    bytes.addAll([0x1B, 0x45, 0x01]); // bold on
    bytes.addAll([0x1D, 0x21, 0x01]); // double height
    bytes.addAll(utf8.encode('JAMI: ${total.toStringAsFixed(0)} so\'m\n'));
    bytes.addAll([0x1D, 0x21, 0x00]); // normal size
    bytes.addAll([0x1B, 0x45, 0x00]); // bold off
    
    bytes.addAll(utf8.encode('\n${footerText ?? "Xaridingiz uchun rahmat!"}\n'));

    if (showInstagram && instagram != null && instagram.isNotEmpty) {
      bytes.addAll(utf8.encode('$divider\n'));
      bytes.addAll(utf8.encode('Instagram: @$instagram\n'));
    }

    bytes.addAll(utf8.encode('\n\n\n\n\n'));

    // Cut paper (partial cut)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  static Future<List<Printer>> getPrinters() async {
    return await Printing.listPrinters();
  }
}
