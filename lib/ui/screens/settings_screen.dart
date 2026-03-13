import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'terminal_management_screen.dart';
import 'warehouse_management_screen.dart';
import '../../services/update_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  const SettingsScreen({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAdmin = state.currentUser?.role == UserRole.admin;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (isAdmin)
                  _buildSection(
                    context,
                    'Asosiy Sozlamalar',
                    'Kassa va unga bog\'langan omborlarni sozlash',
                    [
                      _buildSettingsTile(
                        context,
                        icon: Icons.storefront,
                        color: Colors.blue,
                        title: 'Joriy Kassa',
                        subtitle: state.currentRegister?.name ?? 'Tanlanmagan',
                        onTap: () => _showRegisterPicker(context, state),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.terminal_rounded,
                        color: Colors.indigo,
                        title: 'Kassa Terminallari',
                        subtitle: 'Terminallarni qo\'shish va tahrirlash',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TerminalManagementScreen(),
                          ),
                        ),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.warehouse_rounded,
                        color: Colors.orange,
                        title: 'Omborlar',
                        subtitle: 'Omborlarni qo\'shish va tahrirlash',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WarehouseManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (isAdmin && state.isMaster == false) ...[
                  SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Ma\'lumotlar almashinuvi',
                    'Asosiy server bilan bog\'lanish',
                    [
                      _buildSettingsTile(
                        context,
                        icon: Icons.sync,
                        color: Theme.of(context).colorScheme.primary,
                        title: 'Sinxronizatsiya',
                        subtitle: 'Asosiy kompyuterdan bazani yangilash',
                        onTap: () async {
                          try {
                            await state.syncWithMaster();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ma\'lumotlar muvaffaqiyatli yangilandi',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Xatolik: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.lan,
                        color: Colors.blueGrey,
                        title: 'Server IP',
                        subtitle: state.masterAddress ?? 'Aniqlanmagan',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
                if (isAdmin) SizedBox(height: 24),
                _buildSection(
                  context,
                  'Apparat Ta\'minoti',
                  'Printer va skaner sozlamalari',
                  [
                    _buildSettingsTile(
                      context,
                      icon: Icons.print_outlined,
                      color: Colors.teal,
                      title: 'Asosiy Printer',
                      subtitle:
                          state.selectedPrinterName ??
                          'Tizim primteri (Tanlang)',
                      onTap: () async {
                        final printers = await Printing.listPrinters();
                        if (context.mounted) {
                          _showPrinterPicker(context, state, printers);
                        }
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.qr_code_scanner,
                      color: Colors.purple,
                      title: 'Shtrix-kod Skaner Rejimi',
                      subtitle: state.isBarcodeScanMode
                          ? 'Avtomatik skanerlash yoqilgan'
                          : 'Skanerdan izlash o\'chiq',
                      trailing: Switch(
                        value: state.isBarcodeScanMode,
                        onChanged: (val) => state.toggleBarcodeScanMode(),
                      ),
                      onTap: () => state.toggleBarcodeScanMode(),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.wifi,
                      color: Colors.indigo,
                      title: 'Tarmoq Printeri (IP)',
                      subtitle:
                          state.networkPrinterIp != null &&
                              state.networkPrinterIp!.isNotEmpty
                          ? state.networkPrinterIp!
                          : 'Sozlanmagan',
                      onTap: () async {
                        final ip = await _showIpInputDialog(
                          context,
                          state.networkPrinterIp,
                        );
                        if (ip != null) {
                          await state.updateNetworkPrinterIp(ip);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildSection(
                  context,
                  'Tizim Ma\'lumotlari',
                  'Dastur versiyasi va litsenziya',
                  [
                    _buildSettingsTile(
                      context,
                      icon: Icons.info_outline,
                      color: Colors.grey,
                      title: 'Dastur Versiyasi',
                      subtitle: 'v${context.read<AppState>().appVersion} • 2026',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.system_update_rounded,
                      color: Colors.blue,
                      title: 'Dasturni Yangilash',
                      subtitle: 'Yangi versiyani tekshirish',
                      onTap: () => _checkUpdate(context),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.logout,
                      color: Colors.redAccent,
                      title: 'Tizimdan chiqish',
                      subtitle: 'Boshqa foydalanuvchi sifatida kirish',
                      onTap: () {},
                    ),
                  ],
                ),
                if (isAdmin && state.isMaster == true) ...[
                  SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Ma\'lumotlar xavfsizligi',
                    'Ma\'lumotlar bazasini saqlash va tiklash',
                    [
                      _buildSettingsTile(
                        context,
                        icon: Icons.cloud_upload_rounded,
                        color: Colors.green,
                        title: 'Zaxira nusxasini yaratish',
                        subtitle: 'Bazani faylga yuklab olish',
                        onTap: () async {
                          await state.exportDatabase();
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.cloud_download_rounded,
                        color: Colors.red,
                        title: 'Zaxiradan tiklash',
                        subtitle: 'Bazani tanlangan fayldan tiklash',
                        onTap: () async {
                          final confirmed = await _showConfirmRestore(context);
                          if (confirmed == true) {
                            await state.importDatabase();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Baza muvaffaqiyatli tiklandi!',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _buildSettingsTile(
                        context,
                        icon: Icons.cloud_sync_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        title: 'Bulutli zaxira (Railway)',
                        subtitle: 'Ma\'lumotlarni serverga saqlash',
                        onTap: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Zaxira yuklanmoqda...'),
                              ),
                            );
                            await state.uploadDatabaseToCloud();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Zaxira serverga yuborildi!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.settings_backup_restore_rounded,
                        color: Colors.orange,
                        title: 'Bulutdan tiklash',
                        subtitle: 'Serverdan zaxirani qaytarib olish',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Serverdan tiklash'),
                              content: Text(
                                'Bu amal hozirgi barcha ma\'lumotlarni serverdagi zaxira bilan almashtiradi. Davom etasizmi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Yo\'q'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Ha'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tiklanmoqda...'),
                                  ),
                                );
                              }
                              await state.restoreDatabaseFromCloud();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ma\'lumotlar muvaffaqiyatli tiklandi!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
                if (isAdmin) ...[
                  SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Tizimni Tozalash',
                    'Dasturni boshlang\'ich holatga qaytarish',
                    [
                      _buildSettingsTile(
                        context,
                        icon: Icons.delete_forever_rounded,
                        color: Colors.red,
                        title: 'Barcha ma\'lumotlarni o\'chirish',
                        subtitle:
                            'Dasturni tozalash va qayta o\'rnatish holatiga keltirish',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Diqqat!'),
                              content: Text(
                                'Ushbu amal barcha ma\'lumotlarni (mahsulotlar, sotuvlar, sozlamalar) butunlay o\'chirib yuboradi. Dastur qayta o\'rnatilgan holatga qaytadi. Davom etasizmi?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Yo\'q'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: Text('Ha, hammasini o\'chirish'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await state.clearAllData();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sozlamalar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Dasturiy va texnik sozlamalarni boshqarish',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onMenuPressed != null)
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              onPressed: onMenuPressed,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  void _showRegisterPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kassani tanlang',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              itemCount: state.registers.length,
              itemBuilder: (context, index) {
                final reg = state.registers[index];
                final isSelected = state.currentRegister?.id == reg.id;
                return ListTile(
                  leading: Icon(Icons.storefront),
                  title: Text(
                    reg.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    try {
                      await state.setRegister(reg);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterPicker(
    BuildContext context,
    AppState state,
    List<Printer> printers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Printerni tanlang'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 350,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: printers.length,
            itemBuilder: (context, index) {
              final p = printers[index];
              return ListTile(
                leading: Icon(Icons.print),
                title: Text(p.name),
                onTap: () {
                  state.updatePrinter(p.name);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmRestore(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bazani tiklash'),
        content: Text(
          'Diqqat! Yangi baza faylini tanlasangiz, hozirgi barcha ma\'lumotlaringiz (mahsulotlar, sotuvlar) o\'chiriladi va tanlangan fayl bilan almashadi. Davom etasizmi?',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ha, tiklash'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showIpInputDialog(BuildContext context, String? currentIp) {
    final controller = TextEditingController(text: currentIp ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tarmoq printeri IP manzili'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masalan: 192.168.1.100',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _checkUpdate(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final updateData = await UpdateService.checkUpdate();
    if (context.mounted) Navigator.pop(context); // close loader

    if (updateData != null) {
      if (context.mounted) {
        _showUpdateDialog(context, updateData['version'], updateData['url']);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sizda eng oxirgi versiya o\'rnatilgan.')),
        );
      }
    }
  }

  void _showUpdateDialog(BuildContext context, String version, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi versiya mavjud'),
        content: Text('Simple Sale v$version mavjud. Yuklab olishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keyinroq'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UpdateService.openDownloadPage(url);
            },
            child: const Text('Yuklab olish'),
          ),
        ],
      ),
    );
  }
}
