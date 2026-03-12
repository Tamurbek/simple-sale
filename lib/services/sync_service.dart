import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncService {
  static HttpServer? _server;
  static final List<WebSocketChannel> _clients = [];

  // Broadcast to all connected clients
  static void broadcast(String type, Map<String, dynamic> data) {
    final message = jsonEncode({'type': type, 'data': data});
    final List<WebSocketChannel> toRemove = [];
    
    for (var client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        toRemove.add(client);
      }
    }
    
    for (var client in toRemove) {
      _clients.remove(client);
    }
  }

  // Start a local server on the "Master" register
  static Future<void> startServer({
    required Function(Map<String, dynamic>) onSaleReceived,
    required Function(String type, Map<String, dynamic> data) onUpdateReceived,
    required Map<String, dynamic> Function() onSyncRequested,
    required Future<Map<String, dynamic>> Function(String? registerId, String? deviceId, bool force) onRegisterSelectionRequested,
  }) async {
    final router = Router();

    router.get('/ws', (Request request) {
      return webSocketHandler((WebSocketChannel socket) {
        _clients.add(socket);
        socket.stream.listen(
          (message) {
            // Clients don't send much via WS in this architecture, usually just ping
          },
          onDone: () => _clients.remove(socket),
          onError: (err) => _clients.remove(socket),
        );
      })(request);
    });

    // Endpoint for clients to push sales
    router.post('/sale', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);
        onSaleReceived(data);
        return Response.ok(jsonEncode({'status': 'success'}));
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    // Endpoint for clients to push any data update (Categories, Products, etc.)
    router.post('/update', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);
        onUpdateReceived(data['type'], data['data']);
        return Response.ok(jsonEncode({'status': 'success'}));
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    router.post('/select-register', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);
        final result = await onRegisterSelectionRequested(data['registerId'], data['deviceId'], data['force'] ?? false);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    // Endpoint for clients to pull full database state
    router.get('/sync', (Request request) {
      try {
        final data = onSyncRequested();
        return Response.ok(
          jsonEncode(data),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    // Simple status check endpoint
    router.get('/status', (Request request) {
      return Response.ok(jsonEncode({'status': 'active', 'timestamp': DateTime.now().toIso8601String()}));
    });

    _server = await io.serve(router, InternetAddress.anyIPv4, 8080);
    print('Server ishga tushdi: ${_server!.address.address}:${_server!.port}');
  }

  // Client fetches status from Master
  static Future<Map<String, dynamic>?> fetchStatusFromMaster(String masterIp) async {
    try {
      final response = await http.get(Uri.parse('http://$masterIp:8080/status')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Client fetches full database state from Master
  static Future<Map<String, dynamic>?> fetchFullState(String masterIp) async {
    try {
      final response = await http.get(Uri.parse('http://$masterIp:8080/sync'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch state error: $e');
      return null;
    }
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

  // Client sends generic update to Master
  static Future<bool> sendUpdateToMaster(String masterIp, String type, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://$masterIp:8080/update'),
        body: jsonEncode({'type': type, 'data': data}),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update send error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> selectRegisterOnMaster(String masterIp, String? registerId, String? deviceId, bool force) async {
    try {
      final response = await http.post(
        Uri.parse('http://$masterIp:8080/select-register'),
        body: jsonEncode({'registerId': registerId, 'deviceId': deviceId, 'force': force}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Select register error: $e');
      return null;
    }
  }

  static void stopServer() {
    _server?.close();
  }
}
