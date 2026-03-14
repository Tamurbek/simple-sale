import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
          content: Text('PIN kod xato!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        title: Text('PIN kodni tiklash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Xo\'jayin paroli'),
              obscureText: true,
            ),
            SizedBox(height: 8),
            Text(
              'Foydalanuvchilar soni: ${state.users.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () {
              final enteredPass = passCtrl.text;
              final masterPass = state.masterPassword;
              // 7777 har doim ishlaydi, yoki to'g'ri master parol
              final isValid =
                  enteredPass == '7777' ||
                  (masterPass != null && enteredPass == masterPass);
              if (isValid) {
                Navigator.pop(context);
                if (state.users.isEmpty) {
                  // Foydalanuvchilar yo'q -> to'g'ridan admin yaratish
                  _showEmergencyAdminDialog();
                } else {
                  _showUserResetList();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xo\'jayin paroli xato!')),
                );
              }
            },
            child: Text('Tasdiqlash'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAdminDialog() {
    final state = context.read<AppState>();
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Admin yaratish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tizimda foydalanuvchi yo\'q. Yangi admin PIN yarating:',
              style: TextStyle(color: Colors.orange),
            ),
            SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              decoration: const InputDecoration(
                labelText: 'Yangi 4 xonali PIN',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                final newAdmin = User(
                  id: 'admin',
                  name: 'Admin',
                  pin: pinCtrl.text,
                  role: UserRole.admin,
                );
                await state.addUser(newAdmin);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Admin yaratildi! Endi login turing.'),
                  ),
                );
              }
            },
            child: Text('Saqlash'),
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
        title: Text('Foydalanuvchini tanlang'),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                final newUser = User(
                  id: user.id,
                  name: user.name,
                  pin: pinCtrl.text,
                  role: user.role,
                );
                await state.addUser(newUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN muvaffaqiyatli yangilandi!'),
                  ),
                );
              }
            },
            child: Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.backspace) {
              _onDelete();
              return KeyEventResult.handled;
            }
            final String? digit = event.character;
            if (digit != null && RegExp(r'^[0-9]$').hasMatch(digit)) {
              _onNumberPressed(digit);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.4
                            : 0.1,
                      ),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Tizimga Kirish',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.isMaster == true
                            ? '🖥 Master terminal'
                            : '💻 Klient terminal',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 48),
                    _buildPinDisplay(),
                    SizedBox(height: 48),
                    _buildNumpad(),
                    SizedBox(height: 24),
                    TextButton(
                      onPressed: _showRecoveryDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color,
                      ),
                      child: Text(
                        'PINni unutdingizmi?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: SafeArea(
              child: IconButton(
                onPressed: _resetTerminalMode,
                icon: Icon(
                  Icons.settings_rounded,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                tooltip: 'Terminal sozlamalari',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _resetTerminalMode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Terminal sozlamalari'),
        content: Text(
          'Terminal rejimini qayta sozlashni xohlaysizmi? Barcha mahalliy ma\'lumotlar o\'chiriladi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppState>().resetTerminalMode();
            },
            child: Text('Qayta sozlash'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool filled = index < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                filled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
            border: Border.all(
              color:
                  filled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow:
                filled
                    ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildNumpadRow(['1', '2', '3']),
          _buildNumpadRow(['4', '5', '6']),
          _buildNumpadRow(['7', '8', '9']),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              _buildNumButton('0'),
              _buildIconButton(Icons.backspace_outlined, _onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(List<String> numbers) {
    return Row(
      children: numbers.map((n) => _buildNumButton(n)).toList(),
    );
  }

  Widget _buildNumButton(String n) {
    return Expanded(
      child: InkWell(
        onTap: () => _onNumberPressed(n),
        child: Container(
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          child: Text(
            n,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
          ),
          child: Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
