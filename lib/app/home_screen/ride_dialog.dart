import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:poolmate/app/wallet_screen/select_payment_method_screen.dart';
import 'package:poolmate/app/profile_screen/profile_screen.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/constant/send_notification.dart';
import 'package:poolmate/services/whatsapp_service.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/utils/fire_store_utils.dart';
import 'widgets/seat_widgets.dart';

// Enum to represent the different states a seat can be in
enum SeatStatus { available, unavailable, reservedForLadies, selected, driver }

// The main dialog widget, implemented as a StatefulWidget to manage state
class RideDialog extends StatefulWidget {
  final BookingModel bookingModel;
  final StopOverModel stopOverModel;

  const RideDialog({
    super.key,
    required this.bookingModel,
    required this.stopOverModel,
  });

  @override
  State<RideDialog> createState() => _RideDialogState();
}

class _RideDialogState extends State<RideDialog> {
  // Use a List to track multiple selected seats.
  final List<int> _selectedSeatIndices = [];

  // Initialize seat status based on actual booking data
  late List<SeatStatus> _seatStatus;

  // Loading state for booking process
  bool _isProcessingBooking = false;

  // Payment method selection
  String _selectedPaymentMethod = ''; // Empty initially, user must select

  @override
  void initState() {
    super.initState();
    _initializeSeatStatus();
    // This logic is kept in case you ever have seats pre-selected
    // in the _seatStatus list. It will find them and add them to the selection.
    for (int i = 0; i < _seatStatus.length; i++) {
      if (_seatStatus[i] == SeatStatus.selected) {
        _selectedSeatIndices.add(i);
      }
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

    _seatStatus = List.generate(totalSeats, (index) {
      // First seat is always driver
      if (index == 0) return SeatStatus.driver;

      // If the seat is already booked
      if (bookedSeats.contains(index)) {
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 8.0,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal:
            MediaQuery.of(context).size.width * 0.05, // 5% margin on each side
        vertical:
            MediaQuery.of(context).size.height * 0.1, // 10% margin top/bottom
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildDialogContent(context),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  // Builds the close button positioned at the top right corner
  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      right: -10.0,
      top: -10.0,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close, color: Colors.black),
        ),
      ),
    );
  }

