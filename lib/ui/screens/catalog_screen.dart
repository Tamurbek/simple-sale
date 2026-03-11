import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'product_form_screen.dart';
import 'dart:io';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const CatalogScreen({super.key, this.onMenuPressed});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        return Container(
          color: const Color(0xFFF1F5F9),
          child: Column(
            children: [
              _buildHeader(isNarrow),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductList(isNarrow),
                    _buildCategoryList(isNarrow),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Katalog', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text('Mahsulotlar va turlarni boshqarish', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              if (_tabController.index == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen()));
              } else {
                _showCategoryDialog(null);
              }
            },
            icon: const Icon(Icons.add),
            label: isNarrow ? const Text('Qo\'shish') : Text(_tabController.index == 0 ? 'Yangi mahsulot' : 'Yangi tur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (widget.onMenuPressed != null) ...[
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
              onPressed: widget.onMenuPressed,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6366F1),
        tabs: const [
          Tab(text: 'Mahsulotlar'),
          Tab(text: 'Kategoriyalar'),
        ],
      ),
    );
  }

  Widget _buildProductList(bool isNarrow) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final query = _searchController.text.toLowerCase();
        final filtered = state.activeProducts.where((p) => p.name.toLowerCase().contains(query) || p.barcode.contains(query)).toList();
        final fmt = NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mahsulotlarni qidirish...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final product = filtered[index];
                  final category = state.activeCategories.firstWhere((c) => c.id == product.categoryId, orElse: () => Category(id: '', name: ''));
                  return _buildItemCard(
                    title: product.name,
                    subtitle: '${category.name} • ${product.barcode}',
                    trailing: '${fmt.format(product.price)} s',
                    onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product))),
                    onDelete: () => state.deleteProduct(product.id),
                    isNarrow: isNarrow,
                    imagePath: product.imagePath,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(bool isNarrow) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final activeCategories = state.activeCategories;
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: activeCategories.length,
          itemBuilder: (context, index) {
            final category = activeCategories[index];
            final count = state.activeProducts.where((p) => p.categoryId == category.id).length;
            return _buildItemCard(
              title: category.name,
              subtitle: '$count ta mahsulot',
              trailing: '',
              onEdit: () => _showCategoryDialog(category),
              onDelete: () => state.deleteCategory(category.id),
              isNarrow: isNarrow,
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard({
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool isNarrow,
    String? imagePath,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: imagePath != null ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover) : null,
            ),
            child: imagePath == null ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366F1), size: 20) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          if (!isNarrow && trailing.isNotEmpty)
            Text(trailing, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: onDelete),
        ],
      ),
    );
  }

  void _showCategoryDialog(Category? category) {
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Yangi kategoriya' : 'Kategoriyani tahrirlash'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Kategoriya nomi')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (category == null) {
                  context.read<AppState>().addCategory(controller.text);
                } else {
                  context.read<AppState>().updateCategory(category.id, controller.text);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }
}
