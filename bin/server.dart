import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:my_api_server/infrastructure/di/container.dart';
import 'package:my_api_server/infrastructure/database/database_connection.dart';

void main(List<String> args) async {
  try {
    print('🚀 Starting DADP Server...');
    
    // Initialize database connection first
    print('🔌 Initializing database connection...');
    await DatabaseConnection.initialize();
    print('✅ Database connection initialized');

    // Initialize dependency injection container
    print('📦 Initializing dependency injection container...');
    final container = Container();
    container.initialize();
    print('✅ Dependency injection container initialized');

    // Get routes from container
    final router = container.appRoutes.router;

    // Start server with CORS middleware
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(router.call);

    // Get port from environment variable (Render requirement)
    final port = int.parse(Platform.environment['PORT'] ?? '8080');
    final server = await serve(handler, '0.0.0.0', port);
    
    print('✅ Server running at http://${server.address.host}:${server.port}');
    print('✅ Clean Architecture implemented');
    print('✅ CORS enabled for cross-origin requests');
    print('✅ Database connection established');
    
    // Graceful shutdown handling
    ProcessSignal.sigint.watch().listen((_) async {
      print('\n🛑 Shutting down server...');
      await DatabaseConnection.close();
      exit(0);
    });
    
  } catch (e) {
    print('💥 Failed to start server: $e');
    exit(1);
  }
}