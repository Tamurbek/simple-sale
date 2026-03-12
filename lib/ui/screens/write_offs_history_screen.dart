import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class WriteOffsHistoryScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  const WriteOffsHistoryScreen({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Text('Hisobdan Chiqarishlar'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        leading: onMenuPressed != null ? IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: onMenuPressed,
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.redAccent),
            onPressed: () => _showWriteOffDialog(context, state),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.writeOffs.isEmpty 
        ? const Center(child: Text('Hisobdan chiqarishlar mavjud emas', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.writeOffs.length,
            itemBuilder: (context, index) {
              final wo = state.writeOffs[index];
              return _buildLogCard(
                context,
                state,
                'Hisobdan chiqarish #${wo.id.substring(0, 8)}', 
                wo.date.toString().substring(0, 16), 
                wo.items.length.toString(), 
                Colors.redAccent, 
                [
                  if (wo.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Sababi: ${wo.description}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ...wo.items.map((i) => ListTile(
                    title: Text(i.productName), 
                    trailing: Text('-${i.quantity}'),
                  )).toList(),
                ],
                onDelete: () => _confirmDelete(context, 'Hisobdan chiqarishni bekor qilmoqchimisiz?', () => state.deleteWriteOff(wo.id)),
              );
            },
          ),
    );
  }

  Widget _buildLogCard(BuildContext context, AppState state, String title, String subtitle, String count, Color color, List<Widget> items, {VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.remove_circle_outline, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count ta tur', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
        children: items,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String message, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yo\'q')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              await action();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ha, bekor qilinsin'),
          ),
        ],
      ),
    );
  }

  void _showWriteOffDialog(BuildContext context, AppState state) {
    final List<Map<String, dynamic>> items = [];
    final descCtrl = TextEditingController();
    String? woWarehouseId = state.warehouses.isNotEmpty ? state.warehouses.first.id : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hisobdan Chiqarish (Spisaniye)'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: woWarehouseId,
                    decoration: const InputDecoration(labelText: 'Qaysi ombordan?', border: OutlineInputBorder()),
                    items: state.warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                    onChanged: (val) => setDialogState(() => woWarehouseId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Sababi', border: OutlineInputBorder())),
                  const Divider(height: 32),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: item['productId'],
                              items: state.activeProducts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                              onChanged: (val) {
                                final p = state.activeProducts.firstWhere((p) => p.id == val);
                                setDialogState(() {
                                  items[idx]['productId'] = val;
                                  items[idx]['productName'] = p.name;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: TextField(decoration: const InputDecoration(hintText: 'Soni'), keyboardType: TextInputType.number, onChanged: (v) => items[idx]['quantity'] = double.tryParse(v) ?? 0)),
                          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setDialogState(() => items.removeAt(idx))),
                        ],
                      ),
                    );
                  }).toList(),
                  TextButton.icon(onPressed: () => setDialogState(() => items.add({'productId': null, 'productName': '', 'quantity': 0.0})), icon: const Icon(Icons.add), label: const Text('Mahsulot qo\'shish')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                if (items.isNotEmpty && woWarehouseId != null) {
                  final wo = WriteOff(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    warehouseId: woWarehouseId!,
                    description: descCtrl.text,
                    items: items.where((i) => i['productId'] != null).map((i) => WriteOffItem(productId: i['productId'], productName: i['productName'], quantity: i['quantity'])).toList(),
                  );
                  state.addWriteOff(wo);
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
