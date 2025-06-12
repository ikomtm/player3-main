import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models/channel_strip_model.dart';

const bool enableLogs = true;

class ChannelAudioController {
  final AudioPlayer player;
  final ChannelStripModel model;

  Timer? _fadeInTimer;
  Timer? _fadeOutTimer;
  bool isCompleted = false;
  bool isFading = false;
  bool isPlaying = false;

  ChannelAudioController(this.model) : player = AudioPlayer() {
    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        isCompleted = true;
        isPlaying = false;
        await player.seek(model.startTime);
        await player.pause();
      }
    });
  }

  Future<void> loadSource() async {
    await player.setAudioSource(
      ClippingAudioSource(
        start: model.startTime,
        end: model.stopTime,
        child: AudioSource.file(model.filePath),
      ),
      initialPosition: Duration.zero,
    );
  }

 Future<void> toggle() async {
  _log('Button pressed');

  cancelFadeTimers();

  if (player.playing) {
    _log('Initiating fade-out');

    if (model.fadeOutSeconds > 0) {
      final duration = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
      int ms = 0;
      final completer = Completer<void>();

      _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        ms += 10;
        final volume = (1.0 - ms / duration.inMilliseconds).clamp(0.0, 1.0);
        player.setVolume(volume);
        _log('Fade-out volume=$volume');

        if (ms >= duration.inMilliseconds) {
          timer.cancel();
          player.setVolume(0.0);
          player.stop();
          player.seek(model.startTime);
          player.setVolume(1.0);
          _log('Playback stopped after fade-out');
          completer.complete();
        }
      });

      await completer.future;
    } else {
      await player.stop();
      await player.seek(model.startTime);
      await player.setVolume(1.0);
      _log('Stopped playback immediately');
    }

    return;
  }

  _log('Preparing playback');

  if (isCompleted) {
    await player.seek(model.startTime);
    isCompleted = false;
  } else if (player.audioSource == null) {
    await loadSource();
    await player.seek(model.startTime);
  }

  await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
  await player.play();

  if (model.fadeInSeconds > 0) {
    final duration = Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    int ms = 0;
    _fadeInTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      ms += 10;
      final volume = (ms / duration.inMilliseconds).clamp(0.0, 1.0);
      player.setVolume(volume);
      _log('Fade-in volume=$volume');

      if (ms >= duration.inMilliseconds) {
        timer.cancel();
        player.setVolume(1.0);
        _log('Fade-in complete');
      }
    });
  } else {
    _log('Started playback without fade-in');
  }
}


  void _fadeIn(VoidCallback onComplete) {
    final duration = Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    int ms = 0;

    _fadeInTimer?.cancel();
    _fadeInTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      ms += 10;
      final volume = (ms / duration.inMilliseconds).clamp(0.0, 1.0);
      player.setVolume(volume);
      _log('Fade-in volume=$volume');
      if (ms >= duration.inMilliseconds) {
        timer.cancel();
        player.setVolume(1.0);
        onComplete();
      }
    });
  }

  Future<void> _fadeOut() async {
    final duration = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    int ms = 0;

    final completer = Completer<void>();
    _fadeOutTimer?.cancel();

    if (duration == Duration.zero) {
      player.setVolume(1.0);
      completer.complete();
      return completer.future;
    }

    _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      ms += 10;
      final volume = (1.0 - ms / duration.inMilliseconds).clamp(0.0, 1.0);
      player.setVolume(volume);
      _log('Fade-out volume=$volume');
      if (ms >= duration.inMilliseconds) {
        timer.cancel();
        player.setVolume(0.0);
        completer.complete();
      }
    });

    return completer.future;
  }

  void cancelFadeTimers() {
    _fadeInTimer?.cancel();
    _fadeOutTimer?.cancel();
    _fadeInTimer = null;
    _fadeOutTimer = null;
  }

  Future<void> dispose() async {
    cancelFadeTimers();
    await player.dispose();
  }

  void _log(String message) {
    const bool enableLogs = true;
    if (enableLogs) {
      debugPrint('[${model.name}] $message');
    }
  }
}
