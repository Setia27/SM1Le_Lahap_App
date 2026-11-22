import 'dart:typed_data';
import 'package:flutter/material.dart';

class FormInputWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController kegiatanController;
  final TextEditingController waktuMulaiController;
  final TextEditingController waktuSelesaiController;
  final TextEditingController uraianController;
  final bool isDisabled;
  final bool isSaving;
  final String? lampiranFotoNama;
  final Uint8List? lampiranFotoBytes;
  final Function(TextEditingController) onSelectTime;
  final VoidCallback onPickImage;
  final VoidCallback onSimpan;

  const FormInputWidget({
    super.key,
    required this.formKey,
    required this.kegiatanController,
    required this.waktuMulaiController,
    required this.waktuSelesaiController,
    required this.uraianController,
    required this.isDisabled,
    required this.isSaving,
    required this.lampiranFotoNama,
    required this.lampiranFotoBytes,
    required this.onSelectTime,
    required this.onPickImage,
    required this.onSimpan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: kegiatanController,
                enabled: !isDisabled,
                decoration: const InputDecoration(
                  labelText: 'Nama Kegiatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: waktuMulaiController,
                      enabled: !isDisabled,
                      readOnly: true,
                      onTap: () => onSelectTime(waktuMulaiController),
                      decoration: const InputDecoration(
                        labelText: 'Waktu Mulai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: waktuSelesaiController,
                      enabled: !isDisabled,
                      readOnly: true,
                      onTap: () => onSelectTime(waktuSelesaiController),
                      decoration: const InputDecoration(
                        labelText: 'Waktu Selesai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: uraianController,
                enabled: !isDisabled,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Uraian Kegiatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isDisabled ? null : onPickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(lampiranFotoNama ?? 'Ambil Foto Dokumentasi'),
              ),
              if (lampiranFotoBytes != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    lampiranFotoBytes!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isDisabled ? null : onSimpan,
                icon: isSaving
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
                  isSaving
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
    );
  }
}
