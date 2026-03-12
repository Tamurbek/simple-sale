import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon.png', width: 100, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dastur faollashtirilmagan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ushbu kompyuterda dasturdan foydalanish uchun litsenziya kodi talab qilinadi.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Device ID Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SO\'ROV KODI (DEVICE ID):',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: state.activationRequestCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Suro\'v kodi nusxalandi!'), duration: Duration(seconds: 2)),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      state.activationRequestCode,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: 4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Aktivatsiya kodi',
                  hintText: 'SS-XXXX-OK',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                onChanged: (_) => setState(() => _error = null),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_codeController.text.isEmpty) {
                      setState(() => _error = 'Kodni kiriting!');
                      return;
                    }
                    try {
                      await state.activate(_codeController.text);
                    } catch (e) {
                      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                  child: const Text('FAOLLASHTIRISH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Kodni olish uchun Telegram botga murojaat qiling:',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '@SimpleSaleBot',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
