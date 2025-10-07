import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/widgets/seat_selection_widget.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/home_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/seat_booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';

class SeatBookingDialog extends StatelessWidget {
  final BookingModel bookingModel;
  final StopOverModel stopOverModel;

  const SeatBookingDialog({
    Key? key,
    required this.bookingModel,
    required this.stopOverModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final int totalSeats = int.tryParse(bookingModel.totalSeat ?? '0') ?? 0;

    // Initialize seat list if not already present
    List<SeatBooking> seats = bookingModel.seatBookings ??
        List.generate(
          totalSeats,
          (index) => SeatBooking(
            seatNumber: (index + 1).toString(),
            isBooked: false,
          ),
        );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Seats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppThemeData.grey800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Price per seat: ${Constant.amountShow(amount: bookingModel.pricePerSeat)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => SeatSelectionWidget(
                    useBookingMode: true,
                    seats: seats,
                    selectedSeatNumbers: homeController.selectedSeatsNumbers,
                    maxSelectableSeats:
                        homeController.numberOfSelectedSeats.value,
                    onSeatSelected: (seatNumber) {
                      if (homeController.selectedSeatsNumbers
                          .contains(seatNumber)) {
                        homeController.selectedSeatsNumbers.remove(seatNumber);
                      } else {
                        homeController.selectedSeatsNumbers.add(seatNumber);
                      }
                    },
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => RoundedButtonFill(
                          title:
                              'Confirm ${homeController.selectedSeatsNumbers.length} seats',
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: homeController.selectedSeatsNumbers.isEmpty
                              ? null
                              : () {
                                  // Process booking with selected seats
                                  bookingModel.seatBookings = seats;
                                  Get.back(result: true);
                                },
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
