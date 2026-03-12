import 'dart:io';
import 'dart:convert';
import 'package:window_manager/window_manager.dart';

class SingleInstanceService {
  static final SingleInstanceService _instance =
      SingleInstanceService._internal();
  factory SingleInstanceService() => _instance;
  SingleInstanceService._internal();

  static const int _port = 54321; // Unique port for our app instance

  Future<void> ensureSingleInstance() async {
    if (Platform.isAndroid || Platform.isIOS) return;

    try {
      // Try to bind to the port
      final socket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        _port,
      );

      // If we got here, we are the first instance
      socket.listen((client) {
        client.listen((data) async {
          final message = utf8.decode(data);
          if (message == 'SHOW_WINDOW') {
            await windowManager.show();
            await windowManager.focus();
          }
        });
      });
    } catch (e) {
      // Port already in use, another instance is running
      try {
        final client = await Socket.connect(
          InternetAddress.loopbackIPv4,
          _port,
        );
        client.write('SHOW_WINDOW');
        await client.flush();
        await client.close();
      } catch (err) {
        // Socket error, just exit
      }
      exit(0); // Close this new instance
    }
  }
}
