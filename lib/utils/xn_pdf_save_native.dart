import 'dart:io';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveXnPdf(Uint8List bytes, String filename) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  final result = await OpenFile.open(file.path);
  if (result.type != ResultType.done) {
    throw Exception('Đã tải file nhưng thiết bị chưa mở được PDF.');
  }
}
