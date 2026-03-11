import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class SalesHistoryScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const SalesHistoryScreen({super.key, this.onMenuPressed});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTimeRange? _dateRange;
  String? _selectedRegisterId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    final filteredSales = state.sales.where((s) {
      // Date filter
      bool matchesDate = true;
      if (_dateRange != null) {
        final date = DateTime(s.date.year, s.date.month, s.date.day);
        matchesDate = (date.isAtSameMomentAs(_dateRange!.start) || date.isAfter(_dateRange!.start)) &&
                     (date.isAtSameMomentAs(_dateRange!.end) || date.isBefore(_dateRange!.end));
      }

      // Register filter
      bool matchesRegister = true;
      if (_selectedRegisterId != null) {
        matchesRegister = s.registerId == _selectedRegisterId;
      }

      return matchesDate && matchesRegister;
    }).toList();

    final totalAmount = filteredSales.fold<double>(0, (sum, item) => sum + item.total);

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          _buildHeader(state),
          if (filteredSales.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jami savdo:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        '${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(totalAmount)} so\'m',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredSales.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredSales.length,
                  itemBuilder: (context, index) {
                    final sale = filteredSales[index];
                    return _buildSaleCard(sale, state);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sotuvlar Tarixi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  Text('Barcha amalga oshirilgan savdolarni ko\'rish va filtrlash', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
              if (widget.onMenuPressed != null)
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
                  onPressed: widget.onMenuPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildFilterButton()),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _selectedRegisterId != null ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedRegisterId != null ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.grey.shade100),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRegisterId,
                      hint: const Text('Kassa bo\'yicha', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      isExpanded: true,
                      onChanged: (val) => setState(() => _selectedRegisterId = val),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Barcha kassalar', style: TextStyle(fontSize: 13))),
                        ...state.registers.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name, style: const TextStyle(fontSize: 13)),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildSaleCard(Sale sale, AppState state) {
    final registerName = state.registers.where((r) => r.id == sale.registerId).firstOrNull?.name ?? 'Kassa';
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
        subtitle: Text('${DateFormat('dd.MM.yyyy, HH:mm').format(sale.date)} • $registerName', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        trailing: Text('${sale.total.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
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
                    Text('${sale.total.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF6366F1))),
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
