import 'package:web/web.dart' as web;

void markAppReady() => web.window.dispatchEvent(web.Event('pulselink-ready'));
