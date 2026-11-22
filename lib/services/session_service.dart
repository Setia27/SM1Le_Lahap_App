import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyNip = 'current_user_nip';
  static const String _keyNama = 'current_user_nama';
  static const String _keyFoto = 'current_user_foto';

  static const String _keyIngatSaya = 'ingat_saya';
  static const String _keySavedUsername = 'saved_username';

  // Simpan sesi saat Login berhasil
  static Future<void> saveSession({
    required String nip,
    required String nama,
    required String fotoUrl,
    required bool ingatSaya,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNip, nip);
    await prefs.setString(_keyNama, nama);
    await prefs.setString(_keyFoto, fotoUrl);

    await prefs.setBool(_keyIngatSaya, ingatSaya);
    if (ingatSaya) {
      await prefs.setString(_keySavedUsername, nip);
    } else {
      await prefs.remove(_keySavedUsername);
    }
  }

  // Ambil data "Ingat Saya" untuk LoginPage
  static Future<Map<String, dynamic>> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ingat_saya': prefs.getBool(_keyIngatSaya) ?? false,
      'saved_username': prefs.getString(_keySavedUsername) ?? '',
    };
  }

  // Cek status login untuk SplashScreen
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString(_keyNip);
    return nip != null && nip.isNotEmpty && nip != '-';
  }

  // Ambil data sesi user aktif untuk FormPage
  static Future<Map<String, String>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nip': prefs.getString(_keyNip) ?? '-',
      'nama': prefs.getString(_keyNama) ?? 'Tenaga Kependidikan',
      'foto': prefs.getString(_keyFoto) ?? '',
    };
  }

  // Update URL foto profil
  static Future<void> updateFotoProfil(String urlFoto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFoto, urlFoto);
  }

  // Hapus riwayat sesi saat Logout (tanpa menghapus pengaturan "Ingat Saya")
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNip);
    await prefs.remove(_keyNama);
    await prefs.remove(_keyFoto);
  }
}
