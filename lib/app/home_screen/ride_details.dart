import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:poolmate/app/booking/booking_payment_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'widgets/seat_widgets.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/firestore/auth_utils.dart';

import 'package:poolmate/app/home_screen/passenger_names_screen.dart';
import 'package:poolmate/controller/booking_payment_controller.dart';

// Enum to represent the different states a seat can be in
enum SeatStatus { available, unavailable, reservedForLadies, selected, driver }

// The main page widget, implemented as a StatefulWidget to manage state
class RidePage extends StatefulWidget {
  final BookingModel bookingModel;
  final StopOverModel stopOverModel;

  const RidePage({
    super.key,
    required this.bookingModel,
    required this.stopOverModel,
  });

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> with WidgetsBindingObserver {
  // Use a List to track multiple selected seats.
  final List<int> _selectedSeatIndices = [];

  final controller = Get.put(BookingPaymentController());

  // Initialize seat status based on actual booking data
  late List<SeatStatus> _seatStatus;

  // Payment method selection
  String _selectedPaymentMethod = ''; // Empty initially, user must select
  bool _isPaymentCompleted =
      false; // Track if payment was successfully completed

  // Firebase listener for real-time updates
  StreamSubscription<DocumentSnapshot>? _bookingListener;

  // Store temporarily selected seats with timestamps for cleanup
  final Map<int, DateTime> _tempSeatTimestamps = {};

  // Timer for periodic cleanup of expired temp selections
  Timer? _cleanupTimer;

  // Store remaining seconds for each selected seat
  final Map<int, int> _seatRemainingSeconds = {};

  // ValueNotifier to update only timer display without rebuilding entire widget
  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(0);
  Timer? _countdownTimer;

  // Store passenger names for each seat
  Map<int, String?>? _passengerNames;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.bookingModel.value = widget.bookingModel;
      controller.stopOverModel.value = widget.stopOverModel;
    });
    WidgetsBinding.instance.addObserver(this);
    _initializeSeatStatus();
    _setupRealtimeListener();
    _startCleanupTimer();
    _startCountdownTimer();

    // This logic is kept in case you ever have seats pre-selected
    // in the _seatStatus list. It will find them and add them to the selection.
    for (int i = 0; i < _seatStatus.length; i++) {
      if (_seatStatus[i] == SeatStatus.selected) {
        _selectedSeatIndices.add(i);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bookingListener?.cancel();
    _cleanupTimer?.cancel();
    _countdownTimer?.cancel();
    _timerNotifier.dispose();
    _releaseTemporarySeats();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Release seats when app goes to background (minimized) or inactive
    // if (state == AppLifecycleState.paused ||
    //     state == AppLifecycleState.inactive) {
    //   print('🔴 App going to background - releasing temporary seats');
    //   // Do not pop explicitly; let the user decide or timer expire
    //   // Navigator.of(context).pop();
    // }
  }

  // Setup real-time listener for booking changes
  void _setupRealtimeListener() {
    if (widget.bookingModel.id == null) return;

    // Initialize tempSeatSelection field if it doesn't exist
    _initializeTempSeatSelection();

    _bookingListener = FirebaseFirestore.instance
        .collection('booking')
        .doc(widget.bookingModel.id)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      // Update booking model with latest data
      widget.bookingModel.bookedSeat = data['bookedSeat'];
      widget.bookingModel.tempSeatSelection = data['tempSeatSelection'] != null
          ? List<int>.from(data['tempSeatSelection'])
          : [];

      // Refresh seat status based on new data
      setState(() {
        _initializeSeatStatus();
      });
    });
  }

  // Initialize tempSeatSelection field if it doesn't exist
  Future<void> _initializeTempSeatSelection() async {
    if (widget.bookingModel.id == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingModel.id);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['tempSeatSelection'] == null) {
          // Field doesn't exist, initialize it
          await docRef.update({'tempSeatSelection': []});
          print(
              '✅ Initialized tempSeatSelection field for booking ${widget.bookingModel.id}');
        }
      }
    } catch (e) {
      print('Note: Could not initialize tempSeatSelection: $e');
      // Non-critical error, continue anyway
    }
  }

  // Start periodic timer to cleanup expired temporary selections
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cleanupExpiredTempSeats();
    });
  }

  // Start countdown timer for seat reservation display
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      int minRemainingSeconds = 5 * 60;
      bool hasExpiredSeats = false;

      // Update remaining seconds for each selected seat
      for (var seatIndex in _selectedSeatIndices) {
        if (_tempSeatTimestamps.containsKey(seatIndex)) {
          final elapsed = now.difference(_tempSeatTimestamps[seatIndex]!);
          final remainingSeconds = (5 * 60) - elapsed.inSeconds;

          if (remainingSeconds > 0) {
            _seatRemainingSeconds[seatIndex] = remainingSeconds;
            if (remainingSeconds < minRemainingSeconds) {
              minRemainingSeconds = remainingSeconds;
            }
          } else {
            // Time expired
            _seatRemainingSeconds[seatIndex] = 0;
            hasExpiredSeats = true;
          }
        }
      }

      // Only update the timer notifier, not the entire widget
      _timerNotifier.value = minRemainingSeconds;

      // If any seat has expired (timer reached 0), close the dialog
      if (hasExpiredSeats ||
          (minRemainingSeconds <= 0 && _selectedSeatIndices.isNotEmpty)) {
        timer.cancel();
        ShowToastDialog.showToast(
            'Seat reservation time expired. Please try again.');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  // Cleanup expired temporary seat selections (older than 5 minutes)
  Future<void> _cleanupExpiredTempSeats() async {
    if (widget.bookingModel.id == null) return;

    final now = DateTime.now();
    final expiredSeats = <int>[];

    // Find expired seats from our local tracking
    _tempSeatTimestamps.forEach((seatIndex, timestamp) {
      if (now.difference(timestamp).inMinutes >= 5) {
        expiredSeats.add(seatIndex);
      }
    });

    if (expiredSeats.isEmpty) return;

    // Remove expired seats from Firebase
    try {
      final docRef = FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingModel.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentTempSeats =
            List<int>.from(snapshot.data()?['tempSeatSelection'] ?? []);

        // Remove expired seats
        currentTempSeats.removeWhere((seat) => expiredSeats.contains(seat));

        transaction.update(docRef, {
          'tempSeatSelection': currentTempSeats,
        });
      });

      // Clean local tracking
      for (var seat in expiredSeats) {
        _tempSeatTimestamps.remove(seat);
      }
    } catch (e) {
      print('Error cleaning up expired seats: $e');
    }
  }

  // Release temporary seats when dialog closes
  Future<void> _releaseTemporarySeats() async {
    if (_selectedSeatIndices.isEmpty || widget.bookingModel.id == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingModel.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentTempSeats =
            List<int>.from(snapshot.data()?['tempSeatSelection'] ?? []);

        // Remove this user's selected seats
        currentTempSeats
            .removeWhere((seat) => _selectedSeatIndices.contains(seat));

        transaction.update(docRef, {
          'tempSeatSelection': currentTempSeats,
        });
      });
    } catch (e) {
      print('Error releasing temporary seats: $e');
    }
  }

  void _initializeSeatStatus() {
    // Get total seats from vehicle information
    final totalSeats = int.tryParse(
            widget.bookingModel.vehicleInformation?.seatCount ?? '0') ??
        0;

    // Get selected seats and already booked seats
    final allowedSeats = widget.bookingModel.selectedSeats ?? [];
    final bookedSeats = (widget.bookingModel.bookedSeat ?? "0")
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? -1)
        .toList();

    // Get temporarily selected seats by other users
    final tempSelectedSeats = widget.bookingModel.tempSeatSelection ?? [];

    _seatStatus = List.generate(totalSeats, (index) {
      // First seat is always driver
      if (index == 0) return SeatStatus.driver;

      // If the seat is already booked
      if (bookedSeats.contains(index)) {
        return SeatStatus.unavailable;
      }

      // If seat is temporarily selected by another user (not by current user)
      if (tempSelectedSeats.contains(index) &&
          !_selectedSeatIndices.contains(index)) {
        return SeatStatus.unavailable;
      }

      // If seat is in the allowed seats list
      if (allowedSeats.contains(index.toString())) {
        return SeatStatus.available;
      }

      // All other seats are unavailable
      return SeatStatus.unavailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride Details',
          style: TextStyle(fontFamily: AppThemeData.semiBold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _buildDialogContent(context),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: _buildActionButtons(context),
        ),
      ),
    );
  }

  // Builds the main content of the dialog
  Widget _buildDialogContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your trip preview',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          _buildDriverInfo(),
          const Divider(height: 22, thickness: 1),
          _buildSeatSelection(),
          const SizedBox(height: 24),
          _buildLegend(),
          // const SizedBox(height: 24),
          const Divider(height: 32, thickness: 1),
          _buildAdditionalRequirements(),
          _buildSummary(),
          const SizedBox(height: 24),
          // _buildPaymentMethodSelection(),
          // const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Widget for displaying driver and car information
  Widget _buildDriverInfo() {
    return FutureBuilder<UserModel?>(
      future:
          UserUtils.getUserProfile(widget.bookingModel.createdBy.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userModel = snapshot.data;
        final vehicleInfo = widget.bookingModel.vehicleInformation;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black,
                      backgroundImage: userModel?.profilePic != null &&
                              userModel!.profilePic!.isNotEmpty
                          ? NetworkImage(userModel.profilePic!)
                          : null,
                      child: userModel?.profilePic == null ||
                              userModel!.profilePic!.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userModel?.fullName() ?? 'Driver',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                                userModel?.reviewCount != null
                                    ? (double.parse(
                                                userModel!.reviewSum ?? "0") /
                                            double.parse(
                                                userModel.reviewCount ?? "1"))
                                        .toStringAsFixed(1)
                                    : '0',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(vehicleInfo?.licensePlatNumber ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${vehicleInfo?.vehicleBrand?.name ?? ''} ${vehicleInfo?.vehicleModel?.name ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget for displaying additional requirements if any
  Widget _buildAdditionalRequirements() {
    // Check if there are any additional requirements
    final additionalRequirements = widget.bookingModel.additionalRequirements;

    if (additionalRequirements == null ||
        additionalRequirements.trim().isEmpty) {
      return const SizedBox.shrink(); // Return empty widget if no requirements
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.amber.shade200,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  additionalRequirements,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 16, thickness: 1),
      ],
    );
  }

  // Widget for the seat selection section
  Widget _buildSeatSelection() {
    // Count only the seats that are selected in the booking and not yet booked
    final availableSeats =
        _seatStatus.where((status) => status == SeatStatus.available).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select your preferred seat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            const Spacer(),
            Text(
              '$availableSeats seats available',
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        // Display timer if seats are selected
        if (_selectedSeatIndices.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTimerDisplay(),
        ],
        const SizedBox(height: 20),
        // Dynamic seat layout based on actual seats
        _buildDynamicSeatLayout(),
      ],
    );
  }

  // Widget to display the countdown timer for seat reservation
  Widget _buildTimerDisplay() {
    return ValueListenableBuilder<int>(
      valueListenable: _timerNotifier,
      builder: (context, minRemainingSeconds, child) {
        final minutes = minRemainingSeconds ~/ 60;
        final seconds = minRemainingSeconds % 60;

        // Determine color based on remaining time
        Color timerColor;
        Color backgroundColor;
        if (minRemainingSeconds < 60) {
          // Less than 1 minute - red (urgent)
          timerColor = Colors.red;
          backgroundColor = Colors.red.shade50;
        } else if (minRemainingSeconds < 120) {
          // Less than 2 minutes - orange (warning)
          timerColor = Colors.orange;
          backgroundColor = Colors.orange.shade50;
        } else {
          // More than 2 minutes - green (safe)
          timerColor = Colors.green;
          backgroundColor = Colors.green.shade50;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: timerColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: timerColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seat reserved for',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 24,
                        color: timerColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (minRemainingSeconds < 60)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HURRY!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicSeatLayout() {
    // Guard against empty seat status
    if (_seatStatus.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No seats available'),
        ),
      );
    }

    // _seatStatus.length is the total seats including driver
    final totalSeatsIncludingDriver = _seatStatus.length;
    // Calculate passenger seats (excluding driver)
    final passengerSeats =
        totalSeatsIncludingDriver - 1; // Always exclude driver in ride dialog

    if (passengerSeats <= 0) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Invalid seat configuration'),
        ),
      );
    }

    // Only three supported configurations: 2-seater, 5-seater and 7-seater
    if (passengerSeats == 1) {
      // 2-seater (driver + 1 passenger)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Column(
                children: [
                  const Icon(Icons.drive_eta_outlined,
                      size: 32, color: Colors.black54),
                  const SizedBox(height: 4),
                  _buildSeat(0),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5.0, right: 15, left: 15),
                child: SizedBox(
                  width: 100,
                  child: Divider(
                    color: Colors.black54,
                    height: 12,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: _buildSeat(1),
              ),
            ],
          )
        ],
      );
    } else if (passengerSeats == 4) {
      // 5-seater (driver + 4 passengers)
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 36.0),
                child: _buildSeat(1),
              ),
              const SizedBox(width: 15),
              Column(
                children: [
                  const Icon(Icons.drive_eta_outlined,
                      size: 32, color: Colors.black54),
                  const SizedBox(height: 4),
                  _buildSeat(0),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeat(2),
              _buildSeat(3),
              _buildSeat(4),
            ],
          ),
        ],
      );
    } else if (passengerSeats == 6) {
      // 7-seater (driver + 6 passengers)
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 36.0),
                child: _buildSeat(1),
              ),
              const SizedBox(width: 15),
              Column(
                children: [
                  const Icon(Icons.drive_eta_outlined,
                      size: 32, color: Colors.black54),
                  const SizedBox(height: 4),
                  _buildSeat(0),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeat(2),
              _buildSeat(3),
              _buildSeat(4),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeat(5),
              _buildSeat(6),
            ],
          ),
        ],
      );
    }

    // Unsupported seat configuration
    return const SizedBox(
      height: 100,
      child: Center(
        child: Text('Unsupported seat configuration'),
      ),
    );
  }

  // No generic rows builder needed with fixed 2/5/7 seater layouts

  // Builds a single seat widget with tap detection
  Widget _buildSeat(int index) {
    SeatStatus currentStatus = _seatStatus[index];
    // Check if the seat index is in our list.
    bool isSelected = _selectedSeatIndices.contains(index);
    bool isAvailable = currentStatus == SeatStatus.available;

    // An unavailable seat should not be selectable.
    if (currentStatus == SeatStatus.unavailable ||
        currentStatus == SeatStatus.driver) {
      return SeatIcon(
        status: currentStatus,
        seatNumber: index, // Pass seat number (index is the seat number)
      );
    }

    return GestureDetector(
      onTap: () async {
        if (isAvailable) {
          if (isSelected) {
            // Deselecting - remove from local list and Firebase
            await _deselectSeat(index);
          } else {
            // Selecting - use transaction to ensure atomicity
            await _selectSeatWithTransaction(index);
          }
        }
      },
      child: SeatIcon(
        status: isSelected ? SeatStatus.selected : currentStatus,
        seatNumber: index, // Pass seat number (index is the seat number)
      ),
    );
  }

  // Select seat using Firebase Transaction to prevent race conditions
  Future<void> _selectSeatWithTransaction(int seatIndex) async {
    if (widget.bookingModel.id == null) {
      print('Error: Booking ID is null');
      ShowToastDialog.showToast('Booking ID not found');
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingModel.id);

      print(
          'Attempting to select seat $seatIndex for booking ${widget.bookingModel.id}');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Booking not found');
        }

        final data = snapshot.data();
        if (data == null) {
          throw Exception('Booking data is null');
        }

        print('Current booking data: ${data.keys.toList()}');

        // Get current temp seats with null safety
        List<int> currentTempSeats = [];
        if (data['tempSeatSelection'] != null) {
          try {
            currentTempSeats = List<int>.from(data['tempSeatSelection']);
          } catch (e) {
            print('Error parsing tempSeatSelection: $e');
            currentTempSeats = [];
          }
        }

        // Get booked seats
        final bookedSeatsString = data['bookedSeat'] ?? "0";
        final List<int> bookedSeats = bookedSeatsString
            .toString()
            .split(',')
            .where((String s) => s.isNotEmpty)
            .map((String s) => int.tryParse(s) ?? -1)
            .toList();

        print('Current temp seats: $currentTempSeats');
        print('Booked seats: $bookedSeats');

        // Check if seat is already booked
        if (bookedSeats.contains(seatIndex)) {
          throw Exception('This seat is already booked');
        }

        // Check if seat is already in temp selection by another user
        if (currentTempSeats.contains(seatIndex)) {
          throw Exception('This seat was just selected by another user');
        }

        // Add seat to temp selection
        currentTempSeats.add(seatIndex);

        print('Updating tempSeatSelection to: $currentTempSeats');

        // Update Firebase
        transaction.update(docRef, {
          'tempSeatSelection': currentTempSeats,
        });
      });

      // Transaction successful - update local state
      setState(() {
        _selectedSeatIndices.add(seatIndex);
        _tempSeatTimestamps[seatIndex] = DateTime.now();
        _seatRemainingSeconds[seatIndex] = 5 * 60; // 5 minutes in seconds
      });

      // Update timer notifier to trigger timer display
      _timerNotifier.value = 5 * 60;

      print('✅ Seat $seatIndex selected successfully');
    } catch (e) {
      // Show error message to user
      print('❌ Error selecting seat $seatIndex: $e');

      if (e.toString().contains('just selected by another user')) {
        ShowToastDialog.showToast(
            'This seat was just selected by another user. Please choose a different seat.');
      } else if (e.toString().contains('already booked')) {
        ShowToastDialog.showToast('This seat is already booked');
      } else if (e.toString().contains('Booking not found')) {
        ShowToastDialog.showToast(
            'Booking not found. Please refresh and try again.');
      } else {
        ShowToastDialog.showToast('Error: ${e.toString()}');
      }
    }
  }

  // Deselect seat and remove from Firebase
  Future<void> _deselectSeat(int seatIndex) async {
    if (widget.bookingModel.id == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.bookingModel.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) return;

        final currentTempSeats =
            List<int>.from(snapshot.data()?['tempSeatSelection'] ?? []);

        // Remove seat from temp selection
        currentTempSeats.remove(seatIndex);

        transaction.update(docRef, {
          'tempSeatSelection': currentTempSeats,
        });
      });

      // Update local state
      setState(() {
        _selectedSeatIndices.remove(seatIndex);
        _tempSeatTimestamps.remove(seatIndex);
        _seatRemainingSeconds.remove(seatIndex);
      });

      print('Seat $seatIndex deselected successfully');
    } catch (e) {
      print('Error deselecting seat: $e');
    }
  }

  // Widget for the color-coded legend
  Widget _buildLegend() {
    return Column(
      children: const [
        LegendItem(color: Colors.black, text: 'Not available'),
        SizedBox(height: 8),
        LegendItem(color: Colors.white, text: 'Available'),
        SizedBox(height: 8),
        LegendItem(color: Colors.pinkAccent, text: 'Reserved for Ladies'),
      ],
    );
  }

  // Helper method to determine if this is a full route booking
  // Compares the stopOverModel locations with the booking's main pickup/drop locations

  // Widget for the trip cost summary
  Widget _buildSummary() {
    // Get the number of seats from the list's length.
    final int numberOfSeats = _selectedSeatIndices.length;

    controller.bookingModel.value = widget.bookingModel;
    controller.stopOverModel.value = widget.stopOverModel;
    // Use the helper method to get the correct price
    final double pricePerSeat = controller.getCorrectPrice();
    final double totalAmount = numberOfSeats * pricePerSeat;

    return Column(
      children: [
        Row(
          children: [
            const Text('Selected number of seats: ',
                style: TextStyle(color: Colors.black)),
            Text('$numberOfSeats',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Price per seat: ',
                style: TextStyle(color: Colors.black)),
            Text(Constant.amountShow(amount: pricePerSeat.toString()),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Total payable amount: ',
                style: TextStyle(color: Colors.black)),
            Text(Constant.amountShow(amount: totalAmount.toString()),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ],
    );
  }

  // Widget for the Back and Proceed to Pay buttons
  Widget _buildActionButtons(BuildContext context) {
    final bool canBook = _selectedSeatIndices.isNotEmpty;
    return ElevatedButton(
      onPressed: canBook
          ? () {
              // Check if user is already booked
              if (widget.bookingModel.bookedUserId != null &&
                  widget.bookingModel.bookedUserId!
                      .contains(AuthUtils.getCurrentUid())) {
                ShowToastDialog.showToast("You have already booked this ride");
                return;
              }
              // Calculate booking details
              final int numberOfSeats = _selectedSeatIndices.length;
              controller.bookingModel.value = widget.bookingModel;
              controller.stopOverModel.value = widget.stopOverModel;
              final double pricePerSeat = controller.getCorrectPrice();
              final double totalAmount = pricePerSeat * numberOfSeats;

              // Navigate to passenger names screen
              Get.to(
                PassengerNamesScreen(
                  selectedSeatIndices: _selectedSeatIndices,
                  numberOfSeats: numberOfSeats,
                  pricePerSeat: pricePerSeat,
                  totalAmount: totalAmount,
                  bookingId: widget.bookingModel.id ?? '',
                  driverPaymentMethod: widget.bookingModel.driverPaymentMethod,
                ),
              )?.then((result) {
                // Handle result from passenger names + payment screen
                if (result != null) {
                  // Store passenger names
                  if (result['passengerNames'] != null) {
                    final passengerNamesData = result['passengerNames'];
                    if (passengerNamesData is Map) {
                      // Convert to Map<int, String?>
                      setState(() {
                        _passengerNames = passengerNamesData.map(
                          (key, value) => MapEntry(
                            key is int ? key : int.parse(key.toString()),
                            value as String?,
                          ),
                        );
                      });
                    }
                  }

                  // Store payment method and status
                  setState(() {
                    _selectedPaymentMethod = result['paymentType'] ?? '';
                    _isPaymentCompleted = result['paymentSuccess'] == true;
                  });

                  // If payment was successful, proceed with booking
                  if (result['paymentSuccess'] == true) {
                    // Update controller state
                    controller.bookingModel.value = widget.bookingModel;
                    controller.selectedSeatIndices.value = _selectedSeatIndices;
                    controller.passengerNames.value = _passengerNames ?? {};
                    controller.stopOverModel.value = widget.stopOverModel;

                    controller.processBooking(_selectedPaymentMethod);
                  }
                }
              });
            }
          : () {
              ShowToastDialog.showToast("Please select at least one seat");
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: canBook ? Colors.black : Colors.grey,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
      ),
      child: Text('Proceed to Book',
          style: TextStyle(fontSize: 18, fontFamily: AppThemeData.semiBold)),
    );
  }

  // Widget for payment method selection
  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            _selectPaymentMethod();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPaymentMethod.isEmpty
                            ? "Select Payment Method"
                            : _selectedPaymentMethod,
                        style: TextStyle(
                          color: _selectedPaymentMethod.isEmpty
                              ? Colors.grey.shade600
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedPaymentMethod.isEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "You will be charged after ride",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_selectedPaymentMethod.isNotEmpty &&
                          !_isPaymentCompleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Payment not completed yet",
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (_selectedPaymentMethod.isNotEmpty &&
                          _isPaymentCompleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Payment completed successfully",
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to handle payment method selection
  void _selectPaymentMethod() {
    // Check driver's payment preference
    String? driverPaymentMethod = widget.bookingModel.driverPaymentMethod;

    if (driverPaymentMethod != null && driverPaymentMethod.isNotEmpty) {
      // Driver has set a payment preference, restrict passenger options
      if (driverPaymentMethod == "Cash") {
        // Driver prefers cash, only allow cash
        setState(() {
          _selectedPaymentMethod = "Cash";
          _isPaymentCompleted =
              true; // Cash payment doesn't require upfront completion
        });
        ShowToastDialog.showToast("This driver only accepts cash payments");
        return;
      } else if (driverPaymentMethod == "Online") {
        // Driver prefers online, go to payment method selection but restrict to online options
        // Calculate total amount for payment
        final int numberOfSeats = _selectedSeatIndices.length;
        controller.bookingModel.value = widget.bookingModel;
        controller.stopOverModel.value = widget.stopOverModel;
        final double pricePerSeat = controller.getCorrectPrice();
        final double totalAmount = numberOfSeats * pricePerSeat;

        Get.to(
          const BookingPaymentScreen(),
          arguments: {
            "numberOfSeats": numberOfSeats,
            "pricePerSeat": pricePerSeat.toString(),
            "totalAmount": totalAmount.toString(),
            "bookingId": widget.bookingModel.id,
            "driverPaymentMethod": "Online",
          },
        )?.then((value) {
          if (value != null) {
            setState(() {
              _selectedPaymentMethod = value['paymentType'];
              _isPaymentCompleted = value['paymentSuccess'] == true;
            });

            // If payment was successful, proceed with booking automatically
            if (value['paymentSuccess'] == true) {
              controller.bookingModel.value = widget.bookingModel;
              controller.selectedSeatIndices.value = _selectedSeatIndices;
              controller.passengerNames.value = _passengerNames ?? {};
              controller.stopOverModel.value = widget.stopOverModel;
              controller.isPaymentCompleted.value = _isPaymentCompleted;
              controller.processBooking(_selectedPaymentMethod);
            }
          }
        });
        return;
      }
    }

    // No driver preference set, allow all payment methods
    // Calculate total amount for payment
    final int numberOfSeats = _selectedSeatIndices.length;
    controller.bookingModel.value = widget.bookingModel;
    controller.stopOverModel.value = widget.stopOverModel;
    final double pricePerSeat = controller.getCorrectPrice();
    final double totalAmount = numberOfSeats * pricePerSeat;

    controller.numberOfSeats.value = numberOfSeats;
    controller.pricePerSeat.value = pricePerSeat;
    controller.totalAmount.value = totalAmount;

    Get.to(
      const BookingPaymentScreen(),
      arguments: {
        "numberOfSeats": numberOfSeats,
        "pricePerSeat": pricePerSeat.toString(),
        "totalAmount": totalAmount.toString(),
        "bookingId": widget.bookingModel.id,
        "driverPaymentMethod": driverPaymentMethod,
      },
    )?.then((value) {
      if (value != null) {
        setState(() {
          _selectedPaymentMethod = value['paymentType'];
          _isPaymentCompleted = value['paymentSuccess'] == true;
        });

        if (value['paymentSuccess'] == true) {
          controller.bookingModel.value = widget.bookingModel;
          controller.selectedSeatIndices.value = _selectedSeatIndices;
          controller.passengerNames.value = _passengerNames ?? {};
          controller.stopOverModel.value = widget.stopOverModel;
          controller.isPaymentCompleted.value = _isPaymentCompleted;
          controller.processBooking(_selectedPaymentMethod);
        }
      }
    });
  }
}
