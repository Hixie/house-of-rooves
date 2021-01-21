import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key key,
    @required this.title,
    this.actions,
    this.color,
    @required this.body,
  }) : super(key: key);

  final String title;
  final List<Widget> actions;
  final Color color;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          alignment: FractionalOffset.centerLeft,
          // This opens the drawer in the scaffold above us, not ours.
          onPressed: () { Scaffold.of(context).openDrawer(); },
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        ),
        title: Text(title),
        actions: actions,
      ),
      backgroundColor: color,
      body: body,
    );
  }
}