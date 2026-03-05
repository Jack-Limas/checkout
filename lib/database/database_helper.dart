import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ================= DATABASE GETTER =================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('checkout.db');
    return _database!;
  }

  // ================= INIT DATABASE =================
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // 👈 SUBIMOS VERSION PARA FORZAR UPDATE
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE TABLES =================
  Future _createDB(Database db, int version) async {

    await db.execute('''
CREATE TABLE products(
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT NOT NULL,
price REAL NOT NULL
)
''');

    await db.execute('''
CREATE TABLE cards(
id INTEGER PRIMARY KEY AUTOINCREMENT,
cardNumber TEXT NOT NULL,
holderName TEXT NOT NULL,
expiryDate TEXT NOT NULL,
cvv TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE promo_codes(
id INTEGER PRIMARY KEY AUTOINCREMENT,
code TEXT NOT NULL,
discount REAL NOT NULL,
minAmount REAL NOT NULL
)
''');

    // 🔥 PROMO EXACTA DEL MOCKUP
    await db.insert('promo_codes', {
      'code': 'PROMO20-08',
      'discount': 50000,
      'minAmount': 150000
    });

    // 🔥 PRODUCTOS
    await db.insert('products', {'name': 'Nike Air Max 270', 'price': 450000});
    await db.insert('products', {'name': 'Adidas Hoodie Premium', 'price': 280000});
    await db.insert('products', {'name': 'Apple Watch Series 9', 'price': 1200000});
    await db.insert('products', {'name': 'AirPods Pro 2', 'price': 950000});
    await db.insert('products', {'name': 'Jordan Retro 4', 'price': 780000});
    await db.insert('products', {'name': 'MacBook Air M2', 'price': 5200000});
  }

  // ================= ON UPGRADE =================
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute("DROP TABLE IF EXISTS products");
    await db.execute("DROP TABLE IF EXISTS cards");
    await db.execute("DROP TABLE IF EXISTS promo_codes");
    await _createDB(db, newVersion);
  }

  // =====================================================
  // ================= PRODUCTS ==========================
  // =====================================================

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateProduct(int id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update('products', product, where: 'id=?', whereArgs: [id]);
  }

  // =====================================================
  // ================= CARDS =============================
  // =====================================================

  Future<int> insertCard(Map<String, dynamic> card) async {
    final db = await database;
    return await db.insert('cards', card);
  }

  Future<List<Map<String, dynamic>>> getCards() async {
    final db = await database;
    return await db.query('cards');
  }

  Future<int> deleteCard(int id) async {
    final db = await database;
    return await db.delete('cards', where: 'id=?', whereArgs: [id]);
  }

  Future<int> updateCard(int id, Map<String, dynamic> card) async {
    final db = await database;
    return await db.update('cards', card, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteAllCards() async {
    final db = await database;
    await db.delete('cards');
  }

  // =====================================================
  // ================= PROMO =============================
  // =====================================================

  Future<Map<String, dynamic>?> validatePromo(String code) async {
    final db = await database;

    final result = await db.query(
      'promo_codes',
      where: 'code=?',
      whereArgs: [code],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // =====================================================
  // ================= EXTRA CONTROL =====================
  // =====================================================

  Future<void> closeDB() async {
    final db = await database;
    db.close();
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'checkout.db');
    await deleteDatabase(path);
  }
}