import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseConnection {
  static Connection? _connection;

  static Future<Connection> get connection async {
    _connection ??= await _initDatabase();
    return _connection!;
  }

  static Future<Connection> _initDatabase() async {
    try {
      final databaseUrl = Platform.environment['DATABASE_URL'];

      if (databaseUrl == null || databaseUrl.isEmpty) {
        throw Exception('DATABASE_URL environment variable is required');
      }

      final uri = Uri.parse(databaseUrl);
      
      String host = uri.host;
      int port = uri.port;
      String database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb';
      String username = uri.userInfo.split(':').first;
      String password = uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':').last : '';
      
      if (port == 0) {
        if (host.contains('neon.tech') || host.contains('neon')) {
          port = 5432;
        } else {
          port = 5432;
        }
      }
      
      if (database.startsWith('/')) {
        database = database.substring(1);
      }

      final connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(seconds: 30),
        ),
      );

      print('✅ Connected to PostgreSQL database');
      return connection;
    } catch (e) {
      print('❌ Database connection failed: $e');
      rethrow;
    }
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
