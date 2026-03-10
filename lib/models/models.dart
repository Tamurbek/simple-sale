import 'package:uuid/uuid.dart';

class Warehouse {
  final String id;
  final String name;

  Warehouse({required this.id, required this.name});

  factory Warehouse.create(String name) => Warehouse(id: const Uuid().v4(), name: name);
}

class Register {
  final String id;
  final String name;
  final String warehouseId; // Linked warehouse

  Register({required this.id, required this.name, required this.warehouseId});

  factory Register.create(String name, String warehouseId) => 
      Register(id: const Uuid().v4(), name: name, warehouseId: warehouseId);
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String barcode;
  final Map<String, double> stocks; // warehouseId -> quantity

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.barcode,
    required this.stocks,
  });

  factory Product.create(String name, double price, String category, String barcode) => 
      Product(id: const Uuid().v4(), name: name, price: price, category: category, barcode: barcode, stocks: {});
}

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;
  final double total;
  final String registerId;
  final String warehouseId;

  Sale({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.registerId,
    required this.warehouseId,
  });
}

class SaleItem {
  final String productId;
  final String productName;
  final double quantity;
  final double price;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}
