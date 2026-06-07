import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:poolmate/constant/collection_name.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/utils/co2_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';

/// GetX controller for the CO₂ Impact screen.
/// Fetches all completed rides (driver + passenger) and derives every
/// stat shown in the UI from real Firestore data.
class Co2ImpactController extends GetxController {
  static const String tag = 'co2_impact';

  // ─── Loading ─────────────────────────────────────────────────────────────────
  final RxBool isLoading = true.obs;

  // ─── User ────────────────────────────────────────────────────────────────────
  final RxString firstName = ''.obs;

  // ─── Lifetime totals (stored on UserModel by ride-completion hook) ────────────
  final RxDouble totalCo2Kg = 0.0.obs;
  final RxDouble totalTrees = 0.0.obs;

  // ─── This-month vs last-month ────────────────────────────────────────────────
  final RxDouble thisMonthCo2 = 0.0.obs;
  final RxDouble lastMonthCo2 = 0.0.obs;
  final RxString vsLastMonthStr = ''.obs; // e.g. "↑ 18% vs last month"
  final RxBool vsLastMonthPositive = true.obs;

  // ─── Monthly chart (last 6 months, values normalised 0–1) ────────────────────
  final RxList<double> chartNormalized = <double>[0, 0, 0, 0, 0, 0].obs;
  final RxDouble chartPeakCo2 = 0.0.obs;
  final RxList<String> chartMonthLabels =
      <String>['', '', '', '', '', ''].obs;

  // ─── Donut breakdown (driver vs passenger) ───────────────────────────────────
  final RxDouble driverCo2 = 0.0.obs;
  final RxDouble passengerCo2 = 0.0.obs;
  final RxList<double> donutSegments = <double>[0.5, 0.5].obs;

  // ─── This-month ride stats ───────────────────────────────────────────────────
  final RxInt ridesThisMonth = 0.obs;
  final RxDouble distanceKmThisMonth = 0.0.obs;
  final RxInt totalPassengersThisMonth = 0.obs;
  final RxDouble avgOccupancyThisMonth = 0.0.obs;

  // ─── Environmental equivalents (lifetime) ────────────────────────────────────
  /// Litres of petrol not burned  (1 L petrol ≈ 2.31 kg CO₂)
  final RxDouble fuelSavedLiters = 0.0.obs;
  /// Car-kilometres avoided (120 g CO₂/km)
  final RxDouble carKmNotDriven = 0.0.obs;

  // ─── Gamification ────────────────────────────────────────────────────────────
  final RxInt greenPoints = 0.obs;
  final RxInt levelNumber = 1.obs;
  final RxString levelName = 'Eco Starter'.obs;
  final RxInt pointsToNextLevel = 500.obs;
  final RxDouble levelProgress = 0.0.obs;

  // ─── Streak & totals ────────────────────────────────────────────────────────
  final RxInt streakMonths = 0.obs;
  final RxInt totalRides = 0.obs;
  final RxDouble totalDistanceKm = 0.0.obs;

  // ─── Badges ──────────────────────────────────────────────────────────────────
  final RxBool badgeFirstRide = false.obs;
  final RxBool badgeTreeSaver = false.obs;
  final RxBool badgeCo2Saver = false.obs;
  final RxBool badgeEcoHero = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// Reload all stats (call on pull-to-refresh).
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final uid = AuthUtils.getCurrentUid();

      // 1 ─ User profile (lifetime totals already aggregated there)
      final user = await UserUtils.getUserProfile(uid);
      if (user == null) return;
      firstName.value = user.firstName ?? '';
      totalCo2Kg.value = user.totalCo2SavedKg ?? 0.0;
      totalTrees.value = user.totalTreesEquivalent ?? 0.0;

      // 2 ─ Fetch completed rides
      final driverRides = await _fetchDriverRides(uid);
      final passengerRides = await _fetchPassengerRides(uid);

