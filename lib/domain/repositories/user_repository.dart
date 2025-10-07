import '../entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(int id);
  Future<User> createUser(User user);
  Future<bool> userExistsByEmail(String email);
}
