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
        columnTitles!.contains(title) ? result.addAll({title: row[i]}) : null;
      });

      if (items != null &&
          items.entries.any((item) => result[item.key] != item.value)) {
        continue;
      }

      yield DBRow(index, result);
    }
  }

  void addRow(Map<String, dynamic> items) {
    tableCreationValidator(_columns);

    final List<dynamic> row = _columns.mapIndexed((index, title) {
      final dynamic item = items[title];
      item ?? (throw Exception("Please define $title value"));
      return item;
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

    final List<dynamic> row = _columns.mapIndexed((index, title) {
      final dynamic item = items[title];
      return item ?? _rows[rowIndex][index];
    }).toList();

    rowTypeValidator(row, _columns, _rows);
    _rows[rowIndex] = row;
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

  Future<bool> load({void Function(int value)? progressCallback}) async {
    tableCreationValidator(_columns);
    if (!_drive.isCreated) await _drive.create();

    try {
      final Uint8List data = await _cipher.decryptFromFile(
        path: addAESExtension(_drive.databasePath),
        progressCallback: progressCallback,
      );
      final List<List<dynamic>> rows =
          jsonDecodeFromBytes(data).cast<List<dynamic>>();

      if (rows.isNotEmpty) {
        tableLengthValidator(_columns.length, rows[0].length);
      }

      _rows.addAll(rows);
    } on FileSystemException {
      return false;
    }

    return true;
  }

  Future<String> dump({void Function(int value)? progressCallback}) async {
    tableCreationValidator(_columns);
    if (!_drive.isCreated) await _drive.create();

    return _cipher.encryptToFile(
      data: jsonEncodeToBytes(_rows),
      path: _drive.databasePath,
      ignoreFileExists: true,
      progressCallback: progressCallback,
    );
  }
}