      // 3 ─ Derive every stat
      _computeStats(driverRides, passengerRides);
    } catch (e) {
      print('❌ Co2ImpactController.loadData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Firestore helpers ───────────────────────────────────────────────────────

  Future<List<BookingModel>> _fetchDriverRides(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(CollectionName.booking)
          .where('createdBy', isEqualTo: uid)
          .where('status', isEqualTo: Constant.completed)
          .get();
      return snap.docs
          .map((d) => BookingModel.fromJson(d.data())..id = d.id)
          .toList();
    } catch (e) {
      print('❌ _fetchDriverRides: $e');
      return [];
    }
  }

  Future<List<BookingModel>> _fetchPassengerRides(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(CollectionName.booking)
          .where('bookedUserId', arrayContains: uid)
          .where('status', isEqualTo: Constant.completed)
          .get();
      return snap.docs
          .map((d) => BookingModel.fromJson(d.data())..id = d.id)
          .toList();
    } catch (e) {
      print('❌ _fetchPassengerRides: $e');
      return [];
    }
  }

  // ─── Stats computation ────────────────────────────────────────────────────────

  void _computeStats(
    List<BookingModel> driverRides,
    List<BookingModel> passengerRides,
  ) {
    final now = DateTime.now();
    final thisMonthKey = _mk(now);
    final lastMonthKey = _mk(DateTime(now.year, now.month - 1));

    // Six-month keys (oldest → newest)
    final sixKeys = List.generate(6, (i) {
      return _mk(DateTime(now.year, now.month - (5 - i)));
    });

    final Map<String, double> monthlyCo2 = {};
    final Map<String, double> monthlyDist = {};
    final Map<String, int> monthlyRides = {};
    final Map<String, int> monthlyPax = {}; // passengers per month
    final Set<String> activeMonths = {};

    double driverTotal = 0.0;
    double passengerTotal = 0.0;
    double lifeDist = 0.0;
    int lifeRides = 0;

    void _accumulate(BookingModel ride, bool isDriver) {
      final dt = (ride.departureDateTime as Timestamp?)?.toDate();
      if (dt == null) return;

      final mk = _mk(dt);
      final distKm = Co2Utils.distanceMetresToKm(ride.distance);
      final bookedSeats = int.tryParse(ride.bookedSeat ?? '0') ?? 0;
      
      double co2 = 0.0;
      if (isDriver) {
        final totalPeople = 1 + bookedSeats;
        co2 = Co2Utils.calculateCo2SavedKg(
            distanceKm: distKm, passengers: totalPeople);
      } else {
        // Passenger gets per-person CO2 (1 person's worth)
        co2 = Co2Utils.calculateCo2SavedKg(
            distanceKm: distKm, passengers: 2); 
      }

      if (co2 <= 0 && distKm <= 0) return;

      monthlyCo2[mk] = (monthlyCo2[mk] ?? 0) + co2;
      monthlyDist[mk] = (monthlyDist[mk] ?? 0) + distKm;
      monthlyRides[mk] = (monthlyRides[mk] ?? 0) + 1;
      if (isDriver) {
        // count passengers boarded this month
        monthlyPax[mk] = (monthlyPax[mk] ?? 0) + bookedSeats;
        driverTotal += co2;
      } else {
        passengerTotal += co2;
      }
      activeMonths.add(mk);
      lifeDist += distKm;
      lifeRides++;
    }

    for (final r in driverRides) _accumulate(r, true);
    for (final r in passengerRides) _accumulate(r, false);

    // ─── This month / last month ───────────────────────────────────────────────
    thisMonthCo2.value = monthlyCo2[thisMonthKey] ?? 0.0;
    lastMonthCo2.value = monthlyCo2[lastMonthKey] ?? 0.0;

    if (lastMonthCo2.value > 0) {
      final pct = ((thisMonthCo2.value - lastMonthCo2.value) /
              lastMonthCo2.value *
              100)
          .abs()
          .round();
      if (thisMonthCo2.value >= lastMonthCo2.value) {
        vsLastMonthStr.value = '↑ $pct% vs last month';
        vsLastMonthPositive.value = true;
      } else {
        vsLastMonthStr.value = '↓ $pct% vs last month';
        vsLastMonthPositive.value = false;
      }
    } else if (thisMonthCo2.value > 0) {
      vsLastMonthStr.value = '🌱 New this month!';
      vsLastMonthPositive.value = true;
    } else {
      vsLastMonthStr.value = 'No rides yet';
      vsLastMonthPositive.value = false;
    }

    // ─── Monthly chart ─────────────────────────────────────────────────────────
    final rawMonthly = sixKeys.map((k) => monthlyCo2[k] ?? 0.0).toList();
    final peak = rawMonthly.fold(0.0, (a, b) => a > b ? a : b);
    chartPeakCo2.value = peak;
    chartNormalized.value =
        rawMonthly.map((v) => peak > 0 ? (v / peak) : 0.0).toList();
    chartMonthLabels.value = sixKeys.map((k) {
      final parts = k.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMM').format(d);
    }).toList();

    // ─── Donut ────────────────────────────────────────────────────────────────
    driverCo2.value = driverTotal;
    passengerCo2.value = passengerTotal;
    final donutTotal = driverTotal + passengerTotal;
    donutSegments.value = donutTotal > 0
        ? [driverTotal / donutTotal, passengerTotal / donutTotal]
        : [0.5, 0.5];

    // ─── This-month ride stats ─────────────────────────────────────────────────
    ridesThisMonth.value = monthlyRides[thisMonthKey] ?? 0;
    distanceKmThisMonth.value = monthlyDist[thisMonthKey] ?? 0.0;
    totalPassengersThisMonth.value = monthlyPax[thisMonthKey] ?? 0;
    final ridesM = ridesThisMonth.value;
    final paxM = totalPassengersThisMonth.value;
    avgOccupancyThisMonth.value =
        ridesM > 0 ? (paxM + ridesM) / ridesM : 0.0;

    // ─── Lifetime totals ───────────────────────────────────────────────────────
    totalRides.value = lifeRides;
    totalDistanceKm.value = lifeDist;

    // Environmental equivalents
    final co2 = totalCo2Kg.value;
    fuelSavedLiters.value = co2 / 2.31; // 1 L petrol ≈ 2.31 kg CO₂
    carKmNotDriven.value = co2 / (Co2Utils.petrolFactor / 1000); // 120 g/km

    // ─── Streak ───────────────────────────────────────────────────────────────
    int streak = 0;
    for (int i = 0; i < 36; i++) {
      final mk = _mk(DateTime(now.year, now.month - i));
      if (activeMonths.contains(mk)) {
        streak++;
      } else {
        break;
      }
    }
    streakMonths.value = streak;

    // ─── Badges ───────────────────────────────────────────────────────────────
    badgeFirstRide.value = lifeRides >= 1;
    badgeTreeSaver.value = totalTrees.value >= 0.5;
    badgeCo2Saver.value = co2 >= 5.0;
    badgeEcoHero.value = co2 >= 25.0;

    // ─── Gamification ─────────────────────────────────────────────────────────
    final pts = (co2 * 100).round() + (lifeRides * 10);
    greenPoints.value = pts;

    if (pts < 500) {
      levelNumber.value = 1;
      levelName.value = 'Eco Starter';
      levelProgress.value = (pts / 500).clamp(0.0, 1.0);
      pointsToNextLevel.value = 500;
    } else if (pts < 2000) {
      levelNumber.value = 2;
      levelName.value = 'Green Commuter';
      levelProgress.value = ((pts - 500) / 1500).clamp(0.0, 1.0);
      pointsToNextLevel.value = 2000;
    } else if (pts < 5000) {
      levelNumber.value = 3;
      levelName.value = 'Earth Guardian';
      levelProgress.value = ((pts - 2000) / 3000).clamp(0.0, 1.0);
      pointsToNextLevel.value = 5000;
    } else {
      levelNumber.value = 4;
      levelName.value = 'Eco Champion';
      levelProgress.value = 1.0;
      pointsToNextLevel.value = 5000;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  String _mk(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}
