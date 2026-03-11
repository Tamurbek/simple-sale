import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    final filteredSales = _dateRange == null 
      ? state.sales 
      : state.sales.where((s) {
          final date = DateTime(s.date.year, s.date.month, s.date.day);
          return (date.isAtSameMomentAs(_dateRange!.start) || date.isAfter(_dateRange!.start)) &&
                 (date.isAtSameMomentAs(_dateRange!.end) || date.isBefore(_dateRange!.end));
        }).toList();

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: filteredSales.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredSales.length,
                  itemBuilder: (context, index) {
                    final sale = filteredSales[index];
                    return _buildSaleCard(sale);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sotuvlar Tarixi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Text('Barcha amalga oshirilgan savdolarni ko\'rish va filtrlash', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _dateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6366F1),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF1E293B),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _dateRange = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _dateRange != null ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _dateRange != null ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _dateRange != null ? const Color(0xFF6366F1) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              _dateRange == null 
                ? 'Sana bo\'yicha filter' 
                : '${DateFormat('dd.MM.yyyy').format(_dateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_dateRange!.end)}',
              style: TextStyle(
                color: _dateRange != null ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (_dateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _dateRange = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 20),
        ),
        title: Text('Sotuv #${sale.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(DateFormat('dd.MM.yyyy, HH:mm').format(sale.date), style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        trailing: Text('${sale.totalAmount.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Column(
              children: [
                for (var item in sale.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('${item.quantity} x ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${(item.quantity * item.price).toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jami:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${sale.totalAmount.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Sotuvlar topilmadi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          if (_dateRange != null)
            TextButton(onPressed: () => setState(() => _dateRange = null), child: const Text('Filtrni tozalash')),
        ],
      ),
    );
  }
}
