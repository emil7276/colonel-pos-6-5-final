import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../core/utils.dart';

class DB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dir = await getDatabasesPath();

    _db = await openDatabase(
      path.join(dir, 'colonel_pos_v64.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price INTEGER NOT NULL,
            stock INTEGER NOT NULL DEFAULT 0,
            active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_no TEXT NOT NULL UNIQUE,
            sale_time TEXT NOT NULL,
            cashier TEXT NOT NULL,
            subtotal INTEGER NOT NULL,
            discount INTEGER NOT NULL,
            total INTEGER NOT NULL,
            cash INTEGER NOT NULL,
            change_amount INTEGER NOT NULL,
            payment TEXT NOT NULL,
            returned INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE sale_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER,
            name TEXT NOT NULL,
            qty INTEGER NOT NULL,
            price INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE stock_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            time TEXT NOT NULL,
            type TEXT NOT NULL,
            qty INTEGER NOT NULL,
            note TEXT
          )
        ''');

        await db.insert('users', {
          'username': 'admin',
          'password': '1234',
          'role': 'Administrator',
          'active': 1,
        });

        await db.insert('users', {
          'username': 'kasir',
          'password': '1234',
          'role': 'Kasir',
          'active': 1,
        });

        final products = [
          ['Dada', 'Ayam', 12000],
          ['Paha Atas', 'Ayam', 12000],
          ['Paha Bawah', 'Ayam', 9000],
          ['Sayap', 'Ayam', 9000],
          ['Paket Dada', 'Paket', 15500],
          ['Paket Paha Atas', 'Paket', 15500],
          ['Paket Paha Bawah', 'Paket', 12500],
          ['Paket Sayap', 'Paket', 12500],
          ['Sambal Geprek', 'Tambahan', 3000],
          ['Kentang Goreng', 'Tambahan', 8000],
          ['Air Mineral', 'Minuman', 4000],
          ['Es Teh', 'Minuman', 4000],
        ];

        for (final p in products) {
          await db.insert('products', {
            'name': p[0],
            'category': p[1],
            'price': p[2],
            'stock': 0,
            'active': 1,
          });
        }
      },
    );

    return _db!;
  }

  static Future<List<Map<String, dynamic>>> products() async {
    final db = await database;

    return db.query(
      'products',
      orderBy: 'category,name',
    );
  }

  static Future<List<Map<String, dynamic>>> users() async {
    final db = await database;

    return db.query(
      'users',
      orderBy: 'username',
    );
  }

  static Future<List<Map<String, dynamic>>> sales() async {
    final db = await database;

    return db.query(
      'sales',
      orderBy: 'sale_time DESC',
    );
  }

  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    final db = await database;

    final rows = await db.query(
      'users',
      where: 'username=? AND password=? AND active=1',
      whereArgs: [username, password],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  static Future<void> saveProduct({
    int? id,
    required String name,
    required String category,
    required int price,
    required int stock,
    required bool active,
  }) async {
    final db = await database;

    if (name.trim().isEmpty) {
      throw Exception('Nama menu tidak boleh kosong.');
    }

    if (category.trim().isEmpty) {
      throw Exception('Kategori tidak boleh kosong.');
    }

    if (price <= 0) {
      throw Exception('Harga harus lebih dari 0.');
    }

    if (stock < 0) {
      throw Exception('Stok tidak boleh negatif.');
    }

    final data = {
      'name': name.trim(),
      'category': category.trim(),
      'price': price,
      'stock': stock,
      'active': active ? 1 : 0,
    };

    if (id == null) {
      await db.insert('products', data);
    } else {
      await db.update(
        'products',
        data,
        where: 'id=?',
        whereArgs: [id],
      );
    }
  }

  static Future<void> deleteProduct(int id) async {
    final db = await database;

    await db.update(
      'products',
      {'active': 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> addStock(
    int productId,
    int qty,
    String note,
  ) async {
    if (qty <= 0) {
      throw Exception(
        'Jumlah stok harus lebih dari 0.',
      );
    }

    final db = await database;

    await db.transaction((txn) async {
      final product = await txn.query(
        'products',
        where: 'id=?',
        whereArgs: [productId],
        limit: 1,
      );

      if (product.isEmpty) {
        throw Exception(
          'Produk tidak ditemukan.',
        );
      }

      await txn.rawUpdate(
        'UPDATE products SET stock=stock+? WHERE id=?',
        [qty, productId],
      );

      await txn.insert('stock_logs', {
        'product_id': productId,
        'time': stamp(),
        'type': 'MASUK',
        'qty': qty,
        'note': note,
      });
    });
  }

  static Future<String> nextSaleNo(
    Transaction txn,
  ) async {
    final rows = await txn.rawQuery(
      'SELECT id FROM sales ORDER BY id DESC LIMIT 1',
    );

    final next = rows.isEmpty
        ? 1
        : (rows.first['id'] as int) + 1;

    return 'CFC-${next.toString().padLeft(6, '0')}';
  }

  static Future<int> createSale({
    required String cashier,
    required List<CartLine> items,
    required int subtotal,
    required int discount,
    required int total,
    required int cash,
    required int change,
    required String payment,
  }) async {
    if (items.isEmpty) {
      throw Exception(
        'Keranjang masih kosong.',
      );
    }

    if (total < 0) {
      throw Exception(
        'Total transaksi tidak valid.',
      );
    }

    final db = await database;

    return db.transaction<int>((txn) async {
      for (final line in items) {
        final rows = await txn.query(
          'products',
          columns: [
            'id',
            'name',
            'stock',
            'active',
          ],
          where: 'id=?',
          whereArgs: [line.product.id],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw Exception(
            'Produk ${line.product.name} tidak ditemukan.',
          );
        }

        final product = rows.first;

        if ((product['active'] as int) != 1) {
          throw Exception(
            'Produk ${line.product.name} tidak aktif.',
          );
        }

        final stock =
            (product['stock'] as num).toInt();

        if (stock < line.qty) {
          throw Exception(
            'Stok ${line.product.name} tidak cukup. '
            'Tersedia $stock, diperlukan ${line.qty}.',
          );
        }
      }

      // IMPORTANT:
      // Gunakan transaction yang sama.
      final no = await nextSaleNo(txn);

      final saleId = await txn.insert(
        'sales',
        {
          'sale_no': no,
          'sale_time': stamp(),
          'cashier': cashier,
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'cash': cash,
          'change_amount': change,
          'payment': payment,
          'returned': 0,
        },
      );

      for (final line in items) {
        await txn.insert(
          'sale_items',
          {
            'sale_id': saleId,
            'product_id': line.product.id,
            'name': line.product.name,
            'qty': line.qty,
            'price': line.product.price,
          },
        );

        final updated = await txn.rawUpdate(
          'UPDATE products '
          'SET stock=stock-? '
          'WHERE id=? AND stock>=?',
          [
            line.qty,
            line.product.id,
            line.qty,
          ],
        );

        if (updated != 1) {
          throw Exception(
            'Stok ${line.product.name} berubah. '
            'Silakan ulangi transaksi.',
          );
        }

        await txn.insert(
          'stock_logs',
          {
            'product_id': line.product.id,
            'time': stamp(),
            'type': 'KELUAR',
            'qty': line.qty,
            'note': 'Penjualan $no',
          },
        );
      }

      return saleId;
    });
  }

  static Future<List<Map<String, dynamic>>> saleItems(
    int saleId,
  ) async {
    final db = await database;

    return db.query(
      'sale_items',
      where: 'sale_id=?',
      whereArgs: [saleId],
    );
  }

  static Future<void> returnSale(
    int saleId,
    String adminUser,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      final saleRows = await txn.query(
        'sales',
        where: 'id=?',
        whereArgs: [saleId],
        limit: 1,
      );

      if (saleRows.isEmpty) {
        throw Exception(
          'Transaksi tidak ditemukan.',
        );
      }

      if (saleRows.first['returned'] == 1) {
        throw Exception(
          'Transaksi sudah diretur.',
        );
      }

      final items = await txn.query(
        'sale_items',
        where: 'sale_id=?',
        whereArgs: [saleId],
      );

      for (final item in items) {
        final productId = item['product_id'];
        final qty = item['qty'] as int;

        if (productId != null) {
          await txn.rawUpdate(
            'UPDATE products '
            'SET stock=stock+? WHERE id=?',
            [qty, productId],
          );

          await txn.insert(
            'stock_logs',
            {
              'product_id': productId,
              'time': stamp(),
              'type': 'RETUR',
              'qty': qty,
              'note': 'Retur oleh $adminUser',
            },
          );
        }
      }

      await txn.update(
        'sales',
        {'returned': 1},
        where: 'id=?',
        whereArgs: [saleId],
      );
    });
  }

  static Future<List<Map<String, dynamic>>> bestSelling(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT name,
             SUM(qty) qty,
             SUM(qty*price) omzet
      FROM sale_items
      WHERE sale_id IN (
        SELECT id
        FROM sales
        WHERE sale_time >= ?
          AND sale_time < ?
          AND returned=0
      )
      GROUP BY name
      ORDER BY qty DESC
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );
  }

  static Future<List<Map<String, dynamic>>> hourly(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT substr(sale_time,12,2) jam,
             COUNT(*) transaksi,
             SUM(total) omzet
      FROM sales
      WHERE sale_time >= ?
        AND sale_time < ?
        AND returned=0
      GROUP BY jam
      ORDER BY transaksi DESC
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );
  }

  static Future<List<Map<String, dynamic>>> daily(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT substr(sale_time,1,10) tanggal,
             COUNT(*) transaksi,
             SUM(total) omzet
      FROM sales
      WHERE sale_time >= ?
        AND sale_time < ?
        AND returned=0
      GROUP BY tanggal
      ORDER BY transaksi DESC
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );
  }

  static Future<int> omzet(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total),0) total
      FROM sales
      WHERE sale_time >= ?
        AND sale_time < ?
        AND returned=0
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );

    return (rows.first['total'] as num).toInt();
  }

  static Future<void> saveUser({
    int? id,
    required String username,
    required String password,
    required String role,
    required bool active,
  }) async {
    final db = await database;

    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty) {
      throw Exception(
        'Username tidak boleh kosong.',
      );
    }

    if (password.isEmpty) {
      throw Exception(
        'Password tidak boleh kosong.',
      );
    }

    if (role != 'Administrator' &&
        role != 'Kasir') {
      throw Exception(
        'Role pengguna tidak valid.',
      );
    }

    final duplicate = await db.query(
      'users',
      columns: ['id'],
      where: 'username=? AND id!=?',
      whereArgs: [
        cleanUsername,
        id ?? -1,
      ],
      limit: 1,
    );

    if (duplicate.isNotEmpty) {
      throw Exception(
        'Username "$cleanUsername" sudah digunakan.',
      );
    }

    final data = {
      'username': cleanUsername,
      'password': password,
      'role': role,
      'active': active ? 1 : 0,
    };

    if (id == null) {
      await db.insert('users', data);
    } else {
      await db.update(
        'users',
        data,
        where: 'id=?',
        whereArgs: [id],
      );
    }
  }

  static Future<Map<String, dynamic>> daySummary(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final db = await database;
    final salesRows = await db.query('sales', where: 'sale_time >= ? AND sale_time < ?', whereArgs: [start.toIso8601String(), end.toIso8601String()], orderBy: 'sale_time DESC');
    final valid = salesRows.where((x) => x['returned'] != 1).toList();
    final returned = salesRows.where((x) => x['returned'] == 1).toList();
    final itemRows = await db.rawQuery('SELECT COALESCE(SUM(si.qty),0) jumlah FROM sale_items si INNER JOIN sales s ON s.id=si.sale_id WHERE s.sale_time >= ? AND s.sale_time < ? AND s.returned=0', [start.toIso8601String(), end.toIso8601String()]);
    final payments = <String,int>{};
    for (final row in valid) { final p = row['payment']?.toString() ?? 'Lainnya'; payments[p] = (payments[p] ?? 0) + 1; }
    return {'sales': valid, 'returned': returned.length, 'omzet': valid.fold<int>(0, (sum, x) => sum + (x['total'] as num).toInt()), 'transaksi': valid.length, 'item': (itemRows.first['jumlah'] as num).toInt(), 'payments': payments};
  }

  static Future<Map<String, dynamic>> backup() async {
    final db = await database;

    return {
      'version': '6.5.0',
      'created': stamp(),
      'products': await db.query('products'),
      'users': await db.query('users'),
      'sales': await db.query('sales'),
      'sale_items': await db.query('sale_items'),
      'stock_logs': await db.query('stock_logs'),
    };
  }
}