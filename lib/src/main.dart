import 'dart:io';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:collection/collection.dart';

import 'core/core.dart';
import 'drive.dart';
import 'models.dart';

class DatabaseEngine with AttachmentCore, BackupCore {
  DatabaseEngine(this._drive, {required String key}) {
    _cipher = AESCrypto(key: key);

    attachmentInit(_drive, _cipher);
    backupInit(_drive, _columns, _rows, _cipher, addRow);
  }

  final DriveSetup _drive;
  final List<String> _columns = [];
  final List<List<dynamic>> _rows = [];
  late AESCrypto _cipher;

  void createTable(List<String> columnTitles) {
    if (_columns.isNotEmpty) {
      throw Exception("This database already has table created");
    }

    for (final String title in columnTitles) {
      if (columnTitles.count(title) > 1) {
        throw Exception("$title title is duplicated");
      }
    }

    _columns.addAll(columnTitles);
  }

  Stream<DBRow> select({
    List<String>? columnTitles,
    Map<String, dynamic>? items,
  }) async* {
    tableCreationValidator(_columns);

    columnTitles ??= _columns;

    for (int index = 0; index < _rows.length; index++) {
      final List<dynamic> row = _rows[index];
      final Map<String, dynamic> result = {};

      _columns.forEachIndexed((i, title) {
        if (columnTitles!.contains(title)) result[title] = row[i];
      });

      if (items != null &&
          items.entries.any((item) => result[item.key] != item.value)) {
        continue;
      }

      yield DBRow(items: result, indexQueryCallback: indexQuery);
    }
  }

  void addRow(Map<String, dynamic> items) {
    tableCreationValidator(_columns);

    final List<dynamic> row = _columns.map((title) {
      return items[title] ?? (throw Exception("Please define $title value"));
    }).toList();

    rowTypeValidator(row, _columns, _rows);
    _rows.add(row);
  }

  void edit({
    required int rowIndex,
    required Map<String, dynamic> items,
  }) {
    tableCreationValidator(_columns);
    rowIndexValidator(rowIndex, _rows);

    final List<dynamic> oldRow = _rows[rowIndex];
    final List<dynamic> newRow = _columns.mapIndexed((index, title) {
      return items[title] ?? oldRow[index];
    }).toList();

    rowTypeValidator(newRow, _columns, _rows);
    _rows[rowIndex] = newRow;
  }

  void removeColumn(String title) {
    tableCreationValidator(_columns);

    final int columnIndex = _columns.indexOf(title);
    if (columnIndex < 0) {
      throw Exception("Title $title is not defined");
    }

    _columns.removeAt(columnIndex);

    for (final List<dynamic> row in _rows) {
      row.removeAt(columnIndex);
    }
  }

  void removeRow(int rowIndex) {
    tableCreationValidator(_columns);
    rowIndexValidator(rowIndex, _rows);
    _rows.removeAt(rowIndex);
  }

  void clear() {
    _rows.clear();
  }

  int countColumn() {
    return _columns.length;
  }

  int countRow() {
    return _rows.length;
  }

  void setKey(String key) {
    _cipher.setKey(key);
  }

  Future<bool> load({void Function(int value)? progressCallback}) async {
    tableCreationValidator(_columns);
    if (!_drive.isCreated) await _drive.create();

    Future<bool> loader(String path) async {
      path = addAESExtension(path);

      if (!await File(path).exists()) return false;

      final Uint8List data = await _cipher.decryptFromFile(
        path: path,
        progressCallback: progressCallback,
      );
      final List<List<dynamic>> rows =
          jsonDecodeFromBytes(data).cast<List<dynamic>>();

      if (rows.isNotEmpty) {
        tableLengthValidator(_columns.length, rows[0].length);
      }

      _rows.addAll(rows);
      return true;
    }

    try {
      return await loader(_drive.databasePath);
    } on InvalidKeyError {
      rethrow;
    } catch (_) {
      return await loader(_drive.databaseBakPath);
    }
  }

  Future<String> dump({void Function(int value)? progressCallback}) async {
    tableCreationValidator(_columns);
    if (!_drive.isCreated) await _drive.create();

    final String outputPath = await _cipher.encryptToFile(
      data: jsonEncodeToBytes(_rows),
      path: _drive.databasePath,
      ignoreFileExists: true,
      progressCallback: progressCallback,
    );

    await File(outputPath).copy(addAESExtension(_drive.databaseBakPath));

    return outputPath;
  }

  int indexQuery(Map<String, dynamic> items) {
    final List<dynamic> itemsList = items.values.toList();
    return _rows.indexWhere((items) {
      return items.equals(itemsList);
    });
  }
}
