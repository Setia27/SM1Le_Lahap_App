import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

class UserProfileCard extends StatelessWidget {
  final String namaUser;
  final String nipUser;
  final String? fotoProfilUrl;
  final ValueChanged<String> onFotoUpdated;

  const UserProfileCard({
    super.key,
    required this.namaUser,
    required this.nipUser,
    required this.fotoProfilUrl,
    required this.onFotoUpdated,
  });

  void _tampilkanPilihanUnggahProfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Color(0xFF23a6d5)),
              title: const Text('Unggah Foto dari Berkas'),
              onTap: () {
                Navigator.pop(sheetContext);
                _prosesUnggahFotoProfil(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prosesUnggahFotoProfil(BuildContext context) async {
    final hasil = await CameraService.ambilDariGaleri();
    if (hasil == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final urlBaru = await SupabaseService.updateFotoProfil(
        nipUser: nipUser,
        fotoBytes: hasil.bytes,
      );

      await SessionService.updateFotoProfil(urlBaru);

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading
      onFotoUpdated(urlBaru);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diunggah!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah foto profil: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _tampilkanPilihanUnggahProfil(context),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF23a6d5),
                backgroundImage:
                    fotoProfilUrl != null ? NetworkImage(fotoProfilUrl!) : null,
                child: fotoProfilUrl == null
                    ? const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 36,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 12,
                    color: Color(0xFF23a6d5),
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          namaUser,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("NIP / Username: $nipUser"),
      ),
    );
  }
}
