import 'dart:async';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

/// Service to manage continuous SOS audio playback
/// Uses ALARM audio stream for maximum attention
class SosAudioService extends GetxService {
  static SosAudioService get instance => Get.find<SosAudioService>();

  final AudioPlayer _audioPlayer = AudioPlayer();
  RxBool isPlaying = false.obs;
  Timer? _loopTimer;

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
      log('SOS Audio Player State: $state');
      if (state == PlayerState.playing) {
        isPlaying.value = true;
      } else if (state == PlayerState.stopped ||
          state == PlayerState.completed) {
        // If it stopped but we want it playing, restart
        if (isPlaying.value) {
          log('SOS Audio stopped unexpectedly - restarting...');
          _restartAudio();
        }
      }
    });

    // Handle player completion (backup for loop mode)
    _audioPlayer.onPlayerComplete.listen((_) {
      log('SOS Audio completed - restarting...');
      if (isPlaying.value) {
        _restartAudio();
      }
    });
  }

  /// Start playing SOS audio continuously
  Future<void> startPlaying() async {
    if (isPlaying.value) {
      log('SOS audio is already playing');
      return;
    }

    isPlaying.value = true;
    log('Starting SOS audio playback...');

    // Start a timer to keep restarting audio (backup mechanism)
    _startLoopTimer();

    await _playAudio();
  }

  void _startLoopTimer() {
    _loopTimer?.cancel();
    // Check every 3 seconds if audio is still playing, restart if not
    _loopTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isPlaying.value) {
        final playerState = _audioPlayer.state;
        if (playerState != PlayerState.playing) {
          log('Loop timer: Audio not playing, restarting...');
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
      log('Error restarting audio: $e');
    }
  }

  Future<void> _playAudio() async {
    try {
      // Use asset file for both Android and iOS
      // The file is in assets/audio/sos_43210.mp3
      log('Playing SOS audio from assets/audio/sos_43210.mp3');

      // Set loop mode before playing
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/sos_43210.mp3'));
      await _audioPlayer.setVolume(1.0);

      log('SOS audio started playing successfully');
    } catch (e) {
      log('Error playing SOS audio from assets: $e');
      // Try fallback methods
      await _tryFallbackPlay();
    }
  }

  Future<void> _tryFallbackPlay() async {
    try {
      log('Trying fallback: assets/audio folder');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/sos_43210.mp3'));
      await _audioPlayer.setVolume(1.0);
      log('SOS audio started from assets folder');
    } catch (e2) {
      log('Error with fallback method: $e2');
      try {
        log('Trying last resort: direct asset');
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sos_43210.mp3'));
        await _audioPlayer.setVolume(1.0);
      } catch (e3) {
        log('All methods failed to play SOS audio: $e3');
      }
    }
  }

  /// Stop playing SOS audio
  Future<void> stopPlaying() async {
    log('Stopping SOS audio playback...');

    // Stop the loop timer first
    _loopTimer?.cancel();
    _loopTimer = null;

    // Set flag to false to prevent restarts
    isPlaying.value = false;

    try {
      await _audioPlayer.stop();
      log('SOS audio stopped');
    } catch (e) {
      log('Error stopping SOS audio: $e');
    }
  }

  @override
  void onClose() {
    _loopTimer?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }
}
