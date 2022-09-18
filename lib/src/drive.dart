import 'dart:io';

import 'package:path/path.dart' as pathlib;

class DriveSetup {
  DriveSetup({this.hasAttachments = false, this.hasBackup = false}) {
    tempUpdate(
      main: '.',
      folder: 'temp',
    );
    attachmentUpdate(
      main: pathlib.join('.', 'database'),
      folder: 'attachments',
    );
    databaseUpdate(
      main: '.',
      folder: 'database',
      file: 'database',
      extension: '.db',
    );
    backupUpdate(
      main: '.',
      folder: 'backup',
      file: 'database',
      extension: '.backup',
    );
  }

  final bool hasAttachments;
  final bool hasBackup;

  bool isCreated = false;

  late String _tempFolderName;
  late String tempDir;

  late String _attachmentFolderName;
  late String attachmentDir;

  late String _databaseFolderName;
  late String _databaseFileName;
  late String _databaseExtension;
  late String databaseDir;
  late String databasePath;

  late String _backupFolderName;
  late String _backupFileName;
  late String _backupExtension;
  late String backupDir;
  late String backupPath;

  void tempUpdate({String? main, String? folder}) {
    main ??= pathlib.dirname(tempDir);
    _tempFolderName = folder ?? _tempFolderName;
    tempDir = pathlib.join(main, _tempFolderName);
  }

  void attachmentUpdate({String? main, String? folder}) {
    main ??= pathlib.dirname(attachmentDir);
    _attachmentFolderName = folder ?? _attachmentFolderName;
    attachmentDir = pathlib.join(main, _attachmentFolderName);
  }

  void databaseUpdate({
    String? main,
    String? folder,
    String? file,
    String? extension,
  }) {
    main ??= pathlib.dirname(databaseDir);
    _databaseFolderName = folder ?? _databaseFolderName;
    _databaseFileName = file ?? _databaseFileName;
    _databaseExtension = extension ?? _databaseExtension;

    bool hasSubAttachment;
    try {
      hasSubAttachment = (databaseDir == pathlib.dirname(attachmentDir));
    } catch (e) {
      hasSubAttachment = false;
    }

    databaseDir = pathlib.join(main, _databaseFolderName);
    databasePath = pathlib.join(
      databaseDir,
      _databaseFileName + _databaseExtension,
    );

    if (hasSubAttachment) {
      attachmentUpdate(main: databaseDir);
    }
  }

  void backupUpdate({
    String? main,
    String? folder,
    String? file,
    String? extension,
  }) {
    main ??= pathlib.dirname(backupDir);
    _backupFolderName = folder ?? _backupFolderName;
    _backupFileName = file ?? _backupFileName;
    _backupExtension = extension ?? _backupExtension;
    backupDir = pathlib.join(main, _backupFolderName);
    backupPath = pathlib.join(backupDir, _backupFileName + _backupExtension);
  }

  List<String> create() {
    List<String> result = [];

    Directory(databaseDir).createSync(recursive: true);
    result.add(databaseDir);

    Directory(tempDir).createSync(recursive: true);
    result.add(tempDir);

    if (hasAttachments) {
      Directory(attachmentDir).createSync(recursive: true);
      result.add(attachmentDir);
    }

    if (hasBackup) {
      Directory(backupDir).createSync(recursive: true);
      result.add(backupDir);
    }

    isCreated = true;
    return result;
  }

  List<String> delete({
    bool database = true,
    bool temp = true,
    bool attachment = true,
    bool backup = true,
  }) {
    List<String> result = [];

    if (database) {
      _removeDir(databaseDir);
      result.add(databaseDir);
    }

    if (temp) {
      _removeDir(tempDir);
      result.add(tempDir);
    }

    if (attachment) {
      _removeDir(attachmentDir);
      result.add(attachmentDir);
    }

    if (backup) {
      _removeDir(backupDir);
      result.add(backupDir);
    }

    isCreated = false;
    return result;
  }

  void _removeDir(String directory) {
    try {
      Directory(directory).deleteSync(recursive: true);
    } catch (e) {
      return;
    }
  }
}
