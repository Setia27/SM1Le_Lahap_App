import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CetakPeriodeSheet {
  static void tampilkan(
    BuildContext context, {
    required Future<void> Function(DateTime mulai, DateTime selesai)
        onPilihPeriode,
  }) {
    final sekarang = DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
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
                  Navigator.pop(sheetContext);
                  onPilihPeriode(sekarang, sekarang);
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
                  Navigator.pop(sheetContext);
                  final kemarin = sekarang.subtract(const Duration(days: 1));
                  onPilihPeriode(kemarin, kemarin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.green),
                title: const Text('Minggu Lalu (7 Hari Terakhir)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final mingguLalu = sekarang.subtract(const Duration(days: 7));
                  onPilihPeriode(mingguLalu, sekarang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.purple),
                title: const Text('Pilih Rentang Tanggal Sendiri...'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final rentang = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: sekarang,
                  );
                  if (rentang != null) {
                    onPilihPeriode(rentang.start, rentang.end);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
