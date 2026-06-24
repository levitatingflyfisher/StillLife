/// Holds computed depreciation information for an item.
class DepreciationInfo {
  final double originalValue;
  final double currentValue;
  final double totalDepreciation;
  final double annualDepreciation;
  final double ageYears;
  final int usefulLife;
  final double percentRemaining;

  const DepreciationInfo({
    required this.originalValue,
    required this.currentValue,
    required this.totalDepreciation,
    required this.annualDepreciation,
    required this.ageYears,
    required this.usefulLife,
    required this.percentRemaining,
  });
}

/// Calculates straight-line depreciation with a 10% residual value floor.
class DepreciationCalculator {
  /// Standard useful life in years by category (case-insensitive).
  static const Map<String, int> _usefulLifeByCategory = {
    'electronics': 5,
    'computers': 4,
    'furniture': 10,
    'appliances': 10,
    'clothing': 3,
    'jewelry': 10,
    'tools': 7,
    'musical instruments': 7,
    'sporting goods': 5,
    'kitchenware': 7,
    'books': 5,
  };

  static const int _defaultUsefulLife = 7;
  static const double _residualFactor = 0.10;

  /// Returns the useful life in years for the given category name.
  int getUsefulLife(String categoryName) {
    return _usefulLifeByCategory[categoryName.toLowerCase()] ??
        _defaultUsefulLife;
  }

  /// Calculates the current value of an item using straight-line depreciation.
  ///
  /// The item depreciates linearly from [purchasePrice] to 10% residual value
  /// over its useful life. After the useful life is exceeded the value remains
  /// at the 10% floor.
  double calculateCurrentValue(
    double purchasePrice,
    DateTime purchaseDate,
    String categoryName, {
    DateTime? asOf,
  }) {
    final info = calculateDepreciation(
      purchasePrice,
      purchaseDate,
      categoryName,
      asOf: asOf,
    );
    return info.currentValue;
  }

  /// Returns a full [DepreciationInfo] breakdown for the given item.
  DepreciationInfo calculateDepreciation(
    double purchasePrice,
    DateTime purchaseDate,
    String categoryName, {
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final usefulLife = getUsefulLife(categoryName);
    final residualValue = purchasePrice * _residualFactor;
    final depreciableAmount = purchasePrice - residualValue;
    final annualDepreciation = usefulLife > 0
        ? depreciableAmount / usefulLife
        : 0.0;

    final ageInDays = now.difference(purchaseDate).inDays;
    final ageYears = ageInDays / 365.25;

    double totalDepreciation = annualDepreciation * ageYears;
    if (totalDepreciation < 0) totalDepreciation = 0;
    if (totalDepreciation > depreciableAmount) {
      totalDepreciation = depreciableAmount;
    }

    final currentValue = purchasePrice - totalDepreciation;
    final percentRemaining = purchasePrice > 0
        ? (currentValue / purchasePrice) * 100
        : 0.0;

    return DepreciationInfo(
      originalValue: purchasePrice,
      currentValue: currentValue,
      totalDepreciation: totalDepreciation,
      annualDepreciation: annualDepreciation,
      ageYears: ageYears,
      usefulLife: usefulLife,
      percentRemaining: percentRemaining,
    );
  }
}
