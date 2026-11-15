import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class KegiatanItem {
  final String namaKegiatan;
  final String waktuMulai;
  final String waktuSelesai;
  final String uraian;
  final String lampiranFotoNama;
  final Uint8List? fotoBytes;

  KegiatanItem({
    required this.namaKegiatan,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.uraian,
    required this.lampiranFotoNama,
    this.fotoBytes,
  });
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _kegiatanController = TextEditingController();
  final _waktuMulaiController = TextEditingController();
  final _waktuSelesaiController = TextEditingController();
  final _uraianController = TextEditingController();

  String? _lampiranFotoNama;
  Uint8List? _lampiranFotoBytes;
  final List<KegiatanItem> _daftarKegiatan = [];

  // Variabel penampung Nama & NIP petugas dari halaman Login/Register
  String _namaUser = 'Tenaga Kependidikan';
  String _nipUser = '-';

  bool _sessiSelesai = false;
  Timer? _sessionTimer;
  Duration _remainingTime = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startSessionCountdown();
  }

  // Mengambil Nama Lengkap dan NIP dari SharedPreferences (hasil input saat Register & Login)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('current_user_nama') ?? 'Tenaga Kependidikan';
      _nipUser = prefs.getString('current_user_nip') ?? '-';
    });
  }

  void _startSessionCountdown() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        setState(() {
          _sessiSelesai = true;
        });
        _sessionTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _kegiatanController.dispose();
    _waktuMulaiController.dispose();
    _waktuSelesaiController.dispose();
    _uraianController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        controller.text = localizations.formatTimeOfDay(
          picked,
          alwaysUse24HourFormat: true,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _lampiranFotoNama = image.name;
        _lampiranFotoBytes = bytes;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diambil dari kamera!')),
      );
    }
  }

  void _simpanTugasBerikutnya() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _daftarKegiatan.add(
          KegiatanItem(
            namaKegiatan: _kegiatanController.text,
            waktuMulai: _waktuMulaiController.text,
            waktuSelesai: _waktuSelesaiController.text,
            uraian: _uraianController.text,
            lampiranFotoNama: _lampiranFotoNama ?? 'Tidak ada foto',
            fotoBytes: _lampiranFotoBytes,
          ),
        );

        _kegiatanController.clear();
        _waktuMulaiController.clear();
        _waktuSelesaiController.clear();
        _uraianController.clear();
        _lampiranFotoNama = null;
        _lampiranFotoBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tugas ke-${_daftarKegiatan.length} berhasil disimpan!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Helper membangun 1 kartu tugas di PDF
  // Helper membangun 1 kartu tugas di PDF
  pw.Widget _buildPdfTugasCard(int nomor, KegiatanItem item) {
    pw.MemoryImage? pdfFoto;
    if (item.fotoBytes != null) {
      pdfFoto = pw.MemoryImage(item.fotoBytes!);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(6), // Diperkecil dari 8 ke 6
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
            maxLines: 2, // Membatasi uraian maksimal 2 baris agar kotak tidak terlalu memanjang
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
                height: 95, // <-- Diperkecil dari 130 ke 95 agar 3 baris muat 1 halaman
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

  Future<void> _akhiriSesiDanCetakPdf() async {
    if (_daftarKegiatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada tugas yang disimpan!')),
      );
      return;
    }

    final pdf = pw.Document();

    // Memuat logo sekolah dari folder assets/images/logo_disdik.png
    pw.MemoryImage? kopImage;
    try {
      final ByteData logoData = await rootBundle.load(
        'assets/images/logo_disdik.png',
      );
      kopImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      kopImage = null;
    }

    // 1. Batasi maksimal 6 tugas untuk 1 lembar PDF (atau bagi per 6 item jika ada halaman berikutnya)
    final daftarTampil = _daftarKegiatan.take(6).toList();
    final List<pw.Widget> barisTugasWidgets = [];

    // 2. Kondisi khusus jika HANYA ADA 1 TUGAS
    if (daftarTampil.length == 1) {
      barisTugasWidgets.add(
        pw.Center(
          child: pw.Container(
            // Lebar diatur 340 poin (sekitar 65-70% lebar kertas A4) agar proporsional dan tidak terlalu raksasa
            width: 340,
            child: _buildPdfTugasCard(1, daftarTampil[0]),
          ),
        ),
      );
    } else {
      // 3. Kondisi jika ADA 2 SAMPAI 6 TUGAS
      for (int i = 0; i < daftarTampil.length; i += 2) {
        final itemKiri = daftarTampil[i];
        final itemKanan = (i + 1 < daftarTampil.length)
            ? daftarTampil[i + 1]
            : null;

        // Jika jumlah tugas ganjil (misal 3 atau 5) dan ini adalah item terakhir, posisikan di tengah
        if (itemKanan == null) {
          barisTugasWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Spacer kiri & kanan dengan flex: 1 membuat card di tengah memiliki lebar 50% (sama persis dengan kolom atasnya)
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
          // Jika baris berpasangan (kiri & kanan penuh)
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

    // 1. Definisikan konstanta ukuran F4 (21,5 cm x 33 cm) agar dipakai seragam
    const f4Format = PdfPageFormat(
      21.5 * PdfPageFormat.cm,
      33.0 * PdfPageFormat.cm,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: f4Format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return [
            // --- KOP SURAT DENGAN LOGO DI SEBELAH KIRI ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (kopImage != null) ...[
                  pw.Image(
                    kopImage,
                    width: 58,
                    height: 68,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(width: 12),
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
                            fontStyle: pw.FontStyle.italic,
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
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 2, color: PdfColors.black),
            pw.SizedBox(height: 12),

            // --- JUDUL & IDENTITAS PETUGAS ---
            pw.Center(
              child: pw.Text(
                "LAPORAN KOLEKTIF TENAGA KEPENDIDIKAN",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(100),
                1: const pw.FixedColumnWidth(10),
                2: const pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Text(
                      "Nama Petugas",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(":", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      _namaUser,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text(
                      "NIP / Username",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(":", style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_nipUser, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),

            // --- JARAK & DAFTAR KOTAK TUGAS ---
            pw.SizedBox(height: 14),
            ...barisTugasWidgets,
          ];
        },
      ),
    );

    // 2. Pastikan Printing.layoutPdf juga memakai f4Format
    await Printing.layoutPdf(
      format: f4Format,
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Agenda Kegiatan'),
        backgroundColor: const Color(0xFF23a6d5),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.account_circle,
                  color: Color(0xFF23a6d5),
                  size: 36,
                ),
                title: Text(
                  _namaUser,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("NIP / Username: $_nipUser"),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _kegiatanController,
                        enabled: !_sessiSelesai,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kegiatan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _waktuMulaiController,
                              enabled: !_sessiSelesai,
                              readOnly: true,
                              onTap: () =>
                                  _selectTime(context, _waktuMulaiController),
                              decoration: const InputDecoration(
                                labelText: 'Waktu Mulai',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _waktuSelesaiController,
                              enabled: !_sessiSelesai,
                              readOnly: true,
                              onTap: () =>
                                  _selectTime(context, _waktuSelesaiController),
                              decoration: const InputDecoration(
                                labelText: 'Waktu Selesai',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time_filled),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Wajib diisi'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _uraianController,
                        enabled: !_sessiSelesai,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Uraian Kegiatan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _sessiSelesai ? null : _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          _lampiranFotoNama ?? 'Ambil Foto Dokumentasi',
                        ),
                      ),
                      if (_lampiranFotoBytes != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _lampiranFotoBytes!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _sessiSelesai
                            ? null
                            : _simpanTugasBerikutnya,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Simpan Tugas ke Daftar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF23d5ab),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Daftar Tugas Tersimpan (${_daftarKegiatan.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_daftarKegiatan.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Belum ada tugas yang ditambahkan.",
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._daftarKegiatan.asMap().entries.map((entry) {
                int idx = entry.key;
                KegiatanItem item = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF23a6d5),
                      foregroundColor: Colors.white,
                      child: Text("${idx + 1}"),
                    ),
                    title: Text(
                      item.namaKegiatan,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${item.waktuMulai} - ${item.waktuSelesai}\n${item.uraian}",
                    ),
                    trailing: item.fotoBytes != null
                        ? const Icon(Icons.image, color: Colors.green)
                        : const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _akhiriSesiDanCetakPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Akhiri Sesi & Cetak Laporan PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe73c7e),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
