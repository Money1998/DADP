import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../application/services/user_service.dart';
import '../../domain/usecases/create_user_usecase.dart';

class UserController {
  final UserService _userService;

  UserController(this._userService);

  Future<Response> getAllUsers(Request request) async {
    try {
      final users = await _userService.getAllUsers();
      return Response.ok(
        jsonEncode({'status': 'success', 'data': users}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch users: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> getUserById(Request request, String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid user ID'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.getUserById(userId);
      if (user == null) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'status': 'success', 'data': user}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch user: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> createUser(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final name = data['name'] as String?;
      final email = data['email'] as String?;

      if (name == null || email == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Name and email are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = await _userService.createUser(name: name, email: email);

      return Response.ok(
        jsonEncode({
          'status': 'success',
          'message': 'User created successfully',
          'data': user,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on UserAlreadyExistsException catch (e) {
      return Response.badRequest(
        body: jsonEncode({
          'error': 'Email already exists',
          'message': e.message,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create user: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}

