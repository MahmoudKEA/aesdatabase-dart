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

    await for (final FileSystemEntity file in Directory(
      _drive.attachmentDir,
    ).list(recursive: true)) {
      if (await file
              .stat()
              .then((value) => value.type == FileSystemEntityType.directory) ||
          (name != null && pathlib.basename(file.parent.path) != name) ||
          (fileName != null &&
              pathlib.basename(file.path) != addAESExtension(fileName))) {
        continue;
      }

      yield removeAESExtension(file.path);
    }
  }

  Future<String> importAttachment({
    required String name,
    required String path,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) async {
    attachmentValidator(_drive.hasAttachments);
    final String directory = pathlib.join(_drive.attachmentDir, name);

    _cipher.setKey(_key);

    return await _cipher.encryptFile(
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
  }) async {
    attachmentValidator(_drive.hasAttachments);
    final String path = addAESExtension(
      pathlib.join(_drive.attachmentDir, name, fileName),
    );

    outputDir ??= _drive.tempDir;

    _cipher.setKey(_key);

    return await _cipher.decryptFile(
      path: path,
      directory: outputDir,
      ignoreFileExists: ignoreFileExists,
      progressCallback: progressCallback,
    );
  }

  Future<bool> removeAttachment({
    required String name,
    required String fileName,
  }) async {
    attachmentValidator(_drive.hasAttachments);
    final String directory = pathlib.join(_drive.attachmentDir, name);
    final String path = addAESExtension(pathlib.join(directory, fileName));
    bool valid = false;

    try {
      await File(path).delete();
      valid = true;
      await Directory(directory).delete();
    } on FileSystemException {
      // Ignore if the directory contains other files or file not exists
    }

    return valid;
  }

  Future<bool> existsAttachment({
    required String name,
    required String fileName,
  }) async {
    attachmentValidator(_drive.hasAttachments);
    final String path = addAESExtension(
      pathlib.join(_drive.attachmentDir, name, fileName),
    );

    return await File(path).exists();
  }
}
