import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  const DashboardScreen({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        return Container(
          color: const Color(0xFFF1F5F9),
          child: Column(
            children: [
              _buildHeader(constraints.maxWidth),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildStatsSummary(state, constraints.maxWidth),
                    const SizedBox(height: 24),
                    if (isNarrow) ...[
                      _buildRecentSales(state),
                      const SizedBox(height: 24),
                      _buildTopProducts(state),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildRecentSales(state)),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildTopProducts(state)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/icon.png', width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Savdo va ko\'rsatkichlar tahlili',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          if (width > 600)
            Chip(
              label: Text('Bugun: ${DateFormat('dd MMMM, yyyy').format(DateTime.now())}'),
              avatar: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
              backgroundColor: const Color(0xFFF8FAFC),
            ),
          if (onMenuPressed != null) ...[
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF6366F1), size: 28),
              onPressed: onMenuPressed,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSummary(AppState state, double width) {
    int crossAxisCount = width < 600 ? 1 : width < 1200 ? 2 : 4;
    final fmt = NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard('Bugungi Savdo', '${fmt.format(state.todaySalesTotal)} so\'m', Icons.payments_outlined, Colors.green, 'Live'),
        _buildStatCard('Cheklar soni', '${state.todaySalesCount} ta', Icons.receipt_long_outlined, Colors.blue, 'Live'),
        _buildStatCard('O\'rtacha chek', '${fmt.format(state.averageCheck)} so\'m', Icons.analytics_outlined, Colors.orange, 'Live'),
        _buildStatCard('Mahsulotlar', '${state.products.length} turda', Icons.inventory_2_outlined, Colors.purple, 'Baza'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String status) {
    final isBaza = status == 'Baza';
    final statusColor = isBaza ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildRecentSales(AppState state) {
    final recentSales = state.sales.take(5).toList();
    final fmt = NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Oxirgi Sotuvlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_rounded, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Hozircha sotuvlar yo\'q', style: TextStyle(color: Colors.grey))),
            )
          else
            for (var sale in recentSales)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sotuv #${sale.id.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(DateFormat('HH:mm').format(sale.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('${fmt.format(sale.total)} so\'m',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(AppState state) {
    final topProducts = state.topSellingProducts;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Mahsulotlar (Bugun)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Bugun sotuv bo\'lmadi', style: TextStyle(color: Colors.grey))),
            )
          else
            for (var entry in topProducts)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${entry.value.toStringAsFixed(0)} ta', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: entry.value / (topProducts.first.value == 0 ? 1 : topProducts.first.value),
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: const Color(0xFF6366F1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
