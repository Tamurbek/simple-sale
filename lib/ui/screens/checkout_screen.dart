import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../services/print_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = 'Naqd';
  final TextEditingController receivedController = TextEditingController();
  final fmt = NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    receivedController.text = state.cartTotal.toStringAsFixed(0);
  }

  void onNumPressed(String val) {
    setState(() {
      if (val == 'C') {
        receivedController.clear();
      } else if (val == 'back') {
        if (receivedController.text.isNotEmpty) {
          receivedController.text = receivedController.text.substring(0, receivedController.text.length - 1);
        }
      } else {
        receivedController.text += val;
      }
    });
  }

  void onQuickAdd(double amount) {
    setState(() {
      final current = double.tryParse(receivedController.text) ?? 0;
      receivedController.text = (current + amount).toStringAsFixed(0);
    });
  }

  Future<void> _executeSale(AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      if (state.selectedPrinterName != null) {
        await PrintService.printReceipt(
          items: state.cart,
          total: state.cartTotal,
          registerName: state.currentRegister?.name ?? 'Kassa',
          printerName: state.selectedPrinterName,
        );
      }
      
      await state.processSale();
      if (mounted) {
        Navigator.pop(context); // close loader
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Sotuv yakunlandi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ombor yangilandi va chek chiqarildi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                   Navigator.pop(context); // close success dialog
                   Navigator.pop(context); // back to POS
                },
                child: const Text('Davom Etish', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final total = state.cartTotal;
    final receivedStr = receivedController.text;
    final received = double.tryParse(receivedStr) ?? 0;
    final change = received - total;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('To\'lovni Yakunlash', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 950;
          
          if (isSmall) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryCard(total, change),
                        const SizedBox(height: 20),
                        _buildPaymentMethods(),
                        const SizedBox(height: 20),
                        _buildNumpadSection(total),
                      ],
                    ),
                  ),
                ),
                _buildSimpleFooter(state),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryCard(total, change),
                              const SizedBox(height: 32),
                              _buildPaymentMethods(),
                              const SizedBox(height: 32),
                              _buildBigDisplay(receivedStr),
                            ],
                          ),
                        ),
                      ),
                      _buildSimpleFooter(state),
                    ],
                  ),
                ),
              ),
              Container(
                width: 450,
                color: Colors.white,
                child: _buildNumpadSection(total),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double total, double change) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('To\'lanishi kerak:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Text('${fmt.format(total)} so\'m', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
          if (change > 0 && paymentMethod == 'Naqd') ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Qaytim:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
                Text('${fmt.format(change)} so\'m', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('  TO\'LOV USULI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMethodBtn('Naqd', Icons.payments_rounded, const Color(0xFF6366F1)),
            const SizedBox(width: 16),
            _buildMethodBtn('Plastik', Icons.credit_card_rounded, const Color(0xFF0EA5E9)),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodBtn(String method, IconData icon, Color color) {
    final isSelected = paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => paymentMethod = method),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: 2),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 28),
              const SizedBox(height: 12),
              Text(method, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigDisplay(String val) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OLINGAN SUMMA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  val.isEmpty ? '0' : val,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text('SO\'M', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadSection(double total) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1000, 5000, 10000, 20000, 50000, 100000, 200000].map((amount) {
              return InkWell(
                onTap: () => onQuickAdd(amount.toDouble()),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text('+${fmt.format(amount).trim()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF475569))),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              for (var i = 1; i <= 9; i++) _buildNumBtn(i.toString()),
              _buildNumBtn('C', color: Colors.red.shade50, textColor: Colors.red),
              _buildNumBtn('0'),
              _buildNumBtn('back', icon: Icons.backspace_rounded, color: const Color(0xFFF1F5F9)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => setState(() => receivedController.text = total.toStringAsFixed(0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF475569),
              minimumSize: const Size.fromHeight(60),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('ANIQ SUMMA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumBtn(String val, {Color? color, Color? textColor, IconData? icon}) {
    return Material(
      color: color ?? const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onNumPressed(val),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
          ),
          child: Center(
            child: icon != null 
              ? Icon(icon, color: const Color(0xFF475569), size: 24)
              : Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor ?? const Color(0xFF1E293B))),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleFooter(AppState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Bekor qilish', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _executeSale(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64),
                elevation: 8,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('TASDIQLASH VA BOSISH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
