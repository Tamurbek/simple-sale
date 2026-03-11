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
    final supportDir = await getApplicationSupportDirectory();
    
    final oldPath = join(docsDir.path, 'simple_sale.db');
    final newPath = join(supportDir.path, 'simple_sale.db');

    // Migration: move existing DB from Documents to App Support if it exists
    final oldFile = File(oldPath);
    if (await oldFile.exists()) {
      if (!await supportDir.exists()) {
        await supportDir.create(recursive: true);
      }
      await oldFile.copy(newPath);
      await oldFile.delete(); // Delete old risky file
    }

    return await openDatabase(
      newPath,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            isDeleted INTEGER NOT NULL DEFAULT 0
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
            warehouseId TEXT NOT NULL,
            activeDeviceId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            categoryId TEXT NOT NULL,
            barcode TEXT NOT NULL,
            imagePath TEXT,
            isDeleted INTEGER NOT NULL DEFAULT 0,
            unit TEXT NOT NULL DEFAULT 'dona'
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
            role INTEGER NOT NULL,
            isDeleted INTEGER NOT NULL DEFAULT 0
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
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE categories ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE products ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE users ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 7) {
          await db.execute("ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'dona'");
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE registers ADD COLUMN activeDeviceId TEXT');
        }
      },
    );
  }

  // --- Categories ---
  static Future<void> saveCategory(Category category) async {
    final db = await database;
    final json = category.toJson();
    json['isDeleted'] = category.isDeleted ? 1 : 0;
    await db.insert('categories', json, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final res = await db.query('categories');
    return res.map((c) => Category.fromJson({
      'id': c['id']?.toString() ?? '',
      'name': c['name']?.toString() ?? 'Noma\'lum',
      'isDeleted': c['isDeleted'] == 1,
    })).toList();
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
    return res.map((w) => Warehouse.fromJson({
      'id': w['id']?.toString() ?? '',
      'name': w['name']?.toString() ?? 'Noma\'lum',
    })).toList();
  }

  static Future<void> deleteWarehouse(String id) async {
    final db = await database;
    await db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
  }

  // --- Registers ---
  static Future<void> saveRegister(Register register) async {
    final db = await database;
    await db.insert('registers', register.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Register>> getRegisters() async {
    final db = await database;
    final res = await db.query('registers');
    return res.map((r) => Register.fromJson({
      'id': r['id']?.toString() ?? '',
      'name': r['name']?.toString() ?? 'Noma\'lum',
      'warehouseId': r['warehouseId']?.toString() ?? '',
      'activeDeviceId': r['activeDeviceId']?.toString(),
    })).toList();
  }

  static Future<void> deleteRegister(String id) async {
    final db = await database;
    await db.delete('registers', where: 'id = ?', whereArgs: [id]);
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
      'isDeleted': product.isDeleted ? 1 : 0,
      'unit': product.unit,
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
      final stocks = {for (var s in stockRes) (s['warehouseId']?.toString() ?? 'null'): double.tryParse(s['quantity']?.toString() ?? '0') ?? 0.0};
      
      products.add(Product(
        id: pMap['id']?.toString() ?? '',
        name: pMap['name']?.toString() ?? 'Noma\'lum',
        price: double.tryParse(pMap['price']?.toString() ?? '0') ?? 0.0,
        categoryId: pMap['categoryId']?.toString() ?? '',
        barcode: pMap['barcode']?.toString() ?? '',
        stocks: stocks,
        imagePath: pMap['imagePath']?.toString(),
        isDeleted: pMap['isDeleted'] == 1,
        unit: pMap['unit']?.toString() ?? 'dona',
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
          'isDeleted': p.isDeleted ? 1 : 0,
          'unit': p.unit,
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
        id: eMap['id']?.toString() ?? '',
        warehouseId: eMap['warehouseId']?.toString() ?? '',
        date: eMap['date'] != null ? DateTime.parse(eMap['date'].toString()) : DateTime.now(),
        description: eMap['description']?.toString() ?? '',
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
        id: sMap['id']?.toString() ?? '',
        date: sMap['date'] != null ? DateTime.parse(sMap['date'].toString()) : DateTime.now(),
        items: items,
        total: double.tryParse(sMap['total']?.toString() ?? '0') ?? 0.0,
        registerId: sMap['registerId']?.toString() ?? '',
        warehouseId: sMap['warehouseId']?.toString() ?? '',
      ));
    }
    return sales;
  }

  // --- Users ---
  static Future<void> saveUser(User user) async {
    final db = await database;
    final json = user.toJson();
    json['isDeleted'] = user.isDeleted ? 1 : 0;
    await db.insert('users', json, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<User>> getUsers() async {
    final db = await database;
    final res = await db.query('users');
    return res.map((u) => User.fromJson({
      'id': u['id']?.toString() ?? '',
      'name': u['name']?.toString() ?? 'Noma\'lum',
      'pin': u['pin']?.toString() ?? '',
      'role': u['role'] ?? 1,
      'isDeleted': u['isDeleted'] == 1,
    })).toList();
  }

  static Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
