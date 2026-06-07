import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:poolmate/app/co2_impact/co2_impact_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/co2_utils.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF10B271);
const _kGreenDark = Color(0xFF086640);
const _kGreenLight = Color(0xFFE5FFF5);
const _kGreenMid = Color(0xFF19FFA3);
const _kBlue = Color(0xFF1C58B2);
const _kOrange = Color(0xFFFFAA29);
const _kPurple = Color(0xFF9B59B6);
const _kYellow = Color(0xFFF1C40F);

class Co2ImpactScreen extends StatelessWidget {
  const Co2ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    final Co2ImpactController controller = Get.put(Co2ImpactController());

    return Scaffold(
      backgroundColor:
          isDark ? AppThemeData.grey900 : const Color(0xFFF4F7F5),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: _kGreen),
          );
        }

        final double totalCo2 = controller.totalCo2Kg.value;
        final double totalTrees = controller.totalTrees.value;

        return CustomScrollView(
          slivers: [
            _TopBar(isDark: isDark, firstName: controller.firstName.value),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 6),
                  _GreenImpactHero(
                    totalCo2: controller.thisMonthCo2.value,
                    vsLastMonthStr: controller.vsLastMonthStr.value,
                    vsLastMonthPositive: controller.vsLastMonthPositive.value,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _StatsGrid(
                    totalCo2: controller.thisMonthCo2.value,
                    totalTrees: totalTrees,
                    changeStr: controller.vsLastMonthStr.value,
                    changePositive: controller.vsLastMonthPositive.value,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _SavingsChart(
                              peakCo2: controller.chartPeakCo2.value,
                              points: controller.chartNormalized,
                              labels: controller.chartMonthLabels,
                              isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _SavingsDonut(
                              driverCo2: controller.driverCo2.value,
                              passengerCo2: controller.passengerCo2.value,
                              segments: controller.donutSegments,
                              isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _ImpactThisMonth(
                              rides: controller.ridesThisMonth.value,
                              passengers: controller.totalPassengersThisMonth.value,
                              distanceKm: controller.distanceKmThisMonth.value,
                              avgOccupancy: controller.avgOccupancyThisMonth.value,
                              isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _EnvironmentalImpact(
                              totalCo2: totalCo2,
                              totalTrees: totalTrees,
                              carKmNotDriven: controller.carKmNotDriven.value,
                              fuelSavedLiters: controller.fuelSavedLiters.value,
                              isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CommunityImpact(
                      userLifetimeCo2: totalCo2,
                      userTotalRides: controller.totalRides.value,
                      isDark: isDark),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
String _getGreeting(String name) {
  final hour = DateTime.now().hour;
  String greeting = 'Good evening';
  if (hour < 12) {
    greeting = 'Good morning';
  } else if (hour < 17) {
    greeting = 'Good afternoon';
  }
  return '$greeting, $name!';
}

class _TopBar extends StatelessWidget {
  final bool isDark;
  final String firstName;
  const _TopBar({required this.isDark, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor:
          isDark ? AppThemeData.grey900 : Colors.white,
      elevation: 0,
      floating: true,
      pinned: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: isDark ? Colors.white : AppThemeData.grey800, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getGreeting(firstName),
                style: TextStyle(
                  color:
                      isDark ? Colors.white : AppThemeData.grey800,
                  fontFamily: AppThemeData.bold,
                  fontSize: 17,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            'Every shared ride makes a greener tomorrow.',
            style: TextStyle(
              color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
              fontFamily: AppThemeData.regular,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppThemeData.grey300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                'This Month',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppThemeData.medium,
                  color: isDark ? Colors.white : AppThemeData.grey700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down,
                  size: 16,
                  color: isDark ? Colors.white : AppThemeData.grey700),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Green Impact Hero ────────────────────────────────────────────────────────
class _GreenImpactHero extends StatefulWidget {
  final double totalCo2;
  final String vsLastMonthStr;
  final bool vsLastMonthPositive;
  final bool isDark;
  const _GreenImpactHero({
    required this.totalCo2,
    required this.vsLastMonthStr,
    required this.vsLastMonthPositive,
    required this.isDark,
  });

  @override
  State<_GreenImpactHero> createState() => _GreenImpactHeroState();
}

class _GreenImpactHeroState extends State<_GreenImpactHero> {
  LottieComposition? _composition;
  bool _lottieError = false;

  @override
  void initState() {
    super.initState();
    _loadLottie();
  }

  Future<void> _loadLottie() async {
    try {
      final composition = await AssetLottie(
        'assets/animation/growing_trees.json',
      ).load();
      if (mounted) setState(() => _composition = composition);
    } catch (_) {
      if (mounted) setState(() => _lottieError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayKg = widget.totalCo2 > 0 ? widget.totalCo2 : 0;
    final isDark = widget.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1A12) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _kGreen.withOpacity(0.15)),
        boxShadow: [
         
        ],
      ),
      child: Stack(
        children: [
          // Lottie growing trees animation (with safe async loading)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                width: 155,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: _lottieError || (_composition == null && _lottieError)
                    ? _CarIllustration()
                    : _composition != null
                        ? Lottie(
                            composition: _composition!,
                            fit: BoxFit.cover,
                            repeat: true,
                          )
                        : _CarIllustration(), // placeholder while loading
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your Green Impact',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.bold,
                        color: isDark
                            ? Colors.white
                            : AppThemeData.grey800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.info_outline,
                        size: 14,
                        color: isDark
                            ? AppThemeData.grey400
                            : AppThemeData.grey500),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "You've made our planet a greener ",
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.regular,
                        color: isDark
                            ? AppThemeData.grey400
                            : AppThemeData.grey600,
                      ),
                    ),
                    const Text('🌍', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${displayKg.toStringAsFixed(1)} ',
                        style: const TextStyle(
                          fontSize: 38,
                          fontFamily: AppThemeData.extraBold,
                          color: _kGreenDark,
                          height: 1.1,
                        ),
                      ),
                      const TextSpan(
                        text: 'kg',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: AppThemeData.bold,
                          color: _kGreenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'CO₂ saved this month',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.regular,
                    color: isDark
                        ? AppThemeData.grey400
                        : AppThemeData.grey600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: widget.vsLastMonthPositive ? _kGreenLight : const Color(0xFFFFF0ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: widget.vsLastMonthPositive ? _kGreen.withOpacity(0.3) : AppThemeData.warning300.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.vsLastMonthPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14, color: widget.vsLastMonthPositive ? _kGreenDark : AppThemeData.warning300),
                      const SizedBox(width: 6),
                      Text(
                        widget.vsLastMonthStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppThemeData.medium,
                          color: widget.vsLastMonthPositive ? _kGreenDark : AppThemeData.warning300,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple car + trees SVG-style illustration using Flutter widgets
class _CarIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          // Trees
          Positioned(
            left: 8,
            top: 18,
            child: _Tree(height: 60, color: const Color(0xFF2E8B57)),
          ),
          Positioned(
            right: 8,
            top: 10,
            child: _Tree(height: 75, color: const Color(0xFF3CB371)),
          ),
          Positioned(
            left: 40,
            top: 30,
            child: _Tree(height: 45, color: const Color(0xFF66BB6A)),
          ),
          // Wind turbines (simplified)
          Positioned(
            right: 28,
            top: 8,
            child: _Turbine(color: const Color(0xFF9E9E9E)),
          ),
          // BOLA car
          Positioned(
            bottom: 24,
            left: 10,
            right: 10,
            child: _BolaCarWidget(),
          ),
          // Ground line
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: const Color(0xFFA5D6A7).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tree extends StatelessWidget {
  final double height;
  final Color color;
  const _Tree({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: height * 0.55,
            height: height * 0.7,
            color: color,
          ),
        ),
        Container(
          width: 4,
          height: height * 0.3,
          color: const Color(0xFF795548),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _Turbine extends StatelessWidget {
  final Color color;
  const _Turbine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 55,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 2,
            height: 55,
            color: color,
          ),
          Positioned(
            top: 0,
            child: Transform.rotate(
              angle: pi / 5,
              child: Icon(Icons.wind_power,
                  size: 18, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BolaCarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car, color: _kGreen, size: 22),
          const SizedBox(width: 4),
          Text(
            'BOLA',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: AppThemeData.extraBold,
              color: _kGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final double totalCo2;
  final double totalTrees;
  final String changeStr;
  final bool changePositive;
  final bool isDark;
  const _StatsGrid(
      {required this.totalCo2,
      required this.totalTrees,
      required this.changeStr,
      required this.changePositive,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final co2 = totalCo2 > 0 ? totalCo2 : 0;
    final trees = totalTrees > 0 ? totalTrees : 0;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.co2,
            iconColor: Colors.white,
            iconBg: _kGreen,
            label: 'CO₂ Saved',
            value: '${co2.toStringAsFixed(1)} kg',
            change: changeStr,
            changePositive: changePositive,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.park,
            iconColor: Colors.white,
            iconBg: _kGreen,
            label: 'Trees Equivalent',
            value: '${trees.toStringAsFixed(2)}',
            subLabel: 'trees planted',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? change;
  final String? subLabel;
  final bool changePositive;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.change,
    this.subLabel,
    this.changePositive = true,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppThemeData.medium,
                    color: isDark
                        ? AppThemeData.grey400
                        : AppThemeData.grey600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.white : AppThemeData.grey800,
                  ),
                ),
                if (subLabel != null)
                  Text(
                    subLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.regular,
                      color: _kGreen,
                    ),
                  ),
                if (change != null)
                  Text(
                    change!,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.regular,
                      color: changePositive
                          ? _kGreen
                          : AppThemeData.warning300,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Savings Chart (line chart drawn with CustomPaint) ────────────────────────
class _SavingsChart extends StatelessWidget {
  final double peakCo2;
  final List<double> points;
  final List<String> labels;
  final bool isDark;
  const _SavingsChart({
    required this.peakCo2,
    required this.points,
    required this.labels,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CO₂ Savings Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.bold,
                    color:
                        isDark ? Colors.white : AppThemeData.grey800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppThemeData.grey300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Last 6 Months',
                      style: TextStyle(
                        fontSize: 9,
                        fontFamily: AppThemeData.medium,
                        color: isDark
                            ? Colors.white
                            : AppThemeData.grey700,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        size: 12,
                        color: isDark
                            ? Colors.white
                            : AppThemeData.grey700),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _LineChartPainter(peak: peakCo2, points: points, isDark: isDark),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((lbl) => Text(
              lbl,
              style: TextStyle(
                  fontSize: 9,
                  color: isDark
                      ? AppThemeData.grey500
                      : AppThemeData.grey500,
                  fontFamily: AppThemeData.regular),
            )).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Amazing! You achieved a max of ${peakCo2.toStringAsFixed(1)} kg CO₂ in a single month.',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.medium,
                      color: _kGreenDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final double peak;
  final List<double> points;
  final bool isDark;
  _LineChartPainter({required this.peak, required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final w = size.width;
    final h = size.height - 16;
    final step = w / (points.length - 1);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _kGreen.withOpacity(0.35),
          _kGreen.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final linePaint = Paint()
      ..color = _kGreen
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = step * i;
      final y = h - (points[i] * h);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve
        final prevX = step * (i - 1);
        final prevY = h - (points[i - 1] * h);
        final cx = (prevX + x) / 2;
        path.cubicTo(cx, prevY, cx, y, x, y);
        fillPath.cubicTo(cx, prevY, cx, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    if (points.isNotEmpty && peak > 0) {
      // Draw peak label bubble at max point
      double maxVal = points[0];
      int maxIdx = 0;
      for (int i=1; i<points.length; i++) {
        if (points[i] > maxVal) { maxVal = points[i]; maxIdx = i; }
      }
      final peakX = step * maxIdx;
      final peakY = h - (maxVal * h);
      final bubblePaint = Paint()..color = _kGreenDark;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(peakX, peakY - 14), width: 44, height: 16),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, bubblePaint);

      final textSpan = TextSpan(
        text: '${peak.toStringAsFixed(1)} kg',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(
          text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(peakX - 16, peakY - 22));
    }

    // Y-axis labels
    final labels = ['0', '6', '12', '18', '24', '30'];
    for (int i = 0; i < labels.length; i++) {
      final y = h - (i / (labels.length - 1)) * h;
      final ts = TextSpan(
        text: labels[i],
        style: TextStyle(
            color: isDark ? AppThemeData.grey500 : AppThemeData.grey500,
            fontSize: 8),
      );
      final tp2 = TextPainter(text: ts, textDirection: TextDirection.ltr);
      tp2.layout();
      tp2.paint(canvas, Offset(0, y - 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Savings Donut ────────────────────────────────────────────────────────────
class _SavingsDonut extends StatelessWidget {
  final double driverCo2;
  final double passengerCo2;
  final List<double> segments;
  final bool isDark;
  const _SavingsDonut({
    required this.driverCo2,
    required this.passengerCo2,
    required this.segments,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double totalCo2 = driverCo2 + passengerCo2;
    final co2 = totalCo2 > 0 ? totalCo2 : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where Your Savings\nCome From',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : AppThemeData.grey800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _DonutPainter(
                  segments: segments.isEmpty ? const [0.5, 0.5] : segments,
                  colors: const [_kGreen, _kBlue],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${co2.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppThemeData.bold,
                          color: isDark
                              ? Colors.white
                              : AppThemeData.grey800,
                        ),
                      ),
                      Text(
                        'Total CO₂\nSaved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontFamily: AppThemeData.regular,
                          color: isDark
                              ? AppThemeData.grey400
                              : AppThemeData.grey600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DonutLegend(
              color: _kGreen, label: 'As Driver', percent: '${(segments.isNotEmpty ? segments[0]*100 : 50).round()}%'),
          const SizedBox(height: 5),
          _DonutLegend(
              color: _kBlue, label: 'As Passenger', percent: '${(segments.length > 1 ? segments[1]*100 : 50).round()}%'),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;
  const _DonutLegend(
      {required this.color,
      required this.label,
      required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontFamily: AppThemeData.regular,
              color: AppThemeData.grey600,
            ),
          ),
        ),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 9,
            fontFamily: AppThemeData.bold,
            color: AppThemeData.grey700,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;
  _DonutPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    double startAngle = -pi / 2;
    for (int i = 0; i < segments.length; i++) {
      paint.color = colors[i];
      final sweep = 2 * pi * segments[i];
      canvas.drawArc(rect.deflate(8), startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Impact This Month ────────────────────────────────────────────────────────
class _ImpactThisMonth extends StatelessWidget {
  final int rides;
  final int passengers;
  final double distanceKm;
  final double avgOccupancy;
  final bool isDark;
  const _ImpactThisMonth({
    required this.rides,
    required this.passengers,
    required this.distanceKm,
    required this.avgOccupancy,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact This Month',
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : AppThemeData.grey800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ImpactStat(
                  icon: Icons.directions_car_outlined,
                  label: 'Rides\nShared',
                  value: rides.toString(),
                  change: '',
                  isDark: isDark),
              _ImpactStat(
                  icon: Icons.people_outline,
                  label: 'People\nTraveled',
                  value: passengers.toString(),
                  change: '',
                  isDark: isDark),
              _ImpactStat(
                  icon: Icons.map_outlined,
                  label: 'Kilometers\nTraveled',
                  value: '${distanceKm.toStringAsFixed(1)} km',
                  change: '',
                  isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool isDark;
  const _ImpactStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey700 : const Color(0xFFF0F4F7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18,
              color: isDark ? AppThemeData.grey300 : AppThemeData.grey700),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8,
            fontFamily: AppThemeData.regular,
            color:
                isDark ? AppThemeData.grey400 : AppThemeData.grey600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppThemeData.bold,
            color: isDark ? Colors.white : AppThemeData.grey800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          change,
          style: const TextStyle(
            fontSize: 9,
            fontFamily: AppThemeData.medium,
            color: _kGreen,
          ),
        ),
      ],
    );
  }
}

// ─── Environmental Impact ─────────────────────────────────────────────────────
class _EnvironmentalImpact extends StatelessWidget {
  final double totalCo2;
  final double totalTrees;
  final double fuelSavedLiters;
  final double carKmNotDriven;
  final bool isDark;
  const _EnvironmentalImpact({
    required this.totalCo2,
    required this.totalTrees,
    required this.fuelSavedLiters,
    required this.carKmNotDriven,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final co2 = totalCo2 > 0 ? totalCo2 : 0.0;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environmental Impact',
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : AppThemeData.grey800,
            ),
          ),
          const SizedBox(height: 12),
          _EnvRow(
            icon: Icons.eco_outlined,
            iconColor: _kGreen,
            co2: '${co2.toStringAsFixed(1)} kg CO₂ saved',
            equals: '=',
            result: totalTrees.toStringAsFixed(2),
            resultLabel: 'Trees planted',
            resultColor: _kGreen,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _EnvRow(
            icon: Icons.directions_car_outlined,
            iconColor: _kBlue,
            co2: '${co2.toStringAsFixed(1)} kg CO₂ saved',
            equals: '=',
            result: '${carKmNotDriven.toStringAsFixed(1)} km',
            resultLabel: 'Not driven by car',
            resultColor: _kBlue,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _EnvRow(
            icon: Icons.local_gas_station_outlined,
            iconColor: _kYellow,
            co2: '${co2.toStringAsFixed(1)} kg CO₂ saved',
            equals: '=',
            result: '${fuelSavedLiters.toStringAsFixed(1)} L',
            resultLabel: 'Petrol saved',
            resultColor: _kOrange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _EnvRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String co2;
  final String equals;
  final String result;
  final String resultLabel;
  final Color resultColor;
  final bool isDark;

  const _EnvRow({
    required this.icon,
    required this.iconColor,
    required this.co2,
    required this.equals,
    required this.result,
    required this.resultLabel,
    required this.resultColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                co2,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: AppThemeData.regular,
                  color: isDark
                      ? AppThemeData.grey400
                      : AppThemeData.grey600,
                ),
              ),
              Row(
                children: [
                  Text(
                    result,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppThemeData.bold,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    resultLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: AppThemeData.regular,
                      color: isDark
                          ? AppThemeData.grey400
                          : AppThemeData.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Community Impact ─────────────────────────────────────────────────────────
class _CommunityImpact extends StatelessWidget {
  final double userLifetimeCo2;
  final int userTotalRides;
  final bool isDark;
  const _CommunityImpact({
    required this.userLifetimeCo2,
    required this.userTotalRides,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Globe illustration placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kGreenMid.withOpacity(0.5),
                  _kGreenDark.withOpacity(0.8),
                ],
              ),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Impact',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppThemeData.bold,
                    color:
                        isDark ? Colors.white : AppThemeData.grey800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userLifetimeCo2.toStringAsFixed(1)} kg CO₂',
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: AppThemeData.extraBold,
                    color: _kGreenDark,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Total CO₂ saved by you across\n$userTotalRides lifetime rides',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppThemeData.regular,
                    color: isDark
                        ? AppThemeData.grey400
                        : AppThemeData.grey600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text(
              'View\nCommunity\nImpact',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontFamily: AppThemeData.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Card wrapper ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }
}
