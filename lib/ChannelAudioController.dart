import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models/channel_strip_model.dart';

/// Controller that manages playback for a single [ChannelStripModel].
/// It supports fade-in, fade-out and three play modes.
class ChannelAudioController {
  final AudioPlayer player;
  final ChannelStripModel model;

  /// Timers used for fade effects.
  Timer? _fadeInTimer;
  Timer? _fadeOutTimer;

  /// Whether the clip finished playing to the end.
  bool _completed = false;

  ChannelAudioController(this.model) : player = AudioPlayer() {
    // When playback reaches the end of the clip we pause and reset so the
    // next press starts from the beginning of the defined range.
    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        _completed = true;
        await player.seek(Duration.zero);
        await player.pause();
      }
    });
  }

  /// Load the current file with clipping applied.
  Future<void> _loadSource() async {
    final endTime =
        (model.stopTime > Duration.zero && model.stopTime > model.startTime)
            ? model.stopTime
            : null;

    await player.setAudioSource(
      ClippingAudioSource(
        start: model.startTime,
        end: endTime,
        child: AudioSource.file(model.filePath),
      ),
      initialPosition: Duration.zero,
    );
  }

  /// Start playback from the beginning of the clip with optional fade-in.
  Future<void> _startPlayback() async {
    await _loadSource();
    await player.seek(Duration.zero);
    final fadeInDur =
        Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    if (fadeInDur > Duration.zero) {
      await player.setVolume(0.0);
      await player.play();
      _startFadeIn(fadeInDur);
    } else {
      await player.setVolume(1.0);
      await player.play();
    }
    _completed = false;
  }

  /// Begin a fade-in over [duration].
  void _startFadeIn(Duration duration) {
    int elapsed = 0;
    _fadeInTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      elapsed += 20;
      final vol = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      player.setVolume(vol);
      if (elapsed >= duration.inMilliseconds) {
        player.setVolume(1.0);
        timer.cancel();
        _fadeInTimer = null;
      }
    });
  }

  /// Fade out the current playback and then either stop or pause.
  Future<void> _fadeOutAndFinish({required bool pause}) async {
    final fadeOutDur =
        Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    final startVol = player.volume;

    if (fadeOutDur <= Duration.zero) {
      if (pause) {
        await player.pause();
      } else {
        await player.stop();
      }
      await player.seek(Duration.zero);
      await player.setVolume(1.0);
      return;
    }

    int elapsed = 0;
    final completer = Completer<void>();
    _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) async {
      elapsed += 20;
      final progress = elapsed / fadeOutDur.inMilliseconds;
      final vol = (startVol * (1.0 - progress)).clamp(0.0, 1.0);
      player.setVolume(vol);
      if (elapsed >= fadeOutDur.inMilliseconds) {
        timer.cancel();
        if (pause) {
          await player.pause();
        } else {
          await player.stop();
        }
        await player.seek(Duration.zero);
        await player.setVolume(1.0);
        _fadeOutTimer = null;
        completer.complete();
      }
    });
    await completer.future;
  }

  /// Cancel any running fade timers.
  void _cancelFades() {
    _fadeInTimer?.cancel();
    _fadeOutTimer?.cancel();
    _fadeInTimer = null;
    _fadeOutTimer = null;
  }

  /// Public wrapper used by the settings UI to cancel any fade timers.
  void cancelFadeTimers() => _cancelFades();
  /// Toggle playback according to the selected play mode.
  Future<void> toggle() async {
    _cancelFades();

    if (player.playing) {
      switch (model.playMode) {
        case PlayMode.playStop:
          await _fadeOutAndFinish(pause: false);
          break;
        case PlayMode.playPause:
          await _fadeOutAndFinish(pause: true);
          break;
        case PlayMode.retrigger:
          await player.stop();
          await _startPlayback();
          break;
      }
    } else {
      if (_completed) {
        await player.seek(Duration.zero);
        _completed = false;
      }
      await _startPlayback();
    }
  }

  Future<void> dispose() async {
    _cancelFades();
    await player.dispose();
  }
}
