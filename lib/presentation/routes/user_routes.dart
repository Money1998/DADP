import 'package:shelf_router/shelf_router.dart';
import '../controllers/user_controller.dart';

class UserRoutes {
  final UserController _userController;

  UserRoutes(this._userController);

  Router get router {
    final router = Router();

    router.get('/users', _userController.getAllUsers);
    router.get('/users/<id>', _userController.getUserById);
    router.post('/users', _userController.createUser);

    return router;
  }
}
