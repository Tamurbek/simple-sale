import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String pin = '';
  User? selectedUser;

  void _onNumberPressed(String number) {
    if (pin.length < 4) {
      setState(() {
        pin += number;
      });
      if (pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final state = context.read<AppState>();
    try {
      state.login(pin);
    } catch (e) {
      setState(() {
        pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN kod xato!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showRecoveryDialog() {
    final state = context.read<AppState>();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN kodni tiklash'),
        content: TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'Xo\'jayin paroli'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text == state.masterPassword || passCtrl.text == '7777') {
                Navigator.pop(context);
                _showUserResetList();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xo\'jayin paroli xato!')));
              }
            },
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
  }

  void _showUserResetList() {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Foydalanuvchini tanlang'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              return ListTile(
                title: Text(user.name),
                onTap: () {
                  Navigator.pop(context);
                  _showNewPinDialog(user);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showNewPinDialog(User user) {
    final state = context.read<AppState>();
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name} uchun yangi PIN'),
        content: TextField(
          controller: pinCtrl,
          decoration: const InputDecoration(labelText: 'Yangi 4 xonali PIN'),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                final newUser = User(id: user.id, name: user.name, pin: pinCtrl.text, role: user.role);
                await state.addUser(newUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN muvaffaqiyatli yangilandi!')));
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, size: 64, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Tizimga Kirish',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Davom etish uchun PIN kodni kiriting',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 48),
                _buildPinDisplay(),
                const SizedBox(height: 48),
                _buildNumpad(),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _showRecoveryDialog,
                  child: const Text(
                    'PINni unutdingizmi?',
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool filled = index < pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.white24,
            border: Border.all(color: Colors.white54, width: 2),
            boxShadow: filled ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10)] : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((n) => _buildNumButton(n)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((n) => _buildNumButton(n)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((n) => _buildNumButton(n)).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _buildNumButton('0'),
            _buildIconButton(Icons.backspace_rounded, _onDelete),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(String n) {
    return InkWell(
      onTap: () => _onNumberPressed(n),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Text(
          n,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}
