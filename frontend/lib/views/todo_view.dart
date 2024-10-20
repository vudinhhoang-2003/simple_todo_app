import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/todo_model.dart';

/// Sử dụng địa chỉ IP thích hợp cho backend
/// Do Android Emulator sử dụng địa chỉ 10.2.2.2 để truy cập vào localhost
/// của máy chủ thay vì localhost hoặc 127.0.0.1

String getBackendUrl() {
  if (kIsWeb) {
    return 'http://localhost:8080'; // hoặc sử dụng IP LAN nếu cần
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080'; // cho emulator
    // return 'http://192.168.1.x:8080'; // cho thiết bị thật khi truy cập qua LAN
  } else {
    return 'http://localhost:8080';
  }
}

class TodoView extends StatefulWidget {
  const TodoView({super.key});

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  final _todos = <TodoModel>[];
  final _controller = TextEditingController();
  final apiUrl = '${getBackendUrl()}/api/v1/todos';
  final _headers = {'Content-Type': 'application/json'};

  /// Lấy danh sách Todo
  Future<void> _fetchTodos() async {
    final res = await http.get(Uri.parse(apiUrl));

    if (res.statusCode == 200) {
      final List<dynamic> todoList = json.decode(res.body);
      setState(() {
        _todos.clear();
        _todos.addAll(todoList.map((e) => TodoModel.fromMap(e)).toList());
      });
    }
  }

  /// Thêm một todo mới sử dụng phương thức POST
  Future<void> _addTodo() async {
    if (_controller.text.isEmpty) return;

    final newItem = TodoModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _controller.text,
      completed: false,
    );

    final res = await http.post(
      Uri.parse(apiUrl),
      headers: _headers,
      body: json.encode(newItem.toMap()),
    );

    if (res.statusCode == 200) {
      _controller.clear();
      _fetchTodos(); // làm mới danh sách bằng cách lấy danh sách todo mới
    }
  }

  /// Cập nhật trạng thái completed của todo sử dụng phương thức PUT
  Future<void> _updateTodo(TodoModel item) async {
    item.completed = !item.completed; // hoán đổi trạng thái true/false

    try {
      final res = await http.put(
        Uri.parse('$apiUrl/${item.id}'),
        headers: _headers,
        body: json.encode(item.toMap()),
      );

      if (res.statusCode == 200) {
        _fetchTodos(); // làm mới danh sách
      } else {
        debugPrint(res.reasonPhrase);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Xóa todo sử dụng phương thức DELETE
  Future<void> _deleteTodo(int id) async {
    final res = await http.delete(
      Uri.parse('$apiUrl/$id'),
    );

    if (res.statusCode == 200) {
      _fetchTodos(); // làm mới danh sách sau khi xóa todo
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTodos(); // Khi khởi tạo widget lần đầu thì lấy danh sách todo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo App')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Input cho chức năng thêm todo
            Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Todo mới'),
                )),
                IconButton(onPressed: _addTodo, icon: const Icon(Icons.add))
              ],
            ),
            const SizedBox(height: 20),
            // Danh sách todo
            Expanded(
              child: ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final item = _todos.elementAt(index);
                  return ListTile(
                    title: Text(item.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                            value: item.completed,
                            onChanged: (value) {
                              _updateTodo(item);
                            }),
                        IconButton(
                          onPressed: () {
                            _deleteTodo(item.id);
                          },
                          icon: const Icon(Icons.delete),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
