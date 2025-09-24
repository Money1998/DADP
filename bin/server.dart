import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

// Database connection
late Connection _connection;

void main(List<String> args) async {
  // Initialize database connection
  await _initDatabase();

  // Create router
  final router = Router();

  router.get('/test', (Request request) {
    print('📥 GET /test request received');
    return Response.ok('Hello from server!', headers: {'Content-Type': 'text/plain'});
  });

  // GET all users
  router.get('/users', (Request request) async {
    try {
      final results = await _connection.execute(
        Sql.named('SELECT * FROM users ORDER BY id'),
      );
      final users = results
          .map((row) => {'id': row[0], 'name': row[1], 'email': row[2]})
          .toList();

      return Response.ok(
        jsonEncode({'status': 'success', 'data': users}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch users: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // GET single user by ID
  router.get('/users/<id>', (Request request, String id) async {
    try {
      final results = await _connection.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': int.tryParse(id)},
      );

      if (results.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = {
        'id': results.first[0],
        'name': results.first[1],
        'email': results.first[2],
      };

      return Response.ok(
        jsonEncode({'status': 'success', 'data': user}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch user: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // POST create new user
  router.post('/users', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final name = data['name'] as String?;
      final email = data['email'] as String?;

      if (name == null || email == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Name and email are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if email already exists
      final existingUser = await _connection.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (existingUser.isNotEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Email The already exists',
            'message': 'A user with this email address already exists'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final results = await _connection.execute(
        Sql.named('INSERT INTO users (name, email) VALUES (@name, @email) RETURNING id'),
        parameters: {'name': name, 'email': email},
      );

      final newUserId = results.first[0];

      return Response.ok(
        jsonEncode({
          'status': 'success',
          'message': 'User created successfully',
          'data': {'id': newUserId, 'name': name, 'email': email},
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create user: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // Add OPTIONS handler for CORS preflight
  router.options('/<path|.*>', (Request request) {
    return Response.ok('', headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, ngrok-skip-browser-warning',
    });
  });

  // Start server with CORS middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders()) // This handles CORS automatically
      .addHandler(router.call);

  // Get port from environment variable (Render requirement)
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, '0.0.0.0', port);
  print('✅ Server running at http://${server.address.host}:${server.port}');
  print('✅ Connected to PostgreSQL database');
  print('✅ CORS enabled for cross-origin requests');
}

Future<void> _initDatabase() async {
  try {
    // Get database URL from environment variable (Render requirement)
    final databaseUrl = Platform.environment['DATABASE_URL'];

    print(' DATABASE_URL: ${databaseUrl != null ? "Found" : "Not found"}');

    if (databaseUrl == null || databaseUrl.isEmpty) {
      print('❌ DATABASE_URL environment variable not set!');
      print('❌ Available environment variables:');
      Platform.environment.forEach((key, value) {
        if (key.toLowerCase().contains('database') || key.toLowerCase().contains('db')) {
          print('   $key: $value');
        }
      });
      throw Exception('DATABASE_URL environment variable is required');
    }

    // Parse DATABASE_URL
    final uri = Uri.parse(databaseUrl);
    
    // Extract components with better error handling
    String host = uri.host;
    int port = uri.port;
    String database = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb';
    String username = uri.userInfo.split(':').first;
    String password = uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':').last : '';
    
    // Handle missing port - Neon often doesn't include port in URL
    if (port == 0) {
      // Check if this is a Neon URL and use appropriate port
      if (host.contains('neon.tech') || host.contains('neon')) {
        port = 5432; // Neon default port
      } else {
        port = 5432; // Standard PostgreSQL port
      }
    }
    
    // Clean up database name
    if (database.startsWith('/')) {
      database = database.substring(1);
    }
    
    print('🔗 Connecting to database: $host:$port');
    print('🔗 Database name: $database');
    print('🔗 Username: $username');
    print('🔗 SSL Mode: require');

    _connection = await Connection.open(
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
  } catch (e) {
    print('❌ Database connection failed: $e');
    print('❌ Full error details: ${e.toString()}');
    rethrow;
  }
}