import 'package:aesdatabase/aesdatabase.dart';

void main() async {
  final DriveSetup driveSetup = DriveSetup(hasAttachments: true);

  final DatabaseEngine databaseEngine = DatabaseEngine(
    driveSetup,
    "passwordKey",
  );

  await databaseEngine.load(
    progressCallback: (value) {
      print(value);
    },
  );

  print('start');
  await databaseEngine.exportAttachment(
      name: 'mydataBackup', fileName: 'dataBackup.txt');
  print('end');

  await for (RowModel row in databaseEngine.select()) {
    print(row.items);
  }
}
