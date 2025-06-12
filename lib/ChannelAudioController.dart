import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'models/channel_strip_model.dart';

class ChannelAudioController {
  final AudioPlayer player;
  final ChannelStripModel model;

  Timer? _fadeInTimer;
  Timer? _fadeOutTimer;
  Timer? _fadeOutDelayTimer;
  bool isCompleted = false;

  ChannelAudioController(this.model) : player = AudioPlayer() {
    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        isCompleted = true;
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
    cancelFadeTimers();

    switch (model.playMode) {
      case PlayMode.playStop:
        if (player.playing) {
          await fadeOutAndStop();
        } else {
          if (isCompleted) {
            await player.seek(model.startTime);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
            await player.seek(model.startTime);
          }
          await player.setVolume(1.0); // Reset volume before fade-in
          await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
          await player.play();
          if (model.fadeInSeconds > 0) applyFadeInOut();
        }
        break;

      case PlayMode.playPause:
        if (player.playing) {
          await fadeOutAndStop();
        } else {
          if (isCompleted) {
            await player.seek(model.startTime);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
            await player.seek(model.startTime);
          }
          await player.setVolume(1.0); // Reset volume before fade-in
          await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
          await player.play();
          if (model.fadeInSeconds > 0) applyFadeInOut();
        }
        break;

      case PlayMode.retrigger:
        await player.stop();
        await loadSource();
        await player.seek(model.startTime);
        await player.setVolume(1.0); // Reset volume before fade-in
        await player.setVolume(model.fadeInSeconds > 0 ? 0.0 : 1.0);
        await player.play();
        if (model.fadeInSeconds > 0) applyFadeInOut();
        isCompleted = false;
        break;
    }
  }

  Future<void> fadeOutAndStop() async {
    final fadeOut = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());

    if (fadeOut <= Duration.zero) {
      await player.setVolume(1.0);
      await player.stop();
      await player.seek(model.startTime);
      return;
    }

    int ms = 0;
    _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      ms += 10;
      if (ms >= fadeOut.inMilliseconds) {
        player.setVolume(1.0);
        timer.cancel();
        await player.stop();
        await player.seek(model.startTime);
      } else {
        player.setVolume((1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0));
      }
    });
  }

  Future<void> applyFadeInOut() async {
    final fadeIn = Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    final fadeOut = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    final total = model.stopTime - model.startTime;

    if (fadeIn > Duration.zero) {
      int ms = 0;
      _fadeInTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        ms += 10;
        final newVol = (ms / fadeIn.inMilliseconds).clamp(0.0, 1.0);
        player.setVolume(newVol);
        if (ms >= fadeIn.inMilliseconds) {
          player.setVolume(1.0);
          timer.cancel();
        }
      });
    } else {
      player.setVolume(1.0);
    }

    if (fadeOut > Duration.zero && total > fadeOut) {
      final fadeOutStart = total - fadeOut;

      _fadeOutDelayTimer = Timer(fadeOutStart, () {
        int ms = 0;
        _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
          ms += 10;
          player.setVolume((1.0 - (ms / fadeOut.inMilliseconds)).clamp(0.0, 1.0));
          if (ms >= fadeOut.inMilliseconds) {
            player.setVolume(0.0);
            timer.cancel();
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
