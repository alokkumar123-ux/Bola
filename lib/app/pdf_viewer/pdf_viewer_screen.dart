import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/responsive.dart';
import 'package:provider/provider.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? pdfUrl;
  String? pdfPath;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 0;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    _getArguments();
  }

  void _getArguments() {
    final args = Get.arguments;
    if (args != null && args['pdf_url'] != null) {
      pdfUrl = args['pdf_url'];
      _downloadPdf();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'No PDF URL provided';
      });
    }
  }

  Future<void> _downloadPdf() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get temp directory
      final dir = await getTemporaryDirectory();
      final fileName = 'ticket_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${dir.path}/$fileName';

      // Download PDF using Dio
      final dio = Dio();
      await dio.download(
        pdfUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
                'Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      setState(() {
        pdfPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to download PDF: $e';
      });
    }
  }

  Future<void> _sharePdf() async {
    if (pdfPath == null) return;

    try {
      final xFile = XFile(pdfPath!);
      await Share.shareXFiles(
        [xFile],
        text: 'My Bola Travel E-Ticket',
        subject: 'Bola Travel Ticket',
      );
    } catch (e) {
      ShowToastDialog.showToast('Failed to share: $e');
      debugPrint('Error sharing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor:
          themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
      appBar: AppBar(
        backgroundColor:
            themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeChange.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Your Ticket'.tr,
          style: TextStyle(
            color: themeChange.getThem()
                ? AppThemeData.grey50
                : AppThemeData.grey900,
            fontFamily: AppThemeData.semiBold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!isLoading && pdfPath != null)
            IconButton(
              icon: Icon(
                FluentIcons.share_24_regular,
                color: AppThemeData.primary300,
              ),
              onPressed: _sharePdf,
              tooltip: 'Share',
            ),
        ],
      ),
      body: _buildBody(themeChange),
    );
  }

  Widget _buildBody(DarkThemeProvider themeChange) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppThemeData.primary300,
            ),
            SizedBox(height: Responsive.height(2, context)),
            Text(
              'Loading ticket...'.tr,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey200
                    : AppThemeData.grey700,
                fontFamily: AppThemeData.medium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppThemeData.warning300,
              ),
              SizedBox(height: Responsive.height(2, context)),
              Text(
                'Error'.tr,
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey50
                      : AppThemeData.grey900,
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: Responsive.height(1, context)),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey200
                      : AppThemeData.grey700,
                  fontFamily: AppThemeData.regular,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: Responsive.height(3, context)),
              ElevatedButton(
                onPressed: _downloadPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary300,
                  foregroundColor: AppThemeData.grey50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Retry'.tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pdfPath == null) {
      return Center(
        child: Text(
          'No PDF to display'.tr,
          style: TextStyle(
            color: themeChange.getThem()
                ? AppThemeData.grey200
                : AppThemeData.grey700,
            fontFamily: AppThemeData.medium,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PDFView(
            filePath: pdfPath!,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                totalPages = pages ?? 0;
              });
            },
            onError: (error) {
              debugPrint('PDF render error: $error');
              setState(() {
                errorMessage = 'Failed to render PDF';
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                currentPage = page ?? 0;
                totalPages = total ?? 0;
              });
            },
          ),
        ),
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: themeChange.getThem()
                ? AppThemeData.grey800
                : AppThemeData.grey100,
            child: Center(
              child: Text(
                'Page ${currentPage + 1} of $totalPages',
                style: TextStyle(
                  color: themeChange.getThem()
                      ? AppThemeData.grey200
                      : AppThemeData.grey700,
                  fontFamily: AppThemeData.medium,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
