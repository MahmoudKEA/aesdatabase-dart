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

// Create directories (Required)
List<String> dirsCreated = driveSetup.create();

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
driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");

// Load database if it's already created before
await db.load();

// Or create a table if this is the first time
await db.createTable(['username', 'password', 'age']);

// Insert new row
await db.insert(
    items: {'username': 'user', 'password': '123456', 'age': 20},
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
driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");

// Add a file into attachments database
String attachmentSavedPath = await db.importAttachment(
    name: 'folderName',
    path: 'desktop/photo.png',
    ignoreFileExists: true,
    progressCallback: (value) => print('progressing: $value'),
);

// Export a file from attachments to your drive
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
driveSetup.create();

// Connect with database engine
final DatabaseEngine db = DatabaseEngine(driveSetup, "passwordKey");


// Add a file into attachments database
String backupFilePath = await db.exportBackup(
    outputDir: 'desktop',
    progressCallback: (value) => print('progressing: $value'),
);

// Export a file from attachments to your drive
await db.importBackup(
    path: backupFilePath,
    progressCallback: (value) => print('progressing: $value'),
);

// ChecCheck example/database_engine_example.dart for more examples
// ...
```
