import 'package:flutter/material.dart';
import '../services/api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messages = <Map<String, String>>[];
  final controller = TextEditingController();
  bool sending = false;

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    setState(() => messages.add({"role": "user", "text": text}));

    sending = true;
    final reply = await Api.chat(text);
    sending = false;

    setState(() => messages.add({"role": "bot", "text": reply}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: messages
                  .map(
                    (m) => Align(
                      alignment: m["role"] == "user"
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: m["role"] == "user"
                              ? Colors.blue[200]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m["text"]!),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Ask something...",
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              IconButton(
                icon: sending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                onPressed: sending ? null : send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
