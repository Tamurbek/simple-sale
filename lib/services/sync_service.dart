import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

class SyncService {
  static HttpServer? _server;

  // Start a local server on the "Master" register
  static Future<void> startServer(Function(Map<String, dynamic>) onSaleReceived) async {
    final router = Router();

    router.post('/sale', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      onSaleReceived(data);
      return Response.ok(jsonEncode({'status': 'success'}));
    });

    router.get('/stocks', (Request request) {
      // Logic to return current stocks
      return Response.ok(jsonEncode({'message': 'stocks coming soon'}));
    });

    _server = await io.serve(router, InternetAddress.anyIPv4, 8080);
    print('Server ishga tushdi: ${_server!.address.address}:${_server!.port}');
  }

  // Client (Secondary Register) sends sale to Master
  static Future<bool> sendSaleToMaster(String masterIp, Map<String, dynamic> saleData) async {
    try {
      final response = await http.post(
        Uri.parse('http://$masterIp:8080/sale'),
        body: jsonEncode(saleData),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Sinxronizatsiya xatosi: $e');
      return false;
    }
  }

  static void stopServer() {
    _server?.close();
  }
}
