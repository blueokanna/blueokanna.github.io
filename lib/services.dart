import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'l10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeviceClass
// ─────────────────────────────────────────────────────────────────────────────
enum DeviceClass {
  mobile,
  tablet,
  desktop;

  String label(S s) => switch (this) {
        DeviceClass.mobile => s.mobile,
        DeviceClass.tablet => s.tablet,
        DeviceClass.desktop => s.desktop,
      };

  static DeviceClass fromWidth(double w) {
    if (w < 700) return DeviceClass.mobile;
    if (w < 1100) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WeatherSnapshot
// ─────────────────────────────────────────────────────────────────────────────
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperatureC,
    required this.weatherCode,
  });

  final String city;
  final double temperatureC;
  final int weatherCode;

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '🌤️';
    if (weatherCode <= 3) return '☁️';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌦️';
    if (weatherCode >= 95) return '⛈️';
    return '⛅';
  }

  String get tempText => '${temperatureC.round()}°C';

  String summary(S s) => s.weatherIn(city, tempText);

  static Future<WeatherSnapshot> load() async {
    // Guangzhou Panyu defaults
    const defaultLat = 23.0;
    const defaultLon = 113.35;
    const defaultCity = '番禺';
    try {
      double lat = defaultLat;
      double lon = defaultLon;
      String city = defaultCity;
      // Try multiple geolocation services for VPN resilience
      try {
        final geoRes = await http
            .get(Uri.parse('https://ipapi.co/json/'))
            .timeout(const Duration(seconds: 5));
        if (geoRes.statusCode == 200) {
          final geo = jsonDecode(geoRes.body) as Map<String, dynamic>;
          final gLat = (geo['latitude'] as num?)?.toDouble();
          final gLon = (geo['longitude'] as num?)?.toDouble();
          final gCity = geo['city'] as String?;
          if (gLat != null &&
              gLon != null &&
              gCity != null &&
              gCity.isNotEmpty) {
            lat = gLat;
            lon = gLon;
            city = gCity;
          }
        }
      } catch (_) {
        // Use Guangzhou Panyu defaults
      }
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code&timezone=auto',
      );
      final wRes = await http.get(uri).timeout(const Duration(seconds: 8));
      final w = jsonDecode(wRes.body) as Map<String, dynamic>;
      final cur = w['current'] as Map<String, dynamic>;
      return WeatherSnapshot(
        city: city,
        temperatureC: (cur['temperature_2m'] as num?)?.toDouble() ?? 25,
        weatherCode: (cur['weather_code'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {
      return const WeatherSnapshot(
        city: '番禺',
        temperatureC: 25,
        weatherCode: 1,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HolidayTheme
// ─────────────────────────────────────────────────────────────────────────────
class HolidayTheme {
  const HolidayTheme({
    required this.nameZh,
    required this.nameEn,
    required this.shortZh,
    required this.shortEn,
    required this.emoji,
    required this.icon,
    required this.accent,
    required this.highlight,
  });

  final String nameZh, nameEn, shortZh, shortEn;
  final String emoji;
  final IconData icon;
  final Color accent, highlight;

  String name(S s) => s.isZh ? nameZh : nameEn;
  String shortLabel(S s) => s.isZh ? shortZh : shortEn;

  static HolidayTheme forToday(DateTime now) {
    final m = now.month, d = now.day;
    // 元旦 New Year (Jan 1)
    if (m == 1 && d == 1) {
      return const HolidayTheme(
        nameZh: '元旦',
        nameEn: 'New Year',
        shortZh: '新年快乐',
        shortEn: 'Happy New Year',
        emoji: '🎆',
        icon: Icons.celebration_rounded,
        accent: Color(0xFFC3411A),
        highlight: Color(0xFFFFBF6C),
      );
    }
    // 春节 Spring Festival (Jan 2 – Feb 19)
    if ((m == 1 && d >= 2) || (m == 2 && d <= 19)) {
      return const HolidayTheme(
        nameZh: '春节',
        nameEn: 'Spring Festival',
        shortZh: '新春光辉',
        shortEn: 'Spring glow',
        emoji: '🧧',
        icon: Icons.auto_awesome_rounded,
        accent: Color(0xFFC3411A),
        highlight: Color(0xFFFFBF6C),
      );
    }
    // 情人节 Valentine's (Feb 14 takes priority but range Feb 10-19 covered by Spring Festival)
    // 元宵节 Lantern Festival (~Feb 20-28)
    if (m == 2 && d >= 20) {
      return const HolidayTheme(
        nameZh: '元宵节',
        nameEn: 'Lantern Festival',
        shortZh: '花灯烟火',
        shortEn: 'Lantern glow',
        emoji: '🏮',
        icon: Icons.lightbulb_rounded,
        accent: Color(0xFFD4520E),
        highlight: Color(0xFFFFD166),
      );
    }
    // 春分 Spring Equinox (Mar)
    if (m == 3) {
      return const HolidayTheme(
        nameZh: '春分时节',
        nameEn: 'Spring Equinox',
        shortZh: '万物复苏',
        shortEn: 'Spring awakening',
        emoji: '🌸',
        icon: Icons.local_florist_rounded,
        accent: Color(0xFFE0699A),
        highlight: Color(0xFFFFB3D0),
      );
    }
    // 清明 Qingming (Apr 1-10)
    if (m == 4 && d <= 10) {
      return const HolidayTheme(
        nameZh: '清明',
        nameEn: 'Qingming',
        shortZh: '春雨润物',
        shortEn: 'Spring rain',
        emoji: '🌿',
        icon: Icons.eco_rounded,
        accent: Color(0xFF2D8A5E),
        highlight: Color(0xFF7AE8B8),
      );
    }
    // 春季 Late Spring (Apr 11-30)
    if (m == 4) {
      return const HolidayTheme(
        nameZh: '暮春',
        nameEn: 'Late Spring',
        shortZh: '花开满园',
        shortEn: 'Blossoming',
        emoji: '🌺',
        icon: Icons.yard_rounded,
        accent: Color(0xFF0F7A65),
        highlight: Color(0xFF72E9C6),
      );
    }
    // 劳动节 Labour Day (May 1-5)
    if (m == 5 && d <= 5) {
      return const HolidayTheme(
        nameZh: '劳动节',
        nameEn: 'Labour Day',
        shortZh: '致敬劳动',
        shortEn: 'Celebrate work',
        emoji: '⚒️',
        icon: Icons.construction_rounded,
        accent: Color(0xFFB8860B),
        highlight: Color(0xFFFFD700),
      );
    }
    // 初夏 Early Summer (May 6-31)
    if (m == 5) {
      return const HolidayTheme(
        nameZh: '初夏',
        nameEn: 'Early Summer',
        shortZh: '清风拂面',
        shortEn: 'Summer breeze',
        emoji: '☀️',
        icon: Icons.wb_sunny_rounded,
        accent: Color(0xFF1A8A4E),
        highlight: Color(0xFF66EDAA),
      );
    }
    // 儿童节 Children's Day (Jun 1)
    if (m == 6 && d == 1) {
      return const HolidayTheme(
        nameZh: '儿童节',
        nameEn: "Children's Day",
        shortZh: '童趣时光',
        shortEn: 'Playful vibes',
        emoji: '🎈',
        icon: Icons.child_care_rounded,
        accent: Color(0xFFE85D9A),
        highlight: Color(0xFFFFADD2),
      );
    }
    // 端午节 Dragon Boat (Jun 2-20)
    if (m == 6 && d <= 20) {
      return const HolidayTheme(
        nameZh: '端午节',
        nameEn: 'Dragon Boat',
        shortZh: '龙舟竞渡',
        shortEn: 'Dragon race',
        emoji: '🐉',
        icon: Icons.sailing_rounded,
        accent: Color(0xFF1A6B3C),
        highlight: Color(0xFF5AE89C),
      );
    }
    // 盛夏 Summer (Jun 21 – Aug)
    if (m == 6 || m == 7 || m == 8) {
      return const HolidayTheme(
        nameZh: '盛夏',
        nameEn: 'Midsummer',
        shortZh: '热浪来袭',
        shortEn: 'Summer heat',
        emoji: '🌊',
        icon: Icons.pool_rounded,
        accent: Color(0xFF0E6B8A),
        highlight: Color(0xFF5AC8E8),
      );
    }
    // 中秋节 Mid-Autumn (Sep)
    if (m == 9) {
      return const HolidayTheme(
        nameZh: '中秋节',
        nameEn: 'Mid-Autumn',
        shortZh: '月光',
        shortEn: 'Moonlight',
        emoji: '🥮',
        icon: Icons.brightness_2_rounded,
        accent: Color(0xFF7757D8),
        highlight: Color(0xFFE0C7FF),
      );
    }
    // 国庆节 National Day (Oct 1-7)
    if (m == 10 && d <= 7) {
      return const HolidayTheme(
        nameZh: '国庆节',
        nameEn: 'National Day',
        shortZh: '举国同庆',
        shortEn: 'National pride',
        emoji: '🇨🇳',
        icon: Icons.flag_rounded,
        accent: Color(0xFFCC2936),
        highlight: Color(0xFFFF6B6B),
      );
    }
    // 金秋 Golden Autumn (Oct 8-24)
    if (m == 10 && d <= 24) {
      return const HolidayTheme(
        nameZh: '金秋',
        nameEn: 'Golden Autumn',
        shortZh: '秋高气爽',
        shortEn: 'Autumn breeze',
        emoji: '🍂',
        icon: Icons.park_rounded,
        accent: Color(0xFFB8700A),
        highlight: Color(0xFFFFBB5C),
      );
    }
    // 万圣夜 Halloween (Oct 25-31)
    if (m == 10) {
      return const HolidayTheme(
        nameZh: '万圣夜',
        nameEn: 'Halloween',
        shortZh: '幽灵模式',
        shortEn: 'Spooky mode',
        emoji: '🎃',
        icon: Icons.nightlight_round,
        accent: Color(0xFF8B2E0B),
        highlight: Color(0xFFFF9B61),
      );
    }
    // 初冬 Early Winter (Nov)
    if (m == 11) {
      return const HolidayTheme(
        nameZh: '初冬',
        nameEn: 'Early Winter',
        shortZh: '暖意渐浓',
        shortEn: 'Warm tones',
        emoji: '🍵',
        icon: Icons.coffee_rounded,
        accent: Color(0xFF6B4226),
        highlight: Color(0xFFD4A574),
      );
    }
    // 圣诞季 Christmas (Dec 20-31)
    if (m == 12 && d >= 20) {
      return const HolidayTheme(
        nameZh: '圣诞季',
        nameEn: 'Christmas Season',
        shortZh: '节日光芒',
        shortEn: 'Holiday glow',
        emoji: '🎄',
        icon: Icons.ac_unit_rounded,
        accent: Color(0xFF0F7A65),
        highlight: Color(0xFF72E9C6),
      );
    }
    // 冬至 Winter Solstice (Dec 1-19)
    if (m == 12) {
      return const HolidayTheme(
        nameZh: '冬至',
        nameEn: 'Winter Solstice',
        shortZh: '冬日暖阳',
        shortEn: 'Winter warmth',
        emoji: '❄️',
        icon: Icons.ac_unit_rounded,
        accent: Color(0xFF3A6EA5),
        highlight: Color(0xFF8AC4FF),
      );
    }
    // Fallback
    return const HolidayTheme(
      nameZh: '时令色彩',
      nameEn: 'Seasonal Tone',
      shortZh: '时令色彩',
      shortEn: 'Seasonal accent',
      emoji: '🌿',
      icon: Icons.eco_rounded,
      accent: Color(0xFF0F7A65),
      highlight: Color(0xFF72E9C6),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GitHubSnapshot & RepoCardData
// ─────────────────────────────────────────────────────────────────────────────
class GitHubSnapshot {
  const GitHubSnapshot({
    required this.publicRepos,
    required this.followers,
    required this.totalStars,
    required this.topRepos,
  });

  final int publicRepos, followers, totalStars;
  final List<RepoCardData> topRepos;

  factory GitHubSnapshot.fallback() => const GitHubSnapshot(
        publicRepos: 26,
        followers: 16,
        totalStars: 97,
        topRepos: [
          RepoCardData(
            name: 'VeloGuard',
            description:
                'Cross-platform proxy client with Flutter UI and a high-performance Rust core.',
            url: 'https://github.com/blueokanna/VeloGuard',
            language: 'Rust',
            stars: 8,
            forks: 0,
            icon: Icons.shield_rounded,
            colorA: Color(0xFF8B2E0B),
            colorB: Color(0xFFFF875D),
            updatedLabel: 'Recently',
          ),
        ],
      );

  static Future<GitHubSnapshot> load() async {
    final responses = await Future.wait([
      http.get(Uri.parse('https://api.github.com/users/blueokanna')),
      http.get(
        Uri.parse(
          'https://api.github.com/users/blueokanna/repos?per_page=100&sort=updated',
        ),
      ),
      http.get(
        Uri.parse(
          'https://api.github.com/orgs/AstralQuanta/repos?per_page=100&sort=updated',
        ),
      ),
    ]);
    final userMap = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final userRepos =
        (jsonDecode(responses[1].body) as List).cast<Map<String, dynamic>>();
    final orgRepos = responses[2].statusCode < 300
        ? (jsonDecode(responses[2].body) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final all = [
      ...userRepos,
      ...orgRepos,
    ].where((r) => !(r['archived'] as bool? ?? false)).toList();
    final totalStars = all.fold<int>(
      0,
      (s, r) => s + ((r['stargazers_count'] as num?)?.toInt() ?? 0),
    );
    all.sort((a, b) {
      final sa = (a['stargazers_count'] as num?)?.toInt() ?? 0;
      final sb = (b['stargazers_count'] as num?)?.toInt() ?? 0;
      if (sa != sb) return sb.compareTo(sa);
      final ua =
          DateTime.tryParse(a['updated_at'] as String? ?? '') ?? DateTime(1970);
      final ub =
          DateTime.tryParse(b['updated_at'] as String? ?? '') ?? DateTime(1970);
      return ub.compareTo(ua);
    });
    final repos = all.take(8).map(RepoCardData.fromGitHub).toList();
    return GitHubSnapshot(
      publicRepos: (userMap['public_repos'] as num?)?.toInt() ?? repos.length,
      followers: (userMap['followers'] as num?)?.toInt() ?? 0,
      totalStars: totalStars,
      topRepos: repos,
    );
  }
}

class RepoCardData {
  const RepoCardData({
    required this.name,
    required this.description,
    required this.url,
    required this.language,
    required this.stars,
    required this.forks,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.updatedLabel,
  });

  final String name, description, url, language, updatedLabel;
  final int stars, forks;
  final IconData icon;
  final Color colorA, colorB;

  factory RepoCardData.fromGitHub(Map<String, dynamic> r) {
    final lang = (r['language'] as String?) ?? 'Code';
    final pal = _paletteFor(lang);
    final dt = DateTime.tryParse(r['updated_at'] as String? ?? '');
    return RepoCardData(
      name: r['name'] as String? ?? 'Repository',
      description: r['description'] as String? ?? '',
      url: r['html_url'] as String? ?? 'https://github.com/blueokanna',
      language: lang,
      stars: (r['stargazers_count'] as num?)?.toInt() ?? 0,
      forks: (r['forks_count'] as num?)?.toInt() ?? 0,
      icon: pal.$1,
      colorA: pal.$2,
      colorB: pal.$3,
      updatedLabel: dt == null ? 'Fresh' : _timeAgo(dt),
    );
  }

  static (IconData, Color, Color) _paletteFor(String l) =>
      switch (l.toLowerCase()) {
        'java' => (
            Icons.coffee_rounded,
            const Color(0xFFAA4B12),
            const Color(0xFFFFB055),
          ),
        'rust' => (
            Icons.hive_rounded,
            const Color(0xFF8B2E0B),
            const Color(0xFFFF875D),
          ),
        'dart' => (
            Icons.flutter_dash_rounded,
            const Color(0xFF1368B5),
            const Color(0xFF79C6FF),
          ),
        'kotlin' => (
            Icons.auto_fix_high_rounded,
            const Color(0xFF6C2DA8),
            const Color(0xFFD89AFF),
          ),
        'javascript' => (
            Icons.bolt_rounded,
            const Color(0xFF9B6A00),
            const Color(0xFFFFD44D),
          ),
        'c++' || 'c' => (
            Icons.memory_rounded,
            const Color(0xFF1547A8),
            const Color(0xFF70A7FF),
          ),
        'python' => (
            Icons.data_object_rounded,
            const Color(0xFF166C78),
            const Color(0xFF74E4F7),
          ),
        'css' || 'html' => (
            Icons.web_asset_rounded,
            const Color(0xFF0F7A65),
            const Color(0xFF60E5C7),
          ),
        _ => (
            Icons.widgets_rounded,
            const Color(0xFF0F7A65),
            const Color(0xFF56E1C1),
          ),
      };

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff <= 1) return 'Today';
    if (diff < 7) return '${diff}d';
    final w = diff ~/ 7;
    if (w < 5) return '${w}w';
    return '${diff ~/ 30}mo';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Zhipu AI (GLM-4-Flash)
// ─────────────────────────────────────────────────────────────────────────────
class ZhipuAiService {
  ZhipuAiService._();

  static const _apiKey = String.fromEnvironment('ZHIPU_API_KEY');
  static const _endpoint =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<String?> chat(List<Map<String, String>> messages) async {
    if (!isConfigured) return null;
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'model': 'glm-4-flash', 'messages': messages}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return (choices[0] as Map<String, dynamic>)['message']?['content']
              as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<BlogArticle?> generateTechArticle(AppLanguage lang) async {
    final isZh = lang == AppLanguage.zh;
    final sysPrompt = isZh
        ? '你是一位资深科技博主和技术分析师。你将撰写原创的、深度的科技分析文章。'
            '要求绝对原创，禁止抄袭任何已有文章。必须基于你的知识和分析能力产出全新内容。'
        : 'You are a senior tech blogger and technology analyst. '
            'You write original, deep tech analysis articles. '
            'Absolutely original — never plagiarize. Generate entirely new content based on your knowledge.';
    final userPrompt = isZh
        ? '请选择一个具体的前沿技术话题（如AI大模型、量子计算、边缘计算、Rust生态、'
            'WebAssembly、隐私计算等），撰写一篇800-1200字的专业科技分析文章。'
            '要求：\n'
            '1. 标题简洁有力\n'
            '2. 包含独特的见解和原创观点\n'
            '3. 分析该技术的最新发展趋势和行业影响\n'
            '4. 语言流畅、结构清晰\n\n'
            '请严格以如下JSON格式返回（不要包含```json标记）：\n'
            '{"title":"文章标题","summary":"50字以内摘要","content":"完整正文（使用\\n换行）"}'
        : 'Pick a specific cutting-edge technology topic (e.g. LLMs, quantum computing, '
            'edge computing, Rust ecosystem, WebAssembly, privacy-preserving computation) '
            'and write a professional 400-600 word tech analysis article.\n'
            'Requirements:\n'
            '1. Concise, punchy title\n'
            '2. Unique insights and original perspectives\n'
            '3. Analyze latest trends and industry impact\n'
            '4. Well-structured, fluent language\n\n'
            'Return STRICTLY in this JSON format (no ```json markers):\n'
            '{"title":"Article title","summary":"Brief summary under 30 words","content":"Full body text (use \\n for line breaks)"}';
    final raw = await chat([
      {'role': 'system', 'content': sysPrompt},
      {'role': 'user', 'content': userPrompt},
    ]);
    if (raw == null) return null;
    try {
      final clean = raw.replaceAll(RegExp(r'```json\s*|```'), '').trim();
      final map = jsonDecode(clean) as Map<String, dynamic>;
      return BlogArticle(
        title: map['title'] as String? ?? (isZh ? '未命名文章' : 'Untitled'),
        summary: map['summary'] as String? ?? '',
        content: (map['content'] as String? ?? '').replaceAll('\\n', '\n'),
        generatedAt: DateTime.now(),
      );
    } catch (_) {
      return BlogArticle(
        title: isZh ? 'AI科技洞察' : 'AI Tech Insight',
        summary: '',
        content: raw,
        generatedAt: DateTime.now(),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BlogArticle & ChatMessage
// ─────────────────────────────────────────────────────────────────────────────
class BlogArticle {
  const BlogArticle({
    required this.title,
    required this.summary,
    required this.content,
    required this.generatedAt,
  });

  final String title, summary, content;
  final DateTime generatedAt;
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role, content;
  Map<String, String> toMap() => {'role': role, 'content': content};
}

// ─────────────────────────────────────────────────────────────────────────────
//  Capability / Contact card data
// ─────────────────────────────────────────────────────────────────────────────
class CapabilityCardData {
  const CapabilityCardData({
    required this.title,
    required this.text,
    required this.icon,
    required this.colorA,
    required this.colorB,
    required this.chips,
  });
  final String title, text;
  final IconData icon;
  final Color colorA, colorB;
  final List<String> chips;
}

class ContactCardData {
  const ContactCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.colorA,
    required this.colorB,
  });
  final String title, subtitle, url;
  final IconData icon;
  final Color colorA, colorB;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Greeting helper
// ─────────────────────────────────────────────────────────────────────────────
class GreetingData {
  const GreetingData(this.label, this.emoji);
  final String label, emoji;
}

GreetingData greetingForNow(S s) {
  final h = DateTime.now().hour;
  if (h < 6) return GreetingData(s.lateNight, '🌙');
  if (h < 12) return GreetingData(s.goodMorning, '☀️');
  if (h < 18) return GreetingData(s.goodAfternoon, '🌤️');
  return GreetingData(s.goodEvening, '🌆');
}

IconData deviceIcon(DeviceClass d) => switch (d) {
      DeviceClass.mobile => Icons.smartphone_rounded,
      DeviceClass.tablet => Icons.tablet_mac_rounded,
      DeviceClass.desktop => Icons.desktop_windows_rounded,
    };

// ─────────────────────────────────────────────────────────────────────────────
//  MetricItem helper
// ─────────────────────────────────────────────────────────────────────────────
class MetricItem {
  const MetricItem(this.label, this.value, this.icon, this.colorA, this.colorB);
  final String label;
  final int value;
  final IconData icon;
  final Color colorA, colorB;
}

class FloatingCubeData {
  const FloatingCubeData({
    required this.icon,
    required this.label,
    required this.colorA,
    required this.colorB,
    required this.alignment,
    required this.phase,
  });
  final IconData icon;
  final String label;
  final Color colorA, colorB;
  final Alignment alignment;
  final double phase;
}

class NavSection {
  const NavSection({required this.id, required this.label, required this.icon});
  final String id, label;
  final IconData icon;
}
