import 'dart:typed_data';

class KegiatanItem {
  final dynamic id;
  final String namaKegiatan;
  final String waktuMulai;
  final String waktuSelesai;
  final String uraian;
  final String lampiranFotoNama;
  final String? fotoUrl;
  final Uint8List? fotoBytes;

  KegiatanItem({
    this.id,
    required this.namaKegiatan,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.uraian,
    required this.lampiranFotoNama,
    this.fotoUrl,
    this.fotoBytes,
  });
}
