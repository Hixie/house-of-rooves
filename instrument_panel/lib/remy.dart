import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'backend.dart' as backend;
import 'common.dart';

// TODO(ianh): 'warning', escalation levels, 'failure', 'done', buttons without a message

const Set<String> handledClasses = <String>{ // alphabetical
  'automatic',
  'carey',
  'console-cat-litter',
  'console-laundry',
  'eli',
  'group',
  'guests',
  'hottub',
  'ian',
  'important',
  'multi-stage',
  'nomsg',
  'notice',
  'quiet',
  'remote',
  'sleep',
  'soup',
};

class RemyStyleSet {
  const RemyStyleSet(this.backgroundColor, this.textColor, this.border);
  final Color backgroundColor;
  final Color textColor;
  final BorderSide border;
}

@immutable
class RemyStyle {
  const RemyStyle(this.cardFontSize, this.cardBorderRadius, this.card, this.buttonMargin, this.buttonPadding, this.buttonFontSize, this.buttonBorderRadius, this.normalButton, this.pressedButton, this.activeButton, this.selectedButton);
  final double cardFontSize;
  final BorderRadius cardBorderRadius;
  final RemyStyleSet card;
  final EdgeInsets buttonMargin;
  final EdgeInsets buttonPadding;
  final double buttonFontSize;
  final BorderRadius buttonBorderRadius;
  final RemyStyleSet normalButton;
  final RemyStyleSet pressedButton;
  final RemyStyleSet activeButton; // highlighted without multi-stage
  final RemyStyleSet selectedButton; // highlighted with multi-stage
}

const RemyStyle messageStyle = RemyStyle(
  24.0,
  BorderRadius.all(Radius.circular(2.0)),
  RemyStyleSet(Color(0xFFFFFFEE), Color(0xFF000000), BorderSide(color: Color(0xFF999900), width: 0.0)),
  EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  24.0,
  BorderRadius.all(Radius.circular(24.0)),
  RemyStyleSet(Color(0xFFDDDD00), Color(0xFF000000), BorderSide(color: Color(0xFF999900), width: 0.0)),
  RemyStyleSet(Color(0xFF999900), Color(0xFFFFFFFF), BorderSide(color: Color(0xFF999900), width: 0.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFF000000), width: 2.0)), // ignore: avoid_redundant_argument_values
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFFDDDDDD), width: 2.0)),
);

const RemyStyle statusStyle = RemyStyle(
  24.0,
  BorderRadius.all(Radius.circular(16.0)),
  RemyStyleSet(Color(0xFFFFFFC0), Color(0xFF000000), BorderSide(color: Color(0xFF999900), width: 0.0)),
  null, // no buttons
  null, // no buttons
  null, // no buttons
  null, // no buttons
  null, // no buttons
  null, // no buttons
  null, // no buttons
  null, // no buttons
);

const RemyStyle hotTubStyle = RemyStyle(
  24.0,
  BorderRadius.all(Radius.circular(2.0)),
  RemyStyleSet(Color(0xFFEEEEFF), Color(0xFF000000), BorderSide(color: Color(0xFF000099), width: 0.0)),
  EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  24.0,
  BorderRadius.all(Radius.circular(24.0)),
  RemyStyleSet(Color(0xFFCCCCFF), Color(0xFF000000), BorderSide(color: Color(0xFF000099), width: 0.0)),
  RemyStyleSet(Color(0xFF000099), Color(0xFFFFFFFF), BorderSide(color: Color(0xFF000099), width: 0.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFF000000), width: 2.0)), // ignore: avoid_redundant_argument_values
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFFDDDDDD), width: 2.0)),
);

const RemyStyle testStripStyle = RemyStyle(
  16.0,
  BorderRadius.all(Radius.circular(2.0)),
  RemyStyleSet(Color(0xFFEEEEFF), Color(0xFF000000), BorderSide(color: Color(0xFF000099), width: 0.0)),
  EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
  EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  16.0,
  BorderRadius.all(Radius.circular(14.0)),
  RemyStyleSet(Color(0xFFCCCCFF), Color(0xFF000000), BorderSide(color: Color(0xFF000099), width: 0.0)),
  RemyStyleSet(Color(0xFF000099), Color(0xFFFFFFFF), BorderSide(color: Color(0xFF000099), width: 0.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFF000000), width: 2.0)), // ignore: avoid_redundant_argument_values
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF666666), BorderSide(color: Color(0xFFDDDDDD), width: 2.0)),
);

