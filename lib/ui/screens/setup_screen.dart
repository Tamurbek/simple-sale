import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
   final TextEditingController _ipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isMasterChoice = true;
  bool isLoading = false;

  @override
  void dispose() {
    _ipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF6366F1), size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tizimni sozlash',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ushbu terminal turini tanlang',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              
              // Master/Client Toggle
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Asosiy (Master)',
                      subtitle: 'Server bo\'lib ishlaydi',
                      icon: Icons.storage_rounded,
                      isSelected: isMasterChoice,
                      onTap: () => setState(() => isMasterChoice = true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Qo\'shimcha',
                      subtitle: 'Serverga ulanadi',
                      icon: Icons.computer_rounded,
                      isSelected: !isMasterChoice,
                      onTap: () => setState(() => isMasterChoice = false),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              if (isMasterChoice) ...[
                 FutureBuilder<String?>(
                   future: context.read<AppState>().localIp,
                   builder: (context, snapshot) {
                     return Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.amber.shade50,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.amber.shade200),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.info_outline, color: Colors.amber),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                               'Ushbu kompyuter IP manzili: ${snapshot.data ?? "Aniqlanmoqda..."}\nUni boshqa kompyuterda kiriting.',
                               style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                             ),
                           ),
                         ],
                       ),
                     );
                   }
                 ),
                 const SizedBox(height: 24),
                 TextField(
                   controller: _passwordController,
                   decoration: InputDecoration(
                     labelText: "Xo'jayin paroli (Tiklash uchun)",
                     hintText: "Kamida 4 ta belgi",
                     prefixIcon: const Icon(Icons.vpn_key_outlined),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   obscureText: true,
                 ),
              ],
              
              if (!isMasterChoice) ...[
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'Asosiy kompyuter IP manzili',
                    hintText: 'Masalan: 192.168.1.10',
                    prefixIcon: const Icon(Icons.lan_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : () async {
                    if (isMasterChoice && _passwordController.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parol kamida 4 belgidan iborat bo\'lishi kerak')),
                      );
                      return;
                    }
                    
                    setState(() => isLoading = true);
                    try {
                      await context.read<AppState>().setTerminalMode(
                        isMasterChoice, 
                        ip: _ipController.text,
                        password: _passwordController.text,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isMasterChoice ? 'DAVOM ETISH' : 'ULANISH VA DAVOM ETISH', 
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6366F1) : Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF6366F1) : Colors.black87)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
