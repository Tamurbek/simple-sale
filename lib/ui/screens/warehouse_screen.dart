import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'dart:io';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  String? selectedWarehouseId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.warehouses.isNotEmpty) {
      selectedWarehouseId = state.warehouses.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final searchQuery = _searchController.text.toLowerCase();

    final filteredProducts = state.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(searchQuery) || p.barcode.contains(searchQuery);
      return matchesSearch;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;
          
          return Container(
            color: const Color(0xFFF1F5F9),
            child: Column(
              children: [
                _buildHeader(state, isNarrow),
                const TabBar(
                  labelColor: Color(0xFF6366F1),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF6366F1),
                  tabs: [
                    Tab(text: 'Qoldiqlar'),
                    Tab(text: 'Kirimlar Tarixi'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: Current Stock
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildStatsRow(state, constraints.maxWidth),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Mahsulotlar Qoldig\'i', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          _buildWarehouseSelector(state),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: filteredProducts.isEmpty
                                          ? _buildEmptySearch()
                                          : _buildProductsList(state, filteredProducts, isNarrow),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // TAB 2: History
                      _buildHistoryList(state),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppState state, bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ombor Boshqaruvi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    Text('Mahsulot qoldiqlarini nazorat qilish', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (!isNarrow) ...[
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Qidirish...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showStockEntryDialog(state),
                  icon: const Icon(Icons.add),
                  label: const Text('Kirim qilish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          if (isNarrow) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppState state, double width) {
    final totalProducts = state.products.length;
    final lowStockCount = state.products.where((p) {
      final stock = p.stocks[selectedWarehouseId] ?? 0;
      return stock <= 5;
    }).length;

    int crossAxisCount = width < 600 ? 1 : width < 1000 ? 2 : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard('Jami Mahsulotlar', totalProducts.toString(), Icons.inventory_2, const Color(0xFF6366F1)),
        _buildStatCard('Kam qolganlar', lowStockCount.toString(), Icons.warning_amber_rounded, Colors.orange),
        _buildStatCard('Omborlar', state.warehouses.length.toString(), Icons.warehouse, Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelector(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedWarehouseId,
          items: state.warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
          onChanged: (val) => setState(() => selectedWarehouseId = val),
        ),
      ),
    );
  }

  Widget _buildProductsList(AppState state, List<Product> products, bool isNarrow) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
      itemBuilder: (context, index) {
        final product = products[index];
        final stock = product.stocks[selectedWarehouseId] ?? 0;
        final isLow = stock <= 5;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  image: product.imagePath != null
                      ? DecorationImage(image: FileImage(File(product.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: product.imagePath == null
                    ? const Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B), size: 20)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      state.categories.firstWhere((c) => c.id == product.categoryId, orElse: () => Category(id: '', name: '')).name,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isNarrow)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Barcode', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(product.barcode, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qoldiq: ${stock.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isLow ? Colors.red : Colors.green),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(product.price)} s',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearch() => const Center(child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey)));

  Widget _buildHistoryList(AppState state) {
    if (state.stockEntries.isEmpty) {
      return const Center(child: Text('Kirim hujjatlari mavjud emas', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.stockEntries.length,
      itemBuilder: (context, index) {
        final entry = state.stockEntries[index];
        final warehouse = state.warehouses.firstWhere((w) => w.id == entry.warehouseId, orElse: () => Warehouse(id: '', name: 'Noma\'lum'));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 20),
            ),
            title: Text('Hujjat #${entry.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${warehouse.name} • ${entry.date.toString().substring(0, 16)}'),
            trailing: Text('${entry.items.length} ta tur', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            children: [
              if (entry.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [const Icon(Icons.info_outline, size: 14, color: Colors.grey), const SizedBox(width: 8), Text(entry.description, style: const TextStyle(color: Colors.grey, fontSize: 13))]),
                ),
              const Divider(),
              ...entry.items.map((item) => ListTile(
                title: Text(item.productName),
                trailing: Text('+${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showStockEntryDialog(AppState state) {
    if (state.warehouses.isEmpty || state.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avval ombor va mahsulotlarni kiriting!')));
      return;
    }

    String? entryWarehouseId = state.warehouses.first.id;
    final List<Map<String, dynamic>> items = [];
    final descriptionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yangi Kirim Hujjati', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: entryWarehouseId,
                    decoration: const InputDecoration(labelText: 'Qaysi omborga?', border: OutlineInputBorder()),
                    items: state.warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                    onChanged: (val) => setDialogState(() => entryWarehouseId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Tavsif (izoh)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Mahsulotlar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: item['productId'],
                              hint: const Text('Tanlang'),
                              items: state.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                              onChanged: (val) {
                                final p = state.products.firstWhere((p) => p.id == val);
                                setDialogState(() {
                                  items[idx]['productId'] = val;
                                  items[idx]['productName'] = p.name;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              decoration: const InputDecoration(hintText: 'Soni'),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => items[idx]['quantity'] = double.tryParse(val) ?? 0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setDialogState(() => items.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setDialogState(() => items.add({'productId': null, 'productName': '', 'quantity': 0.0})),
                    icon: const Icon(Icons.add),
                    label: const Text('Mahsulot qo\'shish'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () {
                if (entryWarehouseId != null && items.isNotEmpty) {
                  final finalItems = items
                      .where((i) => i['productId'] != null && i['quantity'] > 0)
                      .map((i) => StockEntryItem(
                            productId: i['productId'],
                            productName: i['productName'],
                            quantity: i['quantity'],
                          ))
                      .toList();

                  if (finalItems.isNotEmpty) {
                    final entry = StockEntry(
                      id: Uuid().v4(),
                      warehouseId: entryWarehouseId!,
                      date: DateTime.now(),
                      description: descriptionCtrl.text,
                      items: finalItems,
                    );
                    state.addStockEntry(entry);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kirim hujjati saqlandi!'), backgroundColor: Colors.green));
                  }
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
