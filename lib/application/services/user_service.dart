import '../../domain/entities/user.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';

class UserService {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final GetUserByIdUseCase _getUserByIdUseCase;
  final CreateUserUseCase _createUserUseCase;

  UserService(
    this._getAllUsersUseCase,
    this._getUserByIdUseCase,
    this._createUserUseCase,
  );

  Future<List<User>> getAllUsers() async {
    return await _getAllUsersUseCase.execute();
  }

  Future<User?> getUserById(int id) async {
    return await _getUserByIdUseCase.execute(id);
  }

  Future<User> createUser({
    required String name,
    required String email,
  }) async {
    return await _createUserUseCase.execute(name: name, email: email);
  }
}
