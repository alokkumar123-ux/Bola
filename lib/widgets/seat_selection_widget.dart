import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/model/seat_booking_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

// Enum to represent the different states a seat can be in
enum SeatStatus { available, unavailable, selected, driver }

class SeatSelectionWidget extends StatefulWidget {
  // For visual layout mode (ride creation)
  final int? totalSeats;
  final List<int>? selectedSeats;
  final Function(List<int>)? onSeatsChanged;
  final bool isDriverSeatVisible;

  // For booking mode (seat booking)
  final List<SeatBooking>? seats;
  final List<String>? selectedSeatNumbers;
  final Function(String)? onSeatSelected;
  final int maxSelectableSeats;

  // Mode selector
  final bool useBookingMode;

  const SeatSelectionWidget({
    super.key,
    // Visual layout mode parameters
    this.totalSeats,
    this.selectedSeats,
    this.onSeatsChanged,
    this.isDriverSeatVisible = true,
    // Booking mode parameters
    this.seats,
    this.selectedSeatNumbers,
    this.onSeatSelected,
    this.maxSelectableSeats = 1,
    // Mode selector
    this.useBookingMode = false,
  });

  @override
  State<SeatSelectionWidget> createState() => _SeatSelectionWidgetState();
}

class _SeatSelectionWidgetState extends State<SeatSelectionWidget> {
  List<SeatStatus> _seatStatus = [];

  @override
  void initState() {
    super.initState();
    if (!widget.useBookingMode) {
      _initializeSeatStatus();
    }
  }

