import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class HasilFoto {
  final String namaFile;
  final Uint8List bytes;

  HasilFoto({required this.namaFile, required this.bytes});
}

class CameraService {
    static final ImagePicker _picker = ImagePicker();

  // Mengambil foto dari kamera sekaligus mengompresnya
  static Future<HasilFoto?> ambilDanKompresFoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (image == null) return null;

    final Uint8List originalBytes = await image.readAsBytes();

    final Uint8List compressedBytes =
        await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 800,
      minHeight: 800,
      quality: 65,
      format: CompressFormat.jpeg,
    );

    final namaBaru = '${image.name.split('.').first}.jpg';
    return HasilFoto(namaFile: namaBaru, bytes: compressedBytes);
  }
    // Mengambil foto profil dari berkas/galeri perangkat
  static Future<HasilFoto?> pilihFotoDariBerkas() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return null;

    final Uint8List originalBytes = await image.readAsBytes();

    final Uint8List compressedBytes =
        await FlutterImageCompress.compressWithList(
      originalBytes,
      minWidth: 500,
      minHeight: 500,
      quality: 65,
      format: CompressFormat.jpeg,
    );

    final namaBaru = '${image.name.split('.').first}.jpg';
    return HasilFoto(namaFile: namaBaru, bytes: compressedBytes);
  }

}
