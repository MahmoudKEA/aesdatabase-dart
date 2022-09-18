import 'package:path/path.dart' as pathlib;

Future<String> pathWithDate(String path) {
  return Future(() {
    return pathWithDateSync(path);
  });
}

String pathWithDateSync(String path) {
  String date = DateTime.now().toString().split('.')[0].replaceAll(':', '-');
  String dirname = pathlib.dirname(path);
  List<String> basename = pathlib.basename(path).split('.');
  basename[0] = '${basename[0]} $date';

  return pathlib.prettyUri(
    pathlib.join(dirname, basename.join('.')),
  );
}
