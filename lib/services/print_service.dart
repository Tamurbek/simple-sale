import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';

class PrintService {
  static Future<void> printBarcodeLabels({
    required List<Map<String, dynamic>> items, // [{'product': Product, 'quantity': int}]
    String? printerName,
  }) async {
    final doc = pw.Document();

    const labelFormat = PdfPageFormat(
      40 * PdfPageFormat.mm,
      30 * PdfPageFormat.mm,
      marginAll: 2 * PdfPageFormat.mm,
    );

    for (var item in items) {
      final Product product = item['product'];
      final int quantity = item['quantity'] ?? 1;

      for (int i = 0; i < quantity; i++) {
        doc.addPage(
          pw.Page(
            pageFormat: labelFormat,
            build: (pw.Context context) {
              return pw.Column(
                mainAxisAlignment: pw.Center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    product.name.toUpperCase(),
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    maxLines: 2,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: product.barcode,
                    width: 35 * PdfPageFormat.mm,
                    height: 12 * PdfPageFormat.mm,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Narxi: ${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(product.price)} so\'m',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

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
    } else {
      await Printing.layoutPdf(onLayout: (format) => doc.save());
    }
  }

  static Future<void> printBarcodeLabel({
    required Product product,
    String? printerName,
  }) async {
    await printBarcodeLabels(
      items: [{'product': product, 'quantity': 1}],
      printerName: printerName,
    );
  }

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

  static Future<void> printReport({
    required String reportTitle,
    required List<Map<String, dynamic>> sections,
    String? printerName,
    String? ipAddress,
    int width = 80,
    String? orgName,
  }) async {
    final doc = pw.Document();
    
    doc.addPage(
      pw.Page(
        pageFormat: width == 58 ? PdfPageFormat.roll57 : PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                (orgName ?? 'SIMPLE SALE').toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: width == 58 ? 10 : 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                reportTitle.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: width == 58 ? 12 : 14),
              ),
              pw.Text(
                'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: width == 58 ? 8 : 10),
              ),
              pw.Divider(thickness: 1),
              ...sections.map((section) {
                final String title = section['title'] ?? '';
                final List<Map<String, String>> rows = (section['rows'] as List?)?.cast<Map<String, String>>() ?? [];
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: width == 58 ? 9 : 11)),
                      pw.Divider(thickness: 0.5),
                    ],
                    ...rows.map((row) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text(row['label'] ?? '', style: pw.TextStyle(fontSize: width == 58 ? 8 : 10))),
                          pw.Text(row['value'] ?? '', style: pw.TextStyle(fontSize: width == 58 ? 8 : 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    )),
                  ],
                );
              }),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 0.5),
              pw.Text('Simple Sale hisoboti', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
        final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 3));
        List<int> bytes = [];
        int maxChars = width == 58 ? 32 : 42;
        
        // init
        bytes.addAll([0x1B, 0x40]);
        // center
        bytes.addAll([0x1B, 0x61, 0x01]);
        bytes.addAll(utf8.encode('${orgName ?? 'SIMPLE SALE'}\n'));
        bytes.addAll([0x1B, 0x45, 0x01]);
        bytes.addAll(utf8.encode('${reportTitle.toUpperCase()}\n'));
        bytes.addAll([0x1B, 0x45, 0x00]);
        bytes.addAll(utf8.encode('Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\n'));
        bytes.addAll(utf8.encode('-' * maxChars + '\n'));
        
        for (var section in sections) {
          final String title = section['title'] ?? '';
          final List<Map<String, String>> rows = (section['rows'] as List?)?.cast<Map<String, String>>() ?? [];
          
          if (title.isNotEmpty) {
            bytes.addAll([0x1B, 0x61, 0x00]); // left
            bytes.addAll([0x1B, 0x45, 0x01]);
            bytes.addAll(utf8.encode('\n$title\n'));
            bytes.addAll([0x1B, 0x45, 0x00]);
            bytes.addAll(utf8.encode('-' * maxChars + '\n'));
          }
          
          for (var row in rows) {
            String label = row['label'] ?? '';
            String value = row['value'] ?? '';
            int spaces = maxChars - label.length - value.length;
            if (spaces < 1) spaces = 1;
            bytes.addAll(utf8.encode(label + (' ' * spaces) + value + '\n'));
          }
        }
        
        bytes.addAll(utf8.encode('\n' + '-' * maxChars + '\n'));
        bytes.addAll(utf8.encode('Simple Sale hisoboti\n\n\n\n\n'));
        bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
        
        socket.add(bytes);
        await socket.flush();
        await socket.close();
      } catch (e) {
        debugPrint('IP Printer error: $e');
      }
    }
  }

  static Future<List<Printer>> getPrinters() async {
    return await Printing.listPrinters();
  }
}
