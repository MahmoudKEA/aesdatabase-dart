import 'dart:convert';
import 'dart:typed_data';

Uint8List jsonEncodeToBytes(Object data) {
  return Uint8List.fromList(
    utf8.encode(
      jsonEncode(data),
    ),
  );
}

dynamic jsonDecodeFromBytes(Uint8List data) {
  return jsonDecode(
    utf8.decode(data),
  );
}
