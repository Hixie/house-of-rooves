import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  MainScreen({
    @required this.title,
    this.actions,
    @required this.body,
  });

  final String title;
  final List<Widget> actions;
  final Widget body;

  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          alignment: FractionalOffset.centerLeft,
          // This opens the drawer in the scaffold above us, not ours.
          onPressed: () { Scaffold.of(context).openDrawer(); },
          tooltip: 'Open navigation menu',
        ),
        title: new Text(title),
        actions: actions,
      ),
      body: body,
    );
  }
}