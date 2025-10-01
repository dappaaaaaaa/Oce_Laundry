import 'package:aplikasi_demo_test/database/order_item.dart';
import 'package:aplikasi_demo_test/database/product.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // *Fungsi untuk membuat database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // *Membuat tabel-tabel yang diperlukan
        await db.execute(
          'CREATE TABLE products ('
          'id INTEGER PRIMARY KEY, '
          'category_id INTEGER, '
          'category TEXT, '
          'product_name TEXT, '
          'description TEXT, '
          'image TEXT, '
          'price INTEGER, '
          'status INTEGER'
          ')',
        );

        await db.execute('''
        CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        product_id INTEGER,
        weight REAL,
        price INTEGER
        )
      ''');

        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_name TEXT NOT NULL,
            phone_number TEXT NOT NULL,
            address TEXT NOT NULL
          );
          ''');

        await db.execute('''
          CREATE TABLE tax (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tax_name TEXT NOT NULL,
            tax REAL NOT NULL
          );
          ''');
        await db.execute('''
          CREATE TABLE discount (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            discount_name TEXT NOT NULL,
            discount REAL NOT NULL
          );
          ''');

        await db.execute('''
        CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_payment INTEGER NOT NULL,
        sub_total INTEGER NOT NULL,
        tax INTEGER NOT NULL,
        discount INTEGER NOT NULL,
        total INTEGER NOT NULL,
        total_item INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        transaction_time INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        is_sync INTEGER NOT NULL DEFAULT 0,
        is_order_complete INTEGER NOT NULL DEFAULT 0,
        is_payment_complete INTEGER NOT NULL DEFAULT 1
      )
    ''');
      },
    );
  }

  // *Fungsi untuk memasukan produk ke database lokal
  Future<void> insertProducts(Product product) async {
    final db = await database;
    await db.insert('products', {
      'id': product.id,
      'category_id': product.categoryId,
      'category': product.category,
      'product_name': product.productName,
      'description': product.description,
      'image': product.image,
      'price': product.price,
      'status': product.status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // *Fungsi untuk memasukan item pesanan ke database lokal
  Future<void> insertOrderItem(OrderItem item) async {
    final db = await database;
    await db.insert(
      'order_items',
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // *Fungsi untuk mendapatkan produk berdasarkan kategori
  Future<List<Product>> getProducts({String? kategori}) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: kategori != null ? 'category = ?' : null,
      whereArgs: kategori != null ? [kategori] : null,
    );

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        categoryId: maps[i]['category_id'],
        category: maps[i]['category'],
        productName: maps[i]['product_name'],
        description: maps[i]['description'] ?? '',
        image: maps[i]['image'],
        price: maps[i]['price'] ?? 0,
        status: maps[i]['status'] ?? 0,
      );
    });
  }

  // *Fungsi untuk mendapatkan semua produk
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        categoryId: maps[i]['category_id'],
        category: maps[i]['category'],
        productName: maps[i]['product_name'],
        description: maps[i]['description'] ?? '',
        image: maps[i]['image'],
        price: maps[i]['price'] ?? 0,
        status: maps[i]['status'] ?? 0,
      );
    });
  }

  // *Fungsi untuk mendapatkan kategori
  Future<List<String>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      columns: ['category'],
      where: 'category IS NOT NULL',
      distinct: true,
    );

    return maps
        .map((map) => map['category']?.toString() ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
  }

  // *Fungsi untuk mengisi data order ke database
  Future<int> insertOrder(Map<String, dynamic> orderData) async {
    final db = await database;
    return await db.insert('orders', orderData);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await database;
    return await db.query('orders', where: 'is_sync = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrdersReady() async {
    final db = await database;
    return await db.query(
      'orders',
      where:
          'is_sync = ? AND is_order_complete = ? AND is_payment_complete = ?',
      whereArgs: [0, 3, 1],
    );
  }

  // *Fungsi untuk mendapatkan item pesanan berdasarkan ID order
  Future<List<Map<String, dynamic>>> getOrderItemsByOrderId(int orderId) async {
    final db = await database;
    return await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  // *Fungsi untuk mengupdate status sinkronisasi
  Future<void> markOrderAsSynced(int id) async {
    final db = await database;
    await db.update('orders', {'is_sync': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // *Fungsi untuk menghapus order berdasarkan ID
  Future<void> deleteOrder(int id) async {
    final db = await database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // *Fungsi untuk menghapus item pesanan berdasarkan ID order
  Future<void> deleteOrderItemsByOrderId(int orderId) async {
    final db = await database;
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  // *Fungsi untuk mengupdate status order
  Future<void> updateOrderStatus(int orderId, int newStatus) async {
    final db = await database;
    await db.update(
      'orders',
      {'is_order_complete': newStatus},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // *Fungsi untuk mendapatkan order berdasarkan ID
  Future<Map<String, dynamic>?> getOrderById(int id) async {
    final db = await database;
    final result = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // *Fungsi untuk mendapatkan semua customer
  Future<List<Map<String, dynamic>>> getAllCustomer() async {
    final db = await database;
    return await db.query("customers", orderBy: "customer_name ASC");
  }

  // *Fungsi untuk memasukan data customer
  Future<int> insertCustomer(Map<String, dynamic> customerData) async {
    final db = await database;
    return await db.insert("customers", customerData);
  }

  // *Fungsi untuk menghapus customer berdasarkan ID
  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete("customers", where: 'id = ?', whereArgs: [id]);
  }

  // *Fungsi untuk mengupdate data customer
  Future<int> updateCustomer({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    final db = await database;
    return await db.update(
      'customers',
      {'customer_name': name, 'phone_number': phone, 'address': address},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // *Fungsi untuk mendapatkan semua pajak
  Future<List<Map<String, dynamic>>> getAllTax() async {
    final db = await database;
    return await db.query("tax", orderBy: "id ASC");
  }

  // *Fungsi untuk memasukan data pajak
  Future<int> insertTax(Map<String, dynamic> taxData) async {
    final db = await database;
    return await db.insert("tax", taxData);
  }

  // *Fungsi untuk menghapus pajak berdasarkan ID
  Future<int> deleteTax(int id) async {
    final db = await database;
    return await db.delete("tax", where: 'id = ?', whereArgs: [id]);
  }

  // *Fungsi untuk mengupdate data pajak
  Future<void> updateTax({
    required int id,
    required String taxName,
    required double tax,
  }) async {
    final db = await database;
    await db.update(
      'tax',
      {'tax_name': taxName, 'tax': tax},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // *Fungsi untuk mendapatkan semua diskon
  Future<List<Map<String, dynamic>>> getAllDiscount() async {
    final db = await database;
    return await db.query("discount", orderBy: "id ASC");
  }

  // *Fungsi untuk memasukan data diskon
  Future<int> insertDiscount(Map<String, dynamic> discountData) async {
    final db = await database;
    return await db.insert("discount", discountData);
  }

  // *Fungsi untuk menghapus diskon berdasarkan ID
  Future<int> deleteDiscount(int id) async {
    final db = await database;
    return await db.delete("discount", where: 'id = ?', whereArgs: [id]);
  }

  // *Fungsi untuk mengupdate data diskon
  Future<void> updateDiscount({
    required int id,
    required String discountName,
    required double discount,
  }) async {
    final db = await database;
    await db.update(
      'discount',
      {'discount_name': discountName, 'discount': discount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // *Fungsi untuk mendapatkan detail item pesanan dengan nama produk
  Future<List<Map<String, dynamic>>> getOrderItemDetailsWithProduct(
    int orderId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT oi.*, b.product_name AS product_name
    FROM order_items oi
    JOIN products b ON b.id = oi.product_id
    WHERE oi.order_id = ?
  ''',
      [orderId],
    );

    return result;
  }

  // *Fungsi untuk mendapatkan jumlah order berdasarkan status
  Future<int> getJumlahOrderStatusid(int status) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) FROM orders WHERE is_order_complete = ?',
      [status],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // *Fungsi untuk mendapatkan jumlah order berdasarkan status pembayaran
  Future<void> updateOrderPayment(
    int orderId,
    int paymentAmount,
    int isComplete,
    int paymentMethod,
  ) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'total_payment': paymentAmount,
        'is_payment_complete': isComplete,
        'payment_method': paymentMethod,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
