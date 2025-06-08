import 'package:flutter/material.dart';

class ChannelStripModel {
  String name;
  Color color;
  String filePath;
  double volume;
  Duration startTime;
  Duration stopTime;

  ChannelStripModel({
    required this.name,
    required this.color,
    required this.filePath,
    required this.volume,
    required this.startTime,
    required this.stopTime,
  });

  ChannelStripModel copy() {
    return ChannelStripModel(
      name: name,
      color: color,
      filePath: filePath,
      volume: volume,
      startTime: startTime,
      stopTime: stopTime,
    );
  }
}
