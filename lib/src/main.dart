import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:collection/collection.dart';

import 'core/core.dart';
import 'drive.dart';
import 'models.dart';

class DatabaseEngine with AttachmentCore, BackupCore {
  DatabaseEngine(this._drive, this._key) {
    attachmentInit(_drive, _key, cipher);
    backupInit(_drive, _key, _columns, _rows, cipher, insertSync);
  }

  final DriveSetup _drive;
  final String _key;
  final List<String> _columns = [];
  final List<List<dynamic>> _rows = [];
  final AESCrypto cipher = AESCrypto(key: "");

  Future<void> createTable(List<String> columnTitles) {
    return Future(() {
      return createTableSync(columnTitles);
    });
  }

  void createTableSync(List<String> columnTitles) {
    if (_columns.isNotEmpty) {
      throw Exception("This database already has table created");
    }

    for (String title in columnTitles) {
      if (columnTitles.count(title) > 1) {
        throw Exception("$title title is duplicated");
      }
    }

    _columns.addAll(columnTitles);
  }

  Stream<RowModel> select({
    List<String>? columnTitles,
    Map<String, dynamic>? items,
  }) async* {
    tableCreationValidator(_columns);

    columnTitles ??= _columns;

    for (int index = 0; index < _rows.length; index++) {
      List<dynamic> row = _rows[index];
      Map<String, dynamic> result = {};

      _columns.forEachIndexed((i, title) {
        columnTitles!.contains(title) ? result.addAll({title: row[i]}) : null;
      });

      if (items != null &&
          items.entries.any((item) => result[item.key] != item.value)) {
        continue;
      }

      yield RowModel(index, result);
    }
  }

  Future<void> insert({int rowIndex = 0, required Map<String, dynamic> items}) {
    return Future(() {
      return insertSync(rowIndex: rowIndex, items: items);
    });
  }

  void insertSync({int rowIndex = 0, required Map<String, dynamic> items}) {
    tableCreationValidator(_columns);

    List<dynamic> row = _columns.mapIndexed((index, title) {
      var item = items[title];
      item ?? (throw Exception("Please define $title value"));
      return item;
    }).toList();

    rowTypeValidator(row, _columns, _rows);
    _rows.insert(rowIndex, row);
  }

  Future<void> edit({
    required int rowIndex,
    required Map<String, dynamic> items,
  }) {
    return Future(() {
      return editSync(rowIndex: rowIndex, items: items);
    });
  }

  void editSync({required int rowIndex, required Map<String, dynamic> items}) {
    tableCreationValidator(_columns);
    rowIndexValidator(rowIndex, _rows);

    List<dynamic> row = _columns.mapIndexed((index, title) {
      var item = items[title];
      return item ?? _rows[rowIndex][index];
    }).toList();

    rowTypeValidator(row, _columns, _rows);
    _rows[rowIndex] = row;
  }

  Future<void> removeColumn(String title) {
    return Future(() {
      return removeColumnSync(title);
    });
  }

  void removeColumnSync(String title) {
    tableCreationValidator(_columns);

    int columnIndex = _columns.indexOf(title);
    if (columnIndex < 0) {
      throw Exception("Title $title is not defined");
    }

    _columns.removeAt(columnIndex);

    for (List<dynamic> row in _rows) {
      row.removeAt(columnIndex);
    }
  }

  Future<void> removeRow(int rowIndex) {
    return Future(() {
      return removeRowSync(rowIndex);
    });
  }

  void removeRowSync(int rowIndex) {
    tableCreationValidator(_columns);
    rowIndexValidator(rowIndex, _rows);
    _rows.removeAt(rowIndex);
  }

  Future<void> clear() {
    return Future(() {
      return clearSync();
    });
  }

  void clearSync() {
    _rows.clear();
  }

  Future<int> countColumn() {
    return Future(() {
      return countColumnSync();
    });
  }

  int countColumnSync() {
    return _columns.length;
  }

  Future<int> countRow() {
    return Future(() {
      return countRowSync();
    });
  }

  int countRowSync() {
    return _rows.length;
  }

  Future<bool> load({void Function(int value)? progressCallback}) {
    return Future(() {
      return loadSync(progressCallback: progressCallback);
    });
  }

  bool loadSync({void Function(int value)? progressCallback}) {
    _drive.isCreated ? null : _drive.create();
    cipher.setKey(_key);

    try {
      _rows.addAll(
        jsonDecode(
          utf8.decode(
            cipher.decryptFromFileSync(
              path: addExtension(_drive.databasePath),
              progressCallback: progressCallback,
            ),
          ),
        ).cast<List<dynamic>>(),
      );
    } on FileSystemException {
      return false;
    }

    List<String> columnTitles = _rows.removeAt(0).cast<String>();
    createTableSync(columnTitles);

    return true;
  }

  Future<String> dump({void Function(int value)? progressCallback}) {
    return Future(() {
      return dumpSync(progressCallback: progressCallback);
    });
  }

  String dumpSync({void Function(int value)? progressCallback}) {
    tableCreationValidator(_columns);
    _drive.isCreated ? null : _drive.create();

    _rows.insert(0, _columns);
    Uint8List data = Uint8List.fromList(jsonEncode(_rows).codeUnits);
    _rows.removeAt(0);

    cipher.setKey(_key);

    return cipher.encryptToFileSync(
      data: data,
      path: _drive.databasePath,
      ignoreFileExists: true,
      progressCallback: progressCallback,
    );
  }
}
