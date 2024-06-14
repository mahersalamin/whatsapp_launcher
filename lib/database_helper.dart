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

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'contacts_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE contacts(id INTEGER PRIMARY KEY, displayName TEXT, phoneNumber TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertContact(Map<String, dynamic> contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  // Method to retrieve contacts as a list of objects
  Future<List<ContactModel>> getContactsList() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) {
      return ContactModel(
        id: maps[i]['id'],
        displayName: maps[i]['displayName'],
        phoneNumber: maps[i]['phoneNumber'],
      );
    });
  }

  Future<void> deleteContacts() async {
    final db = await database;
    await db.delete('contacts');
  }
}

class ContactModel {
  final int id;
  final String displayName;
  final String phoneNumber;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
  });
}
