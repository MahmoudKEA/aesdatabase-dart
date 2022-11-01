import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

Future<Uint8List> jsonEncodeToBytes(Object data) async {
  final ReceivePort receivePort = ReceivePort();

  Isolate.spawn<SendPort>(
    (sendPort) {
      final Uint8List result = Uint8List.fromList(
        jsonEncode(data).codeUnits,
      );

      sendPort.send(result);
    },
    receivePort.sendPort,
  );

  return await receivePort.first;
}

Future<dynamic> jsonDecodeFromBytes(Uint8List data) async {
  final ReceivePort receivePort = ReceivePort();

  Isolate.spawn<SendPort>(
    (sendPort) {
      final dynamic result = jsonDecode(
        utf8.decode(data),
      );

      sendPort.send(result);
    },
    receivePort.sendPort,
  );

  return await receivePort.first;
}
