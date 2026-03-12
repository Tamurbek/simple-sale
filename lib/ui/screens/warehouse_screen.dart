import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class WarehouseScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const WarehouseScreen({super.key, this.onMenuPressed});

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

    final filteredProducts = state.activeProducts.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(searchQuery) ||
          p.barcode.contains(searchQuery);
      return matchesSearch;
    }).toList();

    return DefaultTabController(
      length: 5,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildHeader(state, isNarrow),
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: [
                    Tab(text: 'Qoldiqlar'),
                    Tab(text: 'Kirimlar'),
                    Tab(text: 'Vazvratlar'),
                    Tab(text: 'Hisobdan chiqarish'),
                    Tab(text: 'Inventarizatsiya'),
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
                            SizedBox(height: 24),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Mahsulotlar Qoldig\'i',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          _buildWarehouseSelector(state),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: filteredProducts.isEmpty
                                          ? _buildEmptySearch()
                                          : _buildProductsList(
                                              state,
                                              filteredProducts,
                                              isNarrow,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // TAB 2: Stock History (Inputs)
                      _buildHistoryList(state),
                      // TAB 3: Returns History
                      _buildReturnsList(state),
                      // TAB 4: Write-offs History
                      _buildWriteOffsList(state),
                      // TAB 5: Inventory History
                      _buildInventoriesList(state),
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
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ombor Boshqaruvi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Mahsulot qoldiqlarini nazorat qilish',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
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
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                SizedBox(width: 16),
                _buildActionButtons(state),
              ],
              if (widget.onMenuPressed != null) ...[
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: widget.onMenuPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isNarrow) ...[
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppState state, double width) {
    final totalProducts = state.activeProducts.length;
    final lowStockCount = state.activeProducts.where((p) {
      final stock = p.stocks[selectedWarehouseId] ?? 0;
      return stock <= 5;
    }).length;

    int crossAxisCount = width < 600
        ? 1
        : width < 1000
        ? 2
        : 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          'Jami Mahsulotlar',
          totalProducts.toString(),
          Icons.inventory_2,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          'Kam qolganlar',
          lowStockCount.toString(),
          Icons.warning_amber_rounded,
          Colors.orange,
        ),
        _buildStatCard(
          'Omborlar',
          state.warehouses.length.toString(),
          Icons.warehouse,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedWarehouseId,
          items: state.warehouses
              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
              .toList(),
          onChanged: (val) => setState(() => selectedWarehouseId = val),
        ),
      ),
    );
  }

  Widget _buildProductsList(
    AppState state,
    List<Product> products,
    bool isNarrow,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 24, endIndent: 24),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  image: product.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(product.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imagePath == null
                    ? Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        size: 20,
                      )
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      state.categories
                          .firstWhere(
                            (c) => c.id == product.categoryId,
                            orElse: () => Category(id: '', name: ''),
                          )
                          .name,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
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
                      Text(
                        'Barcode',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        product.barcode,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qoldiq: ${stock.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isLow ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(product.price)} s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearch() => Center(
    child: Text('Mahsulot topilmadi', style: TextStyle(color: Colors.grey)),
  );

  Widget _buildHistoryList(AppState state) {
    if (state.stockEntries.isEmpty) {
      return Center(
        child: Text(
          'Kirim hujjatlari mavjud emas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.stockEntries.length,
      itemBuilder: (context, index) {
        final entry = state.stockEntries[index];
        final warehouse = state.warehouses.firstWhere(
          (w) => w.id == entry.warehouseId,
          orElse: () => Warehouse(id: '', name: 'Noma\'lum'),
        );

        return _buildLogCard(
          'Kirim #${entry.id.substring(0, 8)}',
          '${warehouse.name} • ${entry.date.toString().substring(0, 16)}',
          entry.items.length.toString(),
          Theme.of(context).colorScheme.primary,
          [
            if (entry.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      entry.description,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const Divider(),
            ...entry.items.map(
              (item) => ListTile(
                title: Text(item.productName),
                trailing: Text(
                  '+${item.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
          onDelete: () => _confirmDelete(
            context,
            'Kirimni bekor qilmoqchimisiz?',
            () => state.deleteStockEntry(entry.id),
          ),
        );
      },
    );
  }

  Widget _buildReturnsList(AppState state) {
    if (state.returns.isEmpty) {
      return Center(
        child: Text(
          'Vazvratlar mavjud emas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.returns.length,
      itemBuilder: (context, index) {
        final ret = state.returns[index];
        return _buildLogCard(
          'Vazvrat #${ret.id.substring(0, 8)}',
          'Sotuv #${ret.saleId.substring(0, 8)} • ${ret.date.toString().substring(0, 16)}',
          ret.items.length.toString(),
          Colors.orange,
          ret.items
              .map(
                (i) => ListTile(
                  title: Text(i.productName),
                  trailing: Text('${i.quantity} x ${i.price}'),
                ),
              )
              .toList(),
          onDelete: () => _confirmDelete(
            context,
            'Vazvratni bekor qilmoqchimisiz?',
            () => state.deleteReturn(ret.id),
          ),
        );
      },
    );
  }

  Widget _buildWriteOffsList(AppState state) {
    if (state.writeOffs.isEmpty) {
      return Center(
        child: Text(
          'Hisobdan chiqarishlar mavjud emas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.writeOffs.length,
      itemBuilder: (context, index) {
        final wo = state.writeOffs[index];
        return _buildLogCard(
          'Hisobdan chiqarish #${wo.id.substring(0, 8)}',
          wo.date.toString().substring(0, 16),
          wo.items.length.toString(),
          Colors.redAccent,
          wo.items
              .map(
                (i) => ListTile(
                  title: Text(i.productName),
                  trailing: Text('-${i.quantity}'),
                ),
              )
              .toList(),
          onDelete: () => _confirmDelete(
            context,
            'Hisobdan chiqarishni bekor qilmoqchimisiz?',
            () => state.deleteWriteOff(wo.id),
          ),
        );
      },
    );
  }

  Widget _buildInventoriesList(AppState state) {
    if (state.inventories.isEmpty) {
      return Center(
        child: Text(
          'Inventarizatsiyalar mavjud emas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.inventories.length,
      itemBuilder: (context, index) {
        final inv = state.inventories[index];
        return _buildLogCard(
          'Inventarizatsiya #${inv.id.substring(0, 8)}',
          inv.date.toString().substring(0, 16),
          inv.items.length.toString(),
          Colors.teal,
          inv.items
              .map(
                (i) => ListTile(
                  title: Text(i.productName),
                  subtitle: Text('Kutilgan: ${i.expectedQuantity}'),
                  trailing: Text(
                    'Haqiqiy: ${i.actualQuantity}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLogCard(
    String title,
    String subtitle,
    String count,
    Color color,
    List<Widget> items, {
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.description, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count ta tur',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
        children: items,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String message,
    Future<void> Function() action,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tasdiqlash'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Yo\'q'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await action();
              if (mounted) Navigator.pop(context);
            },
            child: Text('Ha, bekor qilinsin'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          'Kirim',
          Icons.add,
          Theme.of(context).colorScheme.primary,
          () => _showStockEntryDialog(state),
        ),
        _buildActionButton(
          'Vazvrat',
          Icons.settings_backup_restore_rounded,
          Colors.orange,
          () => _showReturnDialog(state),
        ),
        _buildActionButton(
          'Chiqarish',
          Icons.remove_circle_outline,
          Colors.redAccent,
          () => _showWriteOffDialog(state),
        ),
        _buildActionButton(
          'Inventar',
          Icons.fact_check_outlined,
          Colors.teal,
          () => _showInventoryDialog(state),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showReturnDialog(AppState state) {
    final List<Map<String, dynamic>> items = [];
    final saleIdCtrl = TextEditingController();
    String? returnWarehouseId = selectedWarehouseId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Mahsulot Vazvrati (Return)'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: saleIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sotuv ID (ixtiyoriy)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: returnWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Qaysi omborga qaytadi?',
                      border: OutlineInputBorder(),
                    ),
                    items: state.warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => returnWarehouseId = val),
                  ),
                  const Divider(height: 32),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: item['productId'],
                            items: state.activeProducts
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              final p = state.activeProducts.firstWhere(
                                (p) => p.id == val,
                              );
                              setDialogState(() {
                                items[idx]['productId'] = val;
                                items[idx]['productName'] = p.name;
                                items[idx]['price'] = p.price;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: const InputDecoration(hintText: 'Soni'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => items[idx]['quantity'] =
                                double.tryParse(v) ?? 0,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () =>
                              setDialogState(() => items.removeAt(idx)),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(
                      () => items.add({
                        'productId': null,
                        'productName': '',
                        'quantity': 0.0,
                        'price': 0.0,
                      }),
                    ),
                    icon: Icon(Icons.add),
                    label: Text('Qo\'shish'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Yopish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (items.isNotEmpty && returnWarehouseId != null) {
                  final ret = SaleReturn(
                    id: Uuid().v4(),
                    saleId: saleIdCtrl.text.isEmpty
                        ? 'HAND_RETURN'
                        : saleIdCtrl.text,
                    date: DateTime.now(),
                    warehouseId: returnWarehouseId!,
                    total: items.fold(
                      0,
                      (sum, i) => sum + (i['price'] * (i['quantity'] ?? 0)),
                    ),
                    items: items
                        .where((i) => i['productId'] != null)
                        .map(
                          (i) => SaleReturnItem(
                            productId: i['productId'],
                            productName: i['productName'],
                            quantity: i['quantity'],
                            price: i['price'],
                          ),
                        )
                        .toList(),
                  );
                  state.addReturn(ret);
                  Navigator.pop(context);
                }
              },
              child: Text('Vazvratni Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWriteOffDialog(AppState state) {
    final List<Map<String, dynamic>> items = [];
    final descCtrl = TextEditingController();
    String? woWarehouseId = selectedWarehouseId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Hisobdan Chiqarish (Spisaniye)'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: woWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Qaysi ombordan?',
                      border: OutlineInputBorder(),
                    ),
                    items: state.warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => woWarehouseId = val),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sababi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Divider(height: 32),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: item['productId'],
                            items: state.activeProducts
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              final p = state.activeProducts.firstWhere(
                                (p) => p.id == val,
                              );
                              setDialogState(() {
                                items[idx]['productId'] = val;
                                items[idx]['productName'] = p.name;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: const InputDecoration(hintText: 'Soni'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => items[idx]['quantity'] =
                                double.tryParse(v) ?? 0,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () =>
                              setDialogState(() => items.removeAt(idx)),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(
                      () => items.add({
                        'productId': null,
                        'productName': '',
                        'quantity': 0.0,
                      }),
                    ),
                    icon: Icon(Icons.add),
                    label: Text('Qo\'shish'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Yopish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (items.isNotEmpty && woWarehouseId != null) {
                  final wo = WriteOff(
                    id: Uuid().v4(),
                    date: DateTime.now(),
                    warehouseId: woWarehouseId!,
                    description: descCtrl.text,
                    items: items
                        .where((i) => i['productId'] != null)
                        .map(
                          (i) => WriteOffItem(
                            productId: i['productId'],
                            productName: i['productName'],
                            quantity: i['quantity'],
                          ),
                        )
                        .toList(),
                  );
                  state.addWriteOff(wo);
                  Navigator.pop(context);
                }
              },
              child: Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryDialog(AppState state) {
    final List<Map<String, dynamic>> items = [];
    String? invWarehouseId = selectedWarehouseId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Inventarizatsiya'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: invWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Ombor',
                      border: OutlineInputBorder(),
                    ),
                    items: state.warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => invWarehouseId = val),
                  ),
                  const Divider(height: 32),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: item['productId'],
                            items: state.activeProducts
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              final p = state.activeProducts.firstWhere(
                                (p) => p.id == val,
                              );
                              setDialogState(() {
                                items[idx]['productId'] = val;
                                items[idx]['productName'] = p.name;
                                items[idx]['expected'] =
                                    p.stocks[invWarehouseId] ?? 0.0;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text('E: ${item['expected'] ?? 0}')),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Haqiqiy',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) =>
                                items[idx]['actual'] = double.tryParse(v) ?? 0,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () =>
                              setDialogState(() => items.removeAt(idx)),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(
                      () => items.add({
                        'productId': null,
                        'productName': '',
                        'expected': 0.0,
                        'actual': 0.0,
                      }),
                    ),
                    icon: Icon(Icons.add),
                    label: Text('Qo\'shish'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Yopish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (items.isNotEmpty && invWarehouseId != null) {
                  final inv = InventoryEntry(
                    id: Uuid().v4(),
                    date: DateTime.now(),
                    warehouseId: invWarehouseId!,
                    items: items
                        .where((i) => i['productId'] != null)
                        .map(
                          (i) => InventoryItem(
                            productId: i['productId'],
                            productName: i['productName'],
                            expectedQuantity: i['expected'],
                            actualQuantity: i['actual'],
                          ),
                        )
                        .toList(),
                  );
                  state.addInventory(inv);
                  Navigator.pop(context);
                }
              },
              child: Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockEntryDialog(AppState state) {
    if (state.warehouses.isEmpty || state.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval ombor va mahsulotlarni kiriting!')),
      );
      return;
    }

    String? entryWarehouseId = state.warehouses.first.id;
    final List<Map<String, dynamic>> items = [];
    final descriptionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Yangi Kirim Hujjati',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: entryWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Qaysi omborga?',
                      border: OutlineInputBorder(),
                    ),
                    items: state.warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => entryWarehouseId = val),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tavsif (izoh)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  const Divider(),
                  Text(
                    'Mahsulotlar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                              hint: Text('Tanlang'),
                              items: state.activeProducts
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                final p = state.activeProducts.firstWhere(
                                  (p) => p.id == val,
                                );
                                setDialogState(() {
                                  items[idx]['productId'] = val;
                                  items[idx]['productName'] = p.name;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Soni',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) => items[idx]['quantity'] =
                                  double.tryParse(val) ?? 0,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                setDialogState(() => items.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setDialogState(
                      () => items.add({
                        'productId': null,
                        'productName': '',
                        'quantity': 0.0,
                      }),
                    ),
                    icon: Icon(Icons.add),
                    label: Text('Mahsulot qo\'shish'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Bekor qilish'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (entryWarehouseId != null && items.isNotEmpty) {
                  final finalItems = items
                      .where((i) => i['productId'] != null && i['quantity'] > 0)
                      .map(
                        (i) => StockEntryItem(
                          productId: i['productId'],
                          productName: i['productName'],
                          quantity: i['quantity'],
                        ),
                      )
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kirim hujjati saqlandi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
