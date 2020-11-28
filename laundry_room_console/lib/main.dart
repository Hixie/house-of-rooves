import 'dart:async';

import 'package:home_automation_tools/all.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'credentials.dart';

Credentials credentials;

class StreamNotifier<T> extends ValueNotifier<T> {
  StreamNotifier(this._stream, { T initialValue }) : super(initialValue) {
    _subscription = _stream.listen(_update);
  }
  
  final Stream<T> _stream;
  
  StreamSubscription<T> _subscription;

  void _update(T newValue) {
    value = newValue;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class Remy extends InheritedNotifier<ValueListenable<RemyUi>> {
  Remy({ Key key, this.remy, Widget child}) : super(
    key: key,
    notifier: StreamNotifier<RemyUi>(remy.currentStateStream),
    child: child,
  );

  final RemyMultiplexer remy;

  static RemyMultiplexer of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Remy>().remy;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Credentials credentials = await Credentials.load();
  RemyMultiplexer remy = RemyMultiplexer(
    'laundry console',
    credentials.remyPassword,
    securityContext: credentials.securityContext,
    onLog: (String message) {
      debugPrint('remy: $message');
    },
  );
  runApp(Remy(
    remy: remy,
    child: RootWidget(),
  ));
}

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Room Console',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Console(),
    );
  }
}

enum MachineState { empty, ready, running, done }

class Console extends StatefulWidget {
  Console({Key key}) : super(key: key);

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  String messagesFor(RemyUi remy, String section) {
    Iterable<String> messages = remy.getMessagesByClass('console-$section').map<String>((RemyMessage message) => message.label);
    if (messages.isEmpty)
      return null;
    return messages.join(' ');
  }

