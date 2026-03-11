import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
                      Text(
                        '${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(product.price)} s',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
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
              Text(
                '${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(state.cartTotal)} so\'m',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
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
    final total = state.cartTotal;
    final fmt = NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0);
    
    String paymentMethod = 'Naqd';
    final TextEditingController receivedController = TextEditingController(text: total.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final received = double.tryParse(receivedController.text) ?? 0;
            final change = received - total;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Center(child: Text('To\'lovni Yakunlash', style: TextStyle(fontWeight: FontWeight.w900))),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jami To\'lov:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${fmt.format(total)} so\'m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: Text('To\'lov turi:', style: TextStyle(fontWeight: FontWeight.bold))),
                    Row(
                      children: [
                        _buildMethodButton('Naqd', Icons.payments_rounded, paymentMethod, (m) => setDialogState(() => paymentMethod = m)),
                        const SizedBox(width: 12),
                        _buildMethodButton('Plastik', Icons.credit_card_rounded, paymentMethod, (m) => setDialogState(() => paymentMethod = m)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: receivedController,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Olingan summa',
                        prefixIcon: const Icon(Icons.money_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (paymentMethod == 'Naqd' && change > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Qaytim:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${fmt.format(change)} so\'m', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green)),
                        ],
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.all(20),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor Qilish')),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    _executeSale(state);
                  },
                  child: const Text('TASDIQLASH', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      }
    );
  }

  Widget _buildMethodButton(String method, IconData icon, String selected, Function(String) onSelect) {
    final isSelected = selected == method;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6366F1)),
              const SizedBox(height: 8),
              Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeSale(AppState state) async {
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
      if (mounted) {
        Navigator.pop(context); // close loader
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Sotuv yakunlandi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ombor yangilandi va chek chiqarildi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Davom Etish', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey)));
  Widget _buildEmptyCart() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 60, color: Color(0xFFE2E8F0)), const SizedBox(height: 16), Text('Savat bo\'sh', style: TextStyle(color: Colors.grey.shade400))]));
}
