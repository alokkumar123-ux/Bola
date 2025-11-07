import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class TermsAndConditionScreen extends StatelessWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
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
          type == "privacy" ? "Privacy Policy".tr : "Terms & Conditions".tr,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: SingleChildScrollView(
          child: Html(
            data: _sanitizeHtml(type == "privacy"
                ? Constant.privacyPolicy
                : Constant.termsAndConditions),
            style: {
              "*": Style(
                fontFeatureSettings: null,
              ),
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "p": Style(
                margin: Margins.only(bottom: 10),
              ),
            },
          ),
        ),
      ),
    );
  }

  // Sanitize HTML to remove problematic font-feature-settings
  String _sanitizeHtml(String html) {
    if (html.isEmpty) return html;

    // Remove font-feature-settings from inline styles and CSS
    String sanitized = html.replaceAll(
        RegExp(r'font-feature-settings\s*:\s*[^;]+;?', caseSensitive: false),
        '');

    return sanitized;
  }
}
