import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/app/booking/booking_payment_screen.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/booking_payment_controller.dart';

class PassengerNamesScreen extends StatefulWidget {
  final List<int> selectedSeatIndices;
  final Function(Map<int, String?>)? onPassengerNamesSubmitted;

  // Booking details needed for payment screen
  final int numberOfSeats;
  final double pricePerSeat;
  final double totalAmount;
  final String bookingId;
  final String? driverPaymentMethod;

  const PassengerNamesScreen({
    super.key,
    required this.selectedSeatIndices,
    this.onPassengerNamesSubmitted,
    required this.numberOfSeats,
    required this.pricePerSeat,
    required this.totalAmount,
    required this.bookingId,
    this.driverPaymentMethod,
  });

  @override
  State<PassengerNamesScreen> createState() => _PassengerNamesScreenState();
}

class _PassengerNamesScreenState extends State<PassengerNamesScreen> {
  // Map to store passenger names for each seat index
  final Map<int, String> _passengerNames = {};
  // Map to store TextEditingControllers for each seat index
  final Map<int, TextEditingController> _controllers = {};
  // Map to store whether each field is enabled
  final Map<int, bool> _fieldEnabled = {};
  // Map to track validation errors for each seat
  final Map<int, bool> _hasError = {};

  // New: Map to store passenger genders
  final Map<int, String> _passengerGenders = {};
  // New: Map to store passenger ages
  final Map<int, int?> _passengerAges = {};
  // Map to store age TextEditingControllers
  final Map<int, TextEditingController> _ageControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize all fields as enabled by default
    for (int seatIndex in widget.selectedSeatIndices) {
      _fieldEnabled[seatIndex] = true;
      _passengerNames[seatIndex] = '';
      _passengerGenders[seatIndex] = 'Male'; // Default gender
      _passengerAges[seatIndex] = null;
      _controllers[seatIndex] = TextEditingController();
      _ageControllers[seatIndex] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _ageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper method to format seat number to row-letter scheme
  String _formatSeatNumber(int seatIndex) {
    const List<String> labels = [
      'A1',
      'A2',
      'B1',
      'B2',
      'B3',
      'C1',
      'C2',
      'C3'
    ];
    if (seatIndex >= 0 && seatIndex < labels.length) {
      return labels[seatIndex];
    }
    return 'S$seatIndex';
  }

  void _handleSubmit() {
    // Clear previous errors
    setState(() {
      _hasError.clear();
    });

    // Validate: If field is enabled, name and age must be provided
    List<String> missingNames = [];
    List<String> missingAges = [];
    Map<int, bool> newErrors = {};

    for (int seatIndex in widget.selectedSeatIndices) {
      if (_fieldEnabled[seatIndex] == true) {
        final name = _passengerNames[seatIndex]?.trim() ?? '';
        final age = _passengerAges[seatIndex];

        if (name.isEmpty) {
          final seatLabel = _formatSeatNumber(seatIndex);
          missingNames.add(seatLabel);
          newErrors[seatIndex] = true;
        }

        if (age == null || age <= 0) {
          final seatLabel = _formatSeatNumber(seatIndex);
          if (!missingAges.contains(seatLabel)) {
            missingAges.add(seatLabel);
          }
          newErrors[seatIndex] = true;
        }
      }
    }

    // Update error state and show error message if validation fails
    if (missingNames.isNotEmpty || missingAges.isNotEmpty) {
      setState(() {
        _hasError.addAll(newErrors);
      });

      String errorMessage = '';
      if (missingNames.isNotEmpty) {
        errorMessage =
            'Please enter passenger name for seat${missingNames.length > 1 ? 's' : ''} ${missingNames.join(', ')}';
      }
      if (missingAges.isNotEmpty) {
        if (errorMessage.isNotEmpty) errorMessage += '\n';
        errorMessage +=
            'Please enter age for seat${missingAges.length > 1 ? 's' : ''} ${missingAges.join(', ')}';
      }

      ShowToastDialog.showToast(errorMessage);
      return;
    }

    // Prepare the passenger data maps
    Map<int, String?> passengerNamesResult = {};
    Map<int, String?> passengerGendersResult = {};
    Map<int, int?> passengerAgesResult = {};

    for (int seatIndex in widget.selectedSeatIndices) {
      // If field is enabled, include the data
      // If field is disabled, set to null
      if (_fieldEnabled[seatIndex] == true) {
        passengerNamesResult[seatIndex] = _passengerNames[seatIndex]?.trim();
        passengerGendersResult[seatIndex] = _passengerGenders[seatIndex];
        passengerAgesResult[seatIndex] = _passengerAges[seatIndex];
      } else {
        passengerNamesResult[seatIndex] = null;
        passengerGendersResult[seatIndex] = null;
        passengerAgesResult[seatIndex] = null;
      }
    }

    // Update controller values before navigation
    final controller = Get.find<BookingPaymentController>();
    controller.numberOfSeats.value = widget.numberOfSeats;
    controller.pricePerSeat.value = widget.pricePerSeat;
    controller.totalAmount.value = widget.totalAmount;
    // Pass passenger data to controller
    controller.passengerNames.value = passengerNamesResult;
    controller.passengerGenders.value = passengerGendersResult;
    controller.passengerAges.value = passengerAgesResult;
    controller.selectedSeatIndices.value = widget.selectedSeatIndices;

    // Navigate to payment screen
    Get.to(
      const BookingPaymentScreen(),
      arguments: {
        "numberOfSeats": widget.numberOfSeats,
        "pricePerSeat": widget.pricePerSeat.toString(),
        "totalAmount": widget.totalAmount.toString(),
        "bookingId": widget.bookingId,
        "driverPaymentMethod": widget.driverPaymentMethod ?? "",
      },
    )?.then((paymentResult) {
      // When payment is done, return both passenger data and payment result
      if (paymentResult != null) {
        // Combine passenger data with payment result
        Map<String, dynamic> combinedResult = {
          ...paymentResult,
          'passengerNames': passengerNamesResult,
          'passengerGenders': passengerGendersResult,
          'passengerAges': passengerAgesResult,
        };
        Navigator.of(context).pop(combinedResult);
      } else {
        // If payment was cancelled, just return passenger data
        Navigator.of(context).pop({
          'passengerNames': passengerNamesResult,
          'passengerGenders': passengerGendersResult,
          'passengerAges': passengerAgesResult,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Passenger Details',
          style: TextStyle(fontFamily: AppThemeData.semiBold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter passenger details for each seat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide name, gender, and age for each passenger.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Build form fields for each selected seat
                  ...widget.selectedSeatIndices.map((seatIndex) {
                    final seatLabel = _formatSeatNumber(seatIndex);
                    final isEnabled = _fieldEnabled[seatIndex] ?? true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasError[seatIndex] == true
                              ? Colors.red.shade300
                              : Colors.grey.shade300,
                          width: _hasError[seatIndex] == true ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Seat $seatLabel',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    isEnabled ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isEnabled
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CupertinoSwitch(
                                    value: isEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _fieldEnabled[seatIndex] = value;
                                        // Clear the data and error when disabled
                                        if (!value) {
                                          _passengerNames[seatIndex] = '';
                                          _passengerGenders[seatIndex] = 'Male';
                                          _passengerAges[seatIndex] = null;
                                          _controllers[seatIndex]?.clear();
                                          _ageControllers[seatIndex]?.clear();
                                          _hasError.remove(seatIndex);
                                        }
                                      });
                                    },
                                    activeTrackColor: Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isEnabled) ...[
                            const SizedBox(height: 16),

                            // Passenger Name Field
                            TextField(
                              enabled: isEnabled,
                              decoration: InputDecoration(
                                labelText: 'Passenger Name',
                                hintText: 'Enter full name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              controller: _controllers[seatIndex],
                              onChanged: (value) {
                                setState(() {
                                  _passengerNames[seatIndex] = value;
                                  if (_hasError[seatIndex] == true &&
                                      value.trim().isNotEmpty) {
                                    _hasError.remove(seatIndex);
                                  }
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            // Gender and Age Row
                            Row(
                              children: [
                                // Gender Dropdown
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gender',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade400),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _passengerGenders[seatIndex] ??
                                              'Male',
                                          decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            border: InputBorder.none,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'Male',
                                                child: Text('Male')),
                                            DropdownMenuItem(
                                                value: 'Female',
                                                child: Text('Female')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _passengerGenders[seatIndex] =
                                                  value ?? 'Male';
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Age Field
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Age',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _ageControllers[seatIndex],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Age',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade400),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.black, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _passengerAges[seatIndex] =
                                                int.tryParse(value);
                                            if (_hasError[seatIndex] == true &&
                                                value.isNotEmpty) {
                                              _hasError.remove(seatIndex);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Bottom action button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
