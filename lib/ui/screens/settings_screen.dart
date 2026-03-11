import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'terminal_management_screen.dart';
import 'warehouse_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  const SettingsScreen({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSection(
                  context,
                  'Asosiy Sozlamalar',
                  'Kassa va unga bog\'langan omborlarni sozlash',
                  [
                    _buildSettingsTile(
                      icon: Icons.storefront,
                      color: Colors.blue,
                      title: 'Joriy Kassa',
                      subtitle: state.currentRegister?.name ?? 'Tanlanmagan',
                      onTap: () => _showRegisterPicker(context, state),
                    ),
                    _buildSettingsTile(
                      icon: Icons.terminal_rounded,
                      color: Colors.indigo,
                      title: 'Kassa Terminallari',
                      subtitle: 'Terminallarni qo\'shish va tahrirlash',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TerminalManagementScreen())),
                    ),
                    _buildSettingsTile(
                      icon: Icons.warehouse_rounded,
                      color: Colors.orange,
                      title: 'Omborlar',
                      subtitle: 'Omborlarni qo\'shish va tahrirlash',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WarehouseManagementScreen())),
                    ),
                  ],
                ),
                if (state.isMaster == false) ...[
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Ma\'lumotlar almashinuvi',
                    'Asosiy server bilan bog\'lanish',
                    [
                      _buildSettingsTile(
                        icon: Icons.sync,
                        color: const Color(0xFF6366F1),
                        title: 'Sinxronizatsiya',
                        subtitle: 'Asosiy kompyuterdan bazani yangilash',
                        onTap: () async {
                           try {
                             await state.syncWithMaster();
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Ma\'lumotlar muvaffaqiyatli yangilandi')),
                               );
                             }
                           } catch (e) {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
                               );
                             }
                           }
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.lan,
                        color: Colors.blueGrey,
                        title: 'Server IP',
                        subtitle: state.masterAddress ?? 'Aniqlanmagan',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Apparat Ta\'minoti',
                  'Printer va skaner sozlamalari',
                  [
                    _buildSettingsTile(
                      icon: Icons.print_outlined,
                      color: Colors.teal,
                      title: 'Asosiy Printer',
                      subtitle: state.selectedPrinterName ?? 'Tizim primteri (Tanlang)',
                      onTap: () async {
                        final printers = await Printing.listPrinters();
                        if (context.mounted) {
                          _showPrinterPicker(context, state, printers);
                        }
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.qr_code_scanner,
                      color: Colors.purple,
                      title: 'Shtrix-kod Skaner',
                      subtitle: 'Skaner ishchi holatda',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Tizim Ma\'lumotlari',
                  'Dastur versiyasi va litsenziya',
                  [
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      color: Colors.grey,
                      title: 'Dastur Versiyasi',
                      subtitle: 'v1.0.4 • 2026',
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      color: Colors.redAccent,
                      title: 'Tizimdan chiqish',
                      subtitle: 'Boshqa foydalanuvchi sifatida kirish',
                      onTap: () {},
                    ),
                  ],
                ),
                if (state.isMaster == true) ...[
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    'Ma\'lumotlar xavfsizligi',
                    'Ma\'lumotlar bazasini saqlash va tiklash',
                    [
                      _buildSettingsTile(
                        icon: Icons.cloud_upload_rounded,
                        color: Colors.green,
                        title: 'Zaxira nusxasini yaratish',
                        subtitle: 'Bazani faylga yuklab olish',
                        onTap: () async {
                          await state.exportDatabase();
                        },
                      ),
                      _buildSettingsTile(
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
                                const SnackBar(content: Text('Baza muvaffaqiyatli tiklandi!')),
                              );
                            }
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sozlamalar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              Text(
                'Dasturiy va texnik sozlamalarni boshqarish',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
              onPressed: onMenuPressed,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  void _showRegisterPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kassani tanlang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              itemCount: state.registers.length,
              itemBuilder: (context, index) {
                final reg = state.registers[index];
                final isSelected = state.currentRegister?.id == reg.id;
                return ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(reg.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF6366F1)) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    try {
                      await state.setRegister(reg);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  void _showPrinterPicker(BuildContext context, AppState state, List<Printer> printers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printerni tanlang'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 350,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: printers.length,
            itemBuilder: (context, index) {
              final p = printers[index];
              return ListTile(
                leading: const Icon(Icons.print),
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
        title: const Text('Bazani tiklash'),
        content: const Text(
          'Diqqat! Yangi baza faylini tanlasangiz, hozirgi barcha ma\'lumotlaringiz (mahsulotlar, sotuvlar) o\'chiriladi va tanlangan fayl bilan almashadi. Davom etasizmi?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ha, tiklash'),
          ),
        ],
      ),
    );
  }
}
