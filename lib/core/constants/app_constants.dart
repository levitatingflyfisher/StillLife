import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'Still Life';
  static const String appVersion = '0.1.0';

  // Default categories
  static const List<String> defaultCategories = [
    'Electronics',
    'Furniture',
    'Appliances',
    'Clothing',
    'Jewelry',
    'Art & Decor',
    'Kitchen',
    'Tools',
    'Sports & Outdoors',
    'Books & Media',
    'Toys & Games',
    'Musical Instruments',
    'Office',
    'Garden',
    'Automotive',
    'Collectibles',
    'Other',
  ];

  // Default category icons (Material icon names)
  static const Map<String, int> categoryIcons = {
    'Electronics': 0xe1e3, // devices
    'Furniture': 0xe263, // chair
    'Appliances': 0xef65, // kitchen
    'Clothing': 0xea6c, // checkroom
    'Jewelry': 0xe30b, // diamond
    'Art & Decor': 0xea62, // palette
    'Kitchen': 0xef65, // kitchen
    'Tools': 0xea6e, // build
    'Sports & Outdoors': 0xe539, // sports
    'Books & Media': 0xe431, // menu_book
    'Toys & Games': 0xe5e2, // toys
    'Musical Instruments': 0xe405, // music_note
    'Office': 0xe8f9, // work
    'Garden': 0xe56e, // local_florist
    'Automotive': 0xe531, // directions_car
    'Collectibles': 0xe90a, // star
    'Other': 0xe8b8, // category
  };

  /// Reverse map: code-point → const IconData.
  ///
  /// Using explicit `Icons.*` constants here keeps all glyphs referenced in
  /// the source tree, which satisfies the release-build icon tree-shaker.
  static const Map<int, IconData> _codePointToIcon = {
    0xe1e3: Icons.devices,
    0xe263: Icons.chair,
    0xef65: Icons.kitchen,
    0xea6c: Icons.checkroom,
    0xe30b: Icons.diamond,
    0xea62: Icons.palette,
    0xea6e: Icons.build,
    0xe539: Icons.sports,
    0xe431: Icons.menu_book,
    0xe5e2: Icons.toys,
    0xe405: Icons.music_note,
    0xe8f9: Icons.work,
    0xe56e: Icons.local_florist,
    0xe531: Icons.directions_car,
    0xe90a: Icons.star,
    0xe8b8: Icons.category,
  };

  /// Returns the [IconData] for a stored code point, or [Icons.category_outlined]
  /// if the code point is null or unrecognised.
  static IconData iconFromCodePoint(int? codePoint) {
    if (codePoint == null) return Icons.category_outlined;
    return _codePointToIcon[codePoint] ?? Icons.category_outlined;
  }

  // Condition values
  static const List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  // Built-in location names
  static const String unsortedRoom = 'Unsorted';
  static const String personalCarry = 'Personal / Carry';
  static const String vehicle = 'Vehicle';
  static const String storageUnit = 'Storage Unit';

  // Depreciation defaults (years)
  static const Map<String, int> defaultUsefulLife = {
    'Electronics': 5,
    'Furniture': 15,
    'Appliances': 10,
    'Clothing': 3,
    'Jewelry': 25,
    'Art & Decor': 20,
    'Kitchen': 10,
    'Tools': 15,
    'Sports & Outdoors': 7,
    'Books & Media': 10,
    'Toys & Games': 5,
    'Musical Instruments': 20,
    'Office': 7,
    'Garden': 10,
    'Automotive': 7,
    'Collectibles': 25,
    'Other': 10,
  };

  // Search
  static const int searchDebounceMs = 300;
  static const int maxSearchResults = 100;
}
