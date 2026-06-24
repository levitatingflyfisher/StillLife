// Shared UI constants for profile-related screens

import 'package:flutter/material.dart';

/// Parse a profile hex color ("#RRGGBB") into an opaque [Color].
/// Shared helper used by profile screens + widgets — keeps the single
/// source of truth for the hex-to-Color conversion.
Color profileColor(String hex) =>
    Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));

const List<String> kProfileColors = [
  '#F44336',
  '#E91E63',
  '#9C27B0',
  '#6750A4',
  '#2196F3',
  '#4CAF50',
  '#FF9800',
  '#795548',
];

const String kDefaultProfileColor = '#6750A4';
const String kDefaultProfileEmoji = '👤';

const List<String> kProfileEmojis = [
  '👤',
  '👨',
  '👩',
  '👧',
  '👦',
  '👴',
  '👵',
  '🧑',
  '👨‍👩‍👧‍👦',
  '🐕',
  '🐈',
  '🏠',
];
