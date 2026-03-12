import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DashboardScreen({super.key, this.onMenuPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedRegisterId; // null means "All Registers"

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Filter sales by register if selected
    final filteredSales = selectedRegisterId == null
        ? state.sales
        : state.sales.where((s) => s.registerId == selectedRegisterId).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildHeader(context, state, constraints.maxWidth),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildStatsSummary(context, state, filteredSales, constraints.maxWidth),
                    SizedBox(height: 24),
                    if (isNarrow) ...[
                      _buildRecentSales(context, state, filteredSales),
                      SizedBox(height: 24),
                      _buildTopProducts(context, state, filteredSales),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRecentSales(context, state, filteredSales),
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildTopProducts(context, state, filteredSales),
                          ),
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

  Widget _buildHeader(BuildContext context, AppState state, double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                  ),
                ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Savdo va ko\'rsatkichlar tahlili',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Register Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedRegisterId,
                    hint: const Text('Barcha kassalar'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Barcha kassalar'),
                      ),
                      ...state.registers.map((r) {
                        return DropdownMenuItem<String?>(
                          value: r.id,
                          child: Text(r.name),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => selectedRegisterId = val),
                    icon: Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (width > 800) ...[
                SizedBox(width: 16),
                Chip(
                  label: Text(
                    'Bugun: ${DateFormat('dd MMMM, yyyy').format(DateTime.now())}',
                  ),
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.05),
                ),
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
        ],
      ),
    );
  }

  Widget _buildStatsSummary(
    BuildContext context,
    AppState state,
    List<Sale> filteredSales,
    double width,
  ) {
    final now = DateTime.now();
    final todaySales = filteredSales.where((s) {
      return s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;
    }).toList();

    final todayTotal = todaySales.fold(0.0, (sum, s) => sum + s.total);
    final todayCount = todaySales.length;
    final avgCheck = todayCount == 0 ? 0.0 : todayTotal / todayCount;

    int crossAxisCount = width < 600
        ? 1
        : width < 1200
        ? 2
        : 4;
    final fmt = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: '',
      decimalDigits: 0,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(
          context,
          'Bugungi Savdo',
          '${fmt.format(todayTotal)} so\'m',
          Icons.payments_outlined,
          Colors.green,
          'Live',
        ),
        _buildStatCard(
          context,
          'Cheklar soni',
          '$todayCount ta',
          Icons.receipt_long_outlined,
          Colors.blue,
          'Live',
        ),
        _buildStatCard(
          context,
          'O\'rtacha chek',
          '${fmt.format(avgCheck)} so\'m',
          Icons.analytics_outlined,
          Colors.orange,
          'Live',
        ),
        _buildStatCard(
          context,
          'Mahsulotlar',
          '${state.products.length} turda',
          Icons.inventory_2_outlined,
          Colors.purple,
          'Baza',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String status,
  ) {
    final isBaza = status == 'Baza';
    final statusColor = isBaza ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSales(
    BuildContext context,
    AppState state,
    List<Sale> filteredSales,
  ) {
    final recentSales = filteredSales.take(10).toList();
    final fmt = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: '',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oxirgi Sotuvlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.arrow_forward_rounded, size: 20),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (recentSales.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Hozircha sotuvlar yo\'q',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sotuv #${sale.id.substring(0, 5)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(sale.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${fmt.format(sale.total)} so\'m',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(
    BuildContext context,
    AppState state,
    List<Sale> filteredSales,
  ) {
    final now = DateTime.now();
    final todaySales = filteredSales.where(
      (s) =>
          s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day,
    );

    final Map<String, double> topMap = {};
    for (var sale in todaySales) {
      for (var item in sale.items) {
        topMap[item.productName] =
            (topMap[item.productName] ?? 0.0) + item.quantity;
      }
    }

    final sorted = topMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Mahsulotlar (Bugun)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          if (topProducts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Bugun sotuv bo\'lmadi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(0)} ta',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          entry.value /
                          (topProducts.first.value == 0
                              ? 1
                              : topProducts.first.value),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.05),
                      color: Theme.of(context).colorScheme.primary,
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
