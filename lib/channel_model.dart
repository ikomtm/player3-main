import 'package:flutter/material.dart';

class ChannelModel extends ChangeNotifier {
  String _name;

  ChannelModel(this._name);

  String get name => _name;

  set name(String newName) {
    if (_name != newName) {
      _name = newName;
      notifyListeners();
    }
  }
}
