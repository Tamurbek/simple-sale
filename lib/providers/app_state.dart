import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class AppState extends ChangeNotifier {
  List<Warehouse> warehouses = [];
  List<Register> registers = [];
  List<Category> categories = [];
  List<Product> products = [];
  List<StockEntry> stockEntries = [];
  List<User> users = [];
  List<Sale> sales = [];
  User? currentUser;
  String? masterPassword;

  Register? currentRegister;
  List<SaleItem> cart = [];
  String? selectedPrinterName;

  bool? isMaster;
  String? masterAddress;
  String? deviceId;
  bool isInitialized = false;
  bool isActivated = false;
  bool isBlocked = false;
  String? activationCode;

  double get todaySalesTotal {
    final now = DateTime.now();
    return sales
        .where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day)
        .fold(0.0, (sum, s) => sum + s.total);
  }

  int get todaySalesCount {
    final now = DateTime.now();
    return sales.where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day).length;
  }

  double get averageCheck {
    final count = todaySalesCount;
    return count == 0 ? 0 : todaySalesTotal / count;
  }

  List<MapEntry<String, double>> get topSellingProducts {
    final now = DateTime.now();
    final todaySales = sales.where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day);
    
    final Map<String, double> topMap = {};
    for (var sale in todaySales) {
      for (var item in sale.items) {
        topMap[item.productName] = (topMap[item.productName] ?? 0.0) + item.quantity;
      }
    }
    
    final sorted = topMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  // Active items (not deleted)
  List<Category> get activeCategories => categories.where((c) => !c.isDeleted).toList();
  List<Product> get activeProducts => products.where((p) => !p.isDeleted).toList();
  List<User> get activeUsers => users.where((u) => !u.isDeleted).toList();

  // Deleted items (Trash)
  List<Category> get deletedCategories => categories.where((c) => c.isDeleted).toList();
  List<Product> get deletedProducts => products.where((p) => p.isDeleted).toList();
  List<User> get deletedUsers => users.where((u) => u.isDeleted).toList();

  Future<String?> get localIp async {
    try {
      final interfaces = await NetworkInterface.list();
      List<String> allIps = [];
      
      for (var interface in interfaces) {
        // Skip common virtual/docker interfaces
        if (interface.name.contains('utun') || 
            interface.name.contains('docker') || 
            interface.name.contains('vboxnet')) continue;
            
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            allIps.add(addr.address);
          }
        }
      }

      if (allIps.isEmpty) return null;

      // Prioritize common local network patterns
      try {
        return allIps.firstWhere(
          (ip) => ip.startsWith('192.168.') || ip.startsWith('10.0.') || ip.startsWith('172.'),
          orElse: () => allIps.first,
        );
      } catch (e) {
        return allIps.first;
      }
    } catch (e) {
      return null;
    }
  }

  AppState() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool('isMaster');
    final ip = prefs.getString('masterAddress');
    masterPassword = prefs.getString('masterPassword');
    
    isMaster = master;
    masterAddress = ip;
    deviceId = prefs.getString('deviceId') ?? const Uuid().v4();
    await prefs.setString('deviceId', deviceId!);
    isActivated = prefs.getBool('isActivated') ?? false;
    activationCode = prefs.getString('activationCode');
    
    // Load data from DB
    await _loadFromDb();
    
    // Safety check: ensure no nulls
    categories = categories.whereType<Category>().toList();
    products = products.whereType<Product>().toList();
    warehouses = warehouses.whereType<Warehouse>().toList();
    registers = registers.whereType<Register>().toList();
    users = users.whereType<User>().toList();

    // If master and empty, add dummy data for demonstration
    if (isMaster == true && products.isEmpty && categories.isEmpty) {
      await _initializeDummyData();
      await _loadFromDb();
    }

    final savedRegId = prefs.getString('currentRegisterId');
    if (savedRegId != null) {
      final matching = registers.where((r) => r.id == savedRegId).toList();
      if (matching.isNotEmpty && matching.first.activeDeviceId == deviceId) {
        currentRegister = matching.first;
      }
    }

    if (isMaster == true) {
      _startServer();
      // Automatic Windows Firewall rule add (if on Windows)
      if (Platform.isWindows) {
        _addWindowsFirewallRule();
      }
    } else if (isMaster == false && masterAddress != null) {
      await syncWithMaster();
    }
    
    // If master and already activated, check blocking status in background
    if (isMaster == true && isActivated && activationCode != null) {
      checkBlockingStatus();
    }

    isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    categories = await DatabaseService.getCategories();
    products = await DatabaseService.getProducts();
    warehouses = await DatabaseService.getWarehouses();
    registers = await DatabaseService.getRegisters();
    stockEntries = await DatabaseService.getStockEntries();
    users = await DatabaseService.getUsers();
    sales = await DatabaseService.getSales();

    if (users.isEmpty && isMaster == true) {
      final admin = User(id: 'admin', name: 'Admin', pin: '1234', role: UserRole.admin);
      await DatabaseService.saveUser(admin);
      users.add(admin);
    }
  }

  Future<void> _initializeDummyData() async {
    final c1 = Category(id: 'c1', name: 'Ichimliklar');
    final c2 = Category(id: 'c2', name: 'Taomlar');
    final c3 = Category(id: 'c3', name: 'Non mahsulotlari');
    
    await DatabaseService.saveCategory(c1);
    await DatabaseService.saveCategory(c2);
    await DatabaseService.saveCategory(c3);

    final w1 = Warehouse(id: 'w1', name: 'Asosiy Ombor');
    final w2 = Warehouse(id: 'w2', name: 'Zaxira Ombor');
    
    await DatabaseService.saveWarehouse(w1);
    await DatabaseService.saveWarehouse(w2);

    await DatabaseService.saveRegister(Register(id: 'r1', name: 'Kassa 1', warehouseId: 'w1'));
    await DatabaseService.saveRegister(Register(id: 'r2', name: 'Kassa 2', warehouseId: 'w2'));

    await DatabaseService.saveProduct(Product(id: 'p1', name: 'Coca-Cola 0.5L', price: 6000, categoryId: 'c1', barcode: '111111', stocks: {'w1': 100, 'w2': 50}));
    await DatabaseService.saveProduct(Product(id: 'p2', name: 'Osh (1 portsiya)', price: 25000, categoryId: 'c2', barcode: '222222', stocks: {'w1': 20, 'w2': 10}));
    await DatabaseService.saveProduct(Product(id: 'p3', name: 'Non', price: 4000, categoryId: 'c3', barcode: '333333', stocks: {'w1': 50, 'w2': 0}));
    await DatabaseService.saveProduct(Product(id: 'p4', name: 'Fanta 0.5L', price: 6000, categoryId: 'c1', barcode: '444444', stocks: {'w1': 80, 'w2': 40}));
    await DatabaseService.saveProduct(Product(id: 'p5', name: 'Go\'sht (Mol)', price: 95000, categoryId: 'c2', barcode: '555555', stocks: {'w1': 10, 'w2': 5}, unit: 'kg'));
    await DatabaseService.saveProduct(Product(id: 'p6', name: 'Un', price: 7000, categoryId: 'c3', barcode: '666666', stocks: {'w1': 200, 'w2': 100}, unit: 'kg'));
  }

  Future<void> syncWithMaster() async {
    if (isMaster != false || masterAddress == null) return;
    
    final data = await SyncService.fetchFullState(masterAddress!);
    if (data != null) {
      final newCategories = (data['categories'] as List).map((c) => Category.fromJson(c)).toList();
      final newProducts = (data['products'] as List).map((p) => Product.fromJson(p)).toList();
      final newWarehouses = (data['warehouses'] as List).map((w) => Warehouse.fromJson(w)).toList();
      final newRegisters = (data['registers'] as List).map((r) => Register.fromJson(r)).toList();
      final newUsers = data['users'] != null
          ? (data['users'] as List).map((u) => User.fromJson(u)).toList()
          : <User>[];
      
      await DatabaseService.clearAllAndReplace(
        categories: newCategories.whereType<Category>().toList(),
        products: newProducts.whereType<Product>().toList(),
        warehouses: newWarehouses.whereType<Warehouse>().toList(),
        registers: newRegisters.whereType<Register>().toList(),
        users: newUsers.whereType<User>().toList(),
      );
      
      await _loadFromDb();

      if (currentRegister != null) {
        final existingId = currentRegister!.id;
        final matching = registers.where((r) => r.id == existingId).toList();
        if (matching.isNotEmpty) {
          currentRegister = matching.first;
        } else if (registers.isNotEmpty) {
          currentRegister = registers.first;
        } else {
          currentRegister = null;
        }
      }
      
      notifyListeners();
    } else {
      throw Exception('Asosiy kompyuterga ulanib bo\'lmadi. IP manzilni tekshiring.');
    }
  }

  Future<void> setTerminalMode(bool master, {String? ip, String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (master == false) {
      // For secondary, try to sync first
      if (ip == null || ip.isEmpty) throw Exception('IP manzilni kiriting');
      
      final oldIp = masterAddress;
      final oldMaster = isMaster;
      
      masterAddress = ip;
      isMaster = false;
      
      try {
        await syncWithMaster();
        // If sync success, save everything
        await prefs.setBool('isMaster', false);
        await prefs.setString('masterAddress', ip);
        await prefs.setBool('isActivated', true); // Secondary terminals follow Master activation
        isActivated = true;
      } catch (e) {
        // Rollback
        masterAddress = oldIp;
        isMaster = oldMaster;
        rethrow;
      }
    } else {
      // For Master
      await prefs.setBool('isMaster', true);
      if (password != null) {
        await prefs.setString('masterPassword', password);
        masterPassword = password;
      }
      isMaster = true;
      _startServer();
    }
    
    notifyListeners();
  }

  Future<void> resetTerminalMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isMaster');
    await prefs.remove('masterAddress');
    await prefs.remove('masterPassword');
    
    SyncService.stopServer();
    isMaster = null;
    masterAddress = null;
    masterPassword = null;
    currentUser = null;
    
    notifyListeners();
  }

  void _addWindowsFirewallRule() async {
    try {
      // Command to add firewall rule for port 8080
      // Requires admin privileges implicitly or by user prompt depending on OS settings
      await Process.run('netsh', [
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=SimpleSaleServer',
        'dir=in',
        'action=allow',
        'protocol=TCP',
        'localport=8080'
      ]);
      print('Firewall rule added or already exists.');
    } catch (e) {
      print('Failed to add firewall rule: $e');
    }
  }

  void _startServer() {
    SyncService.startServer(
      onSaleReceived: (saleData) async {
        final sale = Sale.fromJson(saleData);
        await DatabaseService.saveSale(sale);
        sales.insert(0, sale);

        for (var item in sale.items) {
          final productIndex = products.indexWhere((p) => p.id == item.productId);
          if (productIndex >= 0) {
            final newStock = (products[productIndex].stocks[sale.warehouseId] ?? 0) - item.quantity;
            products[productIndex].stocks[sale.warehouseId] = newStock;
            await DatabaseService.updateStock(item.productId, sale.warehouseId, newStock);
          }
        }
        notifyListeners();
      },
      onSyncRequested: () {
        return {
          'categories': categories.map((c) => c.toJson()).toList(),
          'products': products.map((p) => p.toJson()).toList(),
          'warehouses': warehouses.map((w) => w.toJson()).toList(),
          'registers': registers.map((r) => r.toJson()).toList(),
          'users': users.map((u) => u.toJson()).toList(),
        };
      },
      onRegisterSelectionRequested: (registerId, rDeviceId, force) async {
        if (registerId == null || rDeviceId == null) {
          return {'status': 'error', 'message': 'Kassa yoki Qurilma ID topilmadi'};
        }
        final regIndex = registers.indexWhere((r) => r.id == registerId);
        if (regIndex < 0) return {'status': 'error', 'message': 'Kassa topilmadi'};

        final reg = registers[regIndex];
        if (!force && reg.activeDeviceId != null && reg.activeDeviceId != rDeviceId) {
          return {
            'status': 'error', 
            'message': 'Ushbu kassa hozirda boshqa qurilmada (${reg.activeDeviceId}) band!',
          };
        }

        // Clear ANY device from this register if force is true
        if (force && reg.activeDeviceId != null && reg.activeDeviceId != rDeviceId) {
           // If we are forcing, we just take over. 
           // Clear other device's reference if they have it (optional but good)
        }

        // Clear THIS device from any other register
        for (int i = 0; i < registers.length; i++) {
          if (registers[i].activeDeviceId == rDeviceId) {
            final cleared = Register(
              id: registers[i].id,
              name: registers[i].name,
              warehouseId: registers[i].warehouseId,
              activeDeviceId: null,
            );
            await DatabaseService.saveRegister(cleared);
            registers[i] = cleared;
          }
        }

        // Clear the target register from OTHER devices if forcing
        if (force) {
          // It's already cleared from THIS device above. 
          // Now just overwrite the target register's device ID.
        }

        final updated = Register(
          id: reg.id,
          name: reg.name,
          warehouseId: reg.warehouseId,
          activeDeviceId: rDeviceId,
        );
        await DatabaseService.saveRegister(updated);
        final finalIdx = registers.indexWhere((r) => r.id == registerId);
        if (finalIdx >= 0) registers[finalIdx] = updated;
        
        notifyListeners();
        return {'status': 'success'};
      },
    );
  }

  // --- Category CRUD ---
  Future<void> addCategory(String name) async {
    final category = Category.create(name);
    await DatabaseService.saveCategory(category);
    categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(String id, String newName) async {
    final category = Category(id: id, name: newName);
    await DatabaseService.saveCategory(category);
    final index = categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    final index = categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final updated = Category(id: categories[index].id, name: categories[index].name, isDeleted: true);
      await DatabaseService.saveCategory(updated);
      categories[index] = updated;
      notifyListeners();
    }
  }

  Future<void> restoreCategory(String id) async {
    final index = categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final updated = Category(id: categories[index].id, name: categories[index].name, isDeleted: false);
      await DatabaseService.saveCategory(updated);
      categories[index] = updated;
      notifyListeners();
    }
  }

  // --- Product CRUD ---
  Future<void> addProduct(Product product) async {
    await DatabaseService.saveProduct(product);
    products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    await DatabaseService.saveProduct(updatedProduct);
    final index = products.indexWhere((p) => p.id == updatedProduct.id);
    if (index >= 0) {
      products[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final index = products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final updated = products[index].copyWith(isDeleted: true);
      await DatabaseService.saveProduct(updated);
      products[index] = updated;
      notifyListeners();
    }
  }

  Future<void> restoreProduct(String id) async {
    final index = products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final updated = products[index].copyWith(isDeleted: false);
      await DatabaseService.saveProduct(updated);
      products[index] = updated;
      notifyListeners();
    }
  }

  // --- Register & Cart ---
  Future<void> setRegister(Register register) async {
    final isAdmin = currentUser?.role == UserRole.admin;
    
    if (isMaster == true) {
      if (!isAdmin && register.activeDeviceId != null && register.activeDeviceId != deviceId) {
        throw Exception('Ushbu kassa hozirda boshqa qurilmada band!');
      }

      // Clear THIS device from others
      for (int i = 0; i < registers.length; i++) {
        if (registers[i].activeDeviceId == deviceId) {
          final cleared = Register(
            id: registers[i].id,
            name: registers[i].name,
            warehouseId: registers[i].warehouseId,
            activeDeviceId: null,
          );
          await DatabaseService.saveRegister(cleared);
          registers[i] = cleared;
        }
      }

      final updated = Register(
        id: register.id,
        name: register.name,
        warehouseId: register.warehouseId,
        activeDeviceId: deviceId,
      );
      await DatabaseService.saveRegister(updated);
      final idx = registers.indexWhere((r) => r.id == register.id);
      if (idx >= 0) registers[idx] = updated;
      currentRegister = updated;
    } else if (isMaster == false && masterAddress != null) {
      final res = await SyncService.selectRegisterOnMaster(masterAddress!, register.id, deviceId!, isAdmin);
      if (res != null && res['status'] == 'success') {
        final updated = Register(
          id: register.id,
          name: register.name,
          warehouseId: register.warehouseId,
          activeDeviceId: deviceId,
        );
        currentRegister = updated;
      } else {
        throw Exception(res?['message'] ?? 'Kassani tanlab bo\'lmadi');
      }
    } else {
      currentRegister = register;
    }
    
    final prefs = await SharedPreferences.getInstance();
    if (currentRegister != null) {
      await prefs.setString('currentRegisterId', currentRegister!.id);
    } else {
      await prefs.remove('currentRegisterId');
    }
    
    notifyListeners();
  }

  void addToCart(Product product) {
    if (currentRegister == null) return;
    final warehouseId = currentRegister!.warehouseId;
    final stock = product.stocks[warehouseId] ?? 0;

    final existingIndex = cart.indexWhere((item) => item.productId == product.id);
    double currentQty = 0;
    if (existingIndex >= 0) {
      currentQty = cart[existingIndex].quantity;
    }

    if (currentQty + 1 > stock) {
      throw Exception('Omborda yetarli mahsulot yo\'q! (Mavjud: ${stock.toInt()})');
    }

    if (existingIndex >= 0) {
      final item = cart[existingIndex];
      cart[existingIndex] = SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: item.quantity + 1,
        price: product.price,
      );
    } else {
      cart.add(SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: 1,
        price: product.price,
      ));
    }
    notifyListeners();
  }

  void updateCartQuantity(String productId, double quantity) {
    if (currentRegister == null) return;
    final warehouseId = currentRegister!.warehouseId;
    
    final product = products.firstWhere((p) => p.id == productId);
    final stock = product.stocks[warehouseId] ?? 0;

    if (quantity > stock) {
      throw Exception('Omborda yetarli mahsulot yo\'q! (Mavjud: ${stock.toInt()})');
    }

    final index = cart.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        cart.removeAt(index);
      } else {
        final item = cart[index];
        cart[index] = SaleItem(
          productId: item.productId,
          productName: item.productName,
          quantity: quantity,
          price: item.price,
        );
      }
      notifyListeners();
    }
  }

  void addToCartByBarcode(String barcode) {
    final product = products.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => throw Exception('Mahsulot topilmadi'),
    );
    addToCart(product);
  }

  void removeFromCart(String productId) {
    cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void decrementInCart(String productId) {
    final index = cart.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (cart[index].quantity > 1) {
        final item = cart[index];
        cart[index] = SaleItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity - 1,
          price: item.price,
        );
      } else {
        cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double get cartTotal => cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> processSale() async {
    if (currentRegister == null || cart.isEmpty) return;
    
    final saleData = {
      'id': Uuid().v4(),
      'date': DateTime.now().toIso8601String(),
      'items': cart.map((i) => i.toJson()).toList(),
      'total': cartTotal,
      'registerId': currentRegister!.id,
      'warehouseId': currentRegister!.warehouseId,
    };

    final sale = Sale.fromJson(saleData);
    await DatabaseService.saveSale(sale);
    sales.insert(0, sale);

    if (isMaster == false && masterAddress != null) {
      final success = await SyncService.sendSaleToMaster(masterAddress!, saleData);
      if (!success) {
        throw Exception('Asosiy server bilan bog\'lanib bo\'lmadi');
      }
    }

    final warehouseId = currentRegister!.warehouseId;
    for (var item in cart) {
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0) {
        final product = products[productIndex];
        final currentStock = product.stocks[warehouseId] ?? 0;
        final newStock = currentStock - item.quantity;
        product.stocks[warehouseId] = newStock;
        await DatabaseService.updateStock(product.id, warehouseId, newStock);
      }
    }

    clearCart();
    notifyListeners();
  }

  // --- Stock Entries ---
  Future<void> addStockEntry(StockEntry entry) async {
    await DatabaseService.saveStockEntry(entry);
    
    // Update local stocks
    for (var item in entry.items) {
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0) {
        final product = products[productIndex];
        final currentStock = product.stocks[entry.warehouseId] ?? 0;
        final newStock = currentStock + item.quantity;
        product.stocks[entry.warehouseId] = newStock;
        await DatabaseService.updateStock(product.id, entry.warehouseId, newStock);
      }
    }
    
    stockEntries.insert(0, entry);
    notifyListeners();
  }

  void updatePrinter(String name) {
    selectedPrinterName = name;
    notifyListeners();
  }

  // --- User Management ---
  Future<void> addUser(User user) async {
    await DatabaseService.saveUser(user);
    users.add(user);
    notifyListeners();
  }

  Future<void> deleteUser(String id) async {
    final index = users.indexWhere((u) => u.id == id);
    if (index >= 0) {
      final updated = User(
        id: users[index].id,
        name: users[index].name,
        pin: users[index].pin,
        role: users[index].role,
        isDeleted: true,
      );
      await DatabaseService.saveUser(updated);
      users[index] = updated;
      notifyListeners();
    }
  }

  Future<void> restoreUser(String id) async {
    final index = users.indexWhere((u) => u.id == id);
    if (index >= 0) {
      final updated = User(
        id: users[index].id,
        name: users[index].name,
        pin: users[index].pin,
        role: users[index].role,
        isDeleted: false,
      );
      await DatabaseService.saveUser(updated);
      users[index] = updated;
      notifyListeners();
    }
  }

  void login(String pin) {
    final user = users.firstWhere((u) => u.pin == pin, orElse: () => throw Exception('PIN xato!'));
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // --- Warehouse Management ---
  Future<void> addWarehouse(String name) async {
    final warehouse = Warehouse.create(name);
    await DatabaseService.saveWarehouse(warehouse);
    warehouses.add(warehouse);
    notifyListeners();
  }

  Future<void> updateWarehouse(String id, String newName) async {
    final warehouse = Warehouse(id: id, name: newName);
    await DatabaseService.saveWarehouse(warehouse);
    final index = warehouses.indexWhere((w) => w.id == id);
    if (index >= 0) {
      warehouses[index] = warehouse;
      notifyListeners();
    }
  }

  Future<void> deleteWarehouse(String id) async {
    await DatabaseService.deleteWarehouse(id);
    warehouses.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  // --- Register Management ---
  Future<void> addRegister(String name, String warehouseId) async {
    final register = Register.create(name, warehouseId);
    await DatabaseService.saveRegister(register);
    registers.add(register);
    notifyListeners();
  }

  Future<void> updateRegister(String id, String name, String warehouseId) async {
    final register = Register(id: id, name: name, warehouseId: warehouseId);
    await DatabaseService.saveRegister(register);
    final index = registers.indexWhere((r) => r.id == id);
    if (index >= 0) {
      registers[index] = register;
      notifyListeners();
    }
  }

  Future<void> deleteRegister(String id) async {
    await DatabaseService.deleteRegister(id);
    registers.removeWhere((r) => r.id == id);
    if (currentRegister?.id == id) {
      currentRegister = registers.isNotEmpty ? registers.first : null;
    }
    notifyListeners();
  }

  Future<void> exportDatabase() async {
    final path = await DatabaseService.getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      final xFile = XFile(path);
      await Share.shareXFiles([xFile], text: 'Simple Sale Baza Zaxira Nusxasi');
    }
  }

  Future<void> importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      await DatabaseService.replaceDatabase(file);
      await loadSettings(); // Refresh everything
      notifyListeners();
    }
  }

  // --- Activation System ---
  String get activationRequestCode {
    if (deviceId == null) return "Unknown";
    // Generate a shorter, user-friendly request code from deviceId
    return deviceId!.substring(0, 8).toUpperCase();
  }

  bool checkActivationCode(String code) {
    if (deviceId == null) return false;
    // Simple secret algorithm: 
    // Take first 8 chars of deviceId, reverse them, and add a secret suffix
    final secret = deviceId!.substring(0, 8).split('').reversed.join('');
    final expected = "SS-$secret-OK".toUpperCase();
    return code.toUpperCase() == expected;
  }

  Future<void> activate(String code, {bool online = true}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (online) {
      const backendUrl = "https://web-production-afb90.up.railway.app/verify";
      try {
        final response = await http.post(
          Uri.parse(backendUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "device_id": deviceId,
            "activation_code": code
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          isActivated = true;
          activationCode = code;
          isBlocked = false;
          await prefs.setBool('isActivated', true);
          await prefs.setString('activationCode', code);
          
          // Attempt cloud restore after activation
          await restoreDatabaseFromCloud();
          
          notifyListeners();
        } else if (response.statusCode == 403) {
          final data = jsonDecode(response.body);
          final detail = data['detail'] ?? "Aktivatsiya xatosi";
          if (detail.toString().contains("bloklangan")) {
            isBlocked = true;
            notifyListeners();
          }
          throw Exception(detail);
        } else {
          throw Exception("Server xatosi: ${response.statusCode}");
        }
      } catch (e) {
        if (e.toString().contains("bloklangan")) rethrow;
        throw Exception("Internet ulanishini tekshiring: $e");
      }
    } else {
      // Offline fallback
      if (checkActivationCode(code)) {
        isActivated = true;
        activationCode = code;
        await prefs.setBool('isActivated', true);
        await prefs.setString('activationCode', code);
        notifyListeners();
      } else {
        throw Exception("Noto'g'ri aktivatsiya kodi");
      }
    }
  }

  Future<void> checkBlockingStatus() async {
    if (isMaster != true || !isActivated || activationCode == null) return;
    
    try {
      const backendUrl = "https://web-production-afb90.up.railway.app/verify";
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "device_id": deviceId,
          "activation_code": activationCode
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        if (data['detail']?.toString().contains("bloklangan") == true) {
          isBlocked = true;
          notifyListeners();
        }
      } else if (response.statusCode == 200) {
        if (isBlocked) {
          isBlocked = false;
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore network errors for background check, just keep current state
      debugPrint("Blocking check failed: $e");
    }
  }

  Future<void> uploadDatabaseToCloud() async {
    if (!isActivated || activationCode == null) throw Exception('Dastur faollashtirilmagan');
    
    final dbPath = await DatabaseService.getDatabasePath();
    final file = File(dbPath);
    if (!await file.exists()) throw Exception('Baza fayli topilmadi');

    const uploadUrl = "https://web-production-afb90.up.railway.app/backup";
    
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$uploadUrl?activation_code=$activationCode'));
      request.files.add(await http.MultipartFile.fromPath('file', dbPath));
      
      var response = await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Zaxira yuklashda xatolik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Serverga ulanib bo\'lmadi: $e');
    }
  }

  Future<void> restoreDatabaseFromCloud() async {
    if (!isActivated || activationCode == null) throw Exception('Dastur faollashtirilmagan');

    final downloadUrl = "https://web-production-afb90.up.railway.app/backup/$activationCode";
    
    try {
      final response = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(join(tempDir.path, 'restore.db'));
        await tempFile.writeAsBytes(response.bodyBytes);
        await DatabaseService.replaceDatabase(tempFile);
        await loadSettings();
        notifyListeners();
      } else if (response.statusCode == 404) {
        throw Exception('Ushbu account uchun zaxira topilmadi');
      } else {
        throw Exception('Zaxira yuklab bo\'lmadi');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Close DB and delete file
    final dbPath = await DatabaseService.getDatabasePath();
    final file = File(dbPath);
    
    // Attempt to close DB if it exists (not strictly necessary with sqflite, but good practice)
    // Actually our DatabaseService doesn't have a close method, so we just delete it.
    
    if (await file.exists()) {
      await file.delete();
    }
    
    // Reset local state
    isMaster = null;
    isActivated = false;
    isBlocked = false;
    activationCode = null;
    currentRegister = null;
    registers = [];
    products = [];
    categories = [];
    sales = [];
    
    notifyListeners();
  }
}