  // Builds the main content of the dialog
  Widget _buildDialogContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
          const Divider(height: 32, thickness: 1),
          _buildSeatSelection(),
          const SizedBox(height: 24),
          _buildLegend(),
          // const SizedBox(height: 24),
          const Divider(height: 32, thickness: 1),
          _buildAdditionalRequirements(),
          _buildSummary(),
          const SizedBox(height: 24),
          _buildPaymentMethodSelection(),
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // Widget for displaying driver and car information
  Widget _buildDriverInfo() {
    return FutureBuilder(
      future: FireStoreUtils.getUserProfile(
          widget.bookingModel.createdBy.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userModel = snapshot.data;
        final vehicleInfo = widget.bookingModel.vehicleInformation;

        return Row(
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
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
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
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                            userModel?.reviewCount != null
                                ? (double.parse(userModel!.reviewSum ?? "0") /
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.directions_car, size: 28),
                const SizedBox(height: 4),
                Text(vehicleInfo?.licensePlatNumber ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                Text(
                    '${vehicleInfo?.vehicleBrand?.name ?? ''} ${vehicleInfo?.vehicleModel?.name ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black)),
              ],
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
          'Additional Requirements',
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
        const SizedBox(height: 20),
        // Dynamic seat layout based on actual seats
        _buildDynamicSeatLayout(),
      ],
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

    if (passengerSeats <= 4) {
      // For 4 or fewer passenger seats, use the original layout
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (passengerSeats >= 1)
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
          if (passengerSeats > 1) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  passengerSeats - 1, (index) => _buildSeat(index + 2)),
            ),
          ],
        ],
      );
    } else {
      // For more than 4 seats, use structured rows with driver row having 2 seats
      return Column(
        children: [
          // Driver row with 2 seats (driver + 1 passenger)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (passengerSeats >= 1)
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
          const SizedBox(height: 8),
          // Remaining passenger seats in rows of max 3
          ..._buildSeatRows(passengerSeats -
              1), // -1 because we already placed 1 passenger in driver row
        ],
      );
    }
  }

  // Helper method to build seat rows with max 3 seats per row
  List<Widget> _buildSeatRows(int totalSeats) {
    List<Widget> rows = [];
    int seatsPerRow = 3;

    for (int i = 0; i < totalSeats; i += seatsPerRow) {
      int seatsInThisRow =
          (i + seatsPerRow <= totalSeats) ? seatsPerRow : totalSeats - i;

      List<Widget> rowSeats = [];
      for (int j = 0; j < seatsInThisRow; j++) {
        rowSeats.add(_buildSeat(i +
            j +
            2)); // +2 to skip driver seat (0) and first passenger seat (1)
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rowSeats,
          ),
        ),
      );
    }

    return rows;
  }

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
      onTap: () {
        if (isAvailable) {
          // Add/remove from the list instead of setting a single variable.
          setState(() {
            if (isSelected) {
              _selectedSeatIndices.remove(index); // Deselect
            } else {
              _selectedSeatIndices.add(index); // Select
            }
          });
        }
      },
      child: SeatIcon(
        status: isSelected ? SeatStatus.selected : currentStatus,
        seatNumber: index, // Pass seat number (index is the seat number)
      ),
    );
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

  // Widget for the trip cost summary
  Widget _buildSummary() {
    // Get the number of seats from the list's length.
    final int numberOfSeats = _selectedSeatIndices.length;
    final double pricePerSeat =
        double.tryParse(widget.stopOverModel.price ?? '0') ?? 0.0;
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
            Text('${Constant.amountShow(amount: pricePerSeat.toString())}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Total payable amount: ',
                style: TextStyle(color: Colors.black)),
            Text('${Constant.amountShow(amount: totalAmount.toString())}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ],
    );
  }

  // Widget for the Back and Proceed to Pay buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          label: const Text('Back'),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        ElevatedButton(
          onPressed: _selectedSeatIndices.isEmpty ||
                  _selectedPaymentMethod.isEmpty ||
                  _isProcessingBooking
              ? null
              : _processBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: _isProcessingBooking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Proceed to pay', style: TextStyle(fontSize: 16)),
        ),
      ],
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
    Get.to(
      const SelectPaymentMethodScreen(),
      arguments: {"type": "bookingSelect", "amount": ""},
    )?.then((value) {
      if (value != null) {
        setState(() {
          _selectedPaymentMethod = value['paymentType'];
        });
      }
    });
  }

  // Complete booking processing method
  Future<void> _processBooking() async {
    if (_selectedSeatIndices.isEmpty) {
      ShowToastDialog.showToast("Please select at least one seat");
      return;
    }

    if (_selectedPaymentMethod.isEmpty) {
      ShowToastDialog.showToast("Please select payment method");
      return;
    }

    setState(() {
      _isProcessingBooking = true;
    });

    try {
      // Get current user
      UserModel? currentUser =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (currentUser == null) {
        ShowToastDialog.showToast("User not found");
        return;
      }

      // Check if ride requires verification and user is not verified
      if (widget.bookingModel.onlyVerifiedPassenger == true) {
        if (currentUser.isVerify != true) {
          setState(() {
            _isProcessingBooking = false;
          });
          _showVerificationRequiredDialog();
          return;
        }
      }

      // Check women only requirement
      if (widget.bookingModel.womenOnly == true) {
        if (currentUser.gender?.toLowerCase() != 'female' &&
            currentUser.gender?.toLowerCase() != 'woman') {
          setState(() {
            _isProcessingBooking = false;
          });
          ShowToastDialog.showToast("This ride is only for women");
          return;
        }
      }

      // Get publisher user
      UserModel? publisherUser = await FireStoreUtils.getUserProfile(
          widget.bookingModel.createdBy.toString());
      if (publisherUser == null) {
        ShowToastDialog.showToast("Driver not found");
        return;
      }

      // Check if user is already booked
      if (widget.bookingModel.bookedUserId!
          .contains(FireStoreUtils.getCurrentUid())) {
        ShowToastDialog.showToast("You have already booked this ride");
        return;
      }

      // Initialize lists if null
      if (widget.bookingModel.bookedUserId == null) {
        widget.bookingModel.bookedUserId = [];
      }

      // Add user to booked list
      widget.bookingModel.bookedUserId!.add(FireStoreUtils.getCurrentUid());

      // Update the bookedSeat field to store the actual seat numbers
      String currentBookedSeats = widget.bookingModel.bookedSeat ?? "";
      List<String> bookedSeatsList =
          currentBookedSeats.isEmpty ? [] : currentBookedSeats.split(',');

      // Add newly selected seats
      bookedSeatsList
          .addAll(_selectedSeatIndices.map((index) => index.toString()));

      // Update booked seats in booking model
      widget.bookingModel.bookedSeat = bookedSeatsList.join(',');

      // Create booking user model
      BookedUserModel bookingUserModel = BookedUserModel();
      bookingUserModel.id = FireStoreUtils.getCurrentUid();
      // Generate 6-digit OTP for trip verification
      final String otp =
          (100000 + (DateTime.now().microsecondsSinceEpoch % 900000))
              .toString()
              .substring(0, 6);
      bookingUserModel.otp = otp;
      // Store the actual seat numbers that were booked
      bookingUserModel.bookedSeat =
          _selectedSeatIndices.map((index) => index.toString()).join(',');
      bookingUserModel.paymentStatus = _selectedPaymentMethod.toLowerCase() ==
          'wallet'; // True if wallet, false if cash
      bookingUserModel.paymentType = _selectedPaymentMethod;
      bookingUserModel.stopOver = widget.stopOverModel;
      bookingUserModel.createdAt = Timestamp.now();
      // Convert CityModel to Location for BookedUserModel
      if (widget.bookingModel.pickupLocation != null &&
          widget.bookingModel.pickupLocation!.geometry?.location != null) {
        bookingUserModel.pickupLocation = Location(
          lat: widget.bookingModel.pickupLocation!.geometry!.location!.lat,
          lng: widget.bookingModel.pickupLocation!.geometry!.location!.lng,
        );
      }
      if (widget.bookingModel.dropLocation != null &&
          widget.bookingModel.dropLocation!.geometry?.location != null) {
        bookingUserModel.dropLocation = Location(
          lat: widget.bookingModel.dropLocation!.geometry!.location!.lat,
          lng: widget.bookingModel.dropLocation!.geometry!.location!.lng,
        );
      }
      bookingUserModel.adminCommission = Constant.adminCommission;
      bookingUserModel.taxList = Constant.taxList;

      // Calculate subtotal
      double pricePerSeat = double.parse(widget.stopOverModel.price ?? '0');
      double subtotal = pricePerSeat * _selectedSeatIndices.length;
      bookingUserModel.subTotal = subtotal.toString();

      ShowToastDialog.showLoader("Processing booking...");

      // Save user booking
      await FireStoreUtils.setUserBooking(
          widget.bookingModel, bookingUserModel);

      // Send notification to driver
      await SendNotification.sendOneNotification(
        type: Constant.booking_confirmed,
        token: publisherUser.fcmToken.toString(),
        payload: {},
      );

      // Send WhatsApp notifications
      // Get current user profile for phone number
      UserModel? currentUserphone =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());

      // To passenger: booking confirmed
      if (currentUserphone?.phoneNumber != null) {
        await WhatsAppService.sendRiderBookingConfirmed(
          phoneNumber: currentUserphone!.phoneNumber!,
        );
      }

      // To driver: seat booked
      if (publisherUser.phoneNumber != null) {
        await WhatsAppService.sendDriverSeatBook(
          phoneNumber: publisherUser.phoneNumber!,
        );
      }

      // Update main booking
      await FireStoreUtils.setBooking(widget.bookingModel);

      ShowToastDialog.closeLoader();

      // Show success message
      ShowToastDialog.showToast("Booking confirmed successfully!");

      // Close dialog
      Navigator.of(context)
          .pop(true); // Return true to indicate successful booking
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error processing booking: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBooking = false;
        });
      }
    }
  }

  // Show verification required dialog
  void _showVerificationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Verification Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This ride requires verified passengers only.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please verify yourself first by uploading your documents to book this ride.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to profile screen for verification
                Get.to(const ProfileScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Verify Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
