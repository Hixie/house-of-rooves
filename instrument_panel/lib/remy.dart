import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

class RemyPage extends StatefulWidget {
  const RemyPage({ Key key }) : super(key: key);
  @override
  _RemyPageState createState() => _RemyPageState();
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
    return MainScreen(
      title: 'Remy',
      body: RemyMessageList(remy: _remy, ui: _ui),
    );
  }
}

class RemyMessageList extends StatelessWidget {
  const RemyMessageList({Key key, this.remy, this.ui}) : super(key: key);

  final backend.Remy remy;
  final backend.RemyUi ui;

  @override
  Widget build(BuildContext context) {
    final List<Widget> messages = <Widget>[];
    if (ui == null) {
      messages.add(const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Not connected.'),
        ),
      ));
    } else {
      for (final backend.RemyMessage message in ui.messages) {
        final List<Widget> content = <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message.label,
              style: Theme.of(context).textTheme.subtitle1,
              textAlign: TextAlign.center,
            ),
          )
        ];
        if (message.buttons.isNotEmpty) {
          content
            ..add(Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Wrap(
                spacing: 16.0,
                children: message.buttons.map((backend.RemyButton button) {
                  return RemyButtonWidget(remy: remy, button: button);
                }).toList()
              ),
            ))
            ..add(Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                (message.classes.toList()
                      ..remove('nomsg')
                      ..remove('quiet')
                      ..remove('important'))
                    .join(', '),
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.right,
              ),
            ));
            //..add(Container(height: 16.0));
        }
        messages.add(Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: Card(
            child: Column(
              children: content,
            ),
          ),
        ));
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16.0),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: Colors.yellow.withGreen(230),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            assert(() { print('pushing $button'); return true; }()); // ignore: avoid_print
            remy.pushButton(button);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              button.label,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
