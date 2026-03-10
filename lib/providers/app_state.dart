import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  List<Warehouse> warehouses = [
    Warehouse(id: 'w1', name: 'Asosiy Ombor'),
    Warehouse(id: 'w2', name: 'Zaxira Ombor'),
  ];
  
  List<Register> registers = [
    Register(id: 'r1', name: 'Kassa 1', warehouseId: 'w1'),
    Register(id: 'r2', name: 'Kassa 2', warehouseId: 'w2'),
  ];

  Register? currentRegister;
  
  List<Product> products = [
    Product(id: 'p1', name: 'Coca-Cola 0.5L', price: 6000, category: 'Ichimliklar', stocks: {'w1': 100, 'w2': 50}),
    Product(id: 'p2', name: 'Osh (1 portsiya)', price: 25000, category: 'Taomlar', stocks: {'w1': 20, 'w2': 10}),
    Product(id: 'p3', name: 'Non', price: 4000, category: 'Non mahsulotlari', stocks: {'w1': 50, 'w2': 0}),
    Product(id: 'p4', name: 'Fanta 0.5L', price: 6000, category: 'Ichimliklar', stocks: {'w1': 80, 'w2': 40}),
  ];

  List<SaleItem> cart = [];
  String? selectedPrinterName;

  AppState() {
    currentRegister = registers.first;
  }

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
      );
    }
    notifyListeners();
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

  void processSale() {
    if (currentRegister == null || cart.isEmpty) return;

    final warehouseId = currentRegister!.warehouseId;

    // Deduct stock
    for (var item in cart) {
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex >= 0) {
        final product = products[productIndex];
        final currentStock = product.stocks[warehouseId] ?? 0;
        product.stocks[warehouseId] = currentStock - item.quantity;
      }
    }

    clearCart();
    notifyListeners();
  }

  void updatePrinter(String name) {
    selectedPrinterName = name;
    notifyListeners();
  }
}
