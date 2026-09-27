
import 'dart:html' as html;

Future<void> logoutKhthBrowser({
  required String url,
}) async {
  final iframe =
      html.IFrameElement()
        ..src = url
        ..style.display = 'none'
        ..style.width = '0'
        ..style.height = '0'
        ..style.border = '0';

  html.document.body?.append(
    iframe,
  );

  try {
    await iframe.onLoad.first.timeout(
      const Duration(
        seconds: 5,
      ),
    );
  } catch (_) {
  } finally {
    iframe.remove();
  }
}