import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'simple_sale.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE warehouses (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE registers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            warehouseId TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            categoryId TEXT NOT NULL,
            barcode TEXT NOT NULL,
            imagePath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE stocks (
            productId TEXT NOT NULL,
            warehouseId TEXT NOT NULL,
            quantity REAL NOT NULL,
            PRIMARY KEY (productId, warehouseId)
          )
        ''');
        await db.execute('''
          CREATE TABLE sales (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            total REAL NOT NULL,
            registerId TEXT NOT NULL,
            warehouseId TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sale_items (
            saleId TEXT NOT NULL,
            productId TEXT NOT NULL,
            productName TEXT NOT NULL,
            quantity REAL NOT NULL,
            price REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_entries (
            id TEXT PRIMARY KEY,
            warehouseId TEXT NOT NULL,
            date TEXT NOT NULL,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_entry_items (
            entryId TEXT NOT NULL,
            productId TEXT NOT NULL,
            quantity REAL NOT NULL,
            productName TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pin TEXT NOT NULL,
            role INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE stock_entries (
              id TEXT PRIMARY KEY,
              warehouseId TEXT NOT NULL,
              date TEXT NOT NULL,
              description TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE stock_entry_items (
              entryId TEXT NOT NULL,
              productId TEXT NOT NULL,
              quantity REAL NOT NULL,
              productName TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              pin TEXT NOT NULL,
              role INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE sale_items (
              saleId TEXT NOT NULL,
              productId TEXT NOT NULL,
              productName TEXT NOT NULL,
              quantity REAL NOT NULL,
              price REAL NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT');
        }
      },
    );
  }

  // --- Categories ---
  static Future<void> saveCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final res = await db.query('categories');
    return res.map((c) => Category.fromJson(c)).toList();
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Warehouses ---
  static Future<void> saveWarehouse(Warehouse warehouse) async {
    final db = await database;
    await db.insert('warehouses', warehouse.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Warehouse>> getWarehouses() async {
    final db = await database;
    final res = await db.query('warehouses');
    return res.map((w) => Warehouse.fromJson(w)).toList();
  }

  // --- Registers ---
  static Future<void> saveRegister(Register register) async {
    final db = await database;
    await db.insert('registers', register.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Register>> getRegisters() async {
    final db = await database;
    final res = await db.query('registers');
    return res.map((r) => Register.fromJson(r)).toList();
  }

  // --- Products & Stocks ---
  static Future<void> saveProduct(Product product) async {
    final db = await database;
    await db.insert('products', {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'categoryId': product.categoryId,
      'barcode': product.barcode,
      'imagePath': product.imagePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Save stocks separately
    for (var entry in product.stocks.entries) {
      await db.insert('stocks', {
        'productId': product.id,
        'warehouseId': entry.key,
        'quantity': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final prodRes = await db.query('products');
    final List<Product> products = [];

    for (var pMap in prodRes) {
      final stockRes = await db.query('stocks', where: 'productId = ?', whereArgs: [pMap['id']]);
      final stocks = {for (var s in stockRes) s['warehouseId'] as String: (s['quantity'] as num).toDouble()};
      
      products.add(Product(
        id: pMap['id'] as String,
        name: pMap['name'] as String,
        price: (pMap['price'] as num).toDouble(),
        categoryId: pMap['categoryId'] as String,
        barcode: pMap['barcode'] as String,
        stocks: stocks,
        imagePath: pMap['imagePath'] as String?,
      ));
    }
    return products;
  }

  static Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await db.delete('stocks', where: 'productId = ?', whereArgs: [id]);
  }

  static Future<void> updateStock(String productId, String warehouseId, double newQuantity) async {
    final db = await database;
    await db.insert('stocks', {
      'productId': productId,
      'warehouseId': warehouseId,
      'quantity': newQuantity,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Bulk Sync ---
  static Future<void> clearAllAndReplace({
    required List<Category> categories,
    required List<Product> products,
    required List<Warehouse> warehouses,
    required List<Register> registers,
    List<User> users = const [],
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('categories');
      await txn.delete('products');
      await txn.delete('warehouses');
      await txn.delete('registers');
      await txn.delete('stocks');
      if (users.isNotEmpty) await txn.delete('users');

      for (var c in categories) await txn.insert('categories', c.toJson());
      for (var w in warehouses) await txn.insert('warehouses', w.toJson());
      for (var r in registers) await txn.insert('registers', r.toJson());
      for (var u in users) await txn.insert('users', u.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      for (var p in products) {
        await txn.insert('products', {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'categoryId': p.categoryId,
          'barcode': p.barcode,
          'imagePath': p.imagePath,
        });
        for (var entry in p.stocks.entries) {
          await txn.insert('stocks', {
            'productId': p.id,
            'warehouseId': entry.key,
            'quantity': entry.value,
          });
        }
      }
    });
  }

  // --- Stock Entries ---
  static Future<void> saveStockEntry(StockEntry entry) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('stock_entries', {
        'id': entry.id,
        'warehouseId': entry.warehouseId,
        'date': entry.date.toIso8601String(),
        'description': entry.description,
      });

      for (var item in entry.items) {
        await txn.insert('stock_entry_items', {
          'entryId': entry.id,
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
        });
      }
    });
  }

  static Future<List<StockEntry>> getStockEntries() async {
    final db = await database;
    final entriesRes = await db.query('stock_entries', orderBy: 'date DESC');
    final List<StockEntry> entries = [];

    for (var eMap in entriesRes) {
      final itemsRes = await db.query('stock_entry_items', where: 'entryId = ?', whereArgs: [eMap['id']]);
      final items = itemsRes.map((i) => StockEntryItem.fromJson({
        'productId': i['productId'],
        'productName': i['productName'],
        'quantity': i['quantity'],
      })).toList();

      entries.add(StockEntry(
        id: eMap['id'] as String,
        warehouseId: eMap['warehouseId'] as String,
        date: DateTime.parse(eMap['date'] as String),
        description: eMap['description'] as String? ?? '',
        items: items,
      ));
    }
    return entries;
  }

  // --- Sales ---
  static Future<void> saveSale(Sale sale) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('sales', {
        'id': sale.id,
        'date': sale.date.toIso8601String(),
        'total': sale.total,
        'registerId': sale.registerId,
        'warehouseId': sale.warehouseId,
      });

      for (var item in sale.items) {
        await txn.insert('sale_items', {
          'saleId': sale.id,
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }
    });
  }

  static Future<List<Sale>> getSales() async {
    final db = await database;
    final salesRes = await db.query('sales', orderBy: 'date DESC');
    final List<Sale> sales = [];

    for (var sMap in salesRes) {
      final itemsRes = await db.query('sale_items', where: 'saleId = ?', whereArgs: [sMap['id']]);
      final items = itemsRes.map((i) => SaleItem.fromJson({
        'productId': i['productId'],
        'productName': i['productName'],
        'quantity': i['quantity'],
        'price': i['price'],
      })).toList();

      sales.add(Sale(
        id: sMap['id'] as String,
        date: DateTime.parse(sMap['date'] as String),
        items: items,
        total: (sMap['total'] as num).toDouble(),
        registerId: sMap['registerId'] as String,
        warehouseId: sMap['warehouseId'] as String,
      ));
    }
    return sales;
  }

  // --- Users ---
  static Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<User>> getUsers() async {
    final db = await database;
    final res = await db.query('users');
    return res.map((u) => User.fromJson(u)).toList();
  }

  static Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
