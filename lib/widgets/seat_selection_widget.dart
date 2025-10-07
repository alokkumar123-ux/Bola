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
      return _SeatIcon(status: currentStatus);
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

  const _SeatIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Color? fillColor;
    Color? borderColor;
    Widget? child;

    switch (status) {
      case SeatStatus.available:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        child =
            Image.asset('assets/icons/available_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.unavailable:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        child =
            Image.asset('assets/icons/unavailable_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.selected:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        child =
            Image.asset('assets/icons/unavailable_seat.png', fit: BoxFit.cover);
        break;
      case SeatStatus.driver:
        fillColor = Colors.transparent;
        borderColor = Colors.transparent;
        child = Image.asset(
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
      child: child,
    );
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
