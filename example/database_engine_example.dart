import 'package:aesdatabase/aesdatabase.dart';

void main() async {
  // Create driver
  final DriveSetup driveSetup = DriveSetup(
    hasAttachments: true,
    hasBackup: true,
  );
  await driveSetup.create();

  final DatabaseEngine databaseEngine = DatabaseEngine(
    driveSetup,
    "passwordKey",
  );

  // Create table
  databaseEngine.createTable(['username', 'password', 'age']);

  // Add row, when adding later, it must be of the same type as the first row you added
  databaseEngine.addRow(
    {'username': 'user', 'password': '123456', 'age': 20},
  );

  // Select data, don't set args for all data / set specific args for filtering
  await for (DBRow row in databaseEngine.select(
    columnTitles: ['username', 'age'],
    items: {'age': 20},
  )) {
    int index = row.index;
    Map<String, dynamic> data = row.items;
  }

  // Edit row by index
  databaseEngine.edit(rowIndex: 0, items: {'age': 21});

  // Remove row by index
  databaseEngine.removeRow(0);

  // Remove column by title
  databaseEngine.removeColumn('age');

  // Get coulmns count
  databaseEngine.countColumn();

  // Get rows count
  databaseEngine.countRow();

  // Save all data and show progress bar value
  String databaseOutputPath = await databaseEngine.dump(
    progressCallback: (value) => print('progressing: $value'),
  );

  // Load all data and show progress bar value
  bool isDatabaseLoaded = await databaseEngine.load(
    progressCallback: (value) => print('progressing: $value'),
  );

  // Save file attachment into database as encrypted with AES extension
  // [name]: It is the name of a folder to collect some files in one folder
  // [path]: Your file path
  // [ignoreFileExists]: Ignore file is already exists before
  // [progressCallback]: Tracking the progress value
  String attachmentSavedPath = await databaseEngine.importAttachment(
    name: 'folderName',
    path: 'desktop/photo.png',
    ignoreFileExists: true,
    progressCallback: (value) => print('progressing: $value'),
  );

  // Export your file attachment to specific path
  // WARNING: Don't add ".aes" extension to file name
  // [name]: It is the name of a folder to collect some files in one folder
  // [fileName]: File name
  // [outputDir]: The destination you want to export to ( Default=TempDir )
  // [ignoreFileExists]: Ignore file is already exists before
  // [progressCallback]: Tracking the progress value
  String outputPath = await databaseEngine.exportAttachment(
    name: 'folderName',
    fileName: 'photo.png',
    outputDir: 'desktop',
    ignoreFileExists: true,
    progressCallback: (value) => print('progressing: $value'),
  );

  // Select attachments, don't set args for all data / set specific args for filtering
  // WARNING: Don't add ".aes" extension to file name
  await for (String file in databaseEngine.selectAttachments(
    name: 'folderName',
    fileName: 'photo.png',
  )) {
    String attachmentPath = file;
  }

  // Check file is exists on database
  // WARNING: Don't add ".aes" extension to file name
  bool isExists = await databaseEngine.existsAttachment(
    name: 'folderName',
    fileName: 'photo.png',
  );

  // Remove a file attachment from database
  // WARNING: Don't add ".aes" extension to file name
  bool isRemoved = await databaseEngine.removeAttachment(
    name: 'folderName',
    fileName: 'photo.png',
  );

  // Export a backup of all ur database
  // WARNING: Don't add ".aes" extension to file name
  // [rowIndexes]: Select some row indexes ( Default export all rows )
  // [attachmentNames]: Select some files name ( Default export all attachments )
  // [key]: Set a password ( Default: use the public key you entered with databaseEngine )
  // [outputDir]: The destination you want to export to ( Default=backupDir )
  // [progressCallback]: Tracking the progress value
  String backupFilePath = await databaseEngine.exportBackup(
    rowIndexes: [0, 1, 2],
    attachmentNames: ['photo.png'],
    key: 'specific password',
    outputDir: 'desktop',
    progressCallback: (value) => print('progressing: $value'),
  );

  // Import a backup file
  // [rowIndexes]: Select some row indexes ( Default import all rows )
  // [attachmentNames]: Select some files name ( Default import all attachments )
  // [key]: Set a password if exported with a different password
  // [removeAfterComplete]: Remove backup file after importing done
  // [progressCallback]: Tracking the progress value
  await databaseEngine.importBackup(
    path: backupFilePath,
    rowIndexes: [0, 1, 2],
    attachmentNames: ['photo.png'],
    key: 'specific password',
    removeAfterComplete: false,
    progressCallback: (value) => print('progressing: $value'),
  );
}
