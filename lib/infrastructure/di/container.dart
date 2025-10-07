import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../application/services/user_service.dart';
import '../../presentation/controllers/user_controller.dart';
import '../../presentation/routes/app_routes.dart';
import '../repositories/user_repository_impl.dart';

class Container {
  static final Container _instance = Container._internal();
  factory Container() => _instance;
  Container._internal();

  // Repositories
  late final UserRepository _userRepository;
  UserRepository get userRepository => _userRepository;

  // Use Cases
  late final GetAllUsersUseCase _getAllUsersUseCase;
  late final GetUserByIdUseCase _getUserByIdUseCase;
  late final CreateUserUseCase _createUserUseCase;

  // Services
  late final UserService _userService;

  // Controllers
  late final UserController _userController;

  // Routes
  late final AppRoutes _appRoutes;

  void initialize() {
    // Initialize repositories
    _userRepository = UserRepositoryImpl();

    // Initialize use cases
    _getAllUsersUseCase = GetAllUsersUseCase(_userRepository);
    _getUserByIdUseCase = GetUserByIdUseCase(_userRepository);
    _createUserUseCase = CreateUserUseCase(_userRepository);

    // Initialize services
    _userService = UserService(
      _getAllUsersUseCase,
      _getUserByIdUseCase,
      _createUserUseCase,
    );

    // Initialize controllers
    _userController = UserController(_userService);

    // Initialize routes
    _appRoutes = AppRoutes(_userController);
  }

  AppRoutes get appRoutes => _appRoutes;
}
