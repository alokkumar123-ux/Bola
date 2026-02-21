import 'package:flutter/material.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';

class ReferralCodeDialog extends StatefulWidget {
  final Function(String) onApplyCode;
  final Function() onDismiss;

  const ReferralCodeDialog({
    super.key,
    required this.onApplyCode,
    required this.onDismiss,
  });

  @override
  State<ReferralCodeDialog> createState() => _ReferralCodeDialogState();
}

class _ReferralCodeDialogState extends State<ReferralCodeDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _codeController;
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleApplyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a referral code'),
          backgroundColor: AppThemeData.warning300,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onApplyCode(code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppThemeData.warning300,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutBack),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _handleDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppThemeData.grey800
                              : AppThemeData.grey100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: themeChange.getThem()
                              ? AppThemeData.grey200
                              : AppThemeData.grey700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Have a referral code?',
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey50
                          : AppThemeData.grey900,
                      fontFamily: AppThemeData.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Enter a referral code to unlock exclusive rewards and benefits!',
                    style: TextStyle(
                      color: themeChange.getThem()
                          ? AppThemeData.grey300
                          : AppThemeData.grey600,
                      fontFamily: AppThemeData.medium,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Field with Icon
                  Container(
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.grey800
                          : AppThemeData.grey100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeChange.getThem()
                            ? AppThemeData.grey700
                            : AppThemeData.grey200,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: themeChange.getThem()
                            ? AppThemeData.grey50
                            : AppThemeData.grey900,
                        fontFamily: AppThemeData.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ENTER CODE',
                        hintStyle: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey400
                              : AppThemeData.grey500,
                          fontFamily: AppThemeData.medium,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.card_giftcard,
                            color: themeChange.getThem()
                                ? AppThemeData.primary300
                                : AppThemeData.primary400,
                            size: 24,
                          ),
                        ),
                      ),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons Row
                  Row(
                    children: [
                      // Dismiss Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleDismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey300,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Skip',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey800,
                                fontFamily: AppThemeData.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Apply Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleApplyCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppThemeData.primary300,
                                  AppThemeData.primary400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppThemeData.grey50,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Apply Code',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppThemeData.grey50,
                                      fontFamily: AppThemeData.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.grey800
                          : AppThemeData.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          size: 16,
                          color: AppThemeData.primary300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can only enter a code once. Choose wisely!',
                            style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey700,
                              fontFamily: AppThemeData.medium,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
