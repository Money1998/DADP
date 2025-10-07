import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/infrastructure/di/container.dart';

void main(List<String> args) async {
  // Initialize dependency injection container
  final container = Container();
  container.initialize();

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
}