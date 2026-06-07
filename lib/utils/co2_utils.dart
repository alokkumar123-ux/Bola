/// CO₂ Savings Utility for BOLA Ride-Sharing
///
/// Formula: CO₂_saved = distance × emission_factor × (people - 1)
/// Where emission_factor defaults to 120 g CO₂/km for petrol cars
class Co2Utils {
  // Emission factors in grams CO₂ per km
  static const double petrolFactor = 120.0;
  static const double dieselFactor = 100.0;
  static const double cngFactor = 80.0;

  // 1 tree absorbs ~21 kg CO₂/year
  static const double kgCo2PerTree = 21.0;

  /// Calculate CO₂ saved (in kg) for a single shared ride
  /// [distanceKm] – trip distance in kilometres
  /// [passengers] – total number of people in the car (driver + riders)
  /// [emissionFactor] – grams CO₂/km (default petrol)
  static double calculateCo2SavedKg({
    required double distanceKm,
    required int passengers,
    double emissionFactor = petrolFactor,
  }) {
    if (passengers <= 1 || distanceKm <= 0) return 0.0;
    final double savedGrams = distanceKm * emissionFactor * (passengers - 1);
    return savedGrams / 1000.0; // convert g → kg
  }

  /// Convert saved CO₂ kg to equivalent number of trees planted
  static double co2ToTrees(double co2SavedKg) {
    if (co2SavedKg <= 0) return 0.0;
    return co2SavedKg / kgCo2PerTree;
  }

  /// Friendly display string for CO₂ saved
  static String formatCo2(double kg) {
    if (kg < 1.0) {
      return '${(kg * 1000).toStringAsFixed(0)} g CO₂';
    }
    return '${kg.toStringAsFixed(2)} kg CO₂';
  }

  /// Friendly display string for trees equivalent
  static String formatTrees(double trees) {
    if (trees < 0.1) {
      return '${(trees * 100).toStringAsFixed(0)}% of a tree';
    }
    return '${trees.toStringAsFixed(2)} trees';
  }

  /// Parse distance string from BookingModel (distance is stored in metres)
  /// Returns km as double
  static double distanceMetresToKm(String? distanceMetres) {
    if (distanceMetres == null || distanceMetres.isEmpty) return 0.0;
    try {
      final metres = double.parse(distanceMetres);
      return metres / 1000.0;
    } catch (_) {
      return 0.0;
    }
  }
}
