import 'package:path/path.dart' as pathlib;

String pathWithDate(String path) {
  final String date = DateTime.now().toString().split('.')[0].replaceAll(
        ':',
        '-',
      );
  final String dirname = pathlib.dirname(path);
  final List<String> basename = pathlib.basename(path).split('.');
  basename[0] = '${basename[0]} $date';

  return Uri.file(
    pathlib.join(dirname, basename.join('.')),
  ).toFilePath();
}
