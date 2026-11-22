// ============================================================================
// Aplikasi   : LAHAP - SMAN 1 Lembang
// Dibuat oleh: SP_27
// File       : about_dialog_widget.dart
// ============================================================================

import 'package:flutter/material.dart';

class AboutAplikasiDialog extends StatelessWidget {
  const AboutAplikasiDialog({super.key});

  /// Fungsi statis agar dialog mudah dipanggil dari halaman mana pun
  static void tampilkan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AboutAplikasiDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan Gradasi Biru Senada Splash Screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 144, 224, 239), // Biru langit pastel
                  Color.fromARGB(255, 72, 202, 228),  // Biru cerah lembut
                ],
              ),
            ),
            child: Column(
              children: [
                // Wadah Logo Aplikasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0077B6).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_lebah.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SM1Le Lahap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03045E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Laporan Harian Pribadi',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF03045E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Versi 1.0.2',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Isi Informasi Aplikasi & Pengembang
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Aplikasi pencatatan dan pelaporan kegiatan harian GTK beserta dokumentasi foto di lingkungan SMAN 1 Lembang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Informasi Instansi & Pengembang
                _barisInfo(Icons.school_rounded, 'Instansi', 'SMAN 1 Lembang'),
                const SizedBox(height: 10),
                _barisInfo(Icons.code_rounded, 'Dikembangkan oleh', 'SP_27'),
                const SizedBox(height: 10),
                _barisInfo(Icons.calendar_today_rounded, 'Tahun Rilis', '2026'),

                const SizedBox(height: 20),

                // Tombol Tutup
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisInfo(IconData icon, String label, String nilai) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0077B6)),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          nilai,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
