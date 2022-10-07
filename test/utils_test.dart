import 'package:aesdatabase/aesdatabase.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as pathlib;

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  group("Utils Group:", () {
    const String path = 'folder/file/data.txt';

    test("Test (pathWithDate)", () async {
      String result = await pathWithDate(path);

      printDebug("""
pathWithDate: $result
      """);

      expect(
        result,
        contains(pathlib.prettyUri(pathlib.dirname(path))),
      );
    });
  });
}
