import 'package:aesdatabase/aesdatabase.dart';

void main() async {
  // Create driver (Required)
  final DriveSetup driveSetup = DriveSetup(
    hasAttachments: true,
    hasBackup: true,
  );

  // Create directories (Required)
  List<String> dirsCreated = await driveSetup.create();

  // Delete directories
  List<String> dirsDeleted = await driveSetup.delete();

  // Checkers
  driveSetup.hasAttachments;
  driveSetup.hasBackup;

  // Temp section
  driveSetup.tempDir;
  driveSetup.tempUpdate(main: 'newMainDir', folder: 'newFolderName');

  // Attachments section
  driveSetup.attachmentDir;
  driveSetup.attachmentUpdate(main: 'newMainDir', folder: 'newFolderName');

  // Database section
  driveSetup.databaseDir;
  driveSetup.databasePath;
  driveSetup.databaseUpdate(
    main: 'newMainDir',
    folder: 'newFolderName',
    file: 'newFileName',
    extensionFile: 'newExtension',
  );

  // Backup section
  driveSetup.backupDir;
  driveSetup.backupPath;
  driveSetup.backupUpdate(
    main: 'newMainDir',
    folder: 'newFolderName',
    file: 'newFileName',
    extensionFile: 'newExtension',
  );
}
