import 'dart:async';
import 'dart:math' as math;

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
    if (remy == null || remyState == null) {
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
                      buttons: <RemyButton>[
                        remyState.getButtonById('laundryWasherFilled'),
                        remyState.getButtonById('laundryWasherStarted'),
                        remyState.getButtonById('laundryWasherStartedFromFull'),
                        remyState.getButtonById('laundryWasherStartedFromClean'),
                        remyState.getButtonById('laundryWasherDone'),
                        remyState.getButtonById('laundryWasherEmpty'),
                      ],
                      child: Washer(
                        state: _getMachineState(remyState, 'laundry-washer'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[
                        remyState.getButtonById('laundryDryerFilled'),
                        remyState.getButtonById('laundryDryerStarted'),
                        remyState.getButtonById('laundryDryerStartedFromFull'),
                        remyState.getButtonById('laundryDryerStartedFromClean'),
                        remyState.getButtonById('laundryDryerDone'),
                        remyState.getButtonById('laundryDryerEmpty'),
                      ],
                      child: Dryer(
                        state: _getMachineState(remyState, 'laundry-dryer'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Button(
                      remy: remy,
                      buttons: <RemyButton>[
                        remyState.getButtonById('laundryCleanDone'),
                      ],
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
                child: Button(
                  remy: remy,
                  buttons: <RemyButton>[
                    remyState.getButtonById('catDoorShut'),
                    remyState.getButtonById('catDoorOpened'),
                    remyState.getButtonById('catsNotInside'),
                    remyState.getButtonById('quarantineCats'),
                    remyState.getButtonById('wildLifeAtHome'),
                    remyState.getButtonById('openDoorPolicy'),
                  ],
                  child: CatDoor(
                    isOpen: !remyState.hasNotification('status-cat-door-shut'),
                  ),
                ),
              ),
              SizedBox(
                width: 8.0,
              ),
              Section(
                label: messagesFor(remyState, 'cat-litter') ?? 'Cat litter box.',
                child: Button(
                  remy: remy,
                  buttons: <RemyButton>[
                    remyState.getButtonById('scoopedCatLitterDownstairs'),
                    remyState.getButtonById('replacedCatLitterDownstairs'),
                    remyState.getButtonById('orderedCatLitterDownstairs'),
                    remyState.getButtonById('receivedCatLitterDownstairs'),
                    remyState.getButtonById('canceledCatLitterDownstairs'),
                    remyState.getButtonById('gotCatLitterDownstairs'),
                    remyState.getButtonById('resetCatLitterDownstairsSupply'),
                  ],
                  child: CatLitter(
                    isDirty: remyState.hasNotification('status-cat-litter-dirty'),
                  ),
                ),
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
              Expanded(
                child: child,
              ),
              SizedBox(height: 4.0),
              Text(label, style: theme.textTheme.bodyText2, textAlign: TextAlign.center),
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
            contentPadding: EdgeInsets.all(6.0),
            children: <Widget>[
              ...buttons.map<Widget>((RemyButton button) {
                return Padding(
                  padding: EdgeInsets.all(6.0),
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
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: child,
        ),
      ),
    );
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

class PileOfLaundry extends StatelessWidget {
  PileOfLaundry({
    Key key,
    this.isFull,
  }) : super(key: key);

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return FittedBox(child: Text(isFull ? 'F' : 'E'));
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
    return FittedBox(child: Text(label));
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
    return FittedBox(child: Text(label));
  }
}

class LaundryGame extends StatelessWidget {
  LaundryGame({
    Key key,
    this.isFull,
  }) : super(key: key);

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return FittedBox(child: Text(isFull ? 'C' : 'N'));
  }
}

class CatDoor extends StatelessWidget {
  CatDoor({
    Key key,
    this.isOpen,
  }) : super(key: key);

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return FittedBox(child: Text(isOpen ? 'Open' : 'Shut'));
  }
}

class CatLitter extends StatelessWidget {
  CatLitter({
    Key key,
    this.isDirty,
  }) : super(key: key);

  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CatLitterPainter(
        isDirty: isDirty,
        color: Theme.of(context).textTheme.headline1.color,
      ),
    );
  }
}

class CatLitterPainter extends CustomPainter {
  CatLitterPainter({ this.isDirty, this.color });

  final bool isDirty;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 4.0;
    final double litterY = size.height / 2.0;
    final Path box = Path()
      ..moveTo(strokeWidth / 2.0, litterY - size.height / 5.0)
      ..lineTo(strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, litterY - size.height / 5.0);
    Path litter = Path()
      ..moveTo(strokeWidth / 2.0, litterY)
      ..lineTo(strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, litterY);
    int wiggleCount = size.width ~/ (strokeWidth * 2.0);
    if (wiggleCount % 2 == 0)
      wiggleCount += 1;
    double x = size.width - strokeWidth / 2.0;
    final Radius wiggleRadius = Radius.circular((size.width - strokeWidth) / (wiggleCount * 2.0));
    for (int index = 0; index < wiggleCount; index += 1) {
      x -= wiggleRadius.x * 2.0;
      litter.arcToPoint(Offset(x, litterY), radius: wiggleRadius, clockwise: index % 2 == 0);
    }
    if (isDirty) {
      final Path feces = Path();
      final math.Random random = math.Random(DateTime.now().day); // TODO(ianh): this should come from the BuildContext
      for (int index = 0; index < size.width ~/ (strokeWidth * 6.0); index += 1) {
        double radius = random.nextDouble() * (strokeWidth * 3.0 + strokeWidth * 2.0);
        feces.addOval(Rect.fromCircle(
          center: Offset(
            radius * 1.5 + random.nextDouble() * (size.width - radius * 3.0),
            litterY - strokeWidth + random.nextDouble() * strokeWidth * 2.0,
          ),
          radius: radius,
        ));
      }
      litter = Path.combine(PathOperation.union, litter, feces);
    }
    Path path = Path()
      ..addPath(box, Offset.zero)
      ..addPath(litter, Offset.zero);
    canvas.drawPath(
      path,
      Paint()
        ..strokeWidth = strokeWidth
        ..color = color
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CatLitterPainter oldDelegate) => isDirty != oldDelegate.isDirty;
}
