import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'user_routes.dart';
import '../controllers/user_controller.dart';

class AppRoutes {
  final UserController _userController;

  AppRoutes(this._userController);

  Router get router {
    final router = Router();

    // Test endpoint
    router.get('/test', (Request request) {
      print('📥 GET /test request received');
      return Response.ok('Hello from server!', headers: {'Content-Type': 'text/plain'});
    });

    // User routes
    final userRoutes = UserRoutes(_userController);
    router.mount('/api', userRoutes.router.call);

    // CORS preflight handler
    router.options('/<path|.*>', (Request request) {
      return Response.ok('', headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, ngrok-skip-browser-warning',
      });
    });

    return router;
  }
}
