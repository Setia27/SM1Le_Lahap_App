import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/session_service.dart';
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

  // Inisialisasi client Supabase
  final _supabase = Supabase.instance.client;

  // Sesuaikan dengan nama tabel user yang Anda buat di Supabase
  final String _namaTabel = 'profil_tendik';

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _ingatSaya = false;

  @override
  void initState() {
    super.initState();
    _muatDataIngatSaya();
  }
  Future<void> _muatDataIngatSaya() async {
    final data = await SessionService.getRememberMe();
    final bool statusIngat = data['ingat_saya'] as bool;
    final String savedUsername = data['saved_username'] as String;

    if (statusIngat && savedUsername.isNotEmpty && mounted) {
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Cek kecocokan username & password ke Supabase
      final response = await _supabase
          .from(_namaTabel)
          .select()
          .eq('nip', username)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // 2. Simpan sesi aktif dan status "Ingat Saya" lewat SessionService
        await SessionService.saveSession(
          nip: username,
          nama: response['nama'] ?? username,
          fotoUrl: response['foto_profil'] ?? '',
          ingatSaya: _ingatSaya,
        );

        if (!mounted) return;
        // 3. Pindah ke FormPage dan hapus riwayat navigasi sebelumnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FormPage()),
          (Route<dynamic> route) => false,
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal terhubung ke server: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Dialog Reset Password ke Supabase
  void _tampilkanDialogLupaPassword() {
    final resetUsernameCtrl = TextEditingController(
      text: _usernameController.text.trim(),
    );
    final newPasswordCtrl = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  onPressed: isResetting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (!resetFormKey.currentState!.validate()) return;

                          setDialogState(() => isResetting = true);
                          final targetUser = resetUsernameCtrl.text.trim();

                          try {
                            // Cek apakah username ada di Supabase
                            final existingUser = await _supabase
                                .from(_namaTabel)
                                .select('nip')
                                .eq('nip', targetUser)
                                .maybeSingle();

                            if (!context.mounted) return;

                            if (existingUser != null) {
                              // Update password baru di Supabase
                              await _supabase
                                  .from(_namaTabel)
                                  .update({'password': newPasswordCtrl.text})
                                  .eq('nip', targetUser);
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
                                  content: Text(
                                    'Username / NIP tidak ditemukan!',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Terjadi kesalahan: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setDialogState(() => isResetting = false);
                            }
                          }
                        },
                  child: isResetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
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
              Color.fromARGB(255, 115, 215, 255), // Biru langit cerah lembut
              Color.fromARGB(255, 56, 163, 255), // Biru cerah terang
              Color.fromARGB(255, 72, 202, 228), // Biru cerah lembut
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
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
                      Image.asset(
                        'assets/images/logo_sekolah.png',
                        height: 85,
                        width: 85,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school,
                            size: 64,
                            color: Color(0xFF23a6d5),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AGENDA KEGIATAN',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Silakan masuk menggunakan akun Anda',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
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
                            ? 'Username / NIP wajib diisi'
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _ingatSaya,
                                onChanged: (val) {
                                  setState(() {
                                    _ingatSaya = val ?? false;
                                  });
                                },
                              ),
                              const Text('Ingat Saya'),
                            ],
                          ),
                          TextButton(
                            onPressed: _tampilkanDialogLupaPassword,
                            child: const Text('Lupa Password?'),
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
                                'Masuk',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun?'),
                          TextButton(
                            onPressed: _navigateToRegister,
                            child: const Text('Daftar Sekarang'),
                          ),
                        ],
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
