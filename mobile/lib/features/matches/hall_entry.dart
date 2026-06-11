/// Entrada do Hall da Fama / Hall da Vergonha (API `/hall-of-week`).
class HallEntry {
  final String key;
  final String displayName;
  final String title;
  final String subtitle;
  final String? avatarUrl;

  const HallEntry({
    required this.key,
    required this.displayName,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
  });

  factory HallEntry.fromJson(Map<String, dynamic> json) {
    return HallEntry(
      key: json['key'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '—',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get fallbackLetter {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class HallOfWeekData {
  final String periodLabel;
  final List<HallEntry> fame;
  final List<HallEntry> shame;

  const HallOfWeekData({
    required this.periodLabel,
    required this.fame,
    required this.shame,
  });

  factory HallOfWeekData.fromJson(Map<String, dynamic> json) {
    List<HallEntry> parseList(String field) {
      final raw = json[field] as List<dynamic>? ?? [];
      return raw
          .map((e) => HallEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }

    return HallOfWeekData(
      periodLabel: json['period_label'] as String? ?? 'Esta semana',
      fame: parseList('fame'),
      shame: parseList('shame'),
    );
  }

  static const empty = HallOfWeekData(
    periodLabel: 'Esta semana',
    fame: [],
    shame: [],
  );
}
