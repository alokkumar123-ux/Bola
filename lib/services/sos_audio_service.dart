import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Service to manage continuous SOS audio playback
/// Uses ALARM audio stream for maximum attention
class SosAudioService extends GetxService {
  static SosAudioService get instance => Get.find<SosAudioService>();

  final AudioPlayer _audioPlayer = AudioPlayer();
  RxBool isPlaying = false.obs;
  Timer? _loopTimer;
  Timer? _autoStopTimer;

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Use ALARM audio context for emergency sounds
    // This plays at alarm volume and can bypass Do Not Disturb
    _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm, // ALARM stream
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        },
      ),
    ));

    // Set release mode to loop for continuous playback
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      print('SOS Audio Player State: $state');
      if (state == PlayerState.playing) {
        isPlaying.value = true;
      } else if (state == PlayerState.stopped ||
          state == PlayerState.completed) {
        // If it stopped but we want it playing, restart
        if (isPlaying.value) {
          print('SOS Audio stopped unexpectedly - restarting...');
          _restartAudio();
        }
      }
    });

    // Handle player completion (backup for loop mode)
    _audioPlayer.onPlayerComplete.listen((_) {
      print('SOS Audio completed - restarting...');
      if (isPlaying.value) {
        _restartAudio();
      }
    });
  }

  /// Start playing SOS audio continuously
  Future<void> startPlaying() async {
    if (isPlaying.value) {
      print('SOS audio is already playing');
      return;
    }

    isPlaying.value = true;
    print('Starting SOS audio playback...');

    // Start a timer to keep restarting audio (backup mechanism)
    _startLoopTimer();

    // Start a timer to auto-stop after 5 minutes (300 seconds)
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(const Duration(minutes: 5), () async {
      print('Auto-stop timer reached 5 minutes, stopping SOS audio');
      await stopPlaying();
    });

    await _playAudio();
  }

  void _startLoopTimer() {
    _loopTimer?.cancel();
    // Check every 3 seconds if audio is still playing, restart if not
    _loopTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isPlaying.value) {
        final playerState = _audioPlayer.state;
        if (playerState != PlayerState.playing) {
          print('Loop timer: Audio not playing, restarting...');
          await _restartAudio();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _restartAudio() async {
    try {
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _playAudio();
    } catch (e) {
      print('Error restarting audio: $e');
    }
  }

  Future<void> _playAudio() async {
    try {
      // Use asset file for both Android and iOS
      // The file is in assets/audio/sos_43210.mp3
      print('Playing SOS audio from assets/audio/sos_43210.mp3');

      // Set loop mode before playing
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/sos_43210.mp3'));
      await _audioPlayer.setVolume(1.0);

      print('SOS audio started playing successfully');
    } catch (e) {
      print('Error playing SOS audio from assets: $e');
      // Try fallback methods
      await _tryFallbackPlay();
    }
  }

  Future<void> _tryFallbackPlay() async {
    try {
      print('Trying fallback: assets/audio folder');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/sos_43210.mp3'));
      await _audioPlayer.setVolume(1.0);
      print('SOS audio started from assets folder');
    } catch (e2) {
      print('Error with fallback method: $e2');
      try {
        print('Trying last resort: direct asset');
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sos_43210.mp3'));
        await _audioPlayer.setVolume(1.0);
      } catch (e3) {
        print('All methods failed to play SOS audio: $e3');
      }
    }
  }

  /// Stop playing SOS audio
  Future<void> stopPlaying() async {
    print('Stopping SOS audio playback...');

    // Stop the loop timer first
    _loopTimer?.cancel();
    _loopTimer = null;

    // Stop the auto-stop timer
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    // Set flag to false to prevent restarts
    isPlaying.value = false;

    try {
      await _audioPlayer.stop();
      print('SOS audio stopped');
    } catch (e) {
      print('Error stopping SOS audio: $e');
    }
  }

  @override
  void onClose() {
    _loopTimer?.cancel();
    _autoStopTimer?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }
}
