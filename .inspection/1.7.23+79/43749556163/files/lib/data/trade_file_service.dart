import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedBackupFile {
  const PickedBackupFile({
    required this.name,
    required this.openRead,
    required this.sizeBytes,
  });
  final String name;
  final Stream<List<int>> Function() openRead;
  final int? sizeBytes;
}

class TradeFileService {
  const TradeFileService._();

  static Future<Uri?> saveBackup(String contents) => FilePicker.saveFile(
    dialogTitle: 'Save complete trading journal backup',
    fileName: _fileName('traderdesk_backup', 'json'),
    mimeType: 'application/json',
    type: FileType.custom,
    allowedExtensions: const ['json'],
    bytes: Uint8List.fromList(utf8.encode(contents)),
  );

  static Future<Uri?> saveCsv(String contents, {required String fileName}) =>
      FilePicker.saveFile(
        dialogTitle: 'Export trading journal as CSV',
        fileName: fileName,
        mimeType: 'text/csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(contents)),
      );

  static Future<Uri?> saveImage(
    Uint8List bytes, {
    required String fileName,
    required String extension,
    required String mimeType,
  }) => FilePicker.saveFile(
    dialogTitle: 'Save trade image',
    fileName: fileName,
    mimeType: mimeType,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
  );

  static Future<PickedBackupFile?> pickBackup() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Select a Trader Desk JSON backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return PickedBackupFile(
      name: file.name,
      openRead: file.readAsByteStream,
      sizeBytes: await file.length(),
    );
  }

  static String csvFileName() => _fileName('traderdesk_trades', 'csv');

  static String _fileName(String prefix, String extension) {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return '${prefix}_$stamp.$extension';
  }
}
