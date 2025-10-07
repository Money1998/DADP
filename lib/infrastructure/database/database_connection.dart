import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseConnection {
  static Connection? _connection;
  static bool _isInitialized = false;

  static Future<Connection> get connection async {
    if (_connection == null || !_connection!.isOpen) {
      _connection = await _initDatabase();
    }
    return _connection!;
  }

  static Future<Connection> _initDatabase() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final databaseUrl = Platform.environment['DATABASE_URL'];

        if (databaseUrl == null || databaseUrl.isEmpty) {
          throw Exception('DATABASE_URL environment variable is required');
        }

        final uri = Uri.parse(databaseUrl);
        
        String host = uri.host;
        int port = uri.port;
        String database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'mydb';
        String username = uri.userInfo.split(':').first;
        String password = uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':').last : '';
        
        if (port == 0) {
          port = 5432;
        }
        
        if (database.startsWith('/')) {
          database = database.substring(1);
        }

        print('🔄 Attempting to connect to database (attempt ${retryCount + 1}/$maxRetries)...');
        print('📍 Host: $host, Port: $port, Database: $database, User: $username');

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
            queryTimeout: Duration(seconds: 30),
          ),
        );

        // Test the connection with a simple query
        await connection.execute(Sql('SELECT 1'));
        
        print('✅ Successfully connected to PostgreSQL database');
        _isInitialized = true;
        return connection;
      } catch (e) {
        retryCount++;
        print('❌ Database connection failed (attempt $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          print('💥 Failed to connect to database after $maxRetries attempts');
          rethrow;
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    
    throw Exception('Failed to connect to database after $maxRetries attempts');
  }

  static Future<void> initialize() async {
    if (!_isInitialized) {
      await connection;
    }
  }

  static Future<bool> isConnected() async {
    try {
      if (_connection == null || !_connection!.isOpen) {
        return false;
      }
      await _connection!.execute(Sql('SELECT 1'));
      return true;
    } catch (e) {
      print('⚠️ Connection health check failed: $e');
      return false;
    }
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _isInitialized = false;
  }
}
