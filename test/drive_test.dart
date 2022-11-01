import 'dart:io';

import 'package:aesdatabase/aesdatabase.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as pathlib;

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  group("DriveSetup Group:", () {
    final DriveSetup driveSetup = DriveSetup(
      hasAttachments: true,
      hasBackup: true,
    );
    const String mainDir = 'storage';

    test("Test default attributes", () {
      String tempDir = pathlib.join('.', 'temp');

      String databaseDir = pathlib.join('.', 'database');
      String databasePath = pathlib.join(databaseDir, 'database.db');

      String attachmentDir = pathlib.join(databaseDir, 'attachments');

      String backupDir = pathlib.join('.', 'backup');
      String backupPath = pathlib.join(backupDir, 'database.backup');

      printDebug("""
hasAttachments: ${driveSetup.hasAttachments}
hasBackup: ${driveSetup.hasBackup}
isCreated: ${driveSetup.isCreated}
tempDir: ${driveSetup.tempDir}
databaseDir: ${driveSetup.databaseDir}
databasePath: ${driveSetup.databasePath}
attachmentDir: ${driveSetup.attachmentDir}
backupDir: ${driveSetup.backupDir}
backupPath: ${driveSetup.backupPath}
      """);

      expect(driveSetup.hasAttachments, isTrue);
      expect(driveSetup.hasBackup, isTrue);
      expect(driveSetup.isCreated, isFalse);
      expect(driveSetup.tempDir, equals(tempDir));
      expect(driveSetup.databaseDir, equals(databaseDir));
      expect(driveSetup.databasePath, equals(databasePath));
      expect(driveSetup.attachmentDir, equals(attachmentDir));
      expect(driveSetup.backupDir, equals(backupDir));
      expect(driveSetup.backupPath, equals(backupPath));
    });

    test("Test (tempUpdate)", () {
      String folderName = 'tmp';
      String directory = pathlib.join(mainDir, folderName);
      driveSetup.tempUpdate(main: mainDir, folder: folderName);

      printDebug("""
tempDir: ${driveSetup.tempDir}
      """);

      expect(driveSetup.tempDir, equals(directory));
    });

    test("Test (attachmentUpdate)", () {
      String folderName = 'attachs';
      String directory = pathlib.join(mainDir, folderName);
      driveSetup.attachmentUpdate(main: mainDir, folder: folderName);

      printDebug("""
attachmentDir: ${driveSetup.attachmentDir}
      """);

      expect(driveSetup.attachmentDir, equals(directory));
    });

    test("Test (databaseUpdate)", () {
      String folderName = 'data';
      String directory = pathlib.join(mainDir, folderName);
      driveSetup.databaseUpdate(main: mainDir, folder: folderName);

      printDebug("""
databaseDir: ${driveSetup.databaseDir}
databasePath: ${driveSetup.databasePath}
      """);

      expect(driveSetup.databaseDir, equals(directory));
      expect(driveSetup.databasePath, contains(directory));
    });

    test("Test (backupUpdate)", () {
      String folderName = 'exports';
      String directory = pathlib.join(mainDir, folderName);
      driveSetup.backupUpdate(main: mainDir, folder: folderName);

      printDebug("""
backupDir: ${driveSetup.backupDir}
backupPath: ${driveSetup.backupPath}
      """);

      expect(driveSetup.backupDir, equals(directory));
      expect(driveSetup.backupPath, contains(directory));
    });

    test("Test (create)", () async {
      List<String> files = await driveSetup.create();

      for (String path in files) {
        printDebug("""
path Created: $path
      """);

        expect(path.startsWith(mainDir), isTrue);
        expect(await Directory(path).exists(), isTrue);
      }

      expect(files.length, equals(4));
      expect(driveSetup.isCreated, isTrue);
    });

    test("Test (delete)", () async {
      List<String> files = await driveSetup.delete();

      for (String path in files) {
        printDebug("""
path Deleted: $path
      """);

        expect(await Directory(path).exists(), isFalse);
      }

      expect(files.length, equals(4));
      expect(driveSetup.isCreated, isFalse);
    });
  });
}
