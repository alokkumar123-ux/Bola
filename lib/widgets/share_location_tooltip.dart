import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poolmate/themes/app_them_data.dart';

class ShareLocationTooltip extends StatefulWidget {
  final Widget child;
  final VoidCallback onShare;
  final String bookingId;

  const ShareLocationTooltip({
    Key? key,
    required this.child,
    required this.onShare,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<ShareLocationTooltip> createState() => _ShareLocationTooltipState();
}

class _ShareLocationTooltipState extends State<ShareLocationTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShow();
    });
  }

  Future<void> _checkAndShow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'has_seen_share_location_tooltip_${widget.bookingId}';
    bool hasSeen = prefs.getBool(key) ?? false;
    if (!hasSeen && mounted) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 280,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(-235, 45), // Adjust based on icon size and layout
            showWhenUnlinked: false,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Triangle pointer pointing to the icon
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: CustomPaint(
                      size: const Size(20, 10),
                      painter: _TrianglePainter(
                        fillColor: Colors.white,
                        borderColor: Colors.black,
                      ),
                    ),
                  ),
                  // Tooltip body
                  Transform.translate(
                    offset: const Offset(0, -1), // Shift up to overlap triangle border
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
                            "Share Live Location",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Let others track your ride in real time",
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
                                onTap: _hideOverlay,
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
                                  _hideOverlay();
                                  widget.onShare();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Share",
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
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() async {
    _overlayEntry?.remove();
    _overlayEntry = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'has_seen_share_location_tooltip_${widget.bookingId}';
    prefs.setBool(key, true);
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

class _TrianglePainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  _TrianglePainter({required this.borderColor, required this.fillColor});

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
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw only the left and right borders of the triangle
    var borderPath = Path();
    borderPath.moveTo(0, size.height);
    borderPath.lineTo(size.width / 2, 0);
    borderPath.lineTo(size.width, size.height);
    
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
