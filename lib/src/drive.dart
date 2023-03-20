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

  bool _isCreated = false;

  late String _tempFolderName;
  late String _tempDir;

  late String _attachmentFolderName;
  late String _attachmentDir;

  late String _databaseFolderName;
  late String _databaseFileName;
  late String _databaseExtension;
  late String _databaseDir;
  late String _databasePath;

  late String _backupFolderName;
  late String _backupFileName;
  late String _backupExtension;
  late String _backupDir;
  late String _backupPath;

  bool get isCreated => _isCreated;

  String get tempDir => _tempDir;

  String get attachmentDir => _attachmentDir;

  String get databaseDir => _databaseDir;

  String get databasePath => _databasePath;

  String get backupDir => _backupDir;

  String get backupPath => _backupPath;

  void tempUpdate({String? main, String? folder}) {
    main ??= pathlib.dirname(_tempDir);
    _tempFolderName = folder ?? _tempFolderName;
    _tempDir = pathlib.join(main, _tempFolderName);
  }

  void attachmentUpdate({String? main, String? folder}) {
    main ??= pathlib.dirname(_attachmentDir);
    _attachmentFolderName = folder ?? _attachmentFolderName;
    _attachmentDir = pathlib.join(main, _attachmentFolderName);
  }

  void databaseUpdate({
    String? main,
    String? folder,
    String? file,
    String? extension,
  }) {
    main ??= pathlib.dirname(_databaseDir);
    _databaseFolderName = folder ?? _databaseFolderName;
    _databaseFileName = file ?? _databaseFileName;
    _databaseExtension = extension ?? _databaseExtension;

    bool hasSubAttachment;
    try {
      hasSubAttachment = (_databaseDir == pathlib.dirname(_attachmentDir));
    } catch (e) {
      hasSubAttachment = false;
    }

    _databaseDir = pathlib.join(main, _databaseFolderName);
    _databasePath = pathlib.join(
      _databaseDir,
      _databaseFileName + _databaseExtension,
    );

    if (hasSubAttachment) {
      attachmentUpdate(main: _databaseDir);
    }
  }

  void backupUpdate({
    String? main,
    String? folder,
    String? file,
    String? extension,
  }) {
    main ??= pathlib.dirname(_backupDir);
    _backupFolderName = folder ?? _backupFolderName;
    _backupFileName = file ?? _backupFileName;
    _backupExtension = extension ?? _backupExtension;
    _backupDir = pathlib.join(main, _backupFolderName);
    _backupPath = pathlib.join(_backupDir, _backupFileName + _backupExtension);
  }

  Future<List<String>> create() async {
    List<String> result = [];

    await Directory(_databaseDir).create(recursive: true);
    result.add(_databaseDir);

    await Directory(_tempDir).create(recursive: true);
    result.add(_tempDir);

    if (hasAttachments) {
      await Directory(_attachmentDir).create(recursive: true);
      result.add(_attachmentDir);
    }

    if (hasBackup) {
      await Directory(_backupDir).create(recursive: true);
      result.add(_backupDir);
    }

    _isCreated = true;
    return result;
  }

  Future<List<String>> delete({
    bool database = true,
    bool temp = true,
    bool attachment = true,
    bool backup = true,
  }) async {
    List<String> result = [];

    if (database) {
      await _removeDir(_databaseDir);
      result.add(_databaseDir);
    }

    if (temp) {
      await _removeDir(_tempDir);
      result.add(_tempDir);
    }

    if (attachment) {
      await _removeDir(_attachmentDir);
      result.add(_attachmentDir);
    }

    if (backup) {
      await _removeDir(_backupDir);
      result.add(_backupDir);
    }

    _isCreated = false;
    return result;
  }

  Future<void> _removeDir(String directory) async {
    try {
      await Directory(directory).delete(recursive: true);
    } catch (e) {
      return;
    }
  }
}
