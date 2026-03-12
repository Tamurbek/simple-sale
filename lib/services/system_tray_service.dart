import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  Future<void> init() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      await windowManager.ensureInitialized();
      
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Prevent default close behavior
      await windowManager.setPreventClose(true);
      windowManager.addListener(this);

      await initTray();
    }
  }

  Future<void> initTray() async {
    String iconPath = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/icon.png';
    
    // On Windows, tray_manager works better if we provide the path carefully
    if (Platform.isWindows) {
      // In release mode, assets are in data/flutter_assets
      // But tray_manager usually handles assets/ correctly if bundled.
      // Let's ensure we are using the correct method.
      await trayManager.setIcon(iconPath);
      await windowManager.setIcon(iconPath);
    } else {
      await trayManager.setIcon(iconPath);
    }
    
    List<MenuItem> items = [
      MenuItem(
        key: 'show_window',
        label: 'Dasturni ochish',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Dasturdan chiqish',
      ),
    ];
    await trayManager.setContextMenu(Menu(items: items));
    trayManager.addListener(this);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      exit(0);
    }
  }
}