const RemyStyle remoteStyle = RemyStyle(
  24.0,
  BorderRadius.all(Radius.circular(8.0)),
  RemyStyleSet(Color(0xFF000000), Color(0xFFFFFFFF), null),
  EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
  EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
  24.0,
  BorderRadius.all(Radius.circular(4.0)),
  RemyStyleSet(Color(0xFFDDDD99), Color(0xFF000000), null),
  RemyStyleSet(Color(0xFF999900), Color(0xFF000000), null),
  RemyStyleSet(Color(0xFF999900), Color(0xFFFFFFFF), null),
  RemyStyleSet(Color(0xFF999900), Color(0xFFFFFFFF), null),
);

const RemyStyle groupStyle = RemyStyle(
  16.0,
  BorderRadius.all(Radius.circular(16.0)),
  RemyStyleSet(Color(0xFFEEEEEE), Color(0xFF000000), null),
  EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
  EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
  16.0,
  BorderRadius.all(Radius.circular(12.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF000000), BorderSide(color: Color(0xFFCCCCCC), width: 0.0)),
  RemyStyleSet(Color(0xFF999999), Color(0xFFFFFFFF), BorderSide(color: Color(0xFFCCCCCC), width: 0.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF000000), BorderSide(color: Color(0xFF999999), width: 4.0)),
  RemyStyleSet(Color(0xFFDDDDDD), Color(0xFF000000), BorderSide(color: Color(0xFF999999), width: 4.0)),
);

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

  String _filter;

  void _handleFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  static const String iconPrefix = 'status-icon-';

  static Widget selectIcon(String code) {
    switch (code) {
      case 'rain': return const Icon(MdiIcons.weatherPouring);
      case 'snow': return const Icon(MdiIcons.weatherSnowyHeavy);
      case 'clear': return null;
      case 'sun': return const Icon(MdiIcons.weatherSunny);
      case 'cloud': return const Icon(MdiIcons.weatherCloudy);
      case 'night': return const Icon(MdiIcons.weatherNight);
      case 'hot': return const Icon(MdiIcons.thermometerHigh);
      case 'cold': return const Icon(MdiIcons.thermometerLow);
      default: return Text(code);
    }
  }

  Widget _buildFilter(String code, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        onSelected: (bool value) {
          if (value)
            _handleFilter(code);
        },
        selected: _filter == code,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    if (_ui != null) {
      for (final backend.RemyMessage message in _ui.messages) {
        if (message.label.startsWith(iconPrefix)) {
          final Widget icon = selectIcon(message.label.substring(iconPrefix.length));
          if (icon != null) {
            actions.add(Padding(
              padding: const EdgeInsets.only(right: 8.0), child: icon),
            );
          }
        }
      }
    }
    actions.addAll(<Widget>[
      const SizedBox(width: 24.0),
      _buildFilter(null, 'ALL'),
      _buildFilter('ian', 'IAN'),
      _buildFilter('carey', 'CAREY'),
      _buildFilter('eli', 'ELI'),
      const SizedBox(width: 18.0),
    ]);
    return MainScreen(
      title: 'Remy',
      actions: actions,
      color: Colors.white,//Colors.grey.shade300,
      body: RemyMessageList(remy: _remy, ui: _ui, filter: _filter),
    );
  }
}

class RemyMessageList extends StatefulWidget {
  const RemyMessageList({Key key, this.remy, this.ui, this.filter}) : super(key: key);

  final backend.Remy remy;
  final backend.RemyUi ui;
  final String filter;

  @override
  State<RemyMessageList> createState() => _RemyMessageListState();
}

class _RemyMessageListState extends State<RemyMessageList> {
  @override
  void initState() {
    super.initState();
    _updateData();
  }

