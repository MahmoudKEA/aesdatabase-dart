import 'dart:typed_data';

import 'package:aesdatabase/src/core/constants.dart';

Uint8List sizePacked(int size, {bool reversed = true}) {
  ByteData bytedata = ByteData(packedLength)..setInt64(0, size);
  Uint8List result = bytedata.buffer.asUint8List();

  return reversed ? Uint8List.fromList(result.reversed.toList()) : result;
}

int sizeUnpacked(Uint8List bytes, {bool reversed = true}) {
  if (reversed) {
    bytes = Uint8List.fromList(bytes.reversed.toList());
  }

  return bytes.buffer.asByteData().getInt64(0);
}
