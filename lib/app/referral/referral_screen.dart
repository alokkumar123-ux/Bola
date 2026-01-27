import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:poolmate/controller/referral_controller.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/model/referral_edge_model.dart';
import 'package:poolmate/model/user_model.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:poolmate/utils/firestore/user_utils.dart';
import 'package:poolmate/utils/network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'referral_code_dialog.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ReferralController>(
      init: ReferralController(),
      builder: (controller) {
        // Show referral popup only once per session on first load
        if (!controller.referralPopupShown.value &&
            !controller.isLoading.value) {
          controller.referralPopupShown.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showReferralPopupIfNeeded(context, controller);
          });
        }

        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppThemeData.grey900
              : AppThemeData.grey50,
          appBar: AppBar(
            backgroundColor: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            centerTitle: false,
            titleSpacing: 0,
            leading: InkWell(
              onTap: Get.back,
              child: Icon(
                Icons.chevron_left_outlined,
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey900,
              ),
            ),
            title: Text(
              "Refer & Earn".tr,
              style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey100
                      : AppThemeData.grey800,
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 16),
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
          body: SafeArea(
            child: controller.isLoading.value
                ? Center(child: Constant.loader())
                : RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshUser();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerCard(context, controller, themeChange),
                            const SizedBox(height: 16),
                            _statRow(context, controller, themeChange),
                            const SizedBox(height: 20),
                            _taskCards(context, controller, themeChange),
                            const SizedBox(height: 12),
                            _taskListSection(context, themeChange,
                                title: "Task 1 • First ride reward",
                                subtitle:
                                    "Earn 1% when your first referral completes their first ride",
                                edges: controller.task1Edges),
                            _taskListSection(context, themeChange,
                                title: "Task 2 • 5 friends",
                                subtitle:
                                    "Refer 5 friends, each completes first ride, get bonus",
                                edges: controller.task2Edges),
                            _taskListSection(context, themeChange,
                                title: "Task 3 • 8 more friends",
                                subtitle:
                                    "Unlock 3% commission on every ride after 8 more first rides",
                                edges: controller.task3Edges),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Show referral popup if user hasn't entered a code yet and hasn't dismissed the popup
  void _showReferralPopupIfNeeded(
      BuildContext context, ReferralController controller) async {
    final shouldShow = await controller.shouldShowReferralPopup();
    if (shouldShow) {
      _showReferralCodeDialog(context, controller);
    }
  }

  /// Display the referral code dialog
  void _showReferralCodeDialog(
      BuildContext context, ReferralController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ReferralCodeDialog(
          onApplyCode: (code) async {
            // Show loading indicator
            showDialog(
              context: dialogContext,
              barrierDismissible: false,
              builder: (BuildContext loadingContext) {
                return Center(
                  child: Constant.loader(),
                );
              },
            );

            try {
              final success = await controller.applyReferralCodeFromPopup(code);

              // Close loading dialog
              Navigator.of(dialogContext).pop();

              if (success) {
                // Close referral dialog
                Navigator.of(dialogContext).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Referral code applied successfully!'),
                    backgroundColor: AppThemeData.success400,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invalid referral code'),
                    backgroundColor: AppThemeData.warning300,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              // Close loading dialog
              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppThemeData.warning300,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onDismiss: () {
            controller.dismissReferralPopup();
          },
        );
      },
    );
  }

  Widget _headerCard(BuildContext context, ReferralController controller,
      DarkThemeProvider themeChange) {
    final code = controller.user.value.referralCode ?? '------';
    final link =
        "https://play.google.com/store/apps/details?id=com.alok.poolmate";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeChange.getThem()
              ? [AppThemeData.grey800, AppThemeData.grey700]
              : [AppThemeData.primary300, AppThemeData.primary200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Invite friends & earn",
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey50
                    : AppThemeData.grey50,
                fontFamily: AppThemeData.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppThemeData.grey900
                    : AppThemeData.grey50,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(
                  code,
                  style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey100
                          : AppThemeData.grey800,
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied')),
                      );
                    },
                    icon: Icon(CupertinoIcons.doc_on_clipboard,
                        color: Colors.black)),
                IconButton(
                    onPressed: () async {
                      final message = """
🚗 Join Bola - Earn While You Ride! 🎉

Save money on rides & earn rewards through carpooling! 💰

Use my referral code: $code
or click here: $link

Benefits:
🎁 Refer 1 friend, earn 1% on their first ride
💵 Refer 5 friends, get ₹100 bonus once they ride
🚀 Refer 8 more friends to unlock 3% on every ride thereafter

Get the app now and start earning! 🚙✨
""";
                      await Share.share(message);
                    },
                    icon: Icon(FluentIcons.share_24_regular,
                        color: Colors.black)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Share via WhatsApp, SMS, Email, or copy the code",
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey200
                    : AppThemeData.grey100,
                fontFamily: AppThemeData.medium,
                fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, ReferralController controller,
      DarkThemeProvider themeChange) {
    final totalEarned =
        double.tryParse(controller.user.value.referralEarningsTotal ?? '0') ??
            0;
    final referredCount = controller.edges.length;
    return Row(
      children: [
        _statCard(themeChange,
            label: "Total earned", value: "₹${totalEarned.toStringAsFixed(2)}"),
        const SizedBox(width: 12),
        _statCard(themeChange,
            label: "Commission rate",
            value: "${(controller.commissionRate * 100).toStringAsFixed(0)}%"),
        const SizedBox(width: 12),
        _statCard(themeChange, label: "Referrals", value: "$referredCount"),
      ],
    );
  }

  Widget _statCard(DarkThemeProvider themeChange,
      {required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey300
                        : AppThemeData.grey600,
                    fontFamily: AppThemeData.medium,
                    fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey50
                        : AppThemeData.grey900,
                    fontFamily: AppThemeData.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _taskCards(BuildContext context, ReferralController controller,
      DarkThemeProvider themeChange) {
    final firstTaskEdge =
        controller.task1Edges.isNotEmpty ? controller.task1Edges.first : null;
    final task1Done =
        firstTaskEdge != null && ((firstTaskEdge.rideCount ?? 0) >= 1);
    final task2Done = controller.task2Progress >= 5;
    final task3Done = controller.task3Progress >= 8;
    return Column(
      children: [
        _taskCard(themeChange,
            title: "Task 1",
            subtitle: "Refer 1 friend, earn 1% on their first ride",
            progress: task1Done ? 1 : 0,
            badge: "1%",
            isDone: task1Done),
        const SizedBox(height: 10),
        _taskCard(themeChange,
            title: "Task 2",
            subtitle: "Refer 5 friends, get ₹100 bonus once they ride",
            progress: (controller.task2Progress / 5).clamp(0, 1).toDouble(),
            badge: "₹100",
            isDone: task2Done),
        const SizedBox(height: 10),
        _taskCard(themeChange,
            title: "Task 3",
            subtitle:
                "Refer 8 more friends to unlock 3% on every ride thereafter",
            progress: (controller.task3Progress / 8).clamp(0, 1).toDouble(),
            badge: "3%",
            isDone: task3Done),
      ],
    );
  }

  Widget _taskCard(DarkThemeProvider themeChange,
      {required String title,
      required String subtitle,
      required double progress,
      required String badge,
      required bool isDone}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppThemeData.grey700
                      : AppThemeData.grey200,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey100
                          : AppThemeData.grey800,
                      fontFamily: AppThemeData.bold,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontFamily: AppThemeData.bold,
                        fontSize: 15)),
              ),
              Icon(
                isDone ? Icons.check_circle : Icons.timelapse,
                color:
                    isDone ? AppThemeData.success400 : AppThemeData.warning300,
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey200
                      : AppThemeData.grey700,
                  fontFamily: AppThemeData.medium,
                  fontSize: 13)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress > 1 ? 1 : progress,
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey700
                  : AppThemeData.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppThemeData.success400 : AppThemeData.primary300),
            ),
          )
        ],
      ),
    );
  }

  Widget _taskListSection(BuildContext context, DarkThemeProvider themeChange,
      {required String title,
      required String subtitle,
      required List<ReferralEdgeModel> edges}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey100
                    : AppThemeData.grey800,
                fontFamily: AppThemeData.bold,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey300
                    : AppThemeData.grey600,
                fontFamily: AppThemeData.medium,
                fontSize: 12)),
        const SizedBox(height: 10),
        if (edges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppThemeData.grey800
                    : AppThemeData.grey100,
                borderRadius: BorderRadius.circular(12)),
            child: Text("No referrals yet",
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey200
                        : AppThemeData.grey700,
                    fontFamily: AppThemeData.medium)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final edge = edges[index];
              return _ReferralUserTile(edge: edge, themeChange: themeChange);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: edges.length,
          )
      ],
    );
  }
}

