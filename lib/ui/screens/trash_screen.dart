import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class TrashScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const TrashScreen({super.key, this.onMenuPressed});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: const Color(0xFFF1F5F9),
        child: Column(
          children: [
            _buildHeader(),
            const TabBar(
              labelColor: Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF6366F1),
              tabs: [
                Tab(text: 'Mahsulotlar'),
                Tab(text: 'Kategoriyalar'),
                Tab(text: 'Hodimlar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDeletedProducts(),
                  _buildDeletedCategories(),
                  _buildDeletedUsers(),
                ],
              ),
            ),
          ],
        ),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/icon.png', width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Savat (O\'chirilganlar)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  Text('O\'chirilgan ma\'lumotlarni qayta tiklash', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          if (widget.onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
              onPressed: widget.onMenuPressed,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeletedProducts() {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final products = state.deletedProducts;
        if (products.isEmpty) return _buildEmptyState('O\'chirilgan mahsulotlar yo\'q');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return _buildTrashCard(
              title: p.name,
              subtitle: 'Barcode: ${p.barcode}',
              icon: Icons.inventory_2_outlined,
              onRestore: () => state.restoreProduct(p.id),
            );
          },
        );
      },
    );
  }

  Widget _buildDeletedCategories() {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final categories = state.deletedCategories;
        if (categories.isEmpty) return _buildEmptyState('O\'chirilgan kategoriyalar yo\'q');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final c = categories[index];
            return _buildTrashCard(
              title: c.name,
              subtitle: 'ID: ${c.id.substring(0, c.id.length < 8 ? c.id.length : 8)}${c.id.length > 8 ? "..." : ""}',
              icon: Icons.category_outlined,
              onRestore: () => state.restoreCategory(c.id),
            );
          },
        );
      },
    );
  }

  Widget _buildDeletedUsers() {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final users = state.deletedUsers;
        if (users.isEmpty) return _buildEmptyState('O\'chirilgan hodimlar yo\'q');

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            return _buildTrashCard(
              title: u.name,
              subtitle: 'Role: ${u.role == UserRole.admin ? "Admin" : "Kassir"}',
              icon: Icons.person_outline,
              onRestore: () => state.restoreUser(u.id),
            );
          },
        );
      },
    );
  }

  Widget _buildTrashCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onRestore,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Tiklash'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}
