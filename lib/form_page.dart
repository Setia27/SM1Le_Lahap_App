import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'login_page.dart';
import 'package:image_picker/image_picker.dart'; // Jangan lupa impor di atas file

// Model data untuk menampung setiap item kegiatan
class KegiatanItem {
  final String namaKegiatan;
  final String waktuMulai;
  final String waktuSelesai;
  final String uraian;
  final String lampiranFoto;

  KegiatanItem({
    required this.namaKegiatan,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.uraian,
    required this.lampiranFoto,
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
  final List<KegiatanItem> _daftarKegiatan = [];

  // Variabel untuk mengontrol status waktu/sesi
  bool _sessiSelesai = false;
  Timer? _sessionTimer;
  Duration _remainingTime = const Duration(seconds: 30); // Contoh: Sesi otomatis habis dalam 30 detik (bisa diubah sesuai kebutuhan)

  @override
  void initState() {
    super.initState();
    _startSessionCountdown();
  }

  // Fungsi pengatur waktu mundur otomatis (Bisa disesuaikan dengan jam target selesai)
  void _startSessionCountdown() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        // Jika waktu habis secara otomatis, ubah status sesi menjadi selesai
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

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        controller.text = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: true);
      });
    }
  }

  Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  // Membuka kamera (atau gunakan ImageSource.gallery jika ingin dari galeri)
  final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

  if (image != null) {
    setState(() {
      _lampiranFotoNama = image.name; // Menyimpan nama file foto asli
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto berhasil diambil dari kamera!')),
    );
  }
}

  // Fungsi untuk menyimpan tugas ke dalam daftar sementara (Selama waktu masih berjalan)
  void _simpanTugasBerikutnya() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _daftarKegiatan.add(
          KegiatanItem(
            namaKegiatan: _kegiatanController.text,
            waktuMulai: _waktuMulaiController.text,
            waktuSelesai: _waktuSelesaiController.text,
            uraian: _uraianController.text,
            lampiranFoto: _lampiranFotoNama ?? 'Tidak ada foto',
          ),
        );

        // Reset form untuk input tugas berikutnya
        _kegiatanController.clear();
        _waktuMulaiController.clear();
        _waktuSelesaiController.clear();
        _uraianController.clear();
        _lampiranFotoNama = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas ke-${_daftarKegiatan.length} berhasil disimpan. Silakan masukkan tugas berikutnya.')),
      );
    }
  }

  // Fungsi untuk Menghasilkan PDF Kolektif dengan Kop Sekolah
  Future<void> _akhiriSesiDanCetakPdf() async {
    if (_daftarKegiatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada tugas yang disimpan!')),
      );
      return;
    }

    final pdf = pw.Document();

    pw.ImageProvider? kopImage;
    try {
      kopImage = await networkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png');
    } catch (_) {
      kopImage = null;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- KOP SURAT ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (kopImage != null) ...[
                  pw.Image(kopImage, width: 60, height: 60),
                  pw.SizedBox(width: 15),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "PEMERINTAH KABUPATEN / KOTA",
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "DINAS PENDIDIKAN DAN KEBUDAYAAN",
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "SEKOLAH MENENGAH PERTAMA / ATAS NEGERI",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Jl. Pendidikan No. 123 Telp. (022) 123456 Kode Pos 40111",
                        style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 2, color: PdfColors.black),
            pw.SizedBox(height: 15),

            // --- JUDUL ---
            pw.Center(
              child: pw.Text(
                "LAPORAN KOLEKTIF HARIAN TENAGA KEPENDIDIKAN",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 20),
            
            // --- DAFTAR TUGAS ---
            ..._daftarKegiatan.asMap().entries.map((entry) {
              int index = entry.key;
              KegiatanItem item = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Tugas ke-${index + 1}: ${item.namaKegiatan}", 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text("Waktu: ${item.waktuMulai} - ${item.waktuSelesai}"),
                    pw.SizedBox(height: 4),
                    pw.Text("Uraian: ${item.uraian}"),
                    pw.SizedBox(height: 4),
                    pw.Text("Lampiran Foto: ${item.lampiranFoto}", 
                      style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_remainingTime.inMinutes.remainder(60));
    final seconds = twoDigits(_remainingTime.inSeconds.remainder(60));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Laporan Kolektif Tendik'),
        backgroundColor: const Color(0xFF23a6d5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Indikator Sisa Waktu Sesi / Timer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _sessiSelesai ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _sessiSelesai ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _sessiSelesai 
                                ? "Status: Waktu Sesi Selesai" 
                                : "Sisa Waktu Sesi: $minutes:$seconds",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _sessiSelesai ? Colors.green[800] : Colors.orange[800],
                            ),
                          ),
                          Text(
                            "Tersimpan: ${_daftarKegiatan.length}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 1. Nama Kegiatan
                    TextFormField(
                      controller: _kegiatanController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kegiatan / Tugas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Nama kegiatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Waktu Mulai
                    TextFormField(
                      controller: _waktuMulaiController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu Mulai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () => _selectTime(context, _waktuMulaiController),
                      validator: (value) => value == null || value.isEmpty ? 'Waktu mulai wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // 3. Waktu Selesai
                    TextFormField(
                      controller: _waktuSelesaiController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu Selesai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      onTap: () => _selectTime(context, _waktuSelesaiController),
                      validator: (value) => value == null || value.isEmpty ? 'Waktu selesai wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Uraian Kegiatan
                    TextFormField(
                      controller: _uraianController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Uraian / Hasil Kegiatan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Uraian wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // 5. Lampiran Foto
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lampiranFotoNama == null 
                                ? 'Belum ada foto dipilih' 
                                : 'File: $_lampiranFotoNama',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Lampirkan Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logika Tombol Berdasarkan Batas Waktu
                    if (!_sessiSelesai) ...[
                      // Tombol Selama Waktu Berjalan (Hanya Simpan Tugas Berikutnya)
                      ElevatedButton.icon(
                        onPressed: _simpanTugasBerikutnya,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Simpan Tugas (Tambah Tugas Berikutnya)', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF23a6d5),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tombol manual jika ingin mengakhiri sesi lebih cepat dari timer
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _sessiSelesai = true;
                          });
                        },
                        child: const Text('Akhiri Sesi Sekarang & Cetak PDF'),
                      ),
                    ] else ...[
                      // Tombol Setelah Waktu Habis (Muncul Tombol Cetak PDF Kolektif)
                      ElevatedButton.icon(
                        onPressed: _akhiriSesiDanCetakPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Simpan & Cetak Laporan Kolektif PDF', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF23d5ab),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}