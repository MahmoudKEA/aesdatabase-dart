import 'dart:io';

import 'package:aescrypto/aescrypto.dart';
import 'package:path/path.dart' as pathlib;

import '../drive.dart';
import 'core.dart';

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

  Future<String> importAttachment({
    required String name,
    required String path,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return importAttachmentSync(
        name: name,
        path: path,
        ignoreFileExists: ignoreFileExists,
        progressCallback: progressCallback,
      );
    });
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

  Future<String> exportAttachment({
    required String name,
    required String fileName,
    String? outputDir,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return exportAttachmentSync(
        name: name,
        fileName: fileName,
        outputDir: outputDir,
        ignoreFileExists: ignoreFileExists,
        progressCallback: progressCallback,
      );
    });
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

  Future<bool> removeAttachment({
    required String name,
    required String fileName,
  }) {
    return Future(() {
      return removeAttachmentSync(
        name: name,
        fileName: fileName,
      );
    });
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

  Future<bool> existsAttachment({
    required String name,
    required String fileName,
  }) {
    return Future(() {
      return existsAttachmentSync(
        name: name,
        fileName: fileName,
      );
    });
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
