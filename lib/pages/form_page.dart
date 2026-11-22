import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/kegiatan_item.dart';

import '../services/camera_service.dart';
import '../services/pdf_generator.dart';
import '../services/session_service.dart';
import '../services/supabase_service.dart';

import '../widgets/about_dialog_widget.dart';
import '../widgets/cetak_periode_sheet.dart';
import '../widgets/daftar_kegiatan_widget.dart';
import '../widgets/form_input_widget.dart';
import '../widgets/user_profile_card.dart';

import 'login_page.dart';

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
  String? _fotoProfilUrl;
  Uint8List? _lampiranFotoBytes;
  List<KegiatanItem> _daftarKegiatan = [];

  bool _isSaving = false;
  bool _isLoadingList = true;

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

  Future<void> _loadUserData() async {
    final userData = await SessionService.getUserSession();
    if (!mounted) return;
    setState(() {
      _namaUser = userData['nama']!;
      _nipUser = userData['nip']!;
      final savedFoto = userData['foto']!;
      _fotoProfilUrl = savedFoto.isNotEmpty ? savedFoto : null;
    });
  }

  Future<void> _muatKegiatanHariIni() async {
    setState(() => _isLoadingList = true);
    try {
      final sekarang = DateTime.now();
      final dataHariIni = await SupabaseService.ambilData(
        nipUser: _nipUser,
        tanggalMulai: sekarang,
        tanggalSelesai: sekarang,
        unduhFoto: false,
      );
      if (mounted) {
        setState(() => _daftarKegiatan = dataHariIni);
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
        setState(() => _sessiSelesai = true);
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
    if (picked != null && mounted) {
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
    final hasil = await CameraService.ambilDanKompresFoto();
    if (hasil != null) {
      setState(() {
        _lampiranFotoNama = hasil.namaFile;
        _lampiranFotoBytes = hasil.bytes;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto berhasil diambil dan dikompres!')),
      );
    }
  }

  Future<void> _prosesCetakPeriode(DateTime mulai, DateTime selesai) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dataUntukCetak = await SupabaseService.ambilData(
        nipUser: _nipUser,
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
        unduhFoto: true,
      );

      if (!mounted) return;
      Navigator.pop(context);

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

      final pdfDoc = await PdfGenerator.generatePdf(
        daftarCetak: dataUntukCetak,
        tanggalMulai: mulai,
        tanggalSelesai: selesai,
        namaUser: _namaUser,
        nipUser: _nipUser,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfDoc.save(),
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

  Future<void> _simpanTugasBerikutnya() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final itemBaru = await SupabaseService.simpanTugas(
        namaUser: _namaUser,
        nipUser: _nipUser,
        namaKegiatan: _kegiatanController.text.trim(),
        uraian: _uraianController.text.trim(),
        waktuMulai: _waktuMulaiController.text.trim(),
        waktuSelesai: _waktuSelesaiController.text.trim(),
        fotoBytes: _lampiranFotoBytes,
        fotoNama: _lampiranFotoNama,
      );

      setState(() {
        _daftarKegiatan.add(itemBaru);
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

  Future<void> _logout() async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    _sessionTimer?.cancel();
    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SM1Le Laporan Kegiatan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'SMAN 1 Lembang',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 77, 192, 254),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF0077B6),
            ),
            tooltip: 'Tentang Aplikasi',
            onPressed: () => AboutAplikasiDialog.tampilkan(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                backgroundColor: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red.shade200, width: 1),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserProfileCard(
              namaUser: _namaUser,
              nipUser: _nipUser,
              fotoProfilUrl: _fotoProfilUrl,
              onFotoUpdated: (urlBaru) =>
                  setState(() => _fotoProfilUrl = urlBaru),
            ),
            const SizedBox(height: 12),
            FormInputWidget(
              formKey: _formKey,
              kegiatanController: _kegiatanController,
              waktuMulaiController: _waktuMulaiController,
              waktuSelesaiController: _waktuSelesaiController,
              uraianController: _uraianController,
              isDisabled: _sessiSelesai || _isSaving,
              isSaving: _isSaving,
              lampiranFotoNama: _lampiranFotoNama,
              lampiranFotoBytes: _lampiranFotoBytes,
              onSelectTime: (controller) => _selectTime(context, controller),
              onPickImage: _pickImage,
              onSimpan: _simpanTugasBerikutnya,
            ),
            const SizedBox(height: 16),
            DaftarKegiatanWidget(
              isLoading: _isLoadingList,
              daftarKegiatan: _daftarKegiatan,
              onCetakPressed: () => CetakPeriodeSheet.tampilkan(
                context,
                onPilihPeriode: _prosesCetakPeriode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
