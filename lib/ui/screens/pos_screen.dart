import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/print_service.dart';
import '../../models/models.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  String selectedCategory = 'Barchasi';
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_focusNode.hasFocus) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processBarcode(_barcodeBuffer.trim());
          _barcodeBuffer = '';
        }
      } else {
        final char = event.character;
        if (char != null && char.isNotEmpty) {
          _barcodeBuffer += char;
        }
      }
    }
  }

  void _processBarcode(String barcode) {
    try {
      context.read<AppState>().addToCartByBarcode(barcode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mahsulot topilmadi: $barcode'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = ['Barchasi', ...state.categories.map((c) => c.name)];
    
    final searchQuery = _searchController.text.toLowerCase();
    final filteredProducts = state.products.where((p) {
       final category = state.categories.firstWhere((c) => c.id == p.categoryId, orElse: () => Category(id: '', name: ''));
       final matchesCategory = selectedCategory == 'Barchasi' || category.name == selectedCategory;
       final matchesSearch = p.name.toLowerCase().contains(searchQuery) || p.barcode.contains(searchQuery);
       return matchesCategory && matchesSearch;
    }).toList();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(state, isMobile),
                      _buildCategoryChips(categories),
                      Expanded(
                        child: _buildProductGrid(filteredProducts, state, constraints.maxWidth),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) _buildCartSidebar(state, 400),
              ],
            ),
            floatingActionButton: isMobile && state.cart.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: () => _showMobileCart(context, state),
                    backgroundColor: const Color(0xFF6366F1),
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      'Savat (${state.cart.length})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildTopBar(AppState state, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Qidirish...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
          if (!isMobile) const SizedBox(width: 20),
          if (!isMobile) _buildKassaInfo(state),
        ],
      ),
    );
  }

  Widget _buildKassaInfo(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, color: Color(0xFF6366F1), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.currentRegister?.name ?? 'Kassa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                'Ombor: ${state.warehouses.firstWhere((w) => w.id == state.currentRegister?.warehouseId, orElse: () => state.warehouses.first).name}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 10),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, AppState state, double width) {
    if (products.isEmpty) return _buildEmptyState();
    
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: width < 600 ? 180 : 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 260,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index], state),
    );
  }

  Widget _buildProductCard(Product product, AppState state) {
    final stock = product.stocks[state.currentRegister?.warehouseId] ?? 0;
    final isLowStock = stock <= 0;

    return InkWell(
      onTap: () => state.addToCart(product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: product.imagePath != null
                      ? DecorationImage(image: FileImage(File(product.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imagePath == null
                    ? Center(
                        child: Icon(
                          state.categories.firstWhere((c) => c.id == product.categoryId, orElse: () => Category(id: '', name: '')).name == 'Ichimliklar'
                              ? Icons.local_drink
                              : Icons.restaurant,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${product.price.toStringAsFixed(0)} so\'m', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isLowStock ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text('$stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSidebar(AppState state, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(-5, 0))],
      ),
      child: Column(
        children: [
          _buildCartHeader(state),
          Expanded(
            child: state.cart.isEmpty ? _buildEmptyCart() : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.cart.length,
              itemBuilder: (context, index) => _buildCartItem(state.cart[index], state),
            ),
          ),
          _buildCartFooter(state),
        ],
      ),
    );
  }

  Widget _buildCartHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Expanded(child: Text('Savat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
          if (state.cart.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent), onPressed: () => state.clearCart()),
        ],
      ),
    );
  }

  Widget _buildCartItem(SaleItem item, AppState state) {
    final product = state.products.where((p) => p.id == item.productId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              image: product?.imagePath != null
                  ? DecorationImage(image: FileImage(File(product!.imagePath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: product?.imagePath == null
                ? const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${item.price.toStringAsFixed(0)} x ${item.quantity.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${item.subtotal.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            onPressed: () => state.removeFromCart(item.productId),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jami:', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text('${state.cartTotal.toStringAsFixed(0)} so\'m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: state.cart.isEmpty ? null : () => _handlePayment(state),
              child: const Text('TOLOVNI YAKUNLASH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileCart(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(child: _buildCartSidebar(state, double.infinity)),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment(AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await PrintService.printReceipt(
        items: state.cart,
        total: state.cartTotal,
        registerName: state.currentRegister?.name ?? 'Kassa',
        printerName: state.selectedPrinterName,
      );
      await state.processSale();
      if (mounted) Navigator.pop(context); // close loader
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatoli: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildEmptyState() => const Center(child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey)));
  Widget _buildEmptyCart() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 60, color: Color(0xFFE2E8F0)), const SizedBox(height: 16), Text('Savat bo\'sh', style: TextStyle(color: Colors.grey.shade400))]));
}
