import 'dart:typed_data';
import 'xn_pdf_save_share.dart'
    if (dart.library.io) 'xn_pdf_save_native.dart'
    as platform;

Future<void> saveXnPdf(Uint8List bytes, String filename) {
  var safeName = filename
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll('..', '_')
      .trim();
  if (safeName.isEmpty) safeName = 'ket_qua.pdf';
  return platform.saveXnPdf(bytes, safeName);
}
