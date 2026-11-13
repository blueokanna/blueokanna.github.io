import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../companion.dart';

class CompanionScene extends StatefulWidget {
  const CompanionScene({
    super.key,
    required this.mood,
    this.onAction,
    this.compact = false,
  });
  final CompanionMood mood;
  final ValueChanged<String>? onAction;
  final bool compact;
  @override
  State<CompanionScene> createState() => _CompanionSceneState();
}

class _CompanionSceneState extends State<CompanionScene> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;
  bool _reduced = false;
  @override
  void initState() {
    super.initState();
    _listener = ((web.MessageEvent event) {
      if (event.origin != web.window.location.origin ||
          event.source != _frame?.contentWindow) {
        return;
      }
      try {
        final raw = event.data.dartify();
        if (raw is! String || raw.length > 512) return;
        final data = jsonDecode(raw);
        if (data is! Map) return;
        if (data['type'] == 'companion-ready') _send();
        if (data['type'] == 'companion-action' &&
            const [
              'pet',
              'celebrate',
              'shy',
              'open',
            ].contains(data['action'])) {
          widget.onAction?.call(data['action'] as String);
        }
      } catch (_) {
        /* Unrelated frames cannot configure this scene. */
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  void _send() => _frame?.contentWindow?.postMessage(
    jsonEncode({
      'type': 'companion-state',
      'mood': widget.mood.name,
      'reduced': _reduced,
      'compact': widget.compact,
    }).toJS,
    web.window.location.origin.toJS,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _send();
  }

  @override
  void didUpdateWidget(CompanionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _send();
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      _frame = frame;
      frame.title = '蓝色大肥鱼 · 3D 互动角色';
      frame.style.width = '100%';
      frame.style.height = '100%';
      frame.style.border = '0';
      frame.style.backgroundColor = 'transparent';
      frame.referrerPolicy = 'no-referrer';
      frame.src = Uri.base
          .resolve('companion/index.html')
          .replace(fragment: widget.mood.name)
          .toString();
    },
  );
}
