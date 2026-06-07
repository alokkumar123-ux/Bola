import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/co2_utils.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

/// A beautiful post-ride popup that shows the CO₂ saved for a single trip.
///
/// Usage:
///   showCo2RideSummaryPopup(context, co2SavedKg: 3.6, treesEquivalent: 0.17);
class Co2RideSummaryPopup extends StatefulWidget {
  final double co2SavedKg;
  final double treesEquivalent;
  final double distanceKm;
  final int passengers;

  const Co2RideSummaryPopup({
    super.key,
    required this.co2SavedKg,
    required this.treesEquivalent,
    required this.distanceKm,
    required this.passengers,
  });

  @override
  State<Co2RideSummaryPopup> createState() => _Co2RideSummaryPopupState();
}

class _Co2RideSummaryPopupState extends State<Co2RideSummaryPopup>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _leafCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _leafAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _leafCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleCtrl,
      curve: Curves.elasticOut,
    );
    _leafAnim = CurvedAnimation(
      parent: _leafCtrl,
      curve: Curves.easeInOut,
    );

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _leafCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _leafCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey900 : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B271).withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF086640), Color(0xFF10B271)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _leafAnim,
                      builder: (_, __) {
                        return Transform.rotate(
                          angle: (_leafAnim.value - 0.5) * 0.3,
                          child: const Text(
                            '🌱',
                            style: TextStyle(fontSize: 52),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ride Complete!',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontFamily: AppThemeData.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here\'s your green impact for this trip',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: AppThemeData.regular,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // CO2 saved highlight
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B271).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                const Color(0xFF10B271).withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'You saved',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: AppThemeData.medium,
                              color: isDark
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Co2Utils.formatCo2(widget.co2SavedKg),
                            style: const TextStyle(
                              fontSize: 28,
                              fontFamily: AppThemeData.bold,
                              color: Color(0xFF10B271),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by sharing this ride 🚗',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: AppThemeData.regular,
                              color: isDark
                                  ? AppThemeData.grey400
                                  : AppThemeData.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            emoji: '🌳',
                            label: 'Trees',
                            value: Co2Utils.formatTrees(
                                widget.treesEquivalent),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            emoji: '📍',
                            label: 'Distance',
                            value:
                                '${widget.distanceKm.toStringAsFixed(1)} km',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            emoji: '👥',
                            label: 'Riders',
                            value: '${widget.passengers}',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Motivational message
                    Text(
                      'Every shared ride makes a difference. Keep it up! 💪',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: AppThemeData.medium,
                        color: isDark
                            ? AppThemeData.grey400
                            : AppThemeData.grey600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B271),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Awesome! 🌿',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool isDark;

  const _MiniStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color:
            isDark ? AppThemeData.grey800 : AppThemeData.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppThemeData.bold,
              color: isDark ? AppThemeData.grey100 : AppThemeData.grey800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: AppThemeData.regular,
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the CO₂ ride summary popup.
///
/// Call this after a ride is marked complete.
/// [passengers] = total people in car (driver + riders, minimum 2 for any savings)
void showCo2RideSummaryPopup(
  BuildContext context, {
  required double distanceKm,
  required int passengers,
}) {
  final double co2Saved = Co2Utils.calculateCo2SavedKg(
    distanceKm: distanceKm,
    passengers: passengers,
  );
  final double trees = Co2Utils.co2ToTrees(co2Saved);

  // Only show popup if there are actual savings
  if (co2Saved <= 0) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => Co2RideSummaryPopup(
      co2SavedKg: co2Saved,
      treesEquivalent: trees,
      distanceKm: distanceKm,
      passengers: passengers,
    ),
  );
}