  @override
  void didUpdateWidget(SeatSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.useBookingMode) {
      if (oldWidget.totalSeats != widget.totalSeats ||
          oldWidget.selectedSeats != widget.selectedSeats) {
        _initializeSeatStatus();
      }
    }
  }

  void _initializeSeatStatus() {
    if (widget.totalSeats == null || widget.totalSeats! <= 0) {
      _seatStatus = [];
      return;
    }
    // totalSeats already includes the driver seat, so we don't add 1
    int totalSeatsWithDriver = widget.totalSeats!;
    _seatStatus = List.generate(totalSeatsWithDriver, (index) {
      if (index == 0 && widget.isDriverSeatVisible) return SeatStatus.driver;
      if (widget.selectedSeats?.contains(index) == true)
        return SeatStatus.selected;
      return SeatStatus.available;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    if (widget.useBookingMode) {
      return _buildBookingMode(themeChange);
    } else {
      return _buildVisualMode(themeChange);
    }
  }

  Widget _buildVisualMode(DarkThemeProvider themeChange) {
    // Guard against invalid state
    if (widget.totalSeats == null || widget.totalSeats! <= 0) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Please select a vehicle with valid seat count'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select seats to offer for ride".tr,
          style: TextStyle(
            color: themeChange.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
            fontFamily: AppThemeData.medium,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        _buildDynamicSeatLayout(),
        const SizedBox(height: 20),
        _buildLegend(themeChange),
      ],
    );
  }

  Widget _buildBookingMode(DarkThemeProvider themeChange) {
    if (widget.seats == null) return const SizedBox();

    // Organize seats into rows (4 seats per row)
    List<List<SeatBooking>> seatRows = [];
    for (var i = 0; i < widget.seats!.length; i += 4) {
      seatRows.add(
        widget.seats!.sublist(
            i, i + 4 > widget.seats!.length ? widget.seats!.length : i + 4),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Seat legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBookingLegendItem('Available', AppThemeData.grey50),
            _buildBookingLegendItem('Selected', AppThemeData.primary300),
            _buildBookingLegendItem('Booked', AppThemeData.grey300),
          ],
        ),
        const SizedBox(height: 24),
        // Seat grid
        Column(
          children: seatRows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((seat) {
                  bool isSelected =
                      widget.selectedSeatNumbers?.contains(seat.seatNumber) ==
                          true;
                  bool isBooked = seat.isBooked ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: isBooked
                          ? null
                          : () {
                              if (!isSelected &&
                                  (widget.selectedSeatNumbers?.length ?? 0) >=
                                      widget.maxSelectableSeats) {
                                Get.snackbar(
                                  'Maximum seats selected',
                                  'You can only select ${widget.maxSelectableSeats} seats',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              widget.onSeatSelected?.call(seat.seatNumber!);
                            },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isBooked
                              ? AppThemeData.grey300
                              : isSelected
                                  ? AppThemeData.primary300
                                  : AppThemeData.grey50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppThemeData.grey300,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            seat.seatNumber!,
                            style: TextStyle(
                              color: isBooked || isSelected
                                  ? AppThemeData.grey50
                                  : AppThemeData.grey800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
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
        totalSeatsIncludingDriver - (widget.isDriverSeatVisible ? 1 : 0);

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
      // 2-seater vehicle (driver + 1 passenger)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              if (widget.isDriverSeatVisible)
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
      // 5-seater vehicle (driver + 4 passengers)
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
              if (widget.isDriverSeatVisible)
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
      // 7-seater vehicle (driver + 6 passengers)
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
              if (widget.isDriverSeatVisible)
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
    if (widget.selectedSeats == null || widget.onSeatsChanged == null) {
      return const SizedBox();
    }

    // Guard against invalid index
    if (index < 0 || index >= _seatStatus.length) {
      return const SizedBox();
    }

    SeatStatus currentStatus = _seatStatus[index];
    bool isSelected = widget.selectedSeats!.contains(index);
    bool isAvailable = currentStatus == SeatStatus.available;

    // Driver seat should not be selectable
    if (currentStatus == SeatStatus.driver) {
      return _SeatIcon(status: currentStatus, seatNumber: index);
    }

    return GestureDetector(
      onTap: () {
        if (isAvailable || isSelected) {
          setState(() {
            List<int> newSelectedSeats = List.from(widget.selectedSeats!);
            if (isSelected) {
              newSelectedSeats.remove(index);
            } else {
              newSelectedSeats.add(index);
            }
            widget.onSeatsChanged!(newSelectedSeats);
          });
        }
      },
      child: _SeatIcon(
        status: isSelected ? SeatStatus.selected : currentStatus,
        seatNumber: index,
      ),
    );
  }

  Widget _buildBookingLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppThemeData.grey300,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget for the color-coded legend
  Widget _buildLegend(DarkThemeProvider themeChange) {
    return Column(
      children: [
        _LegendItem(
          color: Colors.black,
          text: 'Driver Seat',
          themeChange: themeChange,
        ),
        const SizedBox(height: 8),
        _LegendItem(
          color: Colors.white,
          text: 'Available',
          themeChange: themeChange,
        ),
        const SizedBox(height: 8),
        _LegendItem(
          color: Colors.grey,
          text: 'Selected',
          themeChange: themeChange,
        ),
      ],
    );
  }
}

// A helper widget to display a single seat icon based on its status
class _SeatIcon extends StatelessWidget {
  final SeatStatus status;
  final int? seatNumber; // Add seat number parameter

  const _SeatIcon({required this.status, this.seatNumber});

  @override
  Widget build(BuildContext context) {
    Color? fillColor;
    Color? borderColor;
    Widget? seatImage;

    switch (status) {
      case SeatStatus.available:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        seatImage =
            Image.asset('assets/icons/available_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.unavailable:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        seatImage =
            Image.asset('assets/icons/unavailable_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.selected:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        seatImage =
            Image.asset('assets/icons/unavailable_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.driver:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        seatImage = Image.asset(
          'assets/icons/driver_seat.png',
          fit: BoxFit.cover,
        );
        break;
    }

    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fillColor,
        // borderRadius: const BorderRadius.only(
        //   topLeft: Radius.circular(8),
        //   topRight: Radius.circular(8),
        // ),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        children: [
          // Seat image as background
          seatImage,
          // Seat number overlay (including driver seat)
          if (seatNumber != null)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getSeatNumberBackgroundColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getSeatNumberBorderColor(status),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatSeatNumber(seatNumber!),
                      style: TextStyle(
                        color: _getSeatNumberTextColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  // Helper method to get seat number background color based on status
  Color _getSeatNumberBackgroundColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.white;
      case SeatStatus.selected:
        return Colors.green.shade600;
      case SeatStatus.unavailable:
        return Colors.grey.shade300;
      case SeatStatus.driver:
        return Colors.black;
    }
  }

  // Helper method to get seat number border color
  Color _getSeatNumberBorderColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.grey.shade600;
      case SeatStatus.selected:
        return Colors.green.shade800;
      case SeatStatus.unavailable:
        return Colors.grey.shade500;
      case SeatStatus.driver:
        return Colors.black;
    }
  }

  // Helper method to get seat number text color
  Color _getSeatNumberTextColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.black;
      case SeatStatus.selected:
        return Colors.white;
      case SeatStatus.unavailable:
        return Colors.grey.shade600;
      case SeatStatus.driver:
        return Colors.white;
    }
  }
}

// A helper widget for a single item in the legend
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final DarkThemeProvider themeChange;

  const _LegendItem({
    required this.color,
    required this.text,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: themeChange.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
          ),
        ),
      ],
    );
  }
}
