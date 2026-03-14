import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';

class UpdateService {
  static const String _activationServerUrl = "https://web-production-afb90.up.railway.app";

  static Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final response = await http.get(Uri.parse("$_activationServerUrl/update/latest"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] as String;
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewer(latestVersion, currentVersion)) {
          return data;
        }
      }
    } catch (e) {
      print("Yangilanishni tekshirishda xatolik: $e");
    }
    return null;
  }

  static bool _isNewer(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static Future<void> downloadAndInstall(String downloadUrl, Function(double) onProgress) async {
    try {
      final fullUrl = downloadUrl.startsWith('http') ? downloadUrl : "$_activationServerUrl$downloadUrl";
      final response = await http.Client().send(http.Request('GET', Uri.parse(fullUrl)));
      final contentLength = response.contentLength ?? 0;
      
      final bytes = <int>[];
      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0) {
          onProgress(bytes.length / contentLength);
        }
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = downloadUrl.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Platform.isWindows) {
        // Windows uchun avtomatik (silent) o'rnatish
        // /VERYSILENT va /SUPPRESSMSGBOXES - Inno Setup uchun standart bayroqlar
        // /S - NSIS installeri uchun standart bayroq
        await Process.start(file.path, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/SP-', '/NOCANCEL', '/NORESTART']);
        
        // Installer ishga tushishi uchun biroz kutamiz va ilovani yopamiz
        await Future.delayed(const Duration(seconds: 1));
        exit(0); 
      } else {
        // Boshqa platformalar (Android va h.k.) uchun faylni ochish
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print("Yuklab olish yoki o'rnatishda xatolik: $e");
      rethrow;
    }
  }

  static Future<void> openDownloadPage(String url) async {
    final fullUrl = url.startsWith('http') ? url : "$_activationServerUrl$url";
    if (await canLaunchUrl(Uri.parse(fullUrl))) {
      await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    }
  }
}
