import 'dart:isolate';
import 'dart:typed_data';

import 'core.dart';

Future<Uint8List> sizePacked(int size, {bool reversed = true}) async {
  final ReceivePort receivePort = ReceivePort();

  Isolate.spawn<SendPort>(
    (sendPort) {
      final ByteData bytedata = ByteData(packedLength)..setInt64(0, size);
      final Uint8List result = bytedata.buffer.asUint8List();

      sendPort.send(
        reversed ? Uint8List.fromList(result.reversed.toList()) : result,
      );
    },
    receivePort.sendPort,
  );

  return await receivePort.first;
}

Future<int> sizeUnpacked(Uint8List bytes, {bool reversed = true}) async {
  final ReceivePort receivePort = ReceivePort();

  Isolate.spawn<SendPort>(
    (sendPort) {
      if (reversed) {
        bytes = Uint8List.fromList(bytes.reversed.toList());
      }

      sendPort.send(
        bytes.buffer.asByteData().getInt64(0),
      );
    },
    receivePort.sendPort,
  );

  return await receivePort.first;
}