class _ReferralUserTile extends StatelessWidget {
  final ReferralEdgeModel edge;
  final DarkThemeProvider themeChange;
  const _ReferralUserTile({required this.edge, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppThemeData.grey800
              : AppThemeData.grey100,
          borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<UserModel?>(
        future: UserUtils.getUserProfile(edge.referredUserId ?? ''),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?.fullName() ?? 'Friend';
          final rides = edge.rideCount ?? 0;
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: NetworkImageWidget(
                  imageUrl: profile?.profilePic ?? '',
                  height: Responsive.width(10, context),
                  width: Responsive.width(10, context),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.bold,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("Rides completed: $rides",
                        style: TextStyle(
                            color: themeChange.getThem()
                                ? AppThemeData.grey300
                                : AppThemeData.grey600,
                            fontFamily: AppThemeData.medium,
                            fontSize: 12)),
                    if (edge.totalEarnedFromUser != null)
                      Text(
                          "Earned from this friend: ₹${edge.totalEarnedFromUser}",
                          style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey700,
                              fontFamily: AppThemeData.medium,
                              fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.check_circle,
                size: 18,
                color:
                    rides > 0 ? AppThemeData.success400 : AppThemeData.grey500,
              )
            ],
          );
        },
      ),
    );
  }
}
