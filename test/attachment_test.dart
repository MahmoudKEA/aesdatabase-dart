import 'dart:io';

import 'package:aescrypto/aescrypto.dart';
import 'package:aesdatabase/aesdatabase.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as pathlib;

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  group("Attachment Methods Group:", () {
    final DriveSetup driveSetup = DriveSetup(hasAttachments: true);

    final DatabaseEngine databaseEngine = DatabaseEngine(
      driveSetup,
      key: "passwordKey",
    );

    String name = 'mydata';
    String fileName = 'data.txt';
    String filePath = pathlib.join(driveSetup.tempDir, fileName);
    late String fileSHA256;

    setUpAll(() async {
      await driveSetup.create();

      if (!await File(filePath).exists()) {
        await File(filePath).writeAsString('Any Content' * 10000);
      }

      fileSHA256 = await getFileChecksum(filePath);
    });

    test("Test (importAttachment)", () async {
      String outputPath = await databaseEngine.importAttachment(
        name: name,
        path: filePath,
        ignoreFileExists: true,
        progressCallback: (value) => printDebug('Importing...: $value'),
      );
      bool isExists = await databaseEngine.existsAttachment(
        name: name,
        fileName: fileName,
      );

      printDebug("""
outputPath: $outputPath
isExists: $isExists
      """);

      expect(
        pathlib.join('.', outputPath),
        contains(pathlib.join(driveSetup.attachmentDir, name)),
      );
      expect(isExists, isTrue);
    });

    test("Test (selectAttachments)", () async {
      await for (String file in databaseEngine.selectAttachments()) {
        printDebug("""
file: $file
      """);

        expect(
          pathlib.join('.', file),
          equals(pathlib.join(driveSetup.attachmentDir, name, fileName)),
        );
        break; // once to avoid conflict with backup attachment
      }
    });

    test("Test (exportAttachment)", () async {
      String outputPath = await databaseEngine.exportAttachment(
        name: name,
        fileName: fileName,
        ignoreFileExists: true,
        progressCallback: (value) => printDebug('Exporting...: $value'),
      );
      bool isExists = await File(outputPath).exists();

      printDebug("""
outputPath: $outputPath
fileSHA256: $fileSHA256
isExists: $isExists
      """);

      expect(
        pathlib.join('.', outputPath),
        contains(pathlib.join(driveSetup.tempDir, fileName)),
      );
      expect(fileSHA256, equals(await getFileChecksum(filePath)));
      expect(isExists, isTrue);
    });

    test("Test (existsAttachment)", () async {
      bool isExists = await databaseEngine.existsAttachment(
        name: name,
        fileName: fileName,
      );

      printDebug("""
isExists: $isExists
      """);

      expect(isExists, isTrue);
    });

    test("Test (removeAttachment)", () async {
      bool isRemoved = await databaseEngine.removeAttachment(
        name: name,
        fileName: fileName,
      );

      bool isExists = await databaseEngine.existsAttachment(
        name: name,
        fileName: fileName,
      );

      printDebug("""
isRemoved: $isRemoved
isExists: $isExists
      """);

      expect(isRemoved, isTrue);
      expect(isExists, isFalse);
    });
  });
}
