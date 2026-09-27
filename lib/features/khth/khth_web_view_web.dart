// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class KhthWebView extends StatefulWidget {
  final String url;

  const KhthWebView({
    super.key,
    required this.url,
  });

  @override
  State<KhthWebView> createState() =>
      _KhthWebViewState();
}

class _KhthWebViewState
    extends State<KhthWebView> {
  late final String _viewType;

  static int _counter = 0;

  @override
  void initState() {
    super.initState();

    _viewType =
        'khth-iframe-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          ..allowFullscreen = true;

        iframe.setAttribute(
          'allow',
          'fullscreen; clipboard-read; clipboard-write',
        );

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
    );
  }
}