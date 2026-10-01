import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still_life/features/profiles/presentation/profile_ui_constants.dart';

// Avatars are stored as emoji ids but drawn as icons: the web build has no
// colour-emoji font, so a painted emoji is a box there.
void main() {
  test('every picker avatar draws a distinct icon', () {
    final icons = kProfileEmojis.map(profileAvatarIcon).toList();
    expect(icons.toSet(), hasLength(kProfileEmojis.length));
  });

  test('the default avatar is in the picker and draws a person', () {
    expect(kProfileEmojis, contains(kDefaultProfileEmoji));
    expect(profileAvatarIcon(kDefaultProfileEmoji), Icons.person);
  });

  test('an id an older build offered still draws', () {
    expect(profileAvatarIcon('\u{1F408}'), Icons.pets);
  });

  test('an unknown id draws the default instead of a box', () {
    expect(profileAvatarIcon('\u{1F984}'), Icons.person);
    expect(profileAvatarIcon(''), Icons.person);
  });

  test('every picker avatar has a distinct spoken label', () {
    final labels = kProfileEmojis.map(profileAvatarLabel).toList();
    expect(labels.every((l) => l.isNotEmpty), isTrue);
    expect(labels.toSet(), hasLength(kProfileEmojis.length));
  });
}
