import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../exports.dart';

class OrderDatabase {
  static final OrderDatabase instance = OrderDatabase._init();
  static Database? _database;
  static final GetStorage _fallbackStorage = GetStorage('orders_database_storage');

  OrderDatabase._init();

  Future<Database?> get database async {
    if (_database != null) return _database;
    try {
      _database = await _initDB('orders_database.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite initialization error, using fallback storage: $e');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE orders (
  id $idType,
  customer_name $textType,
  mobile $textType,
  subtitle $textType,
  order_title $textType,
  date $textType,
  created_at $textType
)
''');

    await db.execute('''
CREATE TABLE order_items (
  id $idType,
  order_id $textType,
  sr_no $intType,
  size $textType,
  gram $textType,
  pipes $textType,
  FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
)
''');
  }

  Future<void> insertOrder(OrderModel order) async {
    final db = await database;
    if (db != null) {
      try {
        await db.transaction((txn) async {
          await txn.insert(
            'orders',
            {
              'id': order.id,
              'customer_name': order.customerName,
              'mobile': order.mobile,
              'subtitle': order.subtitle,
              'order_title': order.orderTitle,
              'date': order.date,
              'created_at': order.createdAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.delete(
            'order_items',
            where: 'order_id = ?',
            whereArgs: [order.id],
          );

          for (var item in order.items) {
            await txn.insert(
              'order_items',
              item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        return;
      } catch (e) {
        debugPrint('SQLite insert failed, falling back: $e');
      }
    }

    // Fallback storage
    final List<dynamic> currentStored =
        _fallbackStorage.read<List<dynamic>>('orders_list') ?? [];
    final list = currentStored.map((e) => Map<String, dynamic>.from(e)).toList();
    final index = list.indexWhere((element) => element['id'] == order.id);
    if (index != -1) {
      list[index] = order.toMap();
    } else {
      list.add(order.toMap());
    }
    await _fallbackStorage.write('orders_list', list);
  }

  Future<void> updateOrder(OrderModel order) async {
    await insertOrder(order);
  }

  Future<void> deleteOrder(String id) async {
    final db = await database;
    if (db != null) {
      try {
        await db.delete(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [id],
        );
        await db.delete(
          'orders',
          where: 'id = ?',
          whereArgs: [id],
        );
        return;
      } catch (e) {
        debugPrint('SQLite delete failed, falling back: $e');
      }
    }

    // Fallback storage
    final List<dynamic> currentStored =
        _fallbackStorage.read<List<dynamic>>('orders_list') ?? [];
    final list = currentStored.map((e) => Map<String, dynamic>.from(e)).toList();
    list.removeWhere((element) => element['id'] == id);
    await _fallbackStorage.write('orders_list', list);
  }

  Future<List<OrderModel>> getAllOrders() async {
    final db = await database;
    if (db != null) {
      try {
        final ordersData = await db.query('orders', orderBy: 'created_at DESC');
        List<OrderModel> ordersList = [];

        for (var orderMap in ordersData) {
          final id = orderMap['id'] as String;
          final itemsData = await db.query(
            'order_items',
            where: 'order_id = ?',
            whereArgs: [id],
            orderBy: 'sr_no ASC',
          );

          final items = itemsData
              .map((itemMap) => OrderItemModel.fromMap(itemMap))
              .toList();

          final fullMap = Map<String, dynamic>.from(orderMap);
          fullMap['items'] = items.map((i) => i.toMap()).toList();

          ordersList.add(OrderModel.fromMap(fullMap));
        }

        return ordersList;
      } catch (e) {
        debugPrint('SQLite fetch failed, using fallback storage: $e');
      }
    }

    // Fallback storage
    final List<dynamic> currentStored =
        _fallbackStorage.read<List<dynamic>>('orders_list') ?? [];
    return currentStored
        .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OrderModel?> getOrderById(String id) async {
    final orders = await getAllOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
