import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../services/print_service.dart';
import '../../models/models.dart';
import 'checkout_screen.dart';

class POSScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const POSScreen({super.key, this.onMenuPressed});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  String selectedCategory = 'Barchasi';
  final FocusNode _focusNode = FocusNode();
  String _barcodeBuffer = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showKeyboard = false;
  bool _isScanMode = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    _searchFocusNode.addListener(() {
      if (_isScanMode && !_searchFocusNode.hasFocus) {
        // Short delay to avoid focus fighting and ensure it returns
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_isScanMode && mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showQuantityDialog(BuildContext context, AppState state, SaleItem item) {
    final product = state.products.where((p) => p.id == item.productId).firstOrNull;
    final unit = product?.unit ?? 'dona';
    final initialValue = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    final controller = TextEditingController(text: initialValue);

    void saveContent() {
      final text = controller.text.replaceAll(',', '.');
      final newQty = double.tryParse(text) ?? 0;
      try {
        state.updateCartQuantity(item.productId, newQty);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${item.productName} - Miqdorni kiring (${unit})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => saveContent(),
              decoration: InputDecoration(
                labelText: 'Miqdor',
                suffixText: unit,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: saveContent,
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  bool _isCaps = true;

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'back') {
        if (_searchController.text.isNotEmpty) {
          _searchController.text = _searchController.text.substring(0, _searchController.text.length - 1);
        }
      } else if (key == 'space') {
        _searchController.text += ' ';
      } else if (key == 'caps') {
        _isCaps = !_isCaps;
      } else if (key == 'clear') {
        _searchController.clear();
      } else if (key == 'enter') {
        _showKeyboard = false;
        _focusNode.requestFocus(); // Return focus to physical scanner
      } else {
        _searchController.text += _isCaps ? key.toUpperCase() : key.toLowerCase();
      }
    });
  }

  DateTime? _lastBarcodeTime;
  String? _lastBarcode;

  DateTime? _lastKeyEventTime;

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    
    final now = DateTime.now();
    
    // If keys are coming in slowly (>50ms between keys), it's likely manual typing.
    // Scanners are much faster.
    if (_lastKeyEventTime != null && 
        now.difference(_lastKeyEventTime!).inMilliseconds > 100) {
      _barcodeBuffer = ''; // Clear buffer if it's too slow (likely human)
    }
    _lastKeyEventTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_barcodeBuffer.isNotEmpty) {
        _processBarcode(_barcodeBuffer.trim());
        _barcodeBuffer = '';
      }
    } else {
      final char = event.character;
      if (char != null && char.isNotEmpty && RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
        _barcodeBuffer += char;
      }
    }
  }

  void _processBarcode(String barcode) {
    if (barcode.isEmpty) return;
    
    // Prevent double processing within a short time (e.g. 300ms)
    final now = DateTime.now();
    if (_lastBarcode == barcode && 
        _lastBarcodeTime != null && 
        now.difference(_lastBarcodeTime!).inMilliseconds < 500) {
      return; 
    }
    
    _lastBarcode = barcode;
    _lastBarcodeTime = now;
    
    try {
      final state = context.read<AppState>();
      state.addToCartByBarcode(barcode);
      
      final product = state.products.firstWhere(
        (p) => p.barcode == barcode || p.additionalBarcodes.contains(barcode),
        orElse: () => throw Exception('Mahsulot topilmadi'),
      );
      
      // Clear fields if we successfully added
      if (_searchController.text == barcode) {
        _searchController.clear();
      }
      _barcodeBuffer = '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} savatga qo\'shildi'),
          duration: const Duration(milliseconds: 700),
          backgroundColor: const Color(0xFF6366F1), // Using theme color
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      // If it's not a barcode, just let it be (maybe a regular enter in search)
      debugPrint('Not a valid barcode: $barcode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeCategories = state.activeCategories;
    final categories = ['Barchasi', ...activeCategories.map((c) => c.name)];
    
    final searchQuery = _searchController.text.toLowerCase();
    final filteredProducts = state.activeProducts.where((p) {
       final category = activeCategories.any((c) => c.id == p.categoryId)
           ? activeCategories.firstWhere((c) => c.id == p.categoryId)
           : null;
       final matchesCategory = selectedCategory == 'Barchasi' || (category?.name == selectedCategory);
       final matchesSearch = (p.name ?? '').toLowerCase().contains(searchQuery) || (p.barcode ?? '').contains(searchQuery);
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
                if (!isMobile) _buildCartSidebar(state, 400),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(state, isMobile),
                      _buildCategoryChips(categories),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildProductGrid(filteredProducts, state, constraints.maxWidth)),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                              child: _showKeyboard 
                                ? KeyedSubtree(
                                    key: const ValueKey('virtual_keyboard'),
                                    child: _buildVirtualKeyboard(),
                                  ) 
                                : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/icon.png', width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
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
                focusNode: _searchFocusNode,
                onChanged: (v) => setState(() {}),
                onSubmitted: (v) {
                   _processBarcode(v);
                   _searchController.clear();
                   if (_isScanMode) _searchFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'Qidirish yoki shtrix kodni o\'qing...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_outlined, color: _showKeyboard ? const Color(0xFF6366F1) : Colors.grey.shade400),
                        onPressed: () => setState(() => _showKeyboard = !_showKeyboard),
                      ),
                      IconButton(
                        icon: Icon(
                          _isScanMode ? Icons.qr_code_scanner_rounded : Icons.barcode_reader, 
                          color: _isScanMode ? const Color(0xFF6366F1) : Colors.grey.shade400
                        ),
                        onPressed: () {
                          setState(() {
                            _isScanMode = !_isScanMode;
                            if (_isScanMode) {
                              _searchFocusNode.requestFocus();
                              _showKeyboard = false;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
          if (!isMobile) const SizedBox(width: 20),
          if (!isMobile) _buildKassaInfo(state),
          if (widget.onMenuPressed != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: InkWell(
                onTap: widget.onMenuPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
                ),
              ),
            ),
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
              Text(state.currentRegister?.name ?? 'Kassa tanlanmagan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                'Ombor: ${state.currentRegister == null ? "Tanlanmagan" : (state.warehouses.any((w) => w.id == state.currentRegister?.warehouseId) ? state.warehouses.firstWhere((w) => w.id == state.currentRegister?.warehouseId).name : (state.warehouses.isNotEmpty ? state.warehouses.first.name : "Noma\'lum"))}',
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
      onTap: () {
        try {
          state.addToCart(product);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      },
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
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: product.imagePath != null
                      ? DecorationImage(image: FileImage(File(product.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imagePath == null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            state.categories.any((c) => c.id == product.categoryId && c.name == 'Ichimliklar')
                                ? Icons.local_drink_rounded
                                : Icons.restaurant_rounded,
                            size: 40,
                            color: const Color(0xFF6366F1).withOpacity(0.5),
                          ),
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
                        child: Text(
                          '${stock % 1 == 0 ? stock.toInt() : stock.toStringAsFixed(1)} ${product.unit}', 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLowStock ? Colors.red : Colors.green)
                        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade100),
                  image: product?.imagePath != null ? DecorationImage(image: FileImage(File(product!.imagePath!)), fit: BoxFit.cover) : null,
                ),
                child: product?.imagePath == null ? const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF6366F1)) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${item.price.toStringAsFixed(0)} so\'m', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text('${item.subtotal.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => state.removeFromCart(item.productId),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Row(
                children: [
                  _buildQtyBtn(Icons.remove, () {
                    try {
                      state.decrementInCart(item.productId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                      );
                    }
                  }, color: Colors.red.shade50, iconColor: Colors.red),
                  InkWell(
                    onTap: () => _showQuantityDialog(context, state, item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(3), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ),
                  ),
                  _buildQtyBtn(Icons.add, () {
                    if (product != null) {
                      try {
                        state.addToCart(product);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }, color: Colors.green.shade50, iconColor: Colors.green),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {Color? color, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: iconColor ?? Colors.black87),
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

  void _handlePayment(AppState state) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  Widget _buildVirtualKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showKeyboard = false),
                  icon: const Icon(Icons.expand_more_rounded, size: 20, color: Colors.grey),
                  label: const Text('Yashirish', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: () => _onKeyTap('clear'),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.redAccent),
                  label: const Text('Tozalash', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Row 1: Numbers
          _buildKeyRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'back'], rowFlex: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.8]),
          const SizedBox(height: 8),
          // Row 2: QWERTY (Staggered by padding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildKeyRow(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']),
          ),
          const SizedBox(height: 8),
          // Row 3: ASDF (Caps + Enter)
          _buildKeyRow(['caps', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'enter'], rowFlex: [1.4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.8]),
          const SizedBox(height: 8),
          // Row 4: ZXCV (Space)
          _buildKeyRow(['z', 'x', 'c', 'v', 'b', 'n', 'm', '.', ',', 'space'], rowFlex: [1, 1, 1, 1, 1, 1, 1, 1, 1, 4.0]),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, {List<double>? rowFlex}) {
    return Row(
      children: keys.asMap().entries.map((entry) {
        final idx = entry.key;
        final k = entry.value;
        final flex = rowFlex != null ? (rowFlex[idx] * 100).toInt() : 100;
        return Expanded(
          flex: flex,
          child: _buildVirtualKey(k),
        );
      }).toList(),
    );
  }

  Widget _buildVirtualKey(String k) {
    final isBack = k == 'back';
    final isEnter = k == 'enter';
    final isSpace = k == 'space';
    final isCaps = k == 'caps';
    
    final Color bgColor;
    final Color textColor;
    Widget labelWidget;

    if (isEnter) {
      bgColor = const Color(0xFF6366F1);
      textColor = Colors.white;
      labelWidget = const Icon(Icons.keyboard_return_rounded, color: Colors.white, size: 20);
    } else if (isBack) {
      bgColor = const Color(0xFFE2E8F0);
      textColor = Colors.black87;
      labelWidget = const Icon(Icons.backspace_outlined, size: 18);
    } else if (isCaps) {
      bgColor = _isCaps ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0);
      textColor = _isCaps ? Colors.white : Colors.black87;
      labelWidget = Text('ABC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor));
    } else if (isSpace) {
      bgColor = Colors.white;
      textColor = Colors.black54;
      labelWidget = const Text('Bo\'shliq', style: TextStyle(fontSize: 14));
    } else {
      bgColor = Colors.white;
      textColor = Colors.black87;
      labelWidget = Text(
        _isCaps ? k.toUpperCase() : k.toLowerCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      );
    }

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        elevation: (isEnter || isSpace) ? 2 : 1,
        shadowColor: Colors.black.withOpacity(0.2),
        child: InkWell(
          onTap: () => _onKeyTap(k),
          borderRadius: BorderRadius.circular(10),
          child: Center(child: labelWidget),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey)));
  Widget _buildEmptyCart() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shopping_cart_outlined, size: 60, color: Color(0xFFE2E8F0)), const SizedBox(height: 16), Text('Savat bo\'sh', style: TextStyle(color: Colors.grey.shade400))]));
}
