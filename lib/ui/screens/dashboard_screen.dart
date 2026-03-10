import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          if (width > 600)
            const Chip(
              label: Text('Bugun: 10 Mart, 2026'),
              avatar: Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
              backgroundColor: Color(0xFFF8FAFC),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(AppState state, double width) {
    int crossAxisCount = width < 600 ? 1 : width < 1200 ? 2 : 4;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard('Bugungi Savdo', '1,240,000 so\'m', Icons.payments_outlined, Colors.green, '+12%'),
        _buildStatCard('Cheklar soni', '48 ta', Icons.receipt_long_outlined, Colors.blue, '+5%'),
        _buildStatCard('O\'rtacha chek', '25,800 so\'m', Icons.analytics_outlined, Colors.orange, '-2%'),
        _buildStatCard('Mijozlar', '36 ta', Icons.people_outline, Colors.purple, '+8%'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    final isPositive = trend.startsWith('+');
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
                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
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
          for (int i = 0; i < 5; i++)
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
                        Text('Sale #102$i', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('21:0$i', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Text('45,000 so\'m', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Mahsulotlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          for (int i = 0; i < (state.products.length > 4 ? 4 : state.products.length); i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(state.products[i].name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${(80 - i * 10)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (80 - i * 15) / 100,
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
