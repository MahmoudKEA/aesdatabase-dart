import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:collection/collection.dart';

import 'core/core.dart';
import 'drive.dart';
import 'models.dart';

class DatabaseEngine with AttachmentCore, BackupCore {
  DatabaseEngine(this._drive, this._key) {
    attachmentInit(_drive, _key, cipher);
    backupInit(_drive, _key, _columns, _rows, cipher, insert);
  }

  final DriveSetup _drive;
  final String _key;
  final List<String> _columns = [];
  final List<List<dynamic>> _rows = [];
  final AESCrypto cipher = AESCrypto(key: "");

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

  Stream<RowModel> select({
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

      yield RowModel(index, result);
    }
  }

  Future<void> insert({
    int rowIndex = 0,
    required Map<String, dynamic> items,
  }) async {
    tableCreationValidator(_columns);

    final ReceivePort receivePort = ReceivePort();

    Isolate.spawn<SendPort>(
      (sendPort) {
        try {
          final List<dynamic> row = _columns.mapIndexed((index, title) {
            final dynamic item = items[title];
            item ?? (throw Exception("Please define $title value"));
            return item;
          }).toList();

          rowTypeValidator(row, _columns, _rows);

          sendPort.send(row);
        } catch (e) {
          sendPort.send(e);
        }
      },
      receivePort.sendPort,
    );

    final dynamic result = await receivePort.first;
    if (result is Exception) throw result;

    _rows.insert(rowIndex, result);
  }

  Future<void> edit({
    required int rowIndex,
    required Map<String, dynamic> items,
  }) async {
    tableCreationValidator(_columns);
    rowIndexValidator(rowIndex, _rows);

    final ReceivePort receivePort = ReceivePort();

    Isolate.spawn<SendPort>(
      (sendPort) {
        try {
          final List<dynamic> row = _columns.mapIndexed((index, title) {
            var item = items[title];
            return item ?? _rows[rowIndex][index];
          }).toList();

          rowTypeValidator(row, _columns, _rows);

          sendPort.send(row);
        } catch (e) {
          sendPort.send(e);
        }
      },
      receivePort.sendPort,
    );

    final dynamic result = await receivePort.first;
    if (result is Exception) throw result;

    _rows[rowIndex] = result;
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
    _drive.isCreated ? null : await _drive.create();

    cipher.setKey(_key);

    final ReceivePort receivePort = ReceivePort();

    try {
      final Uint8List data = await cipher.decryptFromFile(
        path: addAESExtension(_drive.databasePath),
        progressCallback: progressCallback,
      );

      Isolate.spawn<SendPort>(
        (sendPort) async {
          sendPort.send(
            await jsonDecodeFromBytes(data),
          );
        },
        receivePort.sendPort,
      );

      _rows.addAll(
        await receivePort.first.then((value) => value.cast<List<dynamic>>()),
      );
    } on FileSystemException {
      return false;
    }

    final List<String> columnTitles = _rows.removeAt(0).cast<String>();
    createTable(columnTitles);

    return true;
  }

  Future<String> dump({void Function(int value)? progressCallback}) async {
    tableCreationValidator(_columns);
    _drive.isCreated ? null : await _drive.create();

    final ReceivePort receivePort = ReceivePort();

    Isolate.spawn<SendPort>(
      (sendPort) async {
        _rows.insert(0, _columns);

        sendPort.send(
          await jsonEncodeToBytes(_rows),
        );
      },
      receivePort.sendPort,
    );

    cipher.setKey(_key);

    return await cipher.encryptToFile(
      data: await receivePort.first,
      path: _drive.databasePath,
      ignoreFileExists: true,
      progressCallback: progressCallback,
    );
  }
}
