import 'package:flutter/material.dart';

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

  ChannelStripModel({
    required this.name,
    required this.color,
    required this.filePath,
    required this.volume,
    required this.startTime,
    required this.stopTime,
    required this.playMode,
  });

  ChannelStripModel copy() {
    return ChannelStripModel(
      name: name,
      color: color,
      filePath: filePath,
      volume: volume,
      startTime: startTime,
      stopTime: stopTime,
      playMode: playMode,
    );
  }
}
