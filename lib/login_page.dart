import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'form_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _ingatSaya = false; // Status checkbox Ingat Saya

  @override
  void initState() {
    super.initState();
    _muatDataIngatSaya();
  }

  // Memuat username yang tersimpan jika sebelumnya mencentang "Ingat Saya"
  Future<void> _muatDataIngatSaya() async {
    final prefs = await SharedPreferences.getInstance();
    final bool statusIngat = prefs.getBool('ingat_saya') ?? false;
    final String savedUsername = prefs.getString('saved_username') ?? '';

    if (statusIngat && savedUsername.isNotEmpty) {
      setState(() {
        _ingatSaya = true;
        _usernameController.text = savedUsername;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi memastikan akun default 'admin' selalu tersimpan permanen jika belum ada
  Future<Map<String, dynamic>> _getDaftarAkun(SharedPreferences prefs) async {
    final String? akunJson = prefs.getString('daftar_akun');
    Map<String, dynamic> daftarAkun = akunJson != null
        ? jsonDecode(akunJson)
        : {};

    if (daftarAkun.isEmpty) {
      daftarAkun['admin'] = {'password': '123456', 'nama': 'Administrator'};
      await prefs.setString('daftar_akun', jsonEncode(daftarAkun));
    }
    return daftarAkun;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final prefs = await SharedPreferences.getInstance();
      final daftarAkun = await _getDaftarAkun(prefs);

      if (daftarAkun.containsKey(username) &&
          daftarAkun[username]['password'] == password) {
        // Simpan pengaturan "Ingat Saya"
        await prefs.setBool('ingat_saya', _ingatSaya);
        if (_ingatSaya) {
          await prefs.setString('saved_username', username);
        } else {
          await prefs.remove('saved_username');
        }

        // Simpan identitas petugas aktif untuk FormPage dan PDF
        await prefs.setString(
          'current_user_nama',
          daftarAkun[username]['nama'] ?? username,
        );
        await prefs.setString('current_user_nip', username);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FormPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username atau Password tidak cocok!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Dialog Reset Password
  void _tampilkanDialogLupaPassword() {
    final resetUsernameCtrl = TextEditingController(
      text: _usernameController.text.trim(),
    );
    final newPasswordCtrl = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan Username/NIP Anda yang terdaftar untuk membuat password baru.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: resetUsernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username / NIP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Username wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password baru wajib diisi';
                    }
                    if (val.length < 6) {
                      return 'Minimal 6 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!resetFormKey.currentState!.validate()) return;

                final prefs = await SharedPreferences.getInstance();
                final daftarAkun = await _getDaftarAkun(prefs);
                final targetUser = resetUsernameCtrl.text.trim();

                if (!context.mounted) return;

                if (daftarAkun.containsKey(targetUser)) {
                  daftarAkun[targetUser]['password'] = newPasswordCtrl.text;
                  await prefs.setString('daftar_akun', jsonEncode(daftarAkun));

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password berhasil diperbarui! Silakan login.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username / NIP tidak ditemukan!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Simpan Password'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFee7752),
              Color(0xFFe73c7e),
              Color(0xFF23a6d5),
              Color(0xFF23d5ab),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo_sekolah.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school,
                                size: 40,
                                color: Colors.blueAccent,
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              "AGENDA KEGIATAN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username / NIP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Username wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Baris Checkbox "Ingat Saya" & Tombol "Lupa Password?"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _ingatSaya,
                                activeColor: const Color(0xFF23a6d5),
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) {
                                  setState(() {
                                    _ingatSaya = value ?? false;
                                  });
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _ingatSaya = !_ingatSaya;
                                  });
                                },
                                child: const Text(
                                  'Ingat Saya',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _tampilkanDialogLupaPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF23a6d5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF23a6d5),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: const Text(
                          'Belum punya akun? Buat Akun Baru',
                          style: TextStyle(color: Colors.blueGrey),
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