  MachineState _getMachineState(RemyUi remy, String machine) {
    if (remy.hasNotification('$machine-running'))
      return MachineState.running;
    if (remy.hasNotification('$machine-clean'))
      return MachineState.done;
    if (remy.hasNotification('$machine-full'))
      return MachineState.ready;
    return MachineState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final RemyMultiplexer remy = Remy.of(context);
    final RemyUi remyState = remy.currentState;
    final ThemeData theme = Theme.of(context);
    if (remy == null) {
      return Center(
        child: Material(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Connecting...', style: theme.textTheme.headline3),
          ),
        ),
      );
    }
    if (remyState.hasNotification('private-mode')) {
      return Center(
        child: Material(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Private Mode Enabled', style: theme.textTheme.headline3),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Section(
          flex: 2,
          label: messagesFor(remyState, 'laundry') ?? 'Laundry.',
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[
                        remyState.getButtonById('laundryOverflowing'),
                        remyState.getButtonById('laundryNotMuch'),
                        remyState.getButtonById('laundryNotMuchAnyMore'),
                      ],
                      child: PileOfLaundry(
                        isFull: remyState.hasNotification('laundry-dirty-full'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[],
                      child: Washer(
                        state: _getMachineState(remyState, 'laundry-washer'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[],
                      child: Dryer(
                        state: _getMachineState(remyState, 'laundry-dryer'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[],
                      child: LaundryGame(
                        isFull: remyState.hasNotification('laundry-clean-full'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Arrow(
                    onPressed: () {
                      remy.pushButtonById('laundryAutomaticWasherStarted');
                    },
                  ),
                  Arrow(
                    onPressed: () {
                      remy.pushButtonById('laundryAutomaticWasherEmpty');
                      remy.pushButtonById('laundryAutomaticDryerStarted');
                    },
                  ),
                  Arrow(
                    onPressed: () {
                      remy.pushButtonById('laundryAutomaticDryerEmpty');
                      remy.pushButtonById('laundryAutomaticCleanLaundryPending');
                    },
                  ),
                ],
              ),
            ],
          ),
          // laundry buttons:
          //  - laundryAutomaticWasherFull: filled washer, not started
          //  - laundryAutomaticWasherStarted: started washer
          //  - laundryAutomaticDryerFull: filled dryer, not started
          //  - laundryWasherTransfer: moved from washer to dryer
          //  - laundryDryerEmpty: emptied dryer
          //  - laundryCleanDone: empty clean pile
          //  - maybe more from the list of laundry buttons
          // laundry dryer automatic button
          //  - laundryAutomaticDryerStarted: when the dryer starts
          //  - laundryAutomaticDryerClean: when the dryer ends reasonably
          //  - laundryAutomaticDryerFull: when the dryer ends early
        ),
        SizedBox(
          height: 8.0,
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Section(
                label: messagesFor(remyState, 'cat-door') ?? 'Cat door.',
                child: Placeholder(),
                // cat door:
                //  - messages with class "console-cat-door"
                //  - status: status-cat-door-open, status-cat-door-shut
                //  - buttons:
                //    - catDoorShut: shut door
                //    - catDoorOpened: open door
                //    - catsNotInside: cats not inside
                //    - quarantineCats: set policy (closes)
                //    - wildLifeAtHome: set policy (closes)
                //    - openDoorPolicy: set policy (opens)
              ),
              SizedBox(
                width: 8.0,
              ),
              Section(
                label: messagesFor(remyState, 'cat-litter') ?? 'Cat litter box.',
                child: Placeholder(),
                // cat litter status and buttons
                //  - status: messages with class "console-cat-litter"
                //  - buttons (showing only visible ones):
                //    - scoopedCatLitterDownstairs
                //    - replacedCatLitterDownstairs
                //    - orderedCatLitterDownstairs
                //    - receivedCatLitterDownstairs
                //    - canceledCatLitterDownstairs
                //    - gotCatLitterDownstairs
                //    - resetCatLitterDownstairsSupply
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Section extends StatelessWidget {
  Section({
    Key key,
    this.flex = 1,
    this.label,
    this.child,
  }) : super(key: key);

  final int flex;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Material(
        child: Padding(
          padding: EdgeInsets.all(4.0),
          child: Column(
            children: <Widget>[
              Expanded(child: child),
              SizedBox(height: 4.0),
              Text(label, style: theme.textTheme.bodyText2),
            ],
          ),
        ),
      ),
    );
  }
}

class Button extends StatelessWidget {
  Button({
    Key key,
    this.remy,
    List<RemyButton> buttons,
    this.child,
  }) : buttons = buttons.where((RemyButton button) => button != null).toList(),
       super(key: key);

  final RemyMultiplexer remy;
  final List<RemyButton> buttons;
  final Widget child;

  VoidCallback _handler(BuildContext context) {
    return () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.zero,
            children: <Widget>[
              ...buttons.map<Widget>((RemyButton button) {
                return Padding(
                  padding: EdgeInsets.all(12.0),
                  child: OutlinedButton(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(button.label),
                    ),
                    onPressed: () {
                      remy.pushButton(button);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          );
        },
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: buttons.isNotEmpty ? _handler(context) : null,
      child: FittedBox(
        child: child,
      ),
    );
  }
}

class PileOfLaundry extends StatelessWidget {
  PileOfLaundry({
    Key key,
    this.isFull,
  }) : super(key: key);

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return Text(isFull ? 'F' : 'E');
  }
}

class Washer extends StatelessWidget {
  Washer({
    Key key,
    this.state,
  }) : super(key: key);

  final MachineState state;

  @override
  Widget build(BuildContext context) {
    String label;
    switch (state) {
      case MachineState.empty:
        label = 'E';
        break;
      case MachineState.ready:
        label = 'F';
        break;
      case MachineState.running:
        label = 'R';
        break;
      case MachineState.done:
        label = 'D';
        break;
      default:
        label = '?';
        break;
    }
    return Text(label);
  }
}

class Dryer extends StatelessWidget {
  Dryer({
    Key key,
    this.state,
  }) : super(key: key);

  final MachineState state;

  @override
  Widget build(BuildContext context) {
    String label;
    switch (state) {
      case MachineState.empty:
        label = 'E';
        break;
      case MachineState.ready:
        label = 'F';
        break;
      case MachineState.running:
        label = 'R';
        break;
      case MachineState.done:
        label = 'D';
        break;
      default:
        label = '?';
        break;
    }
    return Text(label);
  }
}

class LaundryGame extends StatelessWidget {
  LaundryGame({
    Key key,
    this.isFull,
    this.onPressed,
  }) : super(key: key);

  final bool isFull;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Text(isFull ? 'C' : 'N');
  }
}

class Arrow extends StatefulWidget {
  Arrow({
    Key key,
    this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  State<Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<Arrow> {
  bool _pressed = false;
  Timer _timer;
  Stopwatch _stopwatch = Stopwatch();

  static const Duration kTouchDelay = const Duration(milliseconds: 75);

  void _handleDown(TapDownDetails details) {
    _timer?.cancel();
    _timer = null;
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _pressed = true;
    });
  }

  void _handleUp(TapUpDetails details) {
    _reset();
  }

  void _handleCancel() {
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    if (_stopwatch.elapsed > kTouchDelay) {
      setState(() {
        _pressed = false;
      });
    } else {
      _timer = Timer(kTouchDelay - _stopwatch.elapsed, () {
        setState(() {
          _pressed = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleDown,
      onTapUp: _handleUp,
      onTapCancel: _handleCancel,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: kTouchDelay,
        curve: Curves.easeIn,
        width: 50.0,
        height: 25.0,
        margin: EdgeInsets.all(12.0),
        decoration: ShapeDecoration(
          shape: ArrowShape(),
          shadows: kElevationToShadow[_pressed ? 0 : 4],
          color: Color.lerp(Colors.yellow, Colors.black, _pressed ? 0.5 : 0.0),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class ArrowShape extends ShapeBorder {
  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    final double tailHeight = rect.height / 5.0;
    final double headWidth = 2.0 * rect.width / 5.0;
    return Path()
      ..moveTo(rect.left, rect.top + tailHeight * 2.0)
      ..lineTo(rect.right - headWidth, rect.top + tailHeight * 2.0)
      ..lineTo(rect.right - headWidth, rect.top)
      ..lineTo(rect.right, rect.top + rect.height / 2.0)
      ..lineTo(rect.right - headWidth, rect.top + rect.height)
      ..lineTo(rect.right - headWidth, rect.top + tailHeight * 3.0)
      ..lineTo(rect.left, rect.top + tailHeight * 3.0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 0.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  ArrowShape scale(double t) => this;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
}
