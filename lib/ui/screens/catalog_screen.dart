import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Katalog', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Text('Mahsulotlar va turlarni boshqarish', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _tabController.index == 0 ? _showProductDialog(null) : _showCategoryDialog(null),
            icon: const Icon(Icons.add),
            label: isNarrow ? const Text('Qo\'shish') : Text(_tabController.index == 0 ? 'Yangi mahsulot' : 'Yangi tur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
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
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            final category = state.categories.firstWhere((c) => c.id == product.categoryId, orElse: () => Category(id: '', name: ''));
            return _buildItemCard(
              title: product.name,
              subtitle: '${category.name} • ${product.barcode}',
              trailing: '${product.price.toStringAsFixed(0)} so\'m',
              onEdit: () => _showProductDialog(product),
              onDelete: () => state.deleteProduct(product.id),
              isNarrow: isNarrow,
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(bool isNarrow) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: state.categories.length,
          itemBuilder: (context, index) {
            final category = state.categories[index];
            final count = state.products.where((p) => p.categoryId == category.id).length;
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366F1), size: 20),
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
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Kategoriya nomi')),
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

  void _showProductDialog(Product? product) {
    final state = context.read<AppState>();
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    String? selectedCatId = product?.categoryId ?? (state.categories.isNotEmpty ? state.categories.first.id : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Yangi mahsulot' : 'Mahsulotni tahrirlash'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Mahsulot nomi')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Narxi (so\'m)'), keyboardType: TextInputType.number),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Shtrix-kod')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: state.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCatId = val),
                  decoration: const InputDecoration(labelText: 'Kategoriya'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty && selectedCatId != null) {
                  if (product == null) {
                    final newProduct = Product.create(nameCtrl.text, double.parse(priceCtrl.text), selectedCatId!, barcodeCtrl.text);
                    state.addProduct(newProduct);
                  } else {
                    final updated = product.copyWith(
                      name: nameCtrl.text,
                      price: double.parse(priceCtrl.text),
                      categoryId: selectedCatId,
                      barcode: barcodeCtrl.text,
                    );
                    state.updateProduct(updated);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
