import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

class RemyPage extends StatefulWidget {
  @override
  _RemyPageState createState() => new _RemyPageState();
}

class _RemyPageState extends State<RemyPage> {
  @override
  void initState() {
    super.initState();
    _remy = backend.openRemy(_handleNotifications, _handleUI);
  }

  backend.Remy _remy;

  @override
  void dispose() {
    _remy.dispose();
    super.dispose();
  }

  void _handleNotifications(backend.RemyNotification notification) {}

  backend.RemyUi _ui;

  void _handleUI(backend.RemyUi ui) {
    setState(() {
      _ui = ui;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MainScreen(
      title: 'Remy',
      body: new RemyMessageList(remy: _remy, ui: _ui),
    );
  }
}

class RemyMessageList extends StatelessWidget {
  RemyMessageList({Key key, this.remy, this.ui}) : super(key: key);

  final backend.Remy remy;
  final backend.RemyUi ui;

  @override
  Widget build(BuildContext context) {
    List<Widget> messages = <Widget>[];
    if (ui == null) {
      messages.add(new Card(
        child: new Padding(
          padding: new EdgeInsets.all(24.0),
          child: new Text('Not connected.'),
        ),
      ));
    } else {
      for (backend.RemyMessage message in ui.messages) {
        List<Widget> content = <Widget>[
          new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new Text(
              message.label,
              style: Theme.of(context).textTheme.subtitle1,
              textAlign: TextAlign.center,
            ),
          )
        ];
        if (message.buttons.isNotEmpty) {
          content.add(new Padding(
            padding: new EdgeInsets.only(left: 8.0, right: 8.0),
            child: new Wrap(
              spacing: 16.0,
              children: message.buttons.map((backend.RemyButton button) {
                return RemyButtonWidget(remy: remy, button: button);
              }).toList()
            ),
          ));
          content.add(new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new Text(
              (message.classes.toList()
                    ..remove("nomsg")
                    ..remove("quiet")
                    ..remove("important"))
                  .join(", "),
              style: Theme.of(context).textTheme.caption,
              textAlign: TextAlign.right,
            ),
          ));
          //content.add(new Container(height: 16.0));
        }
        messages.add(new Padding(
          padding: new EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: new Card(
            child: new Column(
              children: content,
            ),
          ),
        ));
      }
    }
    return new ListView(
      padding: new EdgeInsets.only(bottom: 16.0),
      children: messages,
    );
  }
}

class RemyButtonWidget extends StatelessWidget {
  const RemyButtonWidget({
    Key key,
    @required this.remy,
    @required this.button,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyButton button;

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.only(left: 8.0, right: 8.0),
      child: new Material(
        color: Theme.of(context).accentColor,
        child: new InkWell(
          onTap: () {
            assert(() { print('pushing $button'); return true; }());
            remy.pushButton(button);
          },
          child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Text(
              button.label,
              style: Theme.of(context).accentTextTheme.subtitle1,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
