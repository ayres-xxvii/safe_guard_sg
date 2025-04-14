import 'package:flutter/material.dart';
import 'shared_layer/shared_scaffold.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      body: Center(child: Text('Profile')),
      currentIndex: 3,
    );
  }
}