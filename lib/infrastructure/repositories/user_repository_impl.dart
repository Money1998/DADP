import 'dart:io';
import 'package:postgres/postgres.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../database/database_connection.dart';

class UserRepositoryImpl implements UserRepository {
  Future<Connection> _getConnection() async {
    try {
      final connection = await DatabaseConnection.connection;
      
      // Check if connection is still alive
      if (!connection.isOpen) {
        throw Exception('Database connection is closed');
      }
      
      return connection;
    } catch (e) {
      print('❌ Failed to get database connection: $e');
      rethrow;
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final connection = await _getConnection();
      final results = await connection.execute(
        Sql.named('SELECT * FROM users ORDER BY id'),
      );
      
      return results.map((row) => User(
        id: row[0] as int,
        name: row[1] as String,
        email: row[2] as String,
      )).toList();
    } catch (e) {
      print('❌ Error fetching all users: $e');
      rethrow;
    }
  }

  @override
  Future<User?> getUserById(int id) async {
    try {
      final connection = await _getConnection();
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
    } catch (e) {
      print('❌ Error fetching user by id $id: $e');
      rethrow;
    }
  }

  @override
  Future<User> createUser(User user) async {
    try {
      final connection = await _getConnection();
      final results = await connection.execute(
        Sql.named('INSERT INTO users (name, email) VALUES (@name, @email) RETURNING id'),
        parameters: {'name': user.name, 'email': user.email},
      );

      final newUserId = results.first[0] as int;
      return user.copyWith(id: newUserId);
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    }
  }

  @override
  Future<bool> userExistsByEmail(String email) async {
    try {
      final connection = await _getConnection();
      final results = await connection.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error checking if user exists by email $email: $e');
      rethrow;
    }
  }
}
