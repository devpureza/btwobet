import 'package:flutter/material.dart';

Color achievementTierColor(String tier, ColorScheme scheme) {
  return switch (tier) {
    'bronze' => const Color(0xFFCD7F32),
    'silver' => const Color(0xFF9E9E9E),
    'gold' => const Color(0xFFD4AF37),
    'platinum' => scheme.primary,
    'legendary' => const Color(0xFF9C27B0),
    _ => scheme.outline,
  };
}

IconData achievementTierIcon(String tier, {required bool unlocked}) {
  if (!unlocked) return Icons.lock_outline;
  return switch (tier) {
    'platinum' => Icons.diamond_outlined,
    'legendary' => Icons.auto_awesome,
    'gold' => Icons.emoji_events,
    _ => Icons.military_tech_outlined,
  };
}