  @override
  void didUpdateWidget(RemyMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.ui != oldWidget.ui) || (widget.filter != oldWidget.filter))
      _updateData();
  }

  bool _hasChores = false;
  List<backend.RemyMessage> _messages;

  void _updateData() {
    if (widget.ui != null) {
      _messages = widget.ui.messages.toList();
      int chores = 0;
      for (final backend.RemyMessage message in _messages) {
        if ((widget.filter != null) && !message.classes.contains(widget.filter) && !message.classes.contains('group'))
          continue;
        if (message.classes.contains('automatic'))
          continue;
        if (!message.classes.contains('notice'))
          chores += 1;
      }
      _hasChores = chores > 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ui == null) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Not connected.'),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4.0, bottom: 12.0), // Cards have top/bottom margins of 4px
      itemCount: _messages.length + (_hasChores ? 0 : 1),
      itemBuilder: (BuildContext context, int index) {
        if (!_hasChores) {
          if (index == 0) {
            return RemyImageMessageWidget(
              message: Text('Have fun!', style: Theme.of(context).textTheme.headline1),
              image: Image.network('https://remy.rooves.house/images/looking-right.gif'),
              imageHeight: 382.0,
            );
          }
          index -= 1;
        }
        final backend.RemyMessage message = _messages[index];
        final Key key = Key(message.label);
        if ((widget.filter != null) && !message.classes.contains(widget.filter) && !message.classes.contains('group'))
          return SizedBox.shrink(key: key);
        if (message.classes.contains('automatic'))
          return SizedBox.shrink(key: key);
        if (message.classes.contains('remote'))
          return RemyRemoteWidget(key: key, remy: widget.remy, message: message);
        if (message.classes.contains('test-strip'))
          return RemyTestStripWidget(key: key, remy: widget.remy, message: message);
        if (message.classes.contains('status') && message.buttons.isEmpty)
          return RemyStatusWidget(key: key, remy: widget.remy, message: message);
        if (message.classes.contains('group'))
          return RemyGroupWidget(key: key, remy: widget.remy, message: message);
        return RemyMessageWidget(key: key, remy: widget.remy, message: message);
      },
    );
  }
}

RemyStyle selectStyle(backend.RemyMessage message) {
  if (message.classes.contains('hottub')) {
    if (message.classes.contains('test-strip'))
      return testStripStyle;
    return hotTubStyle;
  }
  if (message.classes.contains('remote'))
    return remoteStyle;
  if (message.classes.contains('status'))
    return statusStyle;
  if (message.classes.contains('group'))
    return groupStyle;
  return messageStyle;
}

