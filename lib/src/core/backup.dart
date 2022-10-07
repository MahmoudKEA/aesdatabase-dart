import 'dart:convert';
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
  late Function _insertSync;

  void backupInit(
    DriveSetup drive,
    String key,
    List<String> columns,
    List<List<dynamic>> rows,
    AESCrypto cipher,
    Function insertSync,
  ) {
    _drive = drive;
    _key = key;
    _columns = columns;
    _rows = rows;
    _cipher = cipher;
    _insertSync = insertSync;
  }

  Future<void> importBackup({
    required String path,
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? key,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return importBackupSync(
        path: path,
        rowIndexes: rowIndexes,
        attachmentNames: attachmentNames,
        key: key,
        removeAfterComplete: removeAfterComplete,
        progressCallback: progressCallback,
      );
    });
  }

  void importBackupSync({
    required String path,
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? key,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) {
    tableCreationValidator(_columns);
    backupValidator(_drive.hasBackup);

    _cipher.setKey(key ?? _key);
    String tempPath = _cipher.decryptFileSync(
      path: path,
      directory: _drive.tempDir,
      ignoreFileExists: true,
      removeAfterComplete: removeAfterComplete,
      progressCallback: progressCallback,
    );

    RandomAccessFile tempFile = File(tempPath).openSync(mode: FileMode.read);
    int size;

    // Read rows
    size = sizeUnpacked(tempFile.readSync(packedLength));
    List<List<dynamic>> rows = jsonDecode(
      utf8.decode(tempFile.readSync(size)),
    ).cast<List<dynamic>>();

    // Import rows
    for (int index = rows.length - 1; index >= 0; index--) {
      if (_rows.containsList(rows[index]) ||
          (rowIndexes != null && !rowIndexes.contains(index))) {
        continue;
      }

      _insertSync(items: {
        for (int i = 0; i < _columns.length; i++) _columns[i]: rows[index][i]
      });
    }

    // Read attachment files info
    size = sizeUnpacked(tempFile.readSync(packedLength));
    Map<String, int> attachmentsInfo = jsonDecode(
      utf8.decode(tempFile.readSync(size)),
    ).cast<String, int>();

    // Import attachment files
    for (MapEntry<String, int> attachInfo in attachmentsInfo.entries) {
      String attachPath = attachInfo.key;
      int attachSize = attachInfo.value;
      String name = pathlib.dirname(attachPath);
      attachPath = pathlib.join(_drive.attachmentDir, attachPath);
      File attachFile = File(attachPath);
      bool attachExists = attachFile.existsSync();

      void reader({RandomAccessFile? file}) {
        while (attachSize > 0) {
          int chunkLenght = min(chunkSize, attachSize);
          attachSize -= chunkLenght;
          Uint8List chunk = tempFile.readSync(chunkLenght);
          file?.writeFromSync(chunk);
        }
      }

      if ((attachmentNames != null && !attachmentNames.contains(name)) ||
          (attachExists && attachFile.statSync().size == attachSize)) {
        // ignore all files that are not selected or have no size
        reader();
        continue;
      } else if (attachExists) {
        attachFile = File(pathWithDateSync(attachPath));
      }

      attachFile.createSync(recursive: true);
      reader(file: attachFile.openSync(mode: FileMode.writeOnly));
    }

    tempFile.closeSync();
    File(tempPath).deleteSync();
  }

  Future<String> exportBackup({
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? outputDir,
    String? key,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return exportBackupSync(
        rowIndexes: rowIndexes,
        attachmentNames: attachmentNames,
        outputDir: outputDir,
        key: key,
        progressCallback: progressCallback,
      );
    });
  }

  String exportBackupSync({
    List<int>? rowIndexes,
    List<String>? attachmentNames,
    String? outputDir,
    String? key,
    void Function(int value)? progressCallback,
  }) {
    tableCreationValidator(_columns);
    backupValidator(_drive.hasBackup);

    // Rows collection
    List<List<dynamic>> rows = (rowIndexes == null)
        ? _rows
        : rowIndexes.map((rowIndex) => _rows[rowIndex]).toList();

    // Attachments collection
    Map<String, int> attachmentsInfo = {};
    if (_drive.hasAttachments) {
      for (FileSystemEntity attachFile
          in Directory(_drive.attachmentDir).listSync(recursive: true)) {
        String name = pathlib.basename(attachFile.parent.path);

        if ((attachFile.statSync().type == FileSystemEntityType.directory) ||
            (attachmentNames != null && !attachmentNames.contains(name))) {
          continue;
        }

        attachmentsInfo.addAll({
          pathlib.relative(attachFile.path, from: _drive.attachmentDir):
              attachFile.statSync().size
        });
      }
    }

    // Create temp file
    RandomAccessFile tempFile = File(
      pathlib.join(
        _drive.tempDir,
        pathlib.relative(_drive.backupPath, from: _drive.backupDir),
      ),
    ).openSync(mode: FileMode.writeOnly);
    Uint8List data;

    // Export rows
    data = Uint8List.fromList(jsonEncode(rows).codeUnits);
    tempFile.writeFromSync(sizePacked(data.length));
    tempFile.writeFromSync(data);

    // Export attachment info
    data = Uint8List.fromList(jsonEncode(attachmentsInfo).codeUnits);
    tempFile.writeFromSync(sizePacked(data.length));
    tempFile.writeFromSync(data);

    // Export attachment files
    for (String attachPath in attachmentsInfo.keys) {
      RandomAccessFile attachFile = File(
        pathlib.join(_drive.attachmentDir, attachPath),
      ).openSync(mode: FileMode.read);

      while (true) {
        Uint8List chunk = attachFile.readSync(chunkSize);
        if (chunk.isEmpty) break;

        tempFile.writeFromSync(chunk);
      }

      attachFile.closeSync();
    }

    tempFile.closeSync();

    outputDir ??= _drive.backupDir;

    // Encrypt to output directory
    _cipher.setKey(key ?? _key);

    String outpathPath = _cipher.encryptFileSync(
      path: tempFile.path,
      directory: outputDir,
      ignoreFileExists: true,
      removeAfterComplete: true,
      progressCallback: progressCallback,
    );

    return File(outpathPath).renameSync(pathWithDateSync(outpathPath)).path;
  }
}
