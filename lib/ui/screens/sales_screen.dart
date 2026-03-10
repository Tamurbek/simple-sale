import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'pos_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6366F1),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Yangi Sotuv', icon: Icon(Icons.add_shopping_cart)),
              Tab(text: 'Sotuvlar Tarixi', icon: Icon(Icons.history_rounded)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const POSScreen(),
              _buildSalesHistory(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesHistory(BuildContext context) {
    final state = context.watch<AppState>();
    
    // Filter sales by date range
    final filteredSales = _dateRange == null 
      ? state.sales 
      : state.sales.where((s) {
          final date = DateTime(s.date.year, s.date.month, s.date.day);
          return date.isAtSameMomentAs(_dateRange!.start) || 
                 date.isAtSameMomentAs(_dateRange!.end) ||
                 (date.isAfter(_dateRange!.start) && date.isBefore(_dateRange!.end));
        }).toList();

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: filteredSales.isEmpty 
            ? const Center(child: Text('Sotuvlar topilmadi'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                itemCount: filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = filteredSales[index];
                  return _buildSaleCard(sale);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                _dateRange == null 
                  ? 'Barcha vaqtlar' 
                  : '${_formatDateShort(_dateRange!.start)} - ${_formatDateShort(_dateRange!.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          Row(
            children: [
              if (_dateRange != null)
                TextButton(
                  onPressed: () => setState(() => _dateRange = null),
                  child: const Text('Tozalash', style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF6366F1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
      setState(() => _dateRange = picked);
    }
  }

  Widget _buildSaleCard(Sale sale) {
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
          child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF6366F1)),
        ),
        title: Text('${sale.total.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_formatDate(sale.date)} • ${sale.items.length} ta mahsulot'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.productName)),
                      Text('${item.quantity.toStringAsFixed(0)} x ${item.price.toStringAsFixed(0)} = ${item.subtotal.toStringAsFixed(0)} so\'m'),
                    ],
                  ),
                )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jami:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${sale.total.toStringAsFixed(0)} so\'m', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
