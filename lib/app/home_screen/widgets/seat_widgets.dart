import 'package:flutter/material.dart';
import 'package:poolmate/app/home_screen/ride_dialog.dart';

// A helper widget to display a single seat icon based on its status
class SeatIcon extends StatelessWidget {
  final SeatStatus status;
  final int? seatNumber; // Add seat number parameter

  const SeatIcon({super.key, required this.status, this.seatNumber});

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
      case SeatStatus.reservedForLadies:
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
        seatImage =
            Image.asset('assets/icons/driver_seat.png', fit: BoxFit.cover);
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
      case SeatStatus.reservedForLadies:
        return Colors.pink.shade100;
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
      case SeatStatus.reservedForLadies:
        return Colors.pink.shade300;
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
      case SeatStatus.reservedForLadies:
        return Colors.pink.shade700;
      case SeatStatus.driver:
        return Colors.white;
    }
  }
}

// A helper widget for a single item in the legend
class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

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
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
