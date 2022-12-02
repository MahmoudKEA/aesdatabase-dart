# AESDatabase Library
#### This library is designed to store database as encrypted with AES-256 algorithm
- The ability to add attachment files to the database
- The ability to import and export a backup of all data and attachments in one file
- Designed by: Mahmoud Khalid


## Usage
### Build a driver that defines all paths and directories
```dart
import 'package:aesdatabase/aesdatabase.dart';

// Build the driver
final DriveSetup driveSetup = DriveSetup(
    hasAttachments: true,
    hasBackup: true,
);

// Create directories
List<String> dirsCreated = await driveSetup.create();

// Check example/drive_example.dart for more examples
// ...
```

### How to connect a driver with database engine and use it
```dart
import 'package:aesdatabase/aesdatabase.dart';

// Build the driver
final DriveSetup driveSetup = DriveSetup(
    hasAttachments: true,
    hasBackup: true,
);
await driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");

// Load database if it's already created before
await db.load();

// Or create a table if this is the first time
db.createTable(['username', 'password', 'age']);

// Add new row
db.addRow(
    {'username': 'user', 'password': '123456', 'age': 20},
);

// Save changes
await db.dump();

// Check example/database_engine_example.dart for more examples
// ...
```

### How to add attachment files
```dart
import 'package:aesdatabase/aesdatabase.dart';

// Build the driver
final DriveSetup driveSetup = DriveSetup(hasAttachments: true);
await driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");

// Save file attachment into database as encrypted with AES extension
// [name]: It is the name of a folder to collect some files in one folder
// [path]: Your file path
// [ignoreFileExists]: Ignore file is already exists before
// [progressCallback]: Tracking the progress value
String attachmentSavedPath = await db.importAttachment(
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
String outputPath = await db.exportAttachment(
    name: 'folderName',
    fileName: 'photo.png',
    outputDir: 'desktop',
    ignoreFileExists: true,
    progressCallback: (value) => print('progressing: $value'),
);

// ChecCheck example/database_engine_example.dart for more examples
// ...
```

### How to make backup file
```dart
import 'package:aesdatabase/aesdatabase.dart';

// Build the driver
final DriveSetup driveSetup = DriveSetup(hasBackup: true);
await driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");


// Export a backup of all ur database
// WARNING: Don't add ".aes" extension to file name
// [rowIndexes]: Select some row indexes ( Default export all rows )
// [attachmentNames]: Select some files name ( Default export all attachments )
// [key]: Set a password ( Default: use the public key you entered with databaseEngine )
// [outputDir]: The destination you want to export to ( Default=backupDir )
// [progressCallback]: Tracking the progress value
String backupFilePath = await db.exportBackup(
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
await db.importBackup(
    path: backupFilePath,
    rowIndexes: [0, 1, 2],
    attachmentNames: ['photo.png'],
    key: 'specific password',
    removeAfterComplete: false,
    progressCallback: (value) => print('progressing: $value'),
);

// ChecCheck example/database_engine_example.dart for more examples
// ...
```
