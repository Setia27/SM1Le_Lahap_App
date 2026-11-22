import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/kegiatan_item.dart';

class PdfGenerator {
  // Fungsi utama dibuat static agar mudah dipanggil tanpa inisialisasi class
  static Future<pw.Document> generatePdf({
    required List<KegiatanItem> daftarCetak,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required String namaUser, // <-- Tambahkan parameter ini
    required String nipUser, // <-- Tambahkan parameter ini
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? kopImage;

    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/logo_disdik.png',
      );
      kopImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      kopImage = null;
    }

    final daftarTampil = daftarCetak.toList();
    final List<pw.Widget> barisTugasWidgets = [];

    if (daftarTampil.length == 1) {
      barisTugasWidgets.add(
        pw.Center(
          child: pw.Container(
            width: 340,
            child: _buildPdfTugasCard(1, daftarTampil[0]),
          ),
        ),
      );
    } else {
      for (int i = 0; i < daftarTampil.length; i += 2) {
        final itemKiri = daftarTampil[i];
        final itemKanan = (i + 1 < daftarTampil.length)
            ? daftarTampil[i + 1]
            : null;

        if (itemKanan == null) {
          barisTugasWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Spacer(flex: 1),
                  pw.Expanded(
                    flex: 2,
                    child: _buildPdfTugasCard(i + 1, itemKiri),
                  ),
                  pw.Spacer(flex: 1),
                ],
              ),
            ),
          );
        } else {
          barisTugasWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _buildPdfTugasCard(i + 1, itemKiri)),
                  pw.SizedBox(width: 10),
                  pw.Expanded(child: _buildPdfTugasCard(i + 2, itemKanan)),
                ],
              ),
            ),
          );
        }
      }
    }

    // Lanjutkan kode pdf.addPage(...) Anda di sini...
    final fmt = DateFormat('dd/MM/yyyy');
    final teksPeriode = (fmt.format(tanggalMulai) == fmt.format(tanggalSelesai))
        ? fmt.format(tanggalMulai)
        : '${fmt.format(tanggalMulai)} s/d ${fmt.format(tanggalSelesai)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        // Opsional: Menampilkan nomor halaman di pojok kanan bawah
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // 1. KOP RESMI SEKOLAH
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (kopImage != null) ...[
                  pw.Image(kopImage, width: 55, height: 55),
                  pw.SizedBox(width: 10),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "PEMERINTAH PROVINSI JAWA BARAT",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "DINAS PENDIDIKAN",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "SMA NEGERI 1 LEMBANG",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Jalan Maribaya No. 68 Telp. (022) 2786655 Kode POS 40391 NPSN. 20206211",
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.RichText(
                        textAlign: pw.TextAlign.center,
                        text: pw.TextSpan(
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.normal,
                            color: PdfColors.black,
                          ),
                          children: [
                            const pw.TextSpan(text: "website : "),
                            const pw.TextSpan(
                              text: "sman1lembang.sch.id",
                              style: pw.TextStyle(color: PdfColors.blue),
                            ),
                            const pw.TextSpan(text: " | e-mail : "),
                            const pw.TextSpan(
                              text: "smansatulembang@gmail.com",
                              style: pw.TextStyle(color: PdfColors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 6),

            // 2. JUDUL & IDENTITAS PETUGAS
            pw.Center(
              child: pw.Text(
                'REKAP LAPORAN KEGIATAN',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Sisi Kiri: Nama & Username/NIP dengan titik dua sejajar
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(82), // Lebar label kiri
                    1: const pw.FixedColumnWidth(10), // Lebar titik dua ':'
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Nama',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.Text(':', style: const pw.TextStyle(fontSize: 9.5)),
                        pw.Text(
                          namaUser,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'Username/NIP',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            ':',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            nipUser,
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sisi Kanan: Tanggal / Periode
                pw.Text(
                  'Tanggal / Periode : $teksPeriode',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            // 3. DAFTAR KARTU TUGAS
            ...barisTugasWidgets,

            // Pengganti pw.Spacer() agar tidak error di MultiPage
            pw.SizedBox(height: 20),

            // 4. TANDA TANGAN PETUGAS (Dibungkus pw.Wrap agar utuh saat pindah halaman)
            pw.Wrap(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Petugas Pelaksana,',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.SizedBox(height: 36),
                        pw.Text(
                          namaUser,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.Text(
                          'NIP. $nipUser',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );
    return pdf; // Kembalikan dokumen PDF yang sudah jadi
  }

  // Helper tetap private (_) karena hanya dipakai di dalam file ini
  static pw.Widget _buildPdfTugasCard(int nomor, KegiatanItem item) {
    pw.MemoryImage? pdfFoto;
    if (item.fotoBytes != null) {
      pdfFoto = pw.MemoryImage(item.fotoBytes!);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Tugas ke-$nomor: ${item.namaKegiatan}",
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            "Waktu: ${item.waktuMulai} - ${item.waktuSelesai}",
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            "Uraian: ${item.uraian}",
            style: const pw.TextStyle(fontSize: 8.5),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
          pw.SizedBox(height: 4),
          if (pdfFoto != null) ...[
            pw.Text(
              "Bukti Dokumentasi:",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Image(
                pdfFoto,
                width: 210,
                height: 100,
                fit: pw.BoxFit.cover,
              ),
            ),
          ] else ...[
            pw.Container(
              height: 40,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                "Tidak ada lampiran foto",
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
