import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'models/channel_strip_model.dart'; // или где у тебя ChannelStripModel
import 'dart:async';

class ChannelAudioController {
  final AudioPlayer player;
  final ChannelStripModel model;
  Timer? _fadeInTimer;
  Timer? _fadeOutTimer; 
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
    );
  }

  Future<void> toggle() async {
    switch (model.playMode) {
      case PlayMode.playStop:
        if (player.playing) {
          cancelFadeTimers(); // 🛑 остановить плавные фейды
          await player.stop();
          await player.seek(model.startTime);
        } else {
          if (isCompleted) {
            await player.seek(model.startTime);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
          }
          await player.play();
          await applyFadeInOut(); // ⬅️ запускаем плавность
        }
        break;

      case PlayMode.playPause:
        if (player.playing) {
          await player.pause();
        } else {
          if (isCompleted) {
            await player.seek(model.startTime);
            isCompleted = false;
          } else if (player.audioSource == null) {
            await loadSource();
          }
          await player.play();
        }
        break;

      case PlayMode.retrigger:
        await player.stop();
        await loadSource();
        await player.play();
        isCompleted = false;
        break;
    }
    
  }

  Future<void> dispose() async {
    await player.dispose();
  }


  Future<void> applyFadeInOut() async {
    final fadeIn = Duration(milliseconds: (model.fadeInSeconds * 1000).round());
    final fadeOut = Duration(milliseconds: (model.fadeOutSeconds * 1000).round());
    final total = model.stopTime - model.startTime;    
    final volumeSteps = 1000; // для точности 1 мс
    final fadeInStep = fadeIn.inMilliseconds ~/ volumeSteps;
    final fadeOutStep = fadeOut.inMilliseconds ~/ volumeSteps;

    // FADING IN
    if (fadeIn > Duration.zero) {
      player.setVolume(0.0);
      _fadeInTimer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
        final t = timer.tick;
        if (t >= fadeIn.inMilliseconds) {
          player.setVolume(1.0);
          timer.cancel();
        } else {
          player.setVolume(t / fadeIn.inMilliseconds);
        }
      });
    } else {
      player.setVolume(1.0);
    }

    // FADING OUT
    if (fadeOut > Duration.zero) {
      final fadeOutStart = total - fadeOut;
      Future.delayed(fadeOutStart, () {
        _fadeOutTimer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
          final t = timer.tick;
          if (t >= fadeOut.inMilliseconds) {
            player.setVolume(0.0);
            timer.cancel();
          } else {
            player.setVolume(1.0 - (t / fadeOut.inMilliseconds));
          }
        });
      });
    }
  }
    void cancelFadeTimers() {
    _fadeInTimer?.cancel();
    _fadeOutTimer?.cancel();
    _fadeInTimer = null;
    _fadeOutTimer = null;
  }
}