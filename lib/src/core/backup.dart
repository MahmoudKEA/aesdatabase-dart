import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:path/path.dart' as pathlib;

import '../drive.dart';
import '../utils.dart';
import 'core.dart';

mixin BackupCore {
  late DriveSetup _drive;
  late String _key;
  late List<String> _columns;
  late List<List<dynamic>> _rows;
  late AESCrypto _cipher;
  late void Function({int rowIndex, required Map<String, dynamic> items})
      _insert;

  void backupInit(
    DriveSetup drive,
    String key,
    List<String> columns,
    List<List<dynamic>> rows,
    AESCrypto cipher,
    void Function({int rowIndex, required Map<String, dynamic> items}) insert,
  ) {
    _drive = drive;
    _key = key;
    _columns = columns;
    _rows = rows;
    _cipher = cipher;
    _insert = insert;
  }

  Future<void> importBackup({
    required String path,
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? key,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) async {
    tableCreationValidator(_columns);
    backupValidator(_drive.hasBackup);

    _cipher.setKey(key ?? _key);

    final String tempPath = await _cipher.decryptFile(
      path: path,
      directory: _drive.tempDir,
      ignoreFileExists: true,
      removeAfterComplete: removeAfterComplete,
      progressCallback: progressCallback,
    );

    final RandomAccessFile tempFile = await File(tempPath).open(
      mode: FileMode.read,
    );
    int size;

    // Read rows
    size = sizeUnpacked(await tempFile.read(packedLength));
    final List<List<dynamic>> rows = jsonDecodeFromBytes(
      await tempFile.read(size),
    ).cast<List<dynamic>>();

    // Import rows
    for (int index = rows.length - 1; index >= 0; index--) {
      if (_rows.containsList(rows[index]) ||
          (rowIndexes != null && !rowIndexes.contains(index))) {
        continue;
      }

      _insert(items: {
        for (int i = 0; i < _columns.length; i++) _columns[i]: rows[index][i]
      });
    }

    // Read attachment files info
    size = sizeUnpacked(await tempFile.read(packedLength));
    final Map<String, int> attachmentsInfo = jsonDecodeFromBytes(
      await tempFile.read(size),
    ).cast<String, int>();

    // Import attachment files
    for (final MapEntry<String, int> attachInfo in attachmentsInfo.entries) {
      String attachPath = attachInfo.key;
      int attachSize = attachInfo.value;
      final String name = pathlib.dirname(attachPath);
      attachPath = pathlib.join(_drive.attachmentDir, attachPath);
      File attachFile = File(attachPath);
      final bool attachExists = await attachFile.exists();

      Future<void> reader({RandomAccessFile? file}) async {
        while (attachSize > 0) {
          final int chunkLenght = min(chunkSize, attachSize);
          attachSize -= chunkLenght;
          final Uint8List chunk = await tempFile.read(chunkLenght);
          await file?.writeFrom(chunk);
        }
      }

      if ((attachmentNames != null && !attachmentNames.contains(name)) ||
          (attachExists &&
              await attachFile
                  .stat()
                  .then((value) => value.size == attachSize))) {
        // ignore all files that are not selected or have no size
        await reader();
        continue;
      } else if (attachExists) {
        attachFile = File(pathWithDate(attachPath));
      }

      await attachFile.create(recursive: true);
      await reader(file: await attachFile.open(mode: FileMode.writeOnly));
    }

    await tempFile.close();
    await File(tempPath).delete();
  }

  Future<String> exportBackup({
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? outputDir,
    String? key,
    void Function(int value)? progressCallback,
  }) async {
    tableCreationValidator(_columns);
    backupValidator(_drive.hasBackup);

    // Rows collection
    final List<List<dynamic>> rows = (rowIndexes == null)
        ? _rows
        : rowIndexes.map((rowIndex) => _rows[rowIndex]).toList();

    // Attachments collection
    final Map<String, int> attachmentsInfo = {};
    if (_drive.hasAttachments) {
      await for (final FileSystemEntity attachFile
          in Directory(_drive.attachmentDir).list(recursive: true)) {
        final String name = pathlib.basename(attachFile.parent.path);

        if (await attachFile.stat().then(
                (value) => value.type == FileSystemEntityType.directory) ||
            (attachmentNames != null && !attachmentNames.contains(name))) {
          continue;
        }

        attachmentsInfo.addAll({
          pathlib.relative(attachFile.path, from: _drive.attachmentDir):
              await attachFile.stat().then((value) => value.size)
        });
      }
    }

    // Create temp file
    final RandomAccessFile tempFile = await File(
      pathWithDate(pathlib.join(
        _drive.tempDir,
        pathlib.relative(_drive.backupPath, from: _drive.backupDir),
      )),
    ).open(mode: FileMode.writeOnly);
    Uint8List data;

    // Export rows
    data = jsonEncodeToBytes(rows);
    await tempFile.writeFrom(sizePacked(data.length));
    await tempFile.writeFrom(data);

    // Export attachment info
    data = jsonEncodeToBytes(attachmentsInfo);
    await tempFile.writeFrom(sizePacked(data.length));
    await tempFile.writeFrom(data);

    // Export attachment files
    for (final String attachPath in attachmentsInfo.keys) {
      final RandomAccessFile attachFile = await File(
        pathlib.join(_drive.attachmentDir, attachPath),
      ).open(mode: FileMode.read);

      while (true) {
        final Uint8List chunk = await attachFile.read(chunkSize);
        if (chunk.isEmpty) break;

        await tempFile.writeFrom(chunk);
      }

      await attachFile.close();
    }

    await tempFile.close();

    outputDir ??= _drive.backupDir;

    // Encrypt to output directory
    _cipher.setKey(key ?? _key);

    return await _cipher.encryptFile(
      path: tempFile.path,
      directory: outputDir,
      ignoreFileExists: true,
      removeAfterComplete: true,
      progressCallback: progressCallback,
    );
  }
}
