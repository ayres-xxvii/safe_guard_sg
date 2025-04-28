import 'package:flutter/material.dart';
import 'shared_layer/shared_scaffold.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      body: Center(child: Text('Settings')),
      currentIndex: 3,
    );
  }
}