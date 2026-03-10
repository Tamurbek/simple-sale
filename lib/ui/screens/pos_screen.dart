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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          _processBarcode(_barcodeBuffer.trim());
          _barcodeBuffer = '';
        }
      } else {
        final char = event.character;
        if (char != null) {
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
    final categories = ['Barchasi', ...state.products.map((p) => p.category).toSet()];
    
    final filteredProducts = selectedCategory == 'Barchasi' 
      ? state.products 
      : state.products.where((p) => p.category == selectedCategory).toList();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Row(
        children: [
          // Product Section
          Expanded(
          flex: 7,
          child: Column(
            children: [
              // Header & Categories
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Mahsulot qidirish...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(state.currentRegister?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Ombor: ${state.warehouses.firstWhere((w) => w.id == state.currentRegister?.warehouseId).name}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) => setState(() => selectedCategory = cat),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final stock = product.stocks[state.currentRegister?.warehouseId] ?? 0;
                    
                    return GestureDetector(
                      onTap: () => state.addToCart(product),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('${product.price.toStringAsFixed(0)} so\'m', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Qoldiq: $stock', style: TextStyle(fontSize: 11, color: stock <= 0 ? Colors.red : Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Cart Section
        Container(
          width: 400,
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.shopping_basket),
                    SizedBox(width: 8),
                    Text('Savat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: state.cart.isEmpty 
                  ? const Center(child: Text('Savat bo\'sh'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: state.cart.length,
                      itemBuilder: (context, index) {
                        final item = state.cart[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${item.price.toStringAsFixed(0)} x ${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Text('${item.subtotal.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => state.removeFromCart(item.productId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jami:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('${state.cartTotal.toStringAsFixed(0)} so\'m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: state.cart.isEmpty ? null : () async {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            // Print
                            await PrintService.printReceipt(
                              items: state.cart,
                              total: state.cartTotal,
                              registerName: state.currentRegister?.name ?? 'Kassa',
                              printerName: state.selectedPrinterName,
                            );
                            
                            // Process stock
                            state.processSale();
                            
                            if (mounted) {
                              Navigator.pop(context); // close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Xarid muvaffaqiyatli yakunlandi va chek chiqarildi!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Xatolik: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('SOTISH VA PRINT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
