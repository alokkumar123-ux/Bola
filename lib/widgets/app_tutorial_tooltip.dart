import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/controller/profile_controller.dart';
import 'package:poolmate/themes/app_them_data.dart';

class AppTutorialTooltip extends StatefulWidget {
  final Widget child;
  final VoidCallback onWatch;
  final VoidCallback onSkip;

  const AppTutorialTooltip({
    Key? key,
    required this.child,
    required this.onWatch,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<AppTutorialTooltip> createState() => _AppTutorialTooltipState();
}

class _AppTutorialTooltipState extends State<AppTutorialTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Listen to the controller to show/hide
    final controller = Get.find<ProfileController>();
    ever(controller.showTutorialTooltip, (bool show) {
      if (show && mounted) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.centerRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -30), // Adjust to position just above the arrow icon
            showWhenUnlinked: false,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tooltip body
                  Transform.translate(
                    offset: const Offset(0, 1), // Shift down slightly
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "App Tutorial",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Learn how to use all features step by step",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.find<ProfileController>().showTutorialTooltip.value = false;
                                  widget.onSkip();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Skip",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  Get.find<ProfileController>().showTutorialTooltip.value = false;
                                  widget.onWatch();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Watch",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  // Triangle pointer pointing down
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: _TriangleDownPainter(
                        fillColor: Colors.white,
                        borderColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child,
    );
  }
}

class _TriangleDownPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  _TriangleDownPainter({required this.borderColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    var borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    var path = Path();
    path.moveTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.lineTo(size.width / 2, size.height); // Bottom tip
    path.close();

    canvas.drawPath(path, paint);

    // Draw only the left and right borders of the downward triangle
    var borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(size.width / 2, size.height);
    borderPath.lineTo(size.width, 0);
    
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
