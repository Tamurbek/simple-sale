import 'package:uuid/uuid.dart';

class Warehouse {
  final String id;
  final String name;

  Warehouse({required this.id, required this.name});

  factory Warehouse.create(String name) => Warehouse(id: const Uuid().v4(), name: name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(id: json['id'], name: json['name']);
}

class Register {
  final String id;
  final String name;
  final String warehouseId;

  Register({required this.id, required this.name, required this.warehouseId});

  factory Register.create(String name, String warehouseId) => 
      Register(id: const Uuid().v4(), name: name, warehouseId: warehouseId);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'warehouseId': warehouseId};
  factory Register.fromJson(Map<String, dynamic> json) => 
      Register(id: json['id'], name: json['name'], warehouseId: json['warehouseId']);
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.create(String name) => Category(id: const Uuid().v4(), name: name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Category.fromJson(Map<String, dynamic> json) => Category(id: json['id'], name: json['name']);
}

class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String barcode;
  final Map<String, double> stocks;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.barcode,
    required this.stocks,
  });

  factory Product.create(String name, double price, String categoryId, String barcode) => 
      Product(id: const Uuid().v4(), name: name, price: price, categoryId: categoryId, barcode: barcode, stocks: {});

  Product copyWith({
    String? name,
    double? price,
    String? categoryId,
    String? barcode,
    Map<String, double>? stocks,
  }) => Product(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    categoryId: categoryId ?? this.categoryId,
    barcode: barcode ?? this.barcode,
    stocks: stocks ?? this.stocks,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'categoryId': categoryId,
    'barcode': barcode,
    'stocks': stocks,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    price: json['price'].toDouble(),
    categoryId: json['categoryId'],
    barcode: json['barcode'],
    stocks: Map<String, double>.from(json['stocks'] ?? {}),
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'total': total,
    'registerId': registerId,
    'warehouseId': warehouseId,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    date: DateTime.parse(json['date']),
    items: (json['items'] as List).map((i) => SaleItem.fromJson(i)).toList(),
    total: json['total'].toDouble(),
    registerId: json['registerId'],
    warehouseId: json['warehouseId'],
  );
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

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'price': price,
  };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'].toDouble(),
    price: json['price'].toDouble(),
  );
}

class StockEntry {
  final String id;
  final String warehouseId;
  final DateTime date;
  final List<StockEntryItem> items;
  final String description;

  StockEntry({
    required this.id,
    required this.warehouseId,
    required this.date,
    required this.items,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'warehouseId': warehouseId,
    'date': date.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'description': description,
  };

  factory StockEntry.fromJson(Map<String, dynamic> json) => StockEntry(
    id: json['id'],
    warehouseId: json['warehouseId'],
    date: DateTime.parse(json['date']),
    items: (json['items'] as List).map((i) => StockEntryItem.fromJson(i)).toList(),
    description: json['description'] ?? '',
  );
}

class StockEntryItem {
  final String productId;
  final String productName;
  final double quantity;

  StockEntryItem({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
  };

  factory StockEntryItem.fromJson(Map<String, dynamic> json) => StockEntryItem(
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'].toDouble(),
  );
}

enum UserRole { admin, cashier }

class User {
  final String id;
  final String name;
  final String pin;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pin': pin,
    'role': role.index,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    pin: json['pin'],
    role: UserRole.values[json['role'] as int],
  );
}
