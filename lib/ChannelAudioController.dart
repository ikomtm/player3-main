import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models/channel_strip_model.dart';

class ChannelAudioController {
  final AudioPlayer player;
  final ChannelStripModel model;
  final bool enableLogs = true;

  void _log(String message) {
    if (enableLogs) {
      debugPrint('[${model.name}] $message');
    }
  }

  Timer? _fadeInTimer;
  Timer? _fadeOutTimer;
  Timer? _fadeOutDelayTimer;
  bool isCompleted = false;

  ChannelAudioController(this.model) : player = AudioPlayer() {
    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        isCompleted = true;
        await player.seek(Duration.zero);
        await player.pause();
      }
    });
  }

  Future<void> loadSource() async {
    final endTime =
        (model.stopTime > Duration.zero && model.stopTime > model.startTime)
            ? model.stopTime
            : null;

    _log('Loading source: ${model.filePath} start=${model.startTime} end=$endTime');

    await player.setAudioSource(
      ClippingAudioSource(
        start: model.startTime,
        end: endTime,
        child: AudioSource.file(model.filePath),
      ),
      initialPosition: Duration.zero,
    );
  }

  Future<void> toggle() async {
    cancelFadeTimers();
    _log('Toggling playback: mode=${model.playMode} playing=${player.playing}');

    switch (model.playMode) {
      case PlayMode.playStop:
        if (player.playing) {
          await fadeOutAndStop();
          _log('Stopping with fade-out');
        } else {
          if (isCompleted) {
            await player.seek(Duration.zero);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
            await player.seek(Duration.zero);
          }
          await player.setVolume(1.0); // Reset volume before fade-in
          await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
          await player.play();
          _log('Started playback');
          if (model.fadeInSeconds > 0) applyFadeInOut();
        }
        break;

      case PlayMode.playPause:
        if (player.playing) {
          await fadeOutAndStop();
          _log('Pausing with fade-out');
        } else {
          if (isCompleted) {
            await player.seek(Duration.zero);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
            await player.seek(Duration.zero);
          }
          await player.setVolume(1.0); // Reset volume before fade-in
          await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
          await player.play();
          _log('Resumed playback');
          if (model.fadeInSeconds > 0) applyFadeInOut();
        }
        break;

      case PlayMode.retrigger:
        await player.stop();
        await loadSource();
        await player.seek(Duration.zero);
        await player.setVolume(1.0); // Reset volume before fade-in
        await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
        await player.play();
        _log('Retrigger playback');
        if (model.fadeInSeconds > 0) applyFadeInOut();
        isCompleted = false;
        break;
    }
  }

  Future<void> fadeOutAndStop() async {
    final fadeOut = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    _log('fadeOutAndStop duration=$fadeOut');

    if (fadeOut <= Duration.zero) {
      await player.setVolume(1.0);
      await player.stop();
      await player.seek(Duration.zero);
      return;
    }

    int ms = 0;
    _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      ms += 10;
      if (ms >= fadeOut.inMilliseconds) {
        player.setVolume(1.0);
        timer.cancel();
        await player.stop();
        await player.seek(Duration.zero);
        _log('Stopped');
      } else {
        player.setVolume((1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0));
        _log('Fade-out volume=${(1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0)}');
      }
    });
  }

  Future<void> applyFadeInOut() async {
    final fadeIn = Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    final fadeOut = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    final total = (model.stopTime > Duration.zero &&
            model.stopTime > model.startTime)
        ? model.stopTime - model.startTime
        : Duration.zero;
    _log('applyFadeInOut fadeIn=$fadeIn fadeOut=$fadeOut total=$total');

    if (fadeIn > Duration.zero) {
      int ms = 0;
      _fadeInTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        ms += 10;
        final newVol = (ms / fadeIn.inMilliseconds).clamp(0.0, 1.0);
        player.setVolume(newVol);
        _log('Fade-in volume=$newVol');
        if (ms >= fadeIn.inMilliseconds) {
          player.setVolume(1.0);
          timer.cancel();
          _log('Fade-in complete');
        }
      });
    } else {
      player.setVolume(1.0);
    }

    if (fadeOut > Duration.zero && total > fadeOut) {
      final fadeOutStart = total - fadeOut;
      _log('Scheduling fade-out to start in $fadeOutStart');

      _fadeOutDelayTimer = Timer(fadeOutStart, () {
        int ms = 0;
        _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          ms += 10;
          player.setVolume((1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0));
          _log('Fade-out volume=${(1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0)}');
          if (ms >= fadeOut.inMilliseconds) {
            player.setVolume(0.0);
            timer.cancel();
            _log('Fade-out complete');
          }
        });
      });
    }
  }

  void cancelFadeTimers() {
    _fadeInTimer?.cancel();
    _fadeOutTimer?.cancel();
    _fadeOutDelayTimer?.cancel();
    _fadeInTimer = null;
    _fadeOutTimer = null;
    _fadeOutDelayTimer = null;
    player.setVolume(1.0);
  }

  Future<void> dispose() async {
    cancelFadeTimers();
    await player.dispose();
  }
}