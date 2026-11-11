import 'package:web/web.dart' as web;

void updatePageMetadata(String language, String title) {
  web.document.documentElement?.setAttribute('lang', language);
  web.document.title = title;
}
