// File: lib/screens/particulate/widgets/particulate_app_bar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/particulate_service.dart';
import '../../../theme/app_theme.dart';

class ParticulateAppBar extends StatefulWidget {
  const ParticulateAppBar({super.key});

  @override
  State<ParticulateAppBar> createState() => _ParticulateAppBarState();
}

class _ParticulateAppBarState extends State<ParticulateAppBar> {
  bool _isDownloading = false;

  Future<void> _downloadDatasetExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isDownloading = true);

    try {
      final data = await ParticulateService.getLatest();
      final latestReading = data["latest_reading"];

      final excel = Excel.createExcel();
      final Sheet sheet = excel['Dataset_Partikulat'];
      excel.delete('Sheet1');

      // Header Kolom
      sheet.appendRow([
        TextCellValue('Waktu Recorded'),
        TextCellValue('Node Code'),
        TextCellValue('Lokasi'),
        TextCellValue('PM1 (µg/m³)'),
        TextCellValue('PM2.5 (µg/m³)'),
        TextCellValue('PM10 (µg/m³)'),
        TextCellValue('Suhu (°C)'),
        TextCellValue('Kelembapan (%)'),
        TextCellValue('Status AI'),
      ]);

      if (latestReading != null) {
        final String recordedAt = latestReading["recordedAt"]?.toString() ??
            latestReading["created_at"]?.toString() ??
            DateTime.now().toIso8601String();
        final String nodeCode =
            latestReading["nodeCode"]?.toString() ?? "NODE-001";
        final String lokasi = latestReading["locationName"]?.toString() ??
            "Kawasan Hutan Belinyu";
        final double pm1 =
            double.tryParse(latestReading["pm1"]?.toString() ?? '0') ?? 0;
        final double pm25 =
            double.tryParse(latestReading["pm25"]?.toString() ?? '0') ?? 0;
        final double pm10 =
            double.tryParse(latestReading["pm10"]?.toString() ?? '0') ?? 0;
        final double suhu = double.tryParse(
                latestReading["temperature"]?.toString() ??
                    latestReading["suhu"]?.toString() ??
                    '0') ??
            0;
        final double kelembapan = double.tryParse(
                latestReading["humidity"]?.toString() ??
                    latestReading["kelembapan"]?.toString() ??
                    '0') ??
            0;
        final String statusAi =
            latestReading["statusTerpadu"]?.toString() ?? "Normal Bersih";

        sheet.appendRow([
          TextCellValue(recordedAt),
          TextCellValue(nodeCode),
          TextCellValue(lokasi),
          DoubleCellValue(pm1),
          DoubleCellValue(pm25),
          DoubleCellValue(pm10),
          DoubleCellValue(suhu),
          DoubleCellValue(kelembapan),
          TextCellValue(statusAi),
        ]);
      } else {
        // 🔥 FIX 1: Menambahkan const pada DoubleCellValue & TextCellValue static
        sheet.appendRow([
          TextCellValue(DateTime.now().toString()),
          TextCellValue('NODE-001'),
          TextCellValue('Kawasan Hutan Belinyu'),
          const DoubleCellValue(0),
          const DoubleCellValue(0),
          const DoubleCellValue(0),
          const DoubleCellValue(0),
          const DoubleCellValue(0),
          TextCellValue('Belum ada data'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final String fileName =
            "Dataset_Partikulat_${DateTime.now().millisecondsSinceEpoch}.xlsx";
        final File file = File("${directory.path}/$fileName");

        await file.writeAsBytes(fileBytes);

        if (!mounted) return;

        // 🔥 FIX 2: Menggunakan SharePlus API v10+ (ShareParams)
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Dataset Pemantauan Partikulat & Cuaca Rimbarest',
          ),
        );

        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Text('File Excel berhasil dibuat: $fileName'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh dataset: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.bgPage,
      surfaceTintColor: Colors.transparent,
      title: const Text('Deteksi Partikulat'),
      actions: [
        if (_isDownloading)
          const Padding(
            padding: EdgeInsets.all(14.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: AppTheme.textPrimary,
            ),
            tooltip: 'Download Excel Dataset',
            onPressed: () => _downloadDatasetExcel(context),
          ),
      ],
    );
  }
}
