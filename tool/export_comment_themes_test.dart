// Build-time export of the exact Flutter color roles used by the comment host.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink_site/comment_theme.dart';
import 'package:pulselink_site/preferences.dart';

void main() {
  test('export giscus themes for every palette and brightness', () {
    final output = Directory('web/giscus')..createSync(recursive: true);
    for (final preset in colorPresets) {
      for (final mode in Brightness.values) {
        final c = blogTheme(mode, preset.color, 'en').colorScheme;
        final tokens = {
          'fg-default': c.onSurface,
          'fg-muted': c.onSurfaceVariant,
          'fg-subtle': c.onSurfaceVariant,
          'canvas-overlay': c.surfaceContainerHigh,
          'canvas-inset': c.surfaceContainerLow,
          'canvas-subtle': c.surfaceContainer,
          'border-default': c.outlineVariant,
          'border-muted': c.outlineVariant,
          'neutral-muted': c.surfaceContainerHigh,
          'accent-fg': c.primary,
          'accent-emphasis': c.primary,
          'accent-muted': c.primaryContainer,
          'accent-subtle': c.primaryContainer,
          'btn-text': c.onSecondaryContainer,
          'btn-bg': c.secondaryContainer,
          'btn-border': c.outlineVariant,
          'btn-hover-bg': c.surfaceContainerHighest,
          'btn-hover-border': c.primary,
          'btn-active-bg': c.primaryContainer,
          'btn-active-border': c.primary,
          'btn-selected-bg': c.primaryContainer,
          'btn-primary-text': c.onPrimary,
          'btn-primary-bg': c.primary,
          'btn-primary-border': c.primary,
          'btn-primary-hover-bg': c.primary,
          'btn-primary-hover-border': c.onSurface,
          'btn-primary-selected-bg': c.primary,
          'btn-primary-disabled-text': c.onSurfaceVariant,
          'btn-primary-disabled-bg': c.surfaceContainerHighest,
          'btn-primary-disabled-border': c.outlineVariant,
          'segmented-control-bg': c.surfaceContainerHigh,
          'segmented-control-button-bg': c.surfaceContainer,
          'segmented-control-button-selected-border': c.primary,
          'danger-fg': c.error,
          'danger-subtle': c.errorContainer,
        };
        final css =
            '''/* Generated from lib/preferences.dart. */
@import url('https://giscus.app/themes/${mode.name}.css');
@font-face{font-family:Google Sans;src:url('../assets/assets/fonts/googlesans.ttf') format('truetype');font-weight:100 900;font-display:swap}
@font-face{font-family:Noto Sans SC;src:url('../assets/assets/fonts/notosanssc.ttf') format('truetype');font-weight:100 900;font-display:swap}
@font-face{font-family:Noto Sans TC;src:url('../assets/assets/fonts/notosanstc.ttf') format('truetype');font-weight:100 900;font-display:swap}
@font-face{font-family:Noto Sans JP;src:url('../assets/assets/fonts/notosansjp.ttf') format('truetype');font-weight:100 900;font-display:swap}
main{
${tokens.entries.map((entry) => '--color-${entry.key}:${cssColor(entry.value)};').join('\n')}
--color-canvas-default:transparent;
--color-primer-shadow-inset:none;
--color-btn-shadow:none;
--color-btn-inset-shadow:none;
--color-btn-primary-shadow:none;
--color-btn-primary-inset-shadow:none;
}
html,body,main,.gsc-main,.gsc-homepage-bg{background:transparent!important}
body,main,.markdown-body,.btn,textarea,input{font-family:'Google Sans','Noto Sans SC',sans-serif;line-height:1.75}
:lang(ja) body,:lang(ja) main,:lang(ja) textarea{font-family:'Google Sans','Noto Sans JP',sans-serif}
:lang(zh-TW) body,:lang(zh-TW) main,:lang(zh-TW) textarea{font-family:'Google Sans','Noto Sans TC',sans-serif}
.gsc-comment-box,.gsc-comment,.gsc-reply-box{border-radius:24px!important}
.gsc-comment-box-textarea,textarea{border-radius:16px!important;font-size:16px!important}
.btn{border-radius:999px!important;min-height:40px;padding-inline:18px}
.gsc-comment-box-tabs{padding:8px 12px;border-radius:23px 23px 0 0}
a:focus-visible,button:focus-visible,textarea:focus-visible{outline:2px solid ${cssColor(c.primary)};outline-offset:3px}
''';
        File('${output.path}/${commentThemeId(c)}.css').writeAsStringSync(css);
      }
    }
  });
}
