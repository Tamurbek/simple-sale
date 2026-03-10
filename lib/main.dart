import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_state.dart';
import 'ui/screens/pos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const SimpleSaleApp(),
    ),
  );
}

class SimpleSaleApp extends StatelessWidget {
  const SimpleSaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Sale POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: Color(0xFF6366F1)),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Kassa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Ombor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Sozlamalar'),
              ),
            ],
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt, color: Colors.white),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const POSScreen(),
                const Center(child: Text('Ombor boshqaruvi (Tez kunda...)')),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Sozlamalar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(
            context,
            'Kassa va Ombor',
            [
              ListTile(
                title: const Text('Joriy Kassa'),
                subtitle: Text(state.currentRegister?.name ?? 'Tanlanmagan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegisterPicker(context, state),
              ),
              ListTile(
                title: const Text('Bog\'langan Ombor'),
                subtitle: Text(
                  state.warehouses.firstWhere((w) => w.id == state.currentRegister?.warehouseId).name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Printer Sozlamalari',
            [
              ListTile(
                title: const Text('Asosiy Printer'),
                subtitle: Text(state.selectedPrinterName ?? 'Tizim primteri (Tanlash)'),
                trailing: const Icon(Icons.print),
                onTap: () async {
                  final printers = await Printing.listPrinters();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Printerni tanlang'),
                        content: SizedBox(
                          width: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: printers.length,
                            itemBuilder: (context, index) {
                              final p = printers[index];
                              return ListTile(
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
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  void _showRegisterPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: state.registers.length,
        itemBuilder: (context, index) {
          final reg = state.registers[index];
          return ListTile(
            title: Text(reg.name),
            subtitle: Text('Ombor: ${state.warehouses.firstWhere((w) => w.id == reg.warehouseId).name}'),
            onTap: () {
              state.setRegister(reg);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
