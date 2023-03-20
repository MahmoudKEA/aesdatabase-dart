import 'dart:typed_data';

import 'core.dart';

Uint8List sizePacked(int size, {bool reversed = true}) {
  final ByteData byteData = ByteData(packedLength)..setInt64(0, size);
  final Uint8List result = byteData.buffer.asUint8List();

  return reversed ? Uint8List.fromList(result.reversed.toList()) : result;
}

int sizeUnpacked(Uint8List bytes, {bool reversed = true}) {
  if (reversed) {
    bytes = Uint8List.fromList(bytes.reversed.toList());
  }

  return bytes.buffer.asByteData().getInt64(0);
}
