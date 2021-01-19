import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

const Set<String> handledClasses = <String>{ // alphabetical
  'automatic',
  'nomsg',
  'notice',
  'quiet',
  'soup',
};

class RemyPage extends StatefulWidget {
  const RemyPage({Key key}) : super(key: key);
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
    // TODO(ianh): Should handle messages with the text "status-icon-*" specially.
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

  // TODO(ianh): A lot of this stuff should be extracted out into subwidgets.

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
      int chores = 0;
      for (final backend.RemyMessage message in ui.messages) {
        if (!(message.classes.contains('notice') || message.classes.contains('automatic')))
          chores += 1;
        final List<String> unhandledClasses = (message.classes.toSet()..removeAll(handledClasses)).toList();
        final List<Widget> content = <Widget>[];
        if (message.classes.contains('soup')) {
          content.add(RemyImageMessageWidget(
            message: Text(message.label, style: Theme.of(context).textTheme.headline4),
            image: Image.network('https://remy.rooves.house/images/looking-right-with-spoon.gif'),
            imageHeight: 379.0,
          ));
        } else if (message.classes.contains('guests')) {
          content.add(RemyImageMessageWidget(
            message: Text(message.label, style: Theme.of(context).textTheme.headline4),
            image: Image.network('https://remy.rooves.house/images/standing-tall.gif'),
            imageHeight: 370.0,
          ));
        } else {
          content.add(Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message.label,
              style: Theme.of(context).textTheme.subtitle1,
              textAlign: TextAlign.center,
            ),
          ));
        }
        if (message.buttons.isNotEmpty) {
          content.add(Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Wrap(
              // TODO(ianh): center the buttons
              spacing: 16.0, // TODO(ianh): use this and other spacing instead of putting padding on the buttons
              children: message.buttons.map((backend.RemyButton button) {
                return RemyButtonWidget(remy: remy, button: button);
              }).toList(),
            ),
          ));
        }
        if (unhandledClasses.isNotEmpty) {
          content.add(Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              unhandledClasses.join(', '),
              style: Theme.of(context).textTheme.caption,
              textAlign: TextAlign.right,
            ),
          ));
        }
        if (!message.classes.contains('automatic')) {
          messages.add(
            Padding(
              padding:
                  const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Card(
                child: Column(
                  children: content,
                ),
              ),
            ),
          );
        }
      }
      if (chores == 0) {
        messages.insert(0, RemyImageMessageWidget(
          message: Text('Have fun!', style: Theme.of(context).textTheme.headline1),
          image: Image.network('https://remy.rooves.house/images/looking-right.gif'),
          imageHeight: 382.0,
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
    final TextStyle font = Theme.of(context).textTheme.headline5;
    return Padding(
      padding: EdgeInsets.all(font.fontSize * 0.25),
      child: Material(
        // TODO(ianh): add the thin border around the buttons
        borderRadius: BorderRadius.circular(font.fontSize),
        color: const Color(0xFFDDDD00),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            assert(() {
              print('pushing $button'); return true; }()); // ignore: avoid_print
            remy.pushButton(button);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: font.fontSize * 0.6, vertical: font.fontSize * 0.5),
            child: Text(
              button.label,
              style: font.copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class RemyImageMessageWidget extends StatelessWidget {
  const RemyImageMessageWidget({
    Key key,
    @required this.message,
    @required this.image,
    @required this.imageHeight,
  }) : super(key: key);

  final Widget message;
  final Widget image;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: imageHeight / MediaQuery.of(context).devicePixelRatio),
              child: image,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: message,
            ),
          ],
        ),
      ),
    );
  }
}
