import 'package:flutter/material.dart';
import '../services/api.dart';
import 'login_screen.dart';
import 'user_form_screen.dart';
import 'chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> users = [];
  bool loading = true;
  String? error;

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      users = await Api.listUsers();
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return _load();
    setState(() {
      loading = true;
    });
    users = await Api.searchUsers(q);
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await Api.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      // ✅ CHATBOT + ADD USER NÚT NẰM Ở ĐÂY
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: "chatbot",
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
              },
              child: const Icon(Icons.chat),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "addUser",
              onPressed: () async {
                final ok = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserFormScreen()),
                );
                if (ok == true) _load();
              },
              label: const Text('Add user'),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ✅ Search Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search user...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _search,
            ),
          ),

          // ✅ List Users
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!))
                : users.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (u['image'] != null &&
                                    u['image'].toString().isNotEmpty)
                                ? NetworkImage(u['image'])
                                : null,
                            child:
                                (u['image'] == null ||
                                    u['image'].toString().isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(u['username'] ?? ''),
                          subtitle: Text(u['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final ok = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UserFormScreen(user: u),
                                    ),
                                  );
                                  if (ok == true) _load();
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete user?'),
                                      content: Text(
                                        'Are you sure to delete ${u['username']}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes == true) {
                                    await Api.deleteUser(u['id']);
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
