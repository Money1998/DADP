import '../entities/user.dart';
import '../repositories/user_repository.dart';

class CreateUserUseCase {
  final UserRepository _userRepository;

  CreateUserUseCase(this._userRepository);

  Future<User> execute({
    required String name,
    required String email,
  }) async {
    // Check if email already exists
    final emailExists = await _userRepository.userExistsByEmail(email);
    if (emailExists) {
      throw UserAlreadyExistsException('A user with this email address already exists');
    }

    final user = User(name: name, email: email);
    return await _userRepository.createUser(user);
  }
}

class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException(this.message);
  
  @override
  String toString() => message;
}
