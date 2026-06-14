bool isMatchLive(Map<String, dynamic> match) {
  final fromApi = match['is_live'] as bool?;
  if (fromApi != null) return fromApi;

  final status = match['status'] as String? ?? 'scheduled';
  if (status == 'live') return true;
  if (status != 'scheduled') return false;

  final kickoff = DateTime.parse(match['kickoff_at'] as String).toLocal();
  final liveScore = match['live_score'] as Map<String, dynamic>?;
  return kickoff.isBefore(DateTime.now()) && liveScore != null;
}

bool isCommunityPredictionsAvailable(Map<String, dynamic> match) {
  final fromApi = match['community_predictions_available'] as bool?;
  if (fromApi != null) return fromApi;

  final status = match['status'] as String? ?? 'scheduled';
  if (status == 'live' || status == 'finished') return true;

  final kickoff = DateTime.parse(match['kickoff_at'] as String).toLocal();
  final revealAt = kickoff.subtract(const Duration(hours: 2));
  return !DateTime.now().isBefore(revealAt);
}

bool hasLiveMatchesInList(Iterable<dynamic> matches) {
  for (final raw in matches) {
    if (raw is Map<String, dynamic> && isMatchLive(raw)) return true;
  }
  return false;
}
