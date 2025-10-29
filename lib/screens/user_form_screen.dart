import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api.dart';

class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  File? image;
  bool loading = false;
  String? error;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      username.text = widget.user!['username'] ?? '';
      email.text = widget.user!['email'] ?? '';
    }
  }

  Future<void> pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x != null) setState(() => image = File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit user" : "Create user")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: image != null
                                ? FileImage(image!)
                                : (isEdit &&
                                          widget.user?['image'] != null &&
                                          widget.user!['image']!.isNotEmpty
                                      ? NetworkImage(widget.user!['image'])
                                      : null),
                            child:
                                (image == null &&
                                    (widget.user?['image'] == null ||
                                        widget.user!['image'].isEmpty))
                                ? const Icon(Icons.person, size: 36)
                                : null,
                          ),

                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.photo),
                            label: const Text("Pick image"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: "Username",
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        decoration: InputDecoration(
                          labelText: isEdit
                              ? "Password (optional)"
                              : "Password",
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (!isEdit && (v == null || v.isEmpty))
                            return "Required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (error != null)
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                if (!_form.currentState!.validate()) return;
                                setState(() {
                                  loading = true;
                                  error = null;
                                });
                                try {
                                  if (isEdit) {
                                    await Api.updateUser(
                                      id: widget.user!['id'],
                                      username: username.text.trim(),
                                      email: email.text.trim(),
                                      password: password.text.isEmpty
                                          ? null
                                          : password.text.trim(),
                                      image: image,
                                    );
                                  } else {
                                    await Api.createUser(
                                      username: username.text.trim(),
                                      email: email.text.trim(),
                                      password: password.text.trim(),
                                      image: image,
                                    );
                                  }
                                  if (!mounted) return;
                                  Navigator.pop(context, true);
                                } catch (e) {
                                  setState(() => error = e.toString());
                                }
                                setState(() => loading = false);
                              },
                        icon: const Icon(Icons.check),
                        label: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            loading
                                ? "Saving..."
                                : (isEdit ? "Save changes" : "Create"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
