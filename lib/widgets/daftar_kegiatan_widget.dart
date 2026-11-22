import 'package:flutter/material.dart';
import '../models/kegiatan_item.dart';

class DaftarKegiatanWidget extends StatelessWidget {
  final bool isLoading;
  final List<KegiatanItem> daftarKegiatan;
  final VoidCallback onCetakPressed;

  const DaftarKegiatanWidget({
    super.key,
    required this.isLoading,
    required this.daftarKegiatan,
    required this.onCetakPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tugas Hari Ini (${daftarKegiatan.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCetakPressed,
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
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (daftarKegiatan.isEmpty)
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
          ...daftarKegiatan.asMap().entries.map((entry) {
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
    );
  }
}
