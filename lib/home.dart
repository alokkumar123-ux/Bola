import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Preview Dialog Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // A font similar to the one in the image
      ),
      home: const HomePage(),
    );
  }
}

// Home page with a button to show the dialog
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Dialog Demo'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Trip Preview'),
          onPressed: () {
            // Function to show the custom dialog
            showDialog(
              context: context,
              barrierDismissible: true, // Allows dismissing by tapping outside
              builder: (BuildContext context) {
                return const TripPreviewDialog();
              },
            );
          },
        ),
      ),
    );
  }
}

// Enum to represent the different states a seat can be in
enum SeatStatus { available, unavailable, reservedForLadies, selected, driver }

// The main dialog widget, implemented as a StatefulWidget to manage state
class TripPreviewDialog extends StatefulWidget {
  const TripPreviewDialog({super.key});

  @override
  State<TripPreviewDialog> createState() => _TripPreviewDialogState();
}

class _TripPreviewDialogState extends State<TripPreviewDialog> {
  // MODIFICATION 1: Use a List to track multiple selected seats.
  final List<int> _selectedSeatIndices = [];
  final int _seatPrice = 600;

  // A list representing the status of each seat in the layout
  final List<SeatStatus> _seatStatus = [
    SeatStatus.driver,
    SeatStatus.unavailable, // Pre-selected for demonstration
    SeatStatus.available,
    SeatStatus.available,
    SeatStatus.available,
  ];

  @override
  void initState() {
    super.initState();
    // This logic is kept in case you ever have seats pre-selected
    // in the _seatStatus list. It will find them and add them to the selection.
    for (int i = 0; i < _seatStatus.length; i++) {
      if (_seatStatus[i] == SeatStatus.selected) {
        _selectedSeatIndices.add(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 8.0,
      backgroundColor: Colors.white,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildDialogContent(context),
          _buildCloseButton(context),
        ],
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
          const SizedBox(height: 24),
          _buildSummary(),
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // Widget for displaying driver and car information
  Widget _buildDriverInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Himangshu Goswami',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 4),
                    Text('0', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.directions_car, size: 28),
            SizedBox(height: 4),
            Text('AS02AJ2345',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('Carnival',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  // Widget for the seat selection section
  Widget _buildSeatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your preferred seat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        // Seat layout
        Row(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the front row seats
          children: [
            // Passenger's side
            Padding(
              padding: const EdgeInsets.only(
                  top: 36.0), // Align passenger seat with driver seat
              child: _buildSeat(1),
            ), // Driver's side
            SizedBox(
              width: 30,
            ),
            Column(
              children: [
                const Icon(Icons.drive_eta_outlined,
                    size: 32, color: Colors.black54),
                const SizedBox(height: 4), // Space between wheel and seat
                _buildSeat(0),
              ],
            ),
            const SizedBox(width: 8), // Space between front seats
          ],
        ),
        const SizedBox(height: 8),
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
  }

  // Builds a single seat widget with tap detection
  Widget _buildSeat(int index) {
    SeatStatus currentStatus = _seatStatus[index];
    // MODIFICATION 2: Check if the seat index is in our list.
    bool isSelected = _selectedSeatIndices.contains(index);
    bool isAvailable = currentStatus == SeatStatus.available;

    // An unavailable seat should not be selectable.
    if (currentStatus == SeatStatus.unavailable ||
        currentStatus == SeatStatus.driver) {
      return _SeatIcon(status: currentStatus);
    }

    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          // MODIFICATION 3: Add/remove from the list instead of setting a single variable.
          setState(() {
            if (isSelected) {
              _selectedSeatIndices.remove(index); // Deselect
            } else {
              _selectedSeatIndices.add(index); // Select
            }
          });
        }
      },
      child: _SeatIcon(
        status: isSelected ? SeatStatus.selected : currentStatus,
      ),
    );
  }

  // Widget for the color-coded legend
  Widget _buildLegend() {
    return const Column(
      children: [
        _LegendItem(color: Color(0xFFD3D3D3), text: 'Not available'),
        SizedBox(height: 8),
        _LegendItem(color: Colors.white, text: 'Available'),
        SizedBox(height: 8),
        _LegendItem(color: Colors.pinkAccent, text: 'Reserved for Ladies'),
      ],
    );
  }

  // Widget for the trip cost summary
  Widget _buildSummary() {
    // MODIFICATION 4: Get the number of seats from the list's length.
    final int numberOfSeats = _selectedSeatIndices.length;
    final int totalAmount = numberOfSeats * _seatPrice;

    return Column(
      children: [
        Row(
          children: [
            const Text('Selected number of seats: ',
                style: TextStyle(color: Colors.black54)),
            Text('$numberOfSeats',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Total payable amount: ',
                style: TextStyle(color: Colors.black54)),
            Text('$totalAmount',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
          onPressed: () {
            // Handle payment logic here
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Proceed to pay', style: TextStyle(fontSize: 16)),
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

    switch (status) {
      case SeatStatus.available:
        fillColor = Colors.transparent;
        borderColor = Colors.black;
        break;
      case SeatStatus.unavailable:
        fillColor = Colors.black;
        borderColor = Colors.black;
        break;
      case SeatStatus.reservedForLadies:
        fillColor = Colors.pinkAccent;
        borderColor = Colors.black;
        break;
      case SeatStatus.selected:
        fillColor = Colors.grey.shade400;
        borderColor = Colors.black;
        break;
      case SeatStatus.driver:
        fillColor = Colors.black;
        borderColor = Colors.black;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }
}

// A helper widget for a single item in the legend
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

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
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
