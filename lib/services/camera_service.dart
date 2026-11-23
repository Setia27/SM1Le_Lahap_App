import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class HasilFoto {
  final String namaFile;
  final Uint8List bytes;

  HasilFoto({required this.namaFile, required this.bytes});
}

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// 1. Mengambil foto langsung dari KAMERA (untuk dokumentasi kegiatan)
  static Future<HasilFoto?> ambilDariKamera() async {
    return await _prosesAmbilDanKompres(
      source: ImageSource.camera,
      maxDimension: 1600,
      minCompressDimension: 800,
    );
  }

  /// 2. Mengambil foto dari GALERI (untuk dokumentasi kegiatan)
  static Future<HasilFoto?> ambilDariGaleri() async {
    return await _prosesAmbilDanKompres(
      source: ImageSource.gallery,
      maxDimension: 1200,
      minCompressDimension: 800,
    );
  }

  /// 3. Mengambil foto profil dari BERKAS/GALERI (khusus ukuran 500x500)
  static Future<HasilFoto?> pilihFotoDariBerkas() async {
    return await _prosesAmbilDanKompres(
      source: ImageSource.gallery,
      maxDimension: 800,
      minCompressDimension: 500,
    );
  }

  /// Fungsi internal untuk memproses pengambilan dan kompresi gambar
  static Future<HasilFoto?> _prosesAmbilDanKompres({
    required ImageSource source,
    required double maxDimension,
    required int minCompressDimension,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
      );

      // Jika pengguna menekan tombol kembali / batal
      if (image == null) return null;

      final Uint8List originalBytes = await image.readAsBytes();

      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: minCompressDimension,
        minHeight: minCompressDimension,
        quality: 65,
        format: CompressFormat.jpeg,
      );

      final namaBaru = '${image.name.split('.').first}.jpg';
      return HasilFoto(namaFile: namaBaru, bytes: compressedBytes);
    } catch (e) {
      debugPrint('Error saat mengambil gambar ($source): $e');
      return null;
    }
  }
}
