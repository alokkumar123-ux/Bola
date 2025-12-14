import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poolmate/app/verification_screen/aadhaar_webview_screen.dart';
import 'package:poolmate/app/verification_screen/pan_webview_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/controller/verification_details_upload_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/themes/round_button_fill.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class VerificationDetailsUploadScreen extends StatelessWidget {
  const VerificationDetailsUploadScreen({super.key});

  Future<bool> _checkKycStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return doc.data()?['aadharVerified'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkPanKycStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return doc.data()?['panVerified'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getAadhaarNumber() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return doc.data()?['aadhaarNumber'] ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<String> _getPanNumber() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return doc.data()?['panNumber'] ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<DetailsUploadController>(
        init: DetailsUploadController(),
        builder: (controller) {
          // Check if this is Aadhaar document
          bool isAadhaarDocument = controller.documentModel.value.title
                      ?.toLowerCase()
                      .contains('aadhaar') ==
                  true ||
              controller.documentModel.value.title
                      ?.toLowerCase()
                      .contains('aadhar') ==
                  true;

          // Check if this is PAN document
          bool isPanDocument = controller.documentModel.value.title
                  ?.toLowerCase()
                  .contains('pan') ==
              true;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: false,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(
                  Icons.chevron_left_outlined,
                  color: themeChange.getThem()
                      ? AppThemeData.grey50
                      : AppThemeData.grey900,
                ),
              ),
              title: Text(
                "${controller.documentModel.value.title}",
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey100
                        : AppThemeData.grey800,
                    fontFamily: AppThemeData.bold,
                    fontSize: 18),
              ),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  color: themeChange.getThem()
                      ? AppThemeData.grey700
                      : AppThemeData.grey200,
                  height: 4.0,
                ),
              ),
            ),
            body: controller.isLoading.value
                ? Center(child: Constant.loader())
                : GetBuilder<DetailsUploadController>(
                    builder: (controller) {
                      // Determine which KYC check to perform
                      Future<bool> kycCheckFuture;
                      if (isAadhaarDocument) {
                        kycCheckFuture = _checkKycStatus();
                      } else if (isPanDocument) {
                        kycCheckFuture = _checkPanKycStatus();
                      } else {
                        kycCheckFuture = Future.value(false);
                      }

                      return FutureBuilder<bool>(
                        future: kycCheckFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: Constant.loader());
                          }

                          final isKycVerified = snapshot.data ?? false;

                          if (isAadhaarDocument && !isKycVerified) {
                            return _buildAadhaarEntryPoint(
                                context, controller, themeChange);
                          } else if (isPanDocument && !isKycVerified) {
                            return _buildPanEntryPoint(
                                context, controller, themeChange);
                          } else {
                            return _buildRegularDocumentUI(
                                context, controller, themeChange);
                          }
                        },
                      );
                    },
                  ),
          );
        });
  }

  // Aadhaar entry via WebView and Firestore listener
  Widget _buildAadhaarEntryPoint(BuildContext context,
      DetailsUploadController controller, DarkThemeProvider themeChange) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aadhaar Verification',
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete Aadhaar KYC using in-app verification.',
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey400
                    : AppThemeData.grey600,
                fontFamily: AppThemeData.regular,
                fontSize: 14),
          ),
          const SizedBox(height: 24),
          RoundedButtonFill(
            title: 'Verify Aadhaar',
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

              // Get user's name from Firebase
              String userName = '';
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();

                if (userDoc.exists) {
                  final userData = userDoc.data();
                  final firstName = userData?['firstName'] ?? '';
                  final lastName = userData?['lastName'] ?? '';
                  userName = '$firstName $lastName'.trim();
                }
              } catch (e) {
                print('Error fetching user name: $e');
              }

              final result = await Get.to(() => AadhaarWebViewScreen(
                    userId: userId,
                    name: userName,
                  ));

              // Force refresh the KYC status after WebView closes
              controller.update(); // This triggers Obx to rebuild

              // Optional: Show success message if verification completed
              if (result == true) {
                Get.snackbar(
                    'Success', 'Aadhaar verification completed successfully!');
              }
            },
          ),
        ],
      ),
    );
  }

  // PAN entry via WebView and Firestore listener
  Widget _buildPanEntryPoint(BuildContext context,
      DetailsUploadController controller, DarkThemeProvider themeChange) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAN Verification',
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete PAN KYC using in-app verification.',
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey400
                    : AppThemeData.grey600,
                fontFamily: AppThemeData.regular,
                fontSize: 14),
          ),
          const SizedBox(height: 24),
          RoundedButtonFill(
            title: 'Verify PAN',
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

              // Get user's name from Firebase
              String userName = '';
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get();

                if (userDoc.exists) {
                  final userData = userDoc.data();
                  final firstName = userData?['firstName'] ?? '';
                  final lastName = userData?['lastName'] ?? '';
                  userName = '$firstName $lastName'.trim();
                }
              } catch (e) {
                print('Error fetching user name: $e');
              }

              final result = await Get.to(() => PanWebViewScreen(
                    userId: userId,
                    name: userName,
                  ));

              // Force refresh the KYC status after WebView closes
              controller.update(); // This triggers Obx to rebuild

              // Optional: Show success message if verification completed
              if (result == true) {
                Get.snackbar(
                    'Success', 'PAN verification completed successfully!');
              }
            },
          ),
        ],
      ),
    );
  }

  // Regular document upload UI (original)
  Widget _buildRegularDocumentUI(BuildContext context,
      DetailsUploadController controller, DarkThemeProvider themeChange) {
    // Check if this is Aadhaar document
    bool isAadhaarDocument = controller.documentModel.value.title
                ?.toLowerCase()
                .contains('aadhaar') ==
            true ||
        controller.documentModel.value.title
                ?.toLowerCase()
                .contains('aadhar') ==
            true;

    // Check if this is PAN document
    bool isPanDocument =
        controller.documentModel.value.title?.toLowerCase().contains('pan') ==
            true;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: isAadhaarDocument
                ? FutureBuilder<String>(
                    future: _getAadhaarNumber(),
                    builder: (context, snapshot) {
                      String aadhaarNumber = snapshot.data ?? '';

                      // Pre-fill the controller with Aadhaar number if available
                      if (aadhaarNumber.isNotEmpty &&
                          controller
                              .documentNumberController.value.text.isEmpty) {
                        controller.documentNumberController.value.text =
                            aadhaarNumber;
                      }

                      return TextFieldWidget(
                        hintText: 'AADHAAR Number',
                        controller: controller.documentNumberController.value,
                        enable: aadhaarNumber
                            .isEmpty, // Disable if Aadhaar number exists
                      );
                    },
                  )
                : isPanDocument
                    ? FutureBuilder<String>(
                        future: _getPanNumber(),
                        builder: (context, snapshot) {
                          String panNumber = snapshot.data ?? '';

                          // Pre-fill the controller with PAN number if available
                          if (panNumber.isNotEmpty &&
                              controller.documentNumberController.value.text
                                  .isEmpty) {
                            controller.documentNumberController.value.text =
                                panNumber;
                          }

                          return TextFieldWidget(
                            hintText: 'PAN Number',
                            controller:
                                controller.documentNumberController.value,
                            enable: panNumber.isEmpty, // Disable if PAN exists
                          );
                        },
                      )
                    : TextFieldWidget(
                        hintText:
                            '${controller.documentModel.value.title.toString()} Number',
                        controller: controller.documentNumberController.value,
                      ),
          ),
          // Show verification status for Aadhaar
          if (isAadhaarDocument)
            FutureBuilder<String>(
              future: _getAadhaarNumber(),
              builder: (context, snapshot) {
                String aadhaarNumber = snapshot.data ?? '';
                if (aadhaarNumber.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppThemeData.success400,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Aadhaar Verified via KYC",
                          style: TextStyle(
                            color: AppThemeData.success400,
                            fontSize: 12,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          // Show verification status for PAN
          if (isPanDocument)
            FutureBuilder<String>(
              future: _getPanNumber(),
              builder: (context, snapshot) {
                String panNumber = snapshot.data ?? '';
                if (panNumber.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppThemeData.success400,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "PAN Verified via KYC",
                          style: TextStyle(
                            color: AppThemeData.success400,
                            fontSize: 12,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          Visibility(
            visible:
                controller.documentModel.value.frontSide == true ? true : false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Front Side of ${controller.documentModel.value.title.toString()}",
                    style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontFamily: AppThemeData.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  controller.frontImage.value.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            if (controller.documents.value.status ==
                                "rejected") {
                              buildBottomSheet(context, controller, "front");
                            }
                          },
                          child: SizedBox(
                            height: Responsive.height(20, context),
                            width: Responsive.width(90, context),
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: Constant().hasValidUrl(
                                          controller.frontImage.value) ==
                                      false
                                  ? Image.file(
                                      File(controller.frontImage.value),
                                      height: Responsive.height(20, context),
                                      width: Responsive.width(80, context),
                                      fit: BoxFit.fill,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: controller.frontImage.value
                                          .toString(),
                                      fit: BoxFit.fill,
                                      height: Responsive.height(20, context),
                                      width: Responsive.width(80, context),
                                      placeholder: (context, url) =>
                                          Center(child: Constant.loader()),
                                      errorWidget: (context, url, error) =>
                                          Image.network(
                                              'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                                    ),
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            buildBottomSheet(context, controller, "front");
                          },
                          child: DottedBorder(
                            options: RectDottedBorderOptions(
                              dashPattern: const [6, 6],
                              color: AppThemeData.grey600,
                              strokeWidth: 1.5,
                            ),
                            child: Container(
                              height: Responsive.height(20, context),
                              width: Responsive.width(90, context),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: Responsive.height(8, context),
                                    width: Responsive.width(20, context),
                                    decoration: const BoxDecoration(
                                      color: AppThemeData.grey500,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: SvgPicture.asset(
                                        'assets/icons/ic_document.svg'),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Add photo".tr,
                                    style: TextStyle(
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey50
                                          : AppThemeData.grey900,
                                      fontFamily: AppThemeData.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          Visibility(
            visible:
                controller.documentModel.value.backSide == true ? true : false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Back side of ${controller.documentModel.value.title.toString()}",
                    style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontFamily: AppThemeData.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  controller.backImage.value.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            if (controller.documents.value.status ==
                                "rejected") {
                              buildBottomSheet(context, controller, "back");
                            }
                          },
                          child: SizedBox(
                            height: Responsive.height(20, context),
                            width: Responsive.width(90, context),
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: Constant().hasValidUrl(
                                          controller.backImage.value) ==
                                      false
                                  ? Image.file(
                                      File(controller.backImage.value),
                                      height: Responsive.height(20, context),
                                      width: Responsive.width(80, context),
                                      fit: BoxFit.fill,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl:
                                          controller.backImage.value.toString(),
                                      fit: BoxFit.fill,
                                      height: Responsive.height(20, context),
                                      width: Responsive.width(80, context),
                                      placeholder: (context, url) =>
                                          Center(child: Constant.loader()),
                                      errorWidget: (context, url, error) =>
                                          Image.network(
                                              'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                                    ),
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            buildBottomSheet(context, controller, "back");
                          },
                          child: DottedBorder(
                            options: RectDottedBorderOptions(
                              dashPattern: const [6, 6],
                              color: AppThemeData.grey600,
                              strokeWidth: 1.5,
                            ),
                            child: SizedBox(
                                height: Responsive.height(20, context),
                                width: Responsive.width(90, context),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: Responsive.height(8, context),
                                      width: Responsive.width(20, context),
                                      decoration: const BoxDecoration(
                                          color: AppThemeData.grey500,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: SvgPicture.asset(
                                          'assets/icons/ic_document.svg',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "Add photo".tr,
                                      style: TextStyle(
                                          color: themeChange.getThem()
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey900,
                                          fontFamily: AppThemeData.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Visibility(
            visible: controller.documents.value.status == "approved" ||
                    controller.documents.value.status == "uploaded"
                ? false
                : true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RoundedButtonFill(
                title: "Upload Document",
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () {
                  if (controller.documentNumberController.value.text.isEmpty) {
                    ShowToastDialog.showToast(
                        "Please enter document number".tr);
                  } else {
                    if (controller.documentModel.value.frontSide == true &&
                        controller.frontImage.value.isEmpty) {
                      ShowToastDialog.showToast(
                          "Please upload front side of document.".tr);
                    } else if (controller.documentModel.value.backSide ==
                            true &&
                        controller.backImage.value.isEmpty) {
                      ShowToastDialog.showToast(
                          "Please upload back side of document.".tr);
                    } else {
                      ShowToastDialog.showLoader("Please wait..".tr);
                      controller.uploadDocument();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildBottomSheet(
      BuildContext context, DetailsUploadController controller, String type) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          final themeChange = Provider.of<DarkThemeProvider>(context);
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: Responsive.height(22, context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      "Please Select".tr,
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                          fontFamily: AppThemeData.bold,
                          fontSize: 16),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => controller.pickFile(
                                    source: ImageSource.camera, type: type),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text("Camera".tr),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () => controller.pickFile(
                                    source: ImageSource.gallery, type: type),
                                icon: const Icon(
                                  Icons.photo_library_sharp,
                                  size: 32,
                                )),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text("Gallery".tr),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }
}
