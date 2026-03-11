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
    final received = double.tryParse(receivedController.text) ?? 0;
    final change = received - total;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('To\'lov', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: isSmall 
                    ? Column(children: [_buildLeft(total, change), const SizedBox(height: 24), _buildRight(total)])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeft(total, change)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildRight(total)),
                        ],
                      ),
                ),
              ),
              _buildActionFooter(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeft(double total, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jami To\'lov:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('${fmt.format(total)} so\'m', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))),
                ],
              ),
              const Divider(height: 48),
              const Text('To\'lov turi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMethodButton('Naqd', Icons.payments_rounded),
                  const SizedBox(width: 16),
                  _buildMethodButton('Plastik', Icons.credit_card_rounded),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: receivedController,
                readOnly: true,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: 'Olingan summa',
                  prefixIcon: const Icon(Icons.money_rounded, size: 28),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ],
          ),
        ),
        if (paymentMethod == 'Naqd' && change > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Qaytim:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.green)),
                Text('${fmt.format(change)} so\'m', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRight(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [1000, 5000, 10000, 20000, 50000, 100000, 200000].map((amount) {
              return InkWell(
                onTap: () => onQuickAdd(amount.toDouble()),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Text('+${amount ~/ 1000}k', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              for (var i = 1; i <= 9; i++) _buildNumBtn(i.toString()),
              _buildNumBtn('C', color: Colors.red.shade50, textColor: Colors.red),
              _buildNumBtn('0'),
              _buildNumBtn('back', icon: Icons.backspace_outlined),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: () => setState(() => receivedController.text = total.toStringAsFixed(0)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ANIQ SUMMA', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              child: const Text('Bekor Qilish', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => _executeSale(state),
              child: const Text('TO\'LOVNI TASDIQLASH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String val, {Color? color, Color? textColor, IconData? icon}) {
    return InkWell(
      onTap: () => onNumPressed(val),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: icon != null 
            ? Icon(icon, color: Colors.black54)
            : Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor ?? Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildMethodButton(String method, IconData icon) {
    final isSelected = paymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => paymentMethod = method),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF6366F1), size: 32),
              const SizedBox(height: 12),
              Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
