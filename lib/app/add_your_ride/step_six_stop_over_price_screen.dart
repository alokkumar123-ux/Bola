import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/controller/add_your_ride_controller.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/model/stop_over_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

class StepSixStopOverPriceScreen extends StatefulWidget {
  const StepSixStopOverPriceScreen({super.key});

  @override
  State<StepSixStopOverPriceScreen> createState() =>
      _StepSixStopOverPriceScreenState();
}

class _StepSixStopOverPriceScreenState
    extends State<StepSixStopOverPriceScreen> {
  final AddYourRideController controller = Get.put(AddYourRideController());

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<AddYourRideController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey50,
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey100,
            leading: InkWell(
              onTap: () => Get.back(),
              child: Icon(
                Icons.chevron_left_outlined,
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
              ),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Container(
                height: 4,
                color: themeChange.getThem()
                    ? AppThemeData.grey700
                    : AppThemeData.grey200,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Edit price per seat".tr,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontFamily: AppThemeData.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.stopOverList.length,
                      itemBuilder: (context, index) {
                        StopOverModel legs = controller.stopOverList[index];

                        return Row(
                          children: [
                            Expanded(
                              child: Timeline.tileBuilder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                theme: TimelineThemeData(nodePosition: 0),
                                builder: TimelineTileBuilder.connected(
                                  itemCount: 2,
                                  contentsAlign: ContentsAlign.basic,
                                  indicatorBuilder: (context, _) => Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFFF5F7F8),
                                      shape: OvalBorder(),
                                      shadows: [
                                        BoxShadow(
                                          color: Color(0xFFC1CED6),
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  contentsBuilder: (context, innerIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Constant.getCityName(
                                        themeChange,
                                        innerIndex == 0
                                            ? Location(
                                                lat: legs.startLocation!.lat!,
                                                lng: legs.startLocation!.lng!)
                                            : Location(
                                                lat: legs.endLocation!.lat!,
                                                lng: legs.endLocation!.lng!),
                                      ),
                                    );
                                  },
                                  connectorBuilder: (_, __, ___) =>
                                      const DashedLineConnector(
                                    color: AppThemeData.grey300,
                                    gap: 2,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${Constant.distanceCalculate(legs.distance!.value.toString())} ${Constant.distanceType}"
                                      .tr,
                                  style: TextStyle(
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                    fontFamily: AppThemeData.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        controller.changeStopOverPrice(
                                            index, false);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppThemeData.primary300),
                                        ),
                                        child: Icon(Icons.remove,
                                            color: AppThemeData.primary300),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 55,
                                      child: TextField(
                                        controller: controller
                                            .stopOverPriceControllers[index],
                                        onChanged: (value) {
                                          controller.stopOverList[index].price =
                                              value;
                                        },
                                        textAlign: TextAlign.center,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    InkWell(
                                      onTap: () {
                                        controller.changeStopOverPrice(
                                            index, true);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppThemeData.primary300),
                                        ),
                                        child: Icon(Icons.add,
                                            color: AppThemeData.primary300),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
