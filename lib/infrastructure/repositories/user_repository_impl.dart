import 'package:postgres/postgres.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../database/database_connection.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<List<User>> getAllUsers() async {
    final connection = await DatabaseConnection.connection;
    final results = await connection.execute(
      Sql.named('SELECT * FROM users ORDER BY id'),
    );
    
    return results.map((row) => User(
      id: row[0] as int,
      name: row[1] as String,
      email: row[2] as String,
    )).toList();
  }

  @override
  Future<User?> getUserById(int id) async {
    final connection = await DatabaseConnection.connection;
    final results = await connection.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': id},
    );

    if (results.isEmpty) {
      return null;
    }

    final row = results.first;
    return User(
      id: row[0] as int,
      name: row[1] as String,
      email: row[2] as String,
    );
  }

  @override
  Future<User> createUser(User user) async {
    final connection = await DatabaseConnection.connection;
    final results = await connection.execute(
      Sql.named('INSERT INTO users (name, email) VALUES (@name, @email) RETURNING id'),
      parameters: {'name': user.name, 'email': user.email},
    );

    final newUserId = results.first[0] as int;
    return user.copyWith(id: newUserId);
  }

  @override
  Future<bool> userExistsByEmail(String email) async {
    final connection = await DatabaseConnection.connection;
    final results = await connection.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    return results.isNotEmpty;
  }
}
