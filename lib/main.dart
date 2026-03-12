import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_state.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/pos_screen.dart';
import 'ui/screens/warehouse_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/catalog_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/screens/employee_screen.dart';
import 'ui/screens/sales_history_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/trash_screen.dart';
import 'ui/screens/activation_screen.dart';
import 'models/models.dart';

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
          background: const Color(0xFFF1F5F9),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
        ),
      ),
      home: const InitializationWrapper(),
    );
  }
}

class InitializationWrapper extends StatelessWidget {
  const InitializationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    if (!state.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }
    
    if (state.isMaster == null) {
      return const SetupScreen();
    }
    
    if (state.isMaster == true && !state.isActivated) {
      return const ActivationScreen();
    }

    if (state.isMaster == true && state.isBlocked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Litsenziya bloklangan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ushbu terminal administrator tomonidan bloklangan. Iltimos, to\'lov yoki boshqa masalalar bo\'yicha administratorga murojaat qiling.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => state.checkBlockingStatus(),
                child: const Text('Qayta tekshirish'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.currentUser == null) {
      return const LoginScreen();
    }
    
    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
    POSScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    DashboardScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    SalesHistoryScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    WarehouseScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    CatalogScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    EmployeeScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    TrashScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
    SettingsScreen(onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: 250,
        child: _buildSidebar(false),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;
          final isMedium = constraints.maxWidth >= 700 && constraints.maxWidth < 1200;
          
          // Disable permanent sidebar everywhere, just like POS
          const bool showPermanentSidebar = false;

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showPermanentSidebar) _buildSidebar(isMedium),
                    if (showPermanentSidebar) const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFF1F5F9)),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSmall) _buildBottomNav(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(bool slim) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: slim ? 80 : 250,
      color: Colors.white,
      child: Column(
        children: [
          _buildLogo(slim),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Sotuv', slim),
                _buildNavItem(1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Dashboard', slim),
                _buildNavItem(2, Icons.history_rounded, Icons.history_rounded, 'Sotuvlar Tarixi', slim),
                _buildNavItem(3, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Ombor', slim),
                _buildNavItem(4, Icons.category_outlined, Icons.category_rounded, 'Katalog', slim),
                _buildNavItem(5, Icons.people_outline, Icons.people_rounded, 'Hodimlar', slim),
                _buildNavItem(6, Icons.delete_outline_rounded, Icons.delete_rounded, 'Savat', slim),
                _buildNavItem(7, Icons.settings_outlined, Icons.settings_rounded, 'Sozlamalar', slim),
              ],
            ),
          ),
          _buildUserAvatar(slim),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart_rounded), label: 'Sotuv'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), activeIcon: Icon(Icons.history_rounded), label: 'Tarix'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2_rounded), label: 'Ombor'),
          BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category_rounded), label: 'Kat'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people_rounded), label: 'Hodim'),
          BottomNavigationBarItem(icon: Icon(Icons.delete_outline_rounded), activeIcon: Icon(Icons.delete_rounded), label: 'Savat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Soz'),
        ],
      ),
    );
  }

  Widget _buildLogo(bool slim) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
          ),
          if (!slim) const SizedBox(width: 12),
          if (!slim)
            const Text(
              'SimpleSale',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool slim) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: slim ? 0 : 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: slim ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade500,
                size: 24,
              ),
              if (!slim) const SizedBox(width: 16),
              if (!slim)
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade600,
                    ),
                  ),
                ),
              if (!slim && isSelected)
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(bool slim) {
    final state = context.watch<AppState>();
    final user = state.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
          padding: EdgeInsets.all(slim ? 8 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(
                  user?.name[0].toUpperCase() ?? '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                ),
              ),
              if (!slim) const SizedBox(width: 12),
              if (!slim)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user?.name ?? 'Tizimda yo\'q', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(user?.role == UserRole.admin ? 'Administrator' : 'Kassir', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              if (!slim) 
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 18),
                  onPressed: () => state.logout(),
                ),
            ],
          ),
        ),
      );
  }
}
