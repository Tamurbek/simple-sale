import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

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

  // Terminal Settings
  bool? isMaster;
  String? masterAddress;
  bool isInitialized = false;

  double get todaySalesTotal {
    final now = DateTime.now();
    return sales
        .where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
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

  Future<String?> get localIp async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
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
    
    // Load data from DB
    await _loadFromDb();

    // If master and empty, add dummy data for demonstration
    if (isMaster == true && products.isEmpty && categories.isEmpty) {
      await _initializeDummyData();
      await _loadFromDb();
    }

    if (registers.isNotEmpty) {
      currentRegister = registers.first;
    }

    if (isMaster == true) {
      _startServer();
    } else if (isMaster == false && masterAddress != null) {
      await syncWithMaster();
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
        categories: newCategories,
        products: newProducts,
        warehouses: newWarehouses,
        registers: newRegisters,
        users: newUsers,
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
    }
  }

  Future<void> setTerminalMode(bool master, {String? ip, String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMaster', master);
    if (ip != null) await prefs.setString('masterAddress', ip);
    if (password != null) {
      await prefs.setString('masterPassword', password);
      masterPassword = password;
    }
    
    isMaster = master;
    masterAddress = ip;
    
    if (isMaster == true) {
      _startServer();
    } else {
      SyncService.stopServer();
      if (masterAddress != null) await syncWithMaster();
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
    await DatabaseService.deleteCategory(id);
    categories.removeWhere((c) => c.id == id);
    notifyListeners();
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
    final productIndex = products.indexWhere((p) => p.id == id);
    if (productIndex >= 0) {
      final product = products[productIndex];
      if (product.imagePath != null) {
        final file = File(product.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await DatabaseService.deleteProduct(id);
      products.removeAt(productIndex);
      notifyListeners();
    }
  }

  // --- Register & Cart ---
  void setRegister(Register register) {
    currentRegister = register;
    notifyListeners();
  }

  void addToCart(Product product) {
    final existingIndex = cart.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      final currentItem = cart[existingIndex];
      cart[existingIndex] = SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: currentItem.quantity + 1,
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
    await DatabaseService.deleteUser(id);
    users.removeWhere((u) => u.id == id);
    notifyListeners();
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
}
