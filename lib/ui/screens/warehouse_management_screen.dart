import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class WarehouseManagementScreen extends StatelessWidget {
  const WarehouseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Text('Omborlar Boshqaruvi', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: state.warehouses.length,
        itemBuilder: (context, index) {
          final warehouse = state.warehouses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.warehouse_rounded, color: Colors.orange),
              ),
              title: Text(warehouse.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('ID: ${warehouse.id.substring(0, warehouse.id.length < 8 ? warehouse.id.length : 8)}${warehouse.id.length > 8 ? "..." : ""}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showWarehouseDialog(context, state, warehouse: warehouse),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, state, warehouse),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWarehouseDialog(context, state),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yangi Ombor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showWarehouseDialog(BuildContext context, AppState state, {Warehouse? warehouse}) {
    final nameController = TextEditingController(text: warehouse?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(warehouse == null ? 'Yangi Ombor' : 'Omborni Tahrirlash', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Ombor nomi',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (warehouse == null) {
                  state.addWarehouse(nameController.text);
                } else {
                  state.updateWarehouse(warehouse.id, nameController.text);
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

  void _confirmDelete(BuildContext context, AppState state, Warehouse warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('"${warehouse.name}" omborini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () {
              state.deleteWarehouse(warehouse.id);
              Navigator.pop(context);
            },
            child: const Text('O\'chirish', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
