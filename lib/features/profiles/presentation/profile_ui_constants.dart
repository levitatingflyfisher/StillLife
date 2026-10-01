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
/// A profile's avatar is stored as an emoji string (the `avatar_emoji`
/// column, backups and sync all carry it), but it is DRAWN as a Material
/// icon. The web build has no platform colour-emoji font, so a drawn emoji
/// is a box there; the icon font ships with the app on every platform.
/// The stored strings are identifiers, never painted — hence not-rendered.
const String kDefaultProfileEmoji = '👤'; // not-rendered

/// Stored avatar id → the icon drawn for it and the word a screen reader
/// says (an emoji Text used to carry its own name), in picker order.
const Map<String, (IconData, String)> kProfileAvatarIcons = {
  '👤': (Icons.person, 'Person'), // not-rendered
  '👨': (Icons.man, 'Man'), // not-rendered
  '👩': (Icons.woman, 'Woman'), // not-rendered
  '👧': (Icons.girl, 'Girl'), // not-rendered
  '👦': (Icons.boy, 'Boy'), // not-rendered
  '👴': (Icons.elderly, 'Older man'), // not-rendered
  '👵': (Icons.elderly_woman, 'Older woman'), // not-rendered
  '🧑': (Icons.face, 'Face'), // not-rendered
  '👨‍👩‍👧‍👦': (Icons.family_restroom, 'Family'), // not-rendered
  '🐕': (Icons.pets, 'Pet'), // not-rendered
  '🏠': (Icons.home, 'Household'), // not-rendered
};

/// Ids older builds offered that the picker no longer does. Material has no
/// cat, and two identical paws in one picker would be indistinguishable.
const Map<String, (IconData, String)> _kLegacyAvatarIcons = {
  '🐈': (Icons.pets, 'Pet'), // not-rendered
};

/// The avatar ids the picker offers.
final List<String> kProfileEmojis = List.unmodifiable(kProfileAvatarIcons.keys);

/// The icon drawn for a stored avatar id. An id this build does not know
/// (typed by hand into an import, or from a newer build) draws the default.
IconData profileAvatarIcon(String stored) => _avatar(stored).$1;

/// What a screen reader says for a stored avatar id.
String profileAvatarLabel(String stored) => _avatar(stored).$2;

(IconData, String) _avatar(String stored) =>
    kProfileAvatarIcons[stored] ??
    _kLegacyAvatarIcons[stored] ??
    kProfileAvatarIcons[kDefaultProfileEmoji]!;

/// A profile's avatar as drawn everywhere in the app.
class ProfileAvatarIcon extends StatelessWidget {
  const ProfileAvatarIcon(this.stored, {super.key, this.size, this.color});

  final String stored;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(profileAvatarIcon(stored),
          size: size, color: color, semanticLabel: profileAvatarLabel(stored));
}
