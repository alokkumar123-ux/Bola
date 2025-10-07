import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/widgets/seat_selection_widget.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/seat_booking_controller.dart';
import 'package:poolmate/model/booking_model.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/round_button_fill.dart';

class RideDialog extends StatelessWidget {
  final BookingModel bookingModel;
  final StopOverModel stopOverModel;

  const RideDialog({
    Key? key,
    required this.bookingModel,
    required this.stopOverModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seatController = Get.put(SeatBookingController());

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
              Obx(() => Column(
                    children: [
                      Text(
                        'Selected seats: ${seatController.selectedSeats.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SeatSelectionWidget(
                        useBookingMode: true,
                        seats: bookingModel.seatBookings ??
                            seatController.initializeSeats(
                                int.tryParse(bookingModel.totalSeat ?? '0') ??
                                    0),
                        selectedSeatNumbers: seatController.selectedSeats,
                        maxSelectableSeats:
                            seatController.numberOfSelectedSeats.value,
                        onSeatSelected: seatController.toggleSeatSelection,
                      ),
                    ],
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
                              'Book ${seatController.selectedSeats.length} seats',
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: seatController.selectedSeats.isEmpty
                              ? null
                              : () async {
                                  bool success = await seatController
                                      .bookSeats(bookingModel);
                                  if (success) {
                                    Get.back(result: true);
                                  } else {
                                    Get.snackbar(
                                      'Error',
                                      'Failed to book seats. Please try again.',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
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
