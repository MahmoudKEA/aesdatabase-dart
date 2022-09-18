import 'package:collection/collection.dart';

extension ListExtend on List {
  int count(dynamic value) {
    return map((e) => e == value ? 1 : 0).reduce(
      (value, element) => value + element,
    );
  }

  bool containsList(List<dynamic> element) {
    for (List<dynamic> e in this) {
      if (e.equals(element)) return true;
    }
    return false;
  }
}
