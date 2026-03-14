import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../services/print_service.dart';

class BarcodePrintScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialItems;
  const BarcodePrintScreen({super.key, this.initialItems});

  @override
  State<BarcodePrintScreen> createState() => _BarcodePrintScreenState();
}

class _BarcodePrintScreenState extends State<BarcodePrintScreen> {
  final List<Map<String, dynamic>> selectedItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      selectedItems.addAll(widget.initialItems!);
    }
  }

  void _addItem(Product product) {
    setState(() {
      final existingIdx = selectedItems.indexWhere((i) => i['product'].id == product.id);
      if (existingIdx >= 0) {
        selectedItems[existingIdx]['quantity'] = (selectedItems[existingIdx]['quantity'] ?? 0) + 1;
      } else {
        selectedItems.add({
          'product': product,
          'quantity': 1,
        });
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = (selectedItems[index]['quantity'] ?? 0) + delta;
      if (newQty > 0) {
        selectedItems[index]['quantity'] = newQty;
      } else {
        selectedItems.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final query = _searchController.text.toLowerCase();
    
    final filteredProducts = state.activeProducts.where((p) {
      return p.name.toLowerCase().contains(query) || p.barcode.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shtrix-kodlarni chop etish', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Selection Side
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Mahsulot qidirish...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p.barcode),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => _addItem(p),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Cart/Print Side
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chop etish uchun tanlanganlar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: selectedItems.isEmpty
                    ? const Center(child: Text('Mahsulot tanlanmagan'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = selectedItems[index];
                          final Product p = item['product'];
                          final int qty = item['quantity'];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(p.barcode, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => _updateQuantity(index, -1),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        qty.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () => _updateQuantity(index, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ElevatedButton.icon(
                      onPressed: selectedItems.isEmpty
                      ? null
                      : () => PrintService.printBarcodeLabels(
                          items: selectedItems,
                          printerName: state.barcodePrinterName,
                        ),
                      icon: const Icon(Icons.print),
                      label: const Text('BARCHASINI CHOP ETISH'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
