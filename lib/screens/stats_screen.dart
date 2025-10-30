import 'package:flutter/material.dart';
import '../services/api.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int userCount = 0;
  bool loading = true;

  Future<void> _load() async {
    final users = await Api.listUsers();
    setState(() {
      userCount = users.length;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thống kê")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Text(
                "Số người dùng hiện tại: $userCount",
                style: const TextStyle(fontSize: 24),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Api.exportExcel(),
        label: const Text("Xuất Excel"),
        icon: const Icon(Icons.download),
      ),
    );
  }
}