class RemyMessageWidget extends StatelessWidget {
  const RemyMessageWidget({
    Key key,
    @required this.remy,
    @required this.message,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;

  @override
  Widget build(BuildContext context) {
    final List<String> unhandledClasses = (message.classes.toSet()..removeAll(handledClasses)).toList();
    final bool soup = message.classes.contains('soup');
    final bool guests = message.classes.contains('guests');
    assert(!soup || !guests);
    final List<Widget> buttons = message.buttons.map((backend.RemyButton button) {
      return RemyButtonWidget(remy: remy, message: message, button: button);
    }).toList();
    final RemyStyle style = selectStyle(message);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: style.cardBorderRadius,
          side: style.card.border ?? BorderSide.none,
        ),
        color: style.card.backgroundColor,
        elevation: 2.0,
        child: Column(
          children: <Widget>[
            if (soup)
              RemyImageMessageWidget(
                message: Text(message.label, style: Theme.of(context).textTheme.headline4),
                image: Image.network('https://remy.rooves.house/images/looking-right-with-spoon.gif'),
                imageHeight: 379.0,
              ),
            if (guests)
              RemyImageMessageWidget(
                message: Text(message.label, style: Theme.of(context).textTheme.headline4),
                image: Image.network('https://remy.rooves.house/images/standing-tall.gif'),
                imageHeight: 370.0,
              ),
            if (!soup && !guests)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                child: Text(
                  message.label,
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                    fontSize: style.cardFontSize,
                    color: style.card.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 4.0),
            if (message.buttons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: buttons,
                ),
              ),
            if (unhandledClasses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    unhandledClasses.join(', '),
                    style: Theme.of(context).textTheme.caption,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            if (message.buttons.isNotEmpty)
              const SizedBox(height: 8.0)
            else
              const SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

class RemyStatusWidget extends StatelessWidget {
  const RemyStatusWidget({
    Key key,
    @required this.remy,
    @required this.message,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;

  @override
  Widget build(BuildContext context) {
    assert(message.buttons.isEmpty);
    final RemyStyle style = selectStyle(message);
    return Padding(
      padding: const EdgeInsets.only(left: 96.0, right: 96.0, top: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: style.cardBorderRadius,
          side: style.card.border ?? BorderSide.none,
        ),
        color: style.card.backgroundColor,
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            message.label,
            style: Theme.of(context).textTheme.bodyText1.copyWith(
              fontSize: style.cardFontSize,
              color: style.card.textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class RemyTestStripWidget extends StatelessWidget {
  const RemyTestStripWidget({
    Key key,
    @required this.remy,
    @required this.message,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;

  @override
  Widget build(BuildContext context) {
    final RemyStyle style = selectStyle(message);
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 32.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: style.cardBorderRadius,
          side: style.card.border ?? BorderSide.none,
        ),
        color: style.card.backgroundColor,
        elevation: 1.0,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 4.0),
              child: Text(
                message.label,
                style: Theme.of(context).textTheme.bodyText1.copyWith(
                  fontSize: style.cardFontSize,
                  color: style.card.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2.0),
            if (message.buttons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 2.0,
                  runSpacing: 2.0,
                  alignment: WrapAlignment.center,
                  children: message.buttons.map((backend.RemyButton button) {
                    return RemyButtonWidget(remy: remy, message: message, button: button, mini: true);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

class RemyRemoteWidget extends StatelessWidget {
  const RemyRemoteWidget({
    Key key,
    @required this.remy,
    @required this.message,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;

  @override
  Widget build(BuildContext context) {
    final RemyStyle style = selectStyle(message);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: style.cardBorderRadius,
          side: style.card.border ?? BorderSide.none,
        ),
        elevation: 2.0,
        color: style.card.backgroundColor,
        child: ListBody(
          children: <Widget>[
            const SizedBox(height: 4.0),
            Text(
              message.label,
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                fontSize: style.cardFontSize,
                color: style.card.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Container(
              color: style.card.textColor,
              height: 1.0,
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: message.buttons.map((backend.RemyButton button) {
                return RemyButtonWidget(remy: remy, message: message, button: button, upperCase: true);
              }).toList(),
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}

class RemyGroupWidget extends StatefulWidget {
  const RemyGroupWidget({
    Key key,
    this.remy,
    this.message,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;

  @override
  State<StatefulWidget> createState() => _RemyGroupWidgetState();
}

class _RemyGroupWidgetState extends State<RemyGroupWidget> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final RemyStyle style = selectStyle(widget.message);
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 12.0),
      child: ListBody(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              setState(() {
                open = !open;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 3.0),
              decoration: BoxDecoration(
                borderRadius: !open ? style.cardBorderRadius : BorderRadius.only(
                  topLeft: style.cardBorderRadius.topLeft,
                  topRight: style.cardBorderRadius.topRight,
                ),
                color: style.card.backgroundColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                (open ? '▼ ' : '▶ ') + widget.message.label,
                style: Theme.of(context).textTheme.bodyText1.copyWith(
                  fontSize: style.cardFontSize,
                  fontWeight: FontWeight.bold,
                  color: style.card.textColor,
                ),
              ),
            ),
          ),
          if (open)
            ...widget.message.buttons.map(
              (backend.RemyButton button) => RemyButtonWidget(
                remy: widget.remy,
                message: widget.message,
                button: button,
              ),
            ),
        ],
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

class RemyButtonWidget extends StatefulWidget {
  const RemyButtonWidget({
    Key key,
    @required this.remy,
    @required this.message,
    @required this.button,
    this.upperCase = false,
    this.mini = false,
  }) : super(key: key);

  final backend.Remy remy;
  final backend.RemyMessage message;
  final backend.RemyButton button;
  final bool upperCase;
  final bool mini;

  @override
  State<RemyButtonWidget> createState() => RemyButtonWidgetState();
}

class RemyButtonWidgetState extends State<RemyButtonWidget> {
  bool _active = false;
  Stopwatch _pressed;

  static const Duration _highlightDuration = Duration(milliseconds: 500);

  RemyStyleSet _computeStyleSet(RemyStyle style) {
    if (_active)
      return style.pressedButton;
    if (widget.button.classes.contains('highlighted')) {
      if (widget.message.classes.contains('multi-stage'))
        return style.selectedButton;
      return style.activeButton;
    }
    return style.normalButton;
  }

  @override
  Widget build(BuildContext context) {
    final RemyStyle style = selectStyle(widget.message);
    final RemyStyleSet styleSet = _computeStyleSet(style);
    final TextStyle font = Theme.of(context).textTheme.bodyText1.copyWith(
      fontSize: style.buttonFontSize,
      color: styleSet.textColor,
    );
    return Container(
      margin: style.buttonMargin,
      decoration: BoxDecoration(
        borderRadius: style.buttonBorderRadius,
        border: Border.fromBorderSide(styleSet.border ?? BorderSide.none),
        color: styleSet.backgroundColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          _pressed = Stopwatch()..start();
          setState(() { _active = true; });
        },
        onTapUp: (TapUpDetails details) {
          Timer(_highlightDuration - _pressed.elapsed, () {
            if (mounted) {
              setState(() { _active = false; });
              widget.remy.pushButton(widget.button);
            }
          });
          _pressed = null;
        },
        onTapCancel: () {
          setState(() { _active = false; });
          _pressed = null;
        },
        child: Padding(
          padding: style.buttonPadding,
          child: Text(
            widget.upperCase ? widget.button.label.toUpperCase() : widget.button.label,
            style: font,
            textAlign: TextAlign.center,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
      ),
    );
  }
}
