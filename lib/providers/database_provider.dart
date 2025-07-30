import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseProvider extends StateNotifier<Database?> {
  DatabaseProvider() : super(null);

  Future<void> initializeDatabase() async {
    final db = await openDatabase(
      'educonnect.db',
      version: 1,
      onCreate: (db, version) {
        // Create tables here
        return db.execute(
          'CREATE TABLE users(id TEXT PRIMARY KEY, name TEXT, email TEXT)',
        );
      },
    );
    state = db;
  }

  Future<void> closeDatabase() async {
    await state?.close();
    state = null;
  }
}

final databaseProvider = StateNotifierProvider<DatabaseProvider, Database?>(
  (ref) => DatabaseProvider(),
);
