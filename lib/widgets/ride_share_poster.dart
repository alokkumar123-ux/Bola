import 'package:flutter/material.dart';

/// A reusable widget that renders a shareable ride poster.
///
/// Designed to be captured off-screen via [ScreenshotController.captureFromLongWidget].
/// Logical size is 540 × 960 pixels (1:1.78 portrait ratio).
/// At pixelRatio 2.0 this produces a 1080 × 1920 image.
///
/// Layout (Stack):
///   • Background image  — assets/images/share_bg.png
///   • Top overlay       — App logo + "Bola" brand name
///   • Center card       — From → To, price badge, date/time
///   • Bottom CTA        — "Book Now" button strip
class RideSharePosterWidget extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String price;
  final String date;
  final String time;
  final String? distance;
  final int? availableSeats;

  const RideSharePosterWidget({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.price,
    required this.date,
    required this.time,
    this.distance,
    this.availableSeats,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Constants
  // ─────────────────────────────────────────────────────────────────────────

  static const double _posterWidth = 540;
  static const double _posterHeight = 960;

  static const Color _brandBlack = Color(0xFF0A0A0A);
  static const Color _accentGold = Color(0xFFFFCA28);
  static const Color _cardBg = Color(0xF0FFFFFF); // slightly translucent white
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF616161);

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _posterWidth,
      height: _posterHeight,
      child: Stack(
        children: [
          // 1. Background image ────────────────────────────────────────────
          _buildBackground(),

          // 2. Dark scrim to improve text legibility ───────────────────────
          _buildScrim(),

          // 3. Content column ──────────────────────────────────────────────
          _buildContent(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layer builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/share_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: _brandBlack),
      ),
    );
  }

  Widget _buildScrim() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _brandBlack.withOpacity(0.55),
              _brandBlack.withOpacity(0.25),
              _brandBlack.withOpacity(0.70),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),

            // ── Brand header ─────────────────────────────────────────────
            _buildBrandHeader(),

            const SizedBox(height: 50),

            // ── Tagline ──────────────────────────────────────────────────
            _buildTagline(),

            const SizedBox(height: 40),

            // ── Ride details card ─────────────────────────────────────────
            _buildRideCard(),

            const Spacer(),

            // ── "Book Now" CTA ────────────────────────────────────────────
            _buildCTA(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/ic_logo.png',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _accentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.drive_eta, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BOLA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            Text(
              'Ride Sharing',
              style: TextStyle(
                color: _accentGold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Ride Available Near You!',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        shadows: [
          Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2)),
        ],
      ),
    );
  }

  Widget _buildRideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Route ──────────────────────────────────────────────────────
          _buildRouteRow(),

          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),

          // ── Price ──────────────────────────────────────────────────────
          _buildPriceRow(),

          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),

          // ── Date & Time ────────────────────────────────────────────────
          _buildDateTimeRow(),

          // ── Distance & Seats ───────────────────────────────────────────
          if (distance != null || availableSeats != null) ...[
            const SizedBox(height: 20),
            _buildDivider(),
            const SizedBox(height: 20),
            _buildDistanceSeatsRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteRow() {
    return Row(
      children: [
        // From location
        Expanded(
          child: Column(
            children: [
              _dot(const Color(0xFF4CAF50)),
              const SizedBox(height: 6),
              Text(
                fromLocation,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const Icon(Icons.arrow_right_alt, color: _textMuted, size: 32),
            ],
          ),
        ),

        // To location
        Expanded(
          child: Column(
            children: [
              _dot(const Color(0xFFF44336)),
              const SizedBox(height: 6),
              Text(
                toLocation,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _accentGold,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              const Icon(Icons.confirmation_num_outlined,
                  size: 18, color: _brandBlack),
              const SizedBox(width: 8),
              Text(
                'Per Seat: $price',
                style: const TextStyle(
                  color: _brandBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoChip(Icons.calendar_today_outlined, date),
        const SizedBox(width: 16),
        _infoChip(Icons.access_time_outlined, time),
      ],
    );
  }

  Widget _buildDistanceSeatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (distance != null && distance!.isNotEmpty && distance != "N/A")
          _infoChip(Icons.route_outlined, distance!),
        if (distance != null && distance!.isNotEmpty && distance != "N/A" && availableSeats != null)
          const SizedBox(width: 16),
        if (availableSeats != null)
          _infoChip(Icons.event_seat_outlined, '$availableSeats Seats Left'),
      ],
    );
  }

  Widget _buildCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _accentGold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentGold.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        '🚗  Book Now  →',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _brandBlack,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Micro-widget helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFFE0E0E0));
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
