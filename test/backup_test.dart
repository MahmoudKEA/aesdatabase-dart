import 'dart:io';

import 'package:aescrypto/aescrypto.dart';
import 'package:aesdatabase/aesdatabase.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as pathlib;

import 'core/core.dart';

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  group("Attachment Methods Group:", () {
    final DriveSetup driveSetup = DriveSetup(
      hasAttachments: true,
      hasBackup: true,
    );

    final DatabaseEngine databaseEngine = DatabaseEngine(
      driveSetup,
      "passwordKey",
    );

    final List<String> titles = getTitlesDataTest();
    final List<Map<String, dynamic>> rowsData = getRowsDataTest();

    String attachName = 'mydataBackup';
    String attachFileName = 'dataBackup.txt';
    String attachFilePath = pathlib.join(driveSetup.tempDir, attachFileName);
    late String fileSHA256;

    late String backupFilePath;

    setUpAll(() {
      driveSetup.create();

      databaseEngine.createTableSync(titles);

      for (Map<String, dynamic> row in rowsData) {
        databaseEngine.insertSync(
          rowIndex: databaseEngine.countRowSync(),
          items: row,
        );
      }

      if (!File(attachFilePath).existsSync()) {
        File(attachFilePath).writeAsStringSync('Any Content' * 10000);
      }

      fileSHA256 = fileChecksumSync(attachFilePath);

      databaseEngine.importAttachmentSync(
        name: attachName,
        path: attachFilePath,
        ignoreFileExists: true,
      );
    });

    test("Test (exportBackup)", () async {
      backupFilePath = await databaseEngine.exportBackup(
        progressCallback: (value) => printDebug('Backup exporting...: $value'),
      );
      bool isExists = File(backupFilePath).existsSync();

      printDebug("""
backupFilePath: $backupFilePath
isExists: $isExists
      """);

      expect(pathlib.join('.', backupFilePath), contains(driveSetup.backupDir));
      expect(isExists, isTrue);
    });

    test("Test (importBackup)", () async {
      databaseEngine.clearSync();
      databaseEngine.removeAttachmentSync(
        name: attachName,
        fileName: attachFileName,
      );

      await databaseEngine.importBackup(
        path: backupFilePath,
        progressCallback: (value) => printDebug('Backup importing...: $value'),
      );

      int countRow = databaseEngine.countRowSync();

      bool isAttachExists = await databaseEngine.existsAttachment(
        name: attachName,
        fileName: attachFileName,
      );

      printDebug("""
countRow: $countRow
isAttachExists: $isAttachExists
      """);

      await for (RowModel row in databaseEngine.select()) {
        expect(row.items, equals(rowsData[row.index]));
      }
      expect(countRow, equals(rowsData.length));
      expect(isAttachExists, isTrue);
    });
  });
}
