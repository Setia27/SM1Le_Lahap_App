import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

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

  // Client & Konstanta Supabase
  final _supabase = Supabase.instance.client;
  final String _tabelAgenda = 'agenda';
  final String _bucketFoto = 'foto_laporan';

  String? _lampiranFotoNama;
  Uint8List? _lampiranFotoBytes;
  List<KegiatanItem> _daftarKegiatan = [];

  // Status Loading
  bool _isSaving = false;
  bool _isLoadingList = true;

  // Variabel penampung Nama & NIP petugas dari halaman Login/Register
  String _namaUser = 'Tenaga Kependidikan';
  String _nipUser = '-';

  bool _sessiSelesai = false;
  Timer? _sessionTimer;
  Duration _remainingTime = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _initHalaman();
    _startSessionCountdown();
  }

  Future<void> _initHalaman() async {
    await _loadUserData();
    await _muatKegiatanHariIni();
  }

  // Mengambil Nama Lengkap dan NIP dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('current_user_nama') ?? 'Tenaga Kependidikan';
      _nipUser = prefs.getString('current_user_nip') ?? '-';
    });
  }

  // Memuat daftar tugas HARI INI dari Supabase agar tidak hilang walau aplikasi ditutup
  Future<void> _muatKegiatanHariIni() async {
    setState(() => _isLoadingList = true);
    try {
      final sekarang = DateTime.now();
      final dataHariIni = await _ambilDataDariSupabase(
        tanggalMulai: sekarang,
        tanggalSelesai: sekarang,
        unduhFoto: false,
      );
      if (mounted) {
        setState(() {
          _daftarKegiatan = dataHariIni;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar tugas hari ini: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
    }
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

  // Simpan tugas ke tabel 'agenda' & upload foto ke bucket 'foto_laporan'
  Future<void> _simpanTugasBerikutnya() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? uploadedFotoUrl;

      // 1. Jika ada foto, unggah ke subfolder 'agenda_tendik/' di bucket 'foto_laporan'
      if (_lampiranFotoBytes != null) {
        final filePath =
            'agenda_tendik/${_nipUser}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await _supabase.storage
            .from(_bucketFoto)
            .uploadBinary(
              filePath,
              _lampiranFotoBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        uploadedFotoUrl = _supabase.storage
            .from(_bucketFoto)
            .getPublicUrl(filePath);
      }

      // 2. Simpan data ke tabel 'agenda' Supabase
      final insertedRow = await _supabase
          .from(_tabelAgenda)
          .insert({
            'nama': _namaUser,
            'nip': _nipUser,
            'judul': _kegiatanController.text.trim(),
            'deskripsi': _uraianController.text.trim(),
            'waktu_mulai': _waktuMulaiController.text.trim(),
            'waktu_selesai': _waktuSelesaiController.text.trim(),
            'foto_url': uploadedFotoUrl,
          })
          .select()
          .single();

      // 3. Tambahkan ke list lokal & bersihkan form
      setState(() {
        _daftarKegiatan.add(
          KegiatanItem(
            id: insertedRow['id'],
            namaKegiatan: _kegiatanController.text.trim(),
            waktuMulai: _waktuMulaiController.text.trim(),
            waktuSelesai: _waktuSelesaiController.text.trim(),
            uraian: _uraianController.text.trim(),
            lampiranFotoNama: _lampiranFotoNama ?? 'Tidak ada foto',
            fotoUrl: uploadedFotoUrl,
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tugas ke-${_daftarKegiatan.length} berhasil disimpan ke server!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan tugas: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Fungsi ambil data dari Supabase berdasarkan rentang tanggal
  Future<List<KegiatanItem>> _ambilDataDariSupabase({
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
        .eq('nip', _nipUser)
        .gte('created_at', awalHari)
        .lte('created_at', akhirHari)
        .order('created_at', ascending: true);

    final List<KegiatanItem> hasil = [];

    for (final row in response) {
      Uint8List? downloadedBytes;
      final String? url = row['foto_url'];

      if (unduhFoto && url != null && url.isNotEmpty) {
        try {
          // Ekstrak path file di dalam bucket 'foto_laporan'
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

  // Menampilkan pilihan periode cetak PDF (Hari Ini, Kemarin, Minggu Lalu, Custom)
  void _tampilkanPilihanCetak() {
    final sekarang = DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  'Pilih Periode Cetak Laporan PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text('Hari Ini'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(sekarang)),
                onTap: () {
                  Navigator.pop(context);
                  _prosesCetakPeriode(sekarang, sekarang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('Hari Kemarin'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy')
                      .format(sekarang.subtract(const Duration(days: 1))),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final kemarin = sekarang.subtract(const Duration(days: 1));
                  _prosesCetakPeriode(kemarin, kemarin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.green),
                title: const Text('Minggu Lalu (7 Hari Terakhir)'),
                onTap: () {
                  Navigator.pop(context);
                  final mingguLalu = sekarang.subtract(const Duration(days: 7));
                  _prosesCetakPeriode(mingguLalu, sekarang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.purple),
                title: const Text('Pilih Rentang Tanggal Sendiri...'),
                onTap: () async {
                  Navigator.pop(context);
                  final rentang = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: sekarang,
                  );
                  if (rentang != null) {
                    _prosesCetakPeriode(rentang.start, rentang.end);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Mengambil data sesuai periode dan mencetak PDF
  Future<void> _prosesCetakPeriode(DateTime mulai, DateTime selesai) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dataUntukCetak = await _ambilDataDariSupabase(
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
        unduhFoto: true,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (dataUntukCetak.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada data tugas pada periode tanggal tersebut!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _generatePdf(
        daftarCetak: dataUntukCetak,
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyiapkan laporan PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Mengambil data sesuai periode dan mencetak PDF
  Future prosesCetakPeriode(DateTime mulai, DateTime selesai) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final dataUntukCetak = await _ambilDataDariSupabase(
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
        unduhFoto: true,
      );
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      if (dataUntukCetak.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada data tugas pada periode tanggal tersebut!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      await _generatePdf(
        daftarCetak: dataUntukCetak,
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyiapkan laporan PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Helper membangun 1 kartu tugas di PDF
  pw.Widget _buildPdfTugasCard(int nomor, KegiatanItem item) {
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

  // Fungsi utama pembuat dokumen PDF
  Future _generatePdf({
    required List daftarCetak,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
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
        // Format teks periode tanggal di header PDF
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
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Nama: $_namaUser  |  NIP/Username: $_nipUser',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
                pw.Text(
                  'Tanggal / Periode: $teksPeriode',
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
                          _namaUser,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.Text(
                          'NIP. $_nipUser',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Agenda Kegiatan'),
        backgroundColor: const Color(0xFF23a6d5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Laporan PDF',
            onPressed: _tampilkanPilihanCetak,
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
                        enabled: !_sessiSelesai && !_isSaving,
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
                              enabled: !_sessiSelesai && !_isSaving,
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
                              enabled: !_sessiSelesai && !_isSaving,
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
                        enabled: !_sessiSelesai && !_isSaving,
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
                        onPressed: (_sessiSelesai || _isSaving)
                            ? null
                            : _pickImage,
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
                        onPressed: (_sessiSelesai || _isSaving)
                            ? null
                            : _simpanTugasBerikutnya,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_task),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan ke Server...'
                              : 'Simpan Tugas ke Daftar',
                        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tugas Hari Ini (${_daftarKegiatan.length})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _tampilkanPilihanCetak,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Cetak Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23a6d5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingList)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_daftarKegiatan.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Belum ada tugas yang ditambahkan hari ini.",
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
                    trailing: item.fotoUrl != null
                        ? const Icon(Icons.image, color: Colors.green)
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
