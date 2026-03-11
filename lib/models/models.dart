import 'package:uuid/uuid.dart';

class Warehouse {
  final String id;
  final String name;

  Warehouse({required this.id, required this.name});

  factory Warehouse.create(String name) => Warehouse(id: const Uuid().v4(), name: name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id']?.toString() ?? '', 
    name: json['name']?.toString() ?? 'Noma\'lum'
  );
}

class Register {
  final String id;
  final String name;
  final String warehouseId;

  final String? activeDeviceId;

  Register({required this.id, required this.name, required this.warehouseId, this.activeDeviceId});

  factory Register.create(String name, String warehouseId) => 
      Register(id: const Uuid().v4(), name: name, warehouseId: warehouseId, activeDeviceId: null);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'warehouseId': warehouseId, 'activeDeviceId': activeDeviceId};
  factory Register.fromJson(Map<String, dynamic> json) => 
      Register(
        id: json['id']?.toString() ?? '', 
        name: json['name']?.toString() ?? 'Noma\'lum', 
        warehouseId: json['warehouseId']?.toString() ?? '', 
        activeDeviceId: json['activeDeviceId']?.toString()
      );
}

class Category {
  final String id;
  final String name;
  final bool isDeleted;

  Category({required this.id, required this.name, this.isDeleted = false});

  factory Category.create(String name) => Category(id: const Uuid().v4(), name: name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isDeleted': isDeleted};
  factory Category.fromJson(Map<String, dynamic> json) => 
      Category(
        id: json['id']?.toString() ?? '', 
        name: json['name']?.toString() ?? 'Noma\'lum', 
        isDeleted: json['isDeleted'] ?? false
      );
}
class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String barcode;
  final Map<String, double> stocks;
  final String? imagePath;
  final bool isDeleted;
  final String unit; // 'dona', 'kg', 'litr', etc.

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.barcode,
    required this.stocks,
    this.imagePath,
    this.isDeleted = false,
    this.unit = 'dona',
  });

  factory Product.create(String name, double price, String categoryId, String barcode, {String? imagePath, String unit = 'dona'}) => 
      Product(id: const Uuid().v4(), name: name, price: price, categoryId: categoryId, barcode: barcode, stocks: {}, imagePath: imagePath, unit: unit);

  Product copyWith({
    String? name,
    double? price,
    String? categoryId,
    String? barcode,
    Map<String, double>? stocks,
    String? imagePath,
    bool? isDeleted,
    String? unit,
  }) => Product(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    categoryId: categoryId ?? this.categoryId,
    barcode: barcode ?? this.barcode,
    stocks: stocks ?? this.stocks,
    imagePath: imagePath ?? this.imagePath,
    isDeleted: isDeleted ?? this.isDeleted,
    unit: unit ?? this.unit,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'categoryId': categoryId,
    'barcode': barcode,
    'imagePath': imagePath,
    'stocks': stocks,
    'isDeleted': isDeleted,
    'unit': unit,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    var stockData = json['stocks'];
    Map<String, double> stocks = {};
    if (stockData != null && stockData is Map) {
      stocks = stockData.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Noma\'lum',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      categoryId: json['categoryId']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      stocks: stocks,
      imagePath: json['imagePath']?.toString(),
      isDeleted: json['isDeleted'] ?? false,
      unit: json['unit']?.toString() ?? 'dona',
    );
  }
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
    id: json['id']?.toString() ?? '',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    items: (json['items'] as List?)?.map((i) => SaleItem.fromJson(i)).toList() ?? [],
    total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    registerId: json['registerId']?.toString() ?? '',
    warehouseId: json['warehouseId']?.toString() ?? '',
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
    productId: json['productId']?.toString() ?? '',
    productName: json['productName']?.toString() ?? 'Noma\'lum',
    quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
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
    id: json['id']?.toString() ?? '',
    warehouseId: json['warehouseId']?.toString() ?? '',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    items: (json['items'] as List?)?.map((i) => StockEntryItem.fromJson(i)).toList() ?? [],
    description: json['description']?.toString() ?? '',
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
    productId: json['productId']?.toString() ?? '',
    productName: json['productName']?.toString() ?? 'Noma\'lum',
    quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
  );
}

enum UserRole { admin, cashier }

class User {
  final String id;
  final String name;
  final String pin;
  final UserRole role;
  final bool isDeleted;

  User({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pin': pin,
    'role': role.index,
    'isDeleted': isDeleted,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Noma\'lum',
    pin: json['pin']?.toString() ?? '',
    role: UserRole.values[(json['role'] ?? 1) as int],
    isDeleted: json['isDeleted'] ?? false,
  );
}
