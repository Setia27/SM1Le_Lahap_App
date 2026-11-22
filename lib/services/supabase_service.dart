import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agenda_tendik/models/kegiatan_item.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;
  static const String _tabelAgenda = 'agenda';
  static const String _bucketFoto = 'foto_laporan';

  // 1. Fungsi upload foto & simpan data ke Supabase
  static Future<KegiatanItem> simpanTugas({
    required String namaUser,
    required String nipUser,
    required String namaKegiatan,
    required String uraian,
    required String waktuMulai,
    required String waktuSelesai,
    Uint8List? fotoBytes,
    String? fotoNama,
  }) async {
    String? uploadedFotoUrl;

    if (fotoBytes != null) {
      final filePath =
          'agenda_tendik/${nipUser}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from(_bucketFoto)
          .uploadBinary(
            filePath,
            fotoBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      uploadedFotoUrl = _supabase.storage
          .from(_bucketFoto)
          .getPublicUrl(filePath);
    }

    final insertedRow = await _supabase
        .from(_tabelAgenda)
        .insert({
          'nama': namaUser,
          'nip': nipUser,
          'judul': namaKegiatan,
          'deskripsi': uraian,
          'waktu_mulai': waktuMulai,
          'waktu_selesai': waktuSelesai,
          'foto_url': uploadedFotoUrl,
        })
        .select()
        .single();

    return KegiatanItem(
      id: insertedRow['id'],
      namaKegiatan: namaKegiatan,
      waktuMulai: waktuMulai,
      waktuSelesai: waktuSelesai,
      uraian: uraian,
      lampiranFotoNama: fotoNama ?? 'Tidak ada foto',
      fotoUrl: uploadedFotoUrl,
      fotoBytes: fotoBytes,
    );
  }

  // 2. Fungsi ambil data dari Supabase berdasarkan tanggal
  static Future<List<KegiatanItem>> ambilData({
    required String nipUser,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    bool unduhFoto = true,
  }) async {
    final awalHari = DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
      0,
      0,
      0,
    ).toUtc().toIso8601String();

    final akhirHari = DateTime(
      tanggalSelesai.year,
      tanggalSelesai.month,
      tanggalSelesai.day,
      23,
      59,
      59,
    ).toUtc().toIso8601String();

    final response = await _supabase
        .from(_tabelAgenda)
        .select()
        .eq('nip', nipUser)
        .gte('created_at', awalHari)
        .lte('created_at', akhirHari)
        .order('created_at', ascending: true);

    final List<KegiatanItem> hasil = [];

    for (final row in response) {
      Uint8List? downloadedBytes;
      final String? url = row['foto_url'];

      if (unduhFoto && url != null && url.isNotEmpty) {
        try {
          final uri = Uri.parse(url);
          final segments = uri.pathSegments;
          final bucketIdx = segments.indexOf(_bucketFoto);
          if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
            final storagePath = segments.sublist(bucketIdx + 1).join('/');
            downloadedBytes = await _supabase.storage
                .from(_bucketFoto)
                .download(storagePath);
          }
        } catch (_) {
          downloadedBytes = null;
        }
      }

      hasil.add(
        KegiatanItem(
          id: row['id'],
          namaKegiatan: row['judul'] ?? '',
          waktuMulai: row['waktu_mulai'] ?? '',
          waktuSelesai: row['waktu_selesai'] ?? '',
          uraian: row['deskripsi'] ?? '',
          lampiranFotoNama: url != null ? 'Foto Tersimpan' : 'Tidak ada foto',
          fotoUrl: url,
          fotoBytes: downloadedBytes,
        ),
      );
    }

    return hasil;
  }
    // Mengunggah foto profil ke folder 'profil/' & update tabel 'profil_tendik'
  static Future<String> updateFotoProfil({
    required String nipUser,
    required Uint8List fotoBytes,
  }) async {
    final filePath =
        'profil/${nipUser}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from(_bucketFoto).uploadBinary(
          filePath,
          fotoBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl =
        _supabase.storage.from(_bucketFoto).getPublicUrl(filePath);

    await _supabase
        .from('profil_tendik')
        .update({'foto_profil': publicUrl})
        .eq('nip', nipUser);

    return publicUrl;
  }
}
