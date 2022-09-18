import 'dart:io';

import 'package:aesdatabase/src/core/core.dart';
import 'package:aesdatabase/src/drive.dart';
import 'package:aescrypto/aescrypto.dart';
import 'package:path/path.dart' as pathlib;

mixin AttachmentCore {
  late DriveSetup _drive;
  late String _key;
  late AESCrypto _cipher;

  void attachmentInit(DriveSetup drive, String key, AESCrypto cipher) {
    _drive = drive;
    _key = key;
    _cipher = cipher;
  }

  Stream<String> selectAttachments({
    String? name,
    String? fileName,
  }) async* {
    attachmentValidator(_drive.hasAttachments);

    for (FileSystemEntity file in Directory(_drive.attachmentDir).listSync(
      recursive: true,
    )) {
      if ((file.statSync().type == FileSystemEntityType.directory) ||
          (name != null && pathlib.basename(file.parent.path) != name) ||
          (fileName != null &&
              pathlib.basename(file.path) != addExtension(fileName))) {
        continue;
      }

      yield removeExtension(file.path);
    }
  }

  String importAttachmentSync({
    required String name,
    required String path,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    attachmentValidator(_drive.hasAttachments);
    String directory = pathlib.join(_drive.attachmentDir, name);

    _cipher.setKey(_key);

    return _cipher.encryptFileSync(
      path: path,
      directory: directory,
      ignoreFileExists: ignoreFileExists,
      progressCallback: progressCallback,
    );
  }

  String exportAttachmentSync({
    required String name,
    required String fileName,
    String? outputDir,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    attachmentValidator(_drive.hasAttachments);
    String path = addExtension(
      pathlib.join(_drive.attachmentDir, name, fileName),
    );

    outputDir ??= _drive.tempDir;

    _cipher.setKey(_key);
    return _cipher.decryptFileSync(
      path: path,
      directory: outputDir,
      ignoreFileExists: ignoreFileExists,
      progressCallback: progressCallback,
    );
  }

  bool removeAttachmentSync({
    required String name,
    required String fileName,
  }) {
    attachmentValidator(_drive.hasAttachments);
    String directory = pathlib.join(_drive.attachmentDir, name);
    String path = addExtension(pathlib.join(directory, fileName));
    bool valid = false;

    try {
      File(path).deleteSync();
      valid = true;
      Directory(directory).deleteSync();
    } on FileSystemException {
      // Ignore if the directory contains other files or file not exists
    }

    return valid;
  }

  bool existsAttachmentSync({
    required String name,
    required String fileName,
  }) {
    attachmentValidator(_drive.hasAttachments);
    String path = addExtension(
      pathlib.join(_drive.attachmentDir, name, fileName),
    );

    return File(path).existsSync();
  }
}
