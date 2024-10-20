import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../models/todo_model.dart';

/// Lớp định nghĩa các route cho các hoạt động CRUD trên Todo
class TodoRouter {
  /// Danh sách các công việc được quản lý bởi backend
  final _todos = <TodoModel>[];

  /// Tạo và trả về một Router cho các hoạt động CRUD trên Todo
  Router get router {
    final router = Router();

    /// Endpoint Lấy danh sách công việc
    router.get('/todos', _getTodoHandler);

    /// Endpoint thêm công việc vào danh sách
    router.post('/todos', _addTodoHandler);

    /// Endpoint xóa một công việc
    router.delete('/todos/<id>', _deleteTodoHandler);

    /// Endpoint cập nhật một công việc theo id
    router.put('/todos/<id>', _updateTodoHandler);

    return router;
  }

  /// Header mặc định cho dữ liệu trả về dưới dạng JSON
  static final _headers = {'Content-Type': 'application/json'};

  /// Xử lý yêu cầu lấy danh sách công việc
  Future<Response> _getTodoHandler(Request req) async {
    try {
      final body = json.encode(_todos.map((todo) => todo.toMap()).toList());
      return Response.ok(
        body,
        headers: _headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  /// Xử lý yêu cầu thêm công việc vào danh sách
  Future<Response> _addTodoHandler(Request req) async {
    try {
      final payload = await req.readAsString();
      final data = json.decode(payload);
      final todo = TodoModel.fromMap(data);
      _todos.add(todo);
      return Response.ok(
        todo.toJson(),
        headers: _headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  /// Xử lý yêu cầu xóa một công việc khỏi danh sách
  Future<Response> _deleteTodoHandler(Request req, String id) async {
    try {
      final index = _todos.indexWhere((todo) => todo.id == int.parse(id));
      if (index == -1) {
        return Response.notFound('Không tìm thấy todo có id = $id');
      }

      final removedTodo = _todos.removeAt(index);
      return Response.ok(
        removedTodo.toJson(),
        headers: _headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }

  /// Xử lý yêu cầu cập nhật một công việc trong danh sách
  Future<Response> _updateTodoHandler(Request req, String id) async {
    try {
      final index = _todos.indexWhere((todo) => todo.id == int.parse(id));
      if (index == -1) {
        return Response.notFound('Không tìm thấy todo có id = $id');
      }

      final payload = await req.readAsString();
      final map = json.decode(payload);
      final updateTodo = TodoModel.fromMap(map);

      _todos[index] = updateTodo;
      return Response.ok(
        updateTodo.toJson(),
        headers: _headers,
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: _headers,
      );
    }
  }
}
