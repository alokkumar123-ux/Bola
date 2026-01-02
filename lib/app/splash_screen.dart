import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/controller/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _morphController;
  late AnimationController _sceneController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _carFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize SplashController for navigation handling
    Get.put(SplashController());

    // Phase 1: Logo intro
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Phase 2: Morph intro
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Phase 3: Infinite Scene Movement
    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Speed of the world
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeOut),
    );

    _carFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    await _morphController.forward();

    // Run scene animation but stop before navigation happens
    // SplashController navigates at 3500ms, so stop animation before that
    _sceneController.repeat();

    // Stop animation after 2 seconds to prevent lag during transition
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _sceneController.stop();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _morphController.dispose();
    _sceneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Sky gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF87CEEB),
                  Color(0xFFE0F4FF),
                  Color(0xFFFFF8E7),
                ],
                stops: [0.0, 0.5, 0.8],
              ),
            ),
          ),

          // Animated clouds
          AnimatedBuilder(
            animation: _sceneController,
            builder: (context, child) =>
                _buildClouds(screenWidth, _sceneController.value),
          ),

          // Sun
          Positioned(
            top: 60,
            right: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amberAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // City skyline
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: _buildCitySkyline(),
          ),

          // Trees and people (moving)
          Positioned(
            bottom: 115,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _sceneController,
              builder: (context, child) {
                return Opacity(
                  opacity: _carFadeAnimation.value,
                  child:
                      _buildMovingScenery(screenWidth, _sceneController.value),
                );
              },
            ),
          ),

          // Road
          Positioned(bottom: 0, left: 0, right: 0, child: _buildRoad()),

          // Moving road markings
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _sceneController,
              builder: (context, child) {
                return Opacity(
                  opacity: _carFadeAnimation.value,
                  child: _buildMovingRoadMarkings(
                      screenWidth, _sceneController.value),
                );
              },
            ),
          ),

          // Logo with scale and fade
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _morphController]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _buildLogoContainer(),
            ),
          ),

          // CAR: Kept your design exactly, added vertical "driving" jitter
          AnimatedBuilder(
            animation: Listenable.merge([_morphController, _sceneController]),
            builder: (context, child) {
              // Engine vibration effect
              double vibration = sin(_sceneController.value * pi * 15) * 1.2;

              return Positioned(
                bottom: 85 + vibration,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _carFadeAnimation.value,
                  child: Center(child: _buildCarShape()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- REUSED YOUR ORIGINAL DESIGN METHODS ---

  Widget _buildLogoContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 5),
        ],
      ),
      child: Image.asset('assets/images/ic_logo.png',
          height: 100,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.drive_eta, size: 100, color: Colors.amber)),
    );
  }

  Widget _buildCarShape() {
    return Container(
      width: 140,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 12,
            left: 8,
            right: 8,
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 38,
            child: Container(
              width: 60,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 42,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(16)),
                border: Border.all(color: const Color(0xFF388E3C), width: 2),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 70,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                borderRadius:
                    const BorderRadius.only(topRight: Radius.circular(16)),
                border: Border.all(color: const Color(0xFF388E3C), width: 2),
              ),
            ),
          ),
          Positioned(bottom: 0, left: 20, child: _buildWheel()),
          Positioned(bottom: 0, right: 20, child: _buildWheel()),
          Positioned(
            bottom: 28,
            left: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.yellow.withOpacity(0.5), blurRadius: 6)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            right: 10,
            child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: Colors.red.shade400, shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade600, width: 3),
      ),
      child: Center(
        child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: Colors.grey.shade700, shape: BoxShape.circle)),
      ),
    );
  }

  // --- PARALLAX SCENE METHODS ---

  Widget _buildClouds(double screenWidth, double anim) {
    return Stack(
      children: [
        Positioned(
            top: 80,
            left: ((anim * screenWidth) + 100) % (screenWidth + 200) - 100,
            child: _buildCloud(80)),
        Positioned(
            top: 120,
            left:
                ((anim * screenWidth * 0.5) + 300) % (screenWidth + 200) - 100,
            child: _buildCloud(60)),
      ],
    );
  }

  Widget _buildCloud(double width) {
    return Opacity(
      opacity: 0.8,
      child: Icon(Icons.cloud, size: width, color: Colors.white),
    );
  }

  Widget _buildMovingScenery(double screenWidth, double anim) {
    // Items move from right to left (simulating forward car motion)
    double speed = anim * screenWidth;
    double tree1Pos = (screenWidth - speed) % (screenWidth + 100) - 50;
    double lampPos = (screenWidth + 200 - speed) % (screenWidth + 100) - 50;

    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: tree1Pos,
            bottom: 0,
            child: _buildTree(),
          ),
          Positioned(
            left: lampPos,
            bottom: 0,
            child: _buildLampPost(),
          ),
        ],
      ),
    );
  }

  Widget _buildTree() {
    return Column(
      children: [
        Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle)),
        Container(width: 8, height: 20, color: Colors.brown),
      ],
    );
  }

  Widget _buildLampPost() {
    return Container(width: 4, height: 60, color: Colors.grey.shade700);
  }

  Widget _buildRoad() {
    return Container(
      height: 120,
      child: Column(
        children: [
          Container(height: 15, color: const Color(0xFFD4C4A8)),
          Container(height: 5, color: const Color(0xFF8B7355)),
          Expanded(child: Container(color: const Color(0xFF3D3D3D))),
        ],
      ),
    );
  }

  Widget _buildMovingRoadMarkings(double screenWidth, double anim) {
    return SizedBox(
      height: 10,
      child: Stack(
        children: List.generate(10, (index) {
          double x = (screenWidth - (anim * screenWidth * 2) + (index * 100)) %
                  (screenWidth + 100) -
              100;
          return Positioned(
            left: x,
            child: Container(
                width: 50,
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2))),
          );
        }),
      ),
    );
  }

  Widget _buildCitySkyline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
          12,
          (i) => Expanded(
                child: Container(
                  height:
                      60 + (i % 4 * 25).toDouble() + (i % 3 * 15).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.3 + (i % 3) * 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
              )),
    );
  }
}
