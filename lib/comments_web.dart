import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class EmbeddedComments extends StatefulWidget {
  const EmbeddedComments({
    super.key,
    required this.postId,
    required this.language,
    required this.dark,
    required this.unavailableLabel,
    required this.linkLabel,
  });
  final String postId, language, unavailableLabel, linkLabel;
  final bool dark;
  @override
  State<EmbeddedComments> createState() => _EmbeddedCommentsState();
}

class _EmbeddedCommentsState extends State<EmbeddedComments> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  double _height = 360;
  @override
  void initState() {
    super.initState();
    _listener = ((web.MessageEvent event) {
      if (event.origin != web.window.location.origin ||
          event.source != _frame?.contentWindow) {
        return;
      }
      final raw = event.data.dartify();
      if (raw is! String) return;
      try {
        final data = jsonDecode(raw);
        if (data is Map &&
            data['type'] == 'pulselink-comments' &&
            data['height'] is num) {
          final value = (data['height'] as num).toDouble().clamp(240.0, 5000.0);
          if (mounted && (_height - value).abs() > 2) {
            setState(() => _height = value);
          }
        }
      } catch (_) {
        /* Ignore unrelated or malformed messages. */
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void didUpdateWidget(EmbeddedComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId ||
        oldWidget.language != widget.language ||
        oldWidget.dark != widget.dark) {
      _configure();
    }
  }

  void _configure() {
    final url = Uri.base
        .resolve('comments.html')
        .replace(
          queryParameters: {
            'post': widget.postId,
            'unavailable': widget.unavailableLabel,
            'linkLabel': widget.linkLabel,
            'lang': widget.language,
            'theme': widget.dark ? 'dark' : 'light',
          },
        );
    _frame?.src = url.toString();
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (element) {
        _frame = element as web.HTMLIFrameElement;
        _frame!.title = 'GitHub Discussions · giscus';
        _frame!.style.border = '0';
        _frame!.style.width = '100%';
        _frame!.style.height = '100%';
        _frame!.referrerPolicy = 'strict-origin-when-cross-origin';
        _configure();
      },
    ),
  );
}
