import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

enum PlayMode {
  playStop,
  playPause,
  retrigger,
}

class ChannelStripModel {
  String name;
  Color color;
  String filePath;
  double volume;
  Duration startTime;
  Duration stopTime;
  PlayMode playMode;
  final AudioPlayer player;

  ChannelStripModel({
    required this.name,
    required this.color,
    required this.filePath,
    required this.volume,
    required this.startTime,
    required this.stopTime,
    required this.playMode,
    AudioPlayer? player,
  }) : player = player ?? AudioPlayer();

  ChannelStripModel copy() {
    return ChannelStripModel(
      name: name,
      color: color,
      filePath: filePath,
      volume: volume,
      startTime: startTime,
      stopTime: stopTime,
      playMode: playMode,
      player: player,
    );
  }
}
