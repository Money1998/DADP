import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetAllUsersUseCase {
  final UserRepository _userRepository;

  GetAllUsersUseCase(this._userRepository);

  Future<List<User>> execute() async {
    return await _userRepository.getAllUsers();
  }
}
