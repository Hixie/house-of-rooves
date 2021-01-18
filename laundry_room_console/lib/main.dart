import 'dart:async';
import 'dart:math' as math;

import 'package:home_automation_tools/all.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'credentials.dart';
import 'third_party/now.dart';

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

class GraphicsSettings extends InheritedWidget {
  GraphicsSettings({ Key key, this.strokeWidth, this.color, this.seed, Widget child}) : super(
    key: key,
    child: child,
  );

  final double strokeWidth;
  final Color color;
  final int seed;

  @override
  bool updateShouldNotify(GraphicsSettings oldWidget) {
    return oldWidget.strokeWidth != strokeWidth
        || oldWidget.color != color
        || oldWidget.seed != seed;
  }

  static GraphicsSettings of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GraphicsSettings>();
  }
}

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Room Console',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Now(
        child: Builder(
          builder: (BuildContext context) {
            return GraphicsSettings(
              color: Theme.of(context).textTheme.headline1.color,
              strokeWidth: MediaQuery.of(context).size.height / 120.0,
              seed: Now.of(context).day,
              child: Console(),
            );
          },
        ),
      ),
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
                        remyState.getButtonById('laundryCleanEliDone'),
                        remyState.getButtonById('laundryCleanCareyDone'),
                        remyState.getButtonById('laundryCleanIanDone'),
                        remyState.getButtonById('laundryCleanClothsDone'),
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
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return CustomPaint(
      painter: PileOfLaundryPainter(
        isFull: isFull,
        color: settings.color,
        strokeWidth: settings.strokeWidth,
        seed: settings.seed ^ 0x6469727479, // "DIRTY"
      ),
    );
  }
}

class Washer extends StatefulWidget {
  Washer({
    Key key,
    this.state,
  }) : super(key: key);

  final MachineState state;

  State<Washer> createState() => _WasherState();
}

class _WasherState extends State<Washer> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = _controller.drive(CurveTween(curve: Curves.easeInOutCirc));
    if (widget.state == MachineState.running)
      _controller.repeat(reverse: true);
  }

  void didUpdateWidget(Washer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == MachineState.running) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: WasherPainter(
          state: widget.state,
          color: settings.color,
          strokeWidth: settings.strokeWidth,
          seed: settings.seed ^ 0x77617368, // "WASH"
          controller: _animation,
        ),
      ),
    );
  }
}

class WasherPainter extends CustomPainter {
  WasherPainter({ this.state, this.color, this.strokeWidth, this.seed, this.controller }): super(repaint: controller);

  final MachineState state;
  final Color color;
  final double strokeWidth;
  final int seed;
  final Animation<double> controller;

  Size _lastSize;
  Path _machine, _annotation, _wave, _edge;
  Paint _machinePaint, _annotationPaint;
  double _waveSize;

  void _preparePaths(Size size) {
    final double floorY = size.height - strokeWidth / 2.0;
    final double leftX = strokeWidth / 2.0;
    final double rightX = size.width - strokeWidth / 2.0;
    final double surfaceY = size.height * 3.0 / 8.0;
    final double controlsY = size.height * 2.0 / 8.0;
    final double controlsLeftX = leftX + size.width * 0.05;
    final double controlsRightX = rightX - size.width * 0.05;
    final double buttonY = controlsY + (surfaceY - controlsY) / 2.0;
    _machine = Path()
      ..moveTo(leftX, floorY)
      ..lineTo(rightX, floorY)
      ..lineTo(rightX, surfaceY)
      ..lineTo(leftX, surfaceY)
      ..close()
      ..moveTo(leftX, surfaceY)
      ..lineTo(controlsLeftX, controlsY)
      ..lineTo(controlsRightX, controlsY)
      ..lineTo(rightX, surfaceY)
      ..addOval(Rect.fromCircle(center: Offset(leftX + size.width * 0.125 * 1.0, buttonY), radius: size.width * 0.02))
      ..addOval(Rect.fromCircle(center: Offset(leftX + size.width * 0.125 * 2.0, buttonY), radius: size.width * 0.02))
      ..addOval(Rect.fromCircle(center: Offset(leftX + size.width * 0.125 * 3.0, buttonY), radius: size.width * 0.02))
      ..addOval(Rect.fromCircle(center: Offset(leftX + size.width * 0.125 * 4.0, buttonY), radius: size.width * 0.02));
    _machinePaint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..style = PaintingStyle.stroke;
    switch (state) {
      case MachineState.done:
        _annotation = Path()
          ..moveTo(leftX + size.width * 0.7, surfaceY + (floorY - surfaceY) * 0.8)
          ..lineTo(leftX + size.width * 0.8, surfaceY + (floorY - surfaceY) * 0.9)
          ..lineTo(leftX + size.width * 0.9, surfaceY + (floorY - surfaceY) * 0.6);
        Rect clothesRect = Rect.fromLTRB(leftX, surfaceY, rightX, floorY).deflate(strokeWidth);
        clothesRect = clothesRect.deflate(clothesRect.shortestSide * 0.3);
        addClothes(_annotation, clothesRect, strokeWidth, math.Random(seed));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.teal // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke;
        break;
      case MachineState.empty:
        final double margin = math.min(math.max(strokeWidth, math.max(size.width * 0.1, size.height * 0.1)), math.max(size.width * 0.5, size.height * 0.5));
        _annotation = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(leftX + margin, surfaceY + margin, rightX - margin, floorY - margin), Radius.circular(margin)));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.white // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke;
        break;
      case MachineState.ready:
        final Offset origin = Offset(leftX + strokeWidth * 2.0, surfaceY + (floorY - surfaceY) * 0.2);
        _annotation = Path();
        addWiggle(
          _annotation,
          origin: origin,
          width: rightX - leftX - strokeWidth * 4.0,
          count: (rightX - leftX) ~/ (strokeWidth * 4.0),
        );
        final double clothesTop = origin.dy + strokeWidth;
        addClothes(_annotation, (Offset(leftX, clothesTop) & Size(rightX - leftX, floorY - clothesTop)).deflate(strokeWidth * 4.0), strokeWidth, math.Random(seed));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        break;
      case MachineState.running:
        final Offset origin = Offset(leftX + strokeWidth * 2.0, surfaceY + (floorY - surfaceY) * 0.2);
        _wave = Path();
        _waveSize = addWiggle(
          _wave,
          origin: origin,
          width: rightX - leftX - strokeWidth * 4.0,
          count: (rightX - leftX) ~/ (strokeWidth * 4.0),
          extraCount: 6,
        );
        double margin = _waveSize * 10.0;
        _wave
          ..lineTo(rightX + margin, origin.dy)
          ..lineTo(rightX + margin, floorY)
          ..lineTo(leftX - margin, floorY)
          ..lineTo(leftX - margin, origin.dy)
          ..close();
        _edge = Path()
          ..addRect(Rect.fromLTRB(leftX + strokeWidth, surfaceY, rightX - strokeWidth, floorY - strokeWidth));
        _annotation = null;
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.blue // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        break;
    }
    _lastSize = size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastSize != size)
      _preparePaths(size);
    canvas.drawPath(_machine, _machinePaint);
    final Path annotation = _annotation ?? Path.combine(PathOperation.intersect, _wave.shift(Offset((controller.value * 2.5 - 3.0) * _waveSize, 0.0)), _edge);
    canvas.drawPath(annotation, _annotationPaint);
  }

  @override
  bool shouldRepaint(WasherPainter oldDelegate) {
    return oldDelegate.state != state
        || oldDelegate.color != color
        || oldDelegate.strokeWidth != strokeWidth
        || oldDelegate.seed != seed
        || oldDelegate.controller != controller;
  }
}

class Dryer extends StatefulWidget {
  Dryer({
    Key key,
    this.state,
  }) : super(key: key);

  final MachineState state;

  State<Dryer> createState() => _DryerState();
}

class _DryerState extends State<Dryer> with TickerProviderStateMixin {
  AnimationController _controller;

  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.state == MachineState.running)
      _controller.repeat();
  }

  void didUpdateWidget(Dryer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == MachineState.running) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: DryerPainter(
          state: widget.state,
          color: settings.color,
          strokeWidth: settings.strokeWidth,
          seed: settings.seed ^ 0x647279, // "DRY"
          controller: _controller.drive(CurveTween(curve: Curves.slowMiddle)),
        ),
      ),
    );
  }
}

class DryerPainter extends CustomPainter {
  DryerPainter({ this.state, this.color, this.strokeWidth, this.seed, this.controller }): super(repaint: controller);

  final MachineState state;
  final Color color;
  final double strokeWidth;
  final int seed;
  final Animation<double> controller;

  Size _lastSize;
  Path _machine, _annotation, _wave, _edge;
  Paint _machinePaint, _annotationPaint;
  double _waveSize;

  void _preparePaths(Size size) {
    final double floorY = size.height - strokeWidth / 2.0;
    final double leftX = strokeWidth / 2.0;
    final double rightX = size.width - strokeWidth / 2.0;
    final double surfaceY = size.height * 3.0 / 8.0;
    final double controlsY = size.height * 2.0 / 8.0;
    final double controlsLeftX = leftX + size.width * 0.05;
    final double controlsRightX = rightX - size.width * 0.05;
    final double buttonY = controlsY + (surfaceY - controlsY) / 2.0;
    _machine = Path()
      ..moveTo(leftX, floorY)
      ..lineTo(rightX, floorY)
      ..lineTo(rightX, surfaceY)
      ..lineTo(leftX, surfaceY)
      ..close()
      ..moveTo(leftX, surfaceY)
      ..lineTo(controlsLeftX, controlsY)
      ..lineTo(controlsRightX, controlsY)
      ..lineTo(rightX, surfaceY)
      ..addOval(Rect.fromCircle(center: Offset(leftX + size.width * 0.125 * 1.0, buttonY), radius: size.width * 0.02))
      ..addOval(Rect.fromCircle(center: Offset(rightX - size.width * 0.125 * 1.0, buttonY), radius: size.width * 0.02));
    _machinePaint = Paint()
      ..strokeWidth = strokeWidth
      ..color = color
      ..style = PaintingStyle.stroke;
    switch (state) {
      case MachineState.done:
        _annotation = Path()
          ..moveTo(leftX + size.width * 0.7, surfaceY + (floorY - surfaceY) * 0.8)
          ..lineTo(leftX + size.width * 0.8, surfaceY + (floorY - surfaceY) * 0.9)
          ..lineTo(leftX + size.width * 0.9, surfaceY + (floorY - surfaceY) * 0.6);
        Rect clothesRect = Rect.fromLTRB(leftX, surfaceY, rightX, floorY).deflate(strokeWidth);
        clothesRect = clothesRect.deflate(clothesRect.shortestSide * 0.3);
        addClothes(_annotation, clothesRect, strokeWidth, math.Random(seed));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.deepOrange // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke;
        break;
      case MachineState.empty:
        final double margin = math.min(math.max(strokeWidth, math.max(size.width * 0.1, size.height * 0.1)), math.max(size.width * 0.5, size.height * 0.5));
        _annotation = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(leftX + margin, surfaceY + margin, rightX - margin, floorY - margin), Radius.circular(margin)));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.white // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke;
        break;
      case MachineState.ready:
        final Offset origin = Offset(leftX + strokeWidth * 2.0, floorY - (floorY - surfaceY) * 0.2);
        _annotation = Path();
        addSawtooth(
          _annotation,
          origin: origin,
          width: rightX - leftX - strokeWidth * 4.0,
          count: (rightX - leftX) ~/ (strokeWidth * 4.0),
        );
        final double clothesTop = surfaceY + strokeWidth;
        addClothes(_annotation, (Offset(leftX, clothesTop) & Size(rightX - leftX, origin.dy - surfaceY - strokeWidth)).deflate(strokeWidth * 6.0), strokeWidth, math.Random(seed));
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        break;
      case MachineState.running:
        final Offset origin = Offset(leftX + strokeWidth * 2.0, floorY - (floorY - surfaceY) * 0.2);
        _wave = Path();
        _waveSize = addSawtooth(
          _wave,
          origin: origin,
          width: rightX - leftX - strokeWidth * 4.0,
          count: (rightX - leftX) ~/ (strokeWidth * 4.0),
          extraCount: 6,
        );
        double margin = _waveSize * 10.0;
        _wave
          ..lineTo(rightX + margin, origin.dy)
          ..lineTo(rightX + margin, floorY)
          ..lineTo(leftX - margin, floorY)
          ..lineTo(leftX - margin, origin.dy)
          ..close();
        _edge = Path()
          ..addRect(Rect.fromLTRB(leftX + strokeWidth, surfaceY, rightX - strokeWidth, floorY - strokeWidth));
        _annotation = null;
        _annotationPaint = Paint()
          ..strokeWidth = strokeWidth
          ..color = Colors.deepOrange // TODO(ianh): make configurable
          ..style = PaintingStyle.stroke;
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastSize != size)
      _preparePaths(size);
    canvas.drawPath(_machine, _machinePaint);
    final Path annotation = _annotation ?? Path.combine(PathOperation.intersect, _wave.shift(Offset((controller.value * 2.5 - 3.0) * _waveSize, 0.0)), _edge);
    canvas.drawPath(annotation, _annotationPaint);
  }

  @override
  bool shouldRepaint(DryerPainter oldDelegate) {
    return oldDelegate.state != state
        || oldDelegate.color != color
        || oldDelegate.strokeWidth != strokeWidth
        || oldDelegate.seed != seed
        || oldDelegate.controller != controller;
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
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return CustomPaint(
      painter: PileOfLaundryPainter(
        isFull: isFull,
        color: settings.color,
        strokeWidth: settings.strokeWidth,
        seed: settings.seed ^ 0x636C65616E, // "CLEAN"
      ),
    );
  }
}

class PileOfLaundryPainter extends CustomPainter {
  PileOfLaundryPainter({ this.isFull, this.color, this.strokeWidth, this.seed });

  final bool isFull;
  final Color color;
  final double strokeWidth;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      // floor
      ..moveTo(strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, size.height - strokeWidth / 2.0);
    if (isFull) {
      final Radius radius = Radius.elliptical(size.width * 0.1, size.height * 0.02);
      final Path edge = Path()..addRRect(RRect.fromRectAndCorners(Rect.fromLTRB(0.0, size.height * 0.1, size.width, size.height - strokeWidth / 2.0), topLeft: radius, topRight: radius));
      final Path clothes = Path();
      addClothes(clothes, Offset(0.0, size.height * 0.2) & size, strokeWidth, math.Random(seed));
      path.addPath(Path.combine(PathOperation.intersect, clothes, edge), Offset.zero);
    }
    canvas.drawPath(
      path,
      Paint()
        ..strokeWidth = strokeWidth
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(PileOfLaundryPainter oldDelegate) {
    return oldDelegate.isFull != isFull
        || oldDelegate.color != color
        || oldDelegate.strokeWidth != strokeWidth
        || oldDelegate.seed != seed;
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
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: CatDoorPainter(
              isOpen: isOpen,
              color: settings.color,
              strokeWidth: settings.strokeWidth,
            ),
            child: isOpen ? Padding(
              padding: EdgeInsets.all(settings.strokeWidth * 8.0),
              child: FittedBox(
                child: Icon(MdiIcons.cat),
              ),
            ) : null,
          ),
        ),
        if (!isOpen)
          Positioned(
            right: 0.0,
            bottom: 0.0,
            child: Padding(
              padding: EdgeInsets.all(settings.strokeWidth * 4.0),
              child: Icon(Icons.lock),
            ),
          ),
      ],
    );
  }
}

class CatDoorPainter extends CustomPainter {
  CatDoorPainter({ this.isOpen, this.color, this.strokeWidth });

  final bool isOpen;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    Size doorAspectRatio = const Size(3.0, 4.0);
    FittedSizes sizes = applyBoxFit(BoxFit.contain, doorAspectRatio, size);
    assert(sizes.source == doorAspectRatio);
    assert(sizes.destination.height == size.height);
    double doorWidth = sizes.destination.width;
    Offset origin = Offset(size.width / 2.0 - doorWidth / 2.0, 0.0);
    Rect doorRect = origin & sizes.destination;
    Path door = Path()
      ..addRRect(RRect.fromRectAndRadius(doorRect, Radius.circular(strokeWidth)))
      ..addRRect(RRect.fromRectAndRadius(doorRect.deflate(doorWidth / 10.0), Radius.circular(strokeWidth)));
    canvas.drawPath(
      door,
      Paint()
        ..strokeWidth = strokeWidth
        ..color = color
        ..style = isOpen ? PaintingStyle.stroke : PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CatDoorPainter oldDelegate) {
    return oldDelegate.isOpen != isOpen
        || oldDelegate.color != color
        || oldDelegate.strokeWidth != strokeWidth;
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
    final GraphicsSettings settings = GraphicsSettings.of(context);
    return CustomPaint(
      painter: CatLitterPainter(
        isDirty: isDirty,
        color: settings.color,
        strokeWidth: settings.strokeWidth,
        seed: settings.seed,
      ),
    );
  }
}

class CatLitterPainter extends CustomPainter {
  CatLitterPainter({ this.isDirty, this.color, this.strokeWidth, this.seed });

  final bool isDirty;
  final Color color;
  final double strokeWidth;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final double litterY = size.height / 2.0;
    final Path box = Path()
      ..moveTo(strokeWidth / 2.0, litterY - size.height / 5.0)
      ..lineTo(strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(size.width - strokeWidth / 2.0, litterY - size.height / 5.0);
    Path litter = Path()
      ..moveTo(size.width - strokeWidth / 2.0, litterY)
      ..lineTo(size.width - strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(strokeWidth / 2.0, size.height - strokeWidth / 2.0)
      ..lineTo(strokeWidth / 2.0, litterY);
    int wiggleCount = size.width ~/ (strokeWidth * 2.0);
    if (wiggleCount % 2 == 0)
      wiggleCount += 1;
    addWiggle(
      litter,
      origin: Offset(strokeWidth / 2.0, litterY),
      width: size.width - strokeWidth,
      count: wiggleCount,
    );
    if (isDirty) {
      final Path feces = Path();
      final math.Random random = math.Random(seed);
      for (int index = 0; index < size.width ~/ (strokeWidth * 6.0); index += 1) {
        double radius = random.nextDouble() * (strokeWidth * 4.0) + strokeWidth;
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
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(CatLitterPainter oldDelegate) {
    return oldDelegate.isDirty != isDirty
        || oldDelegate.color != color
        || oldDelegate.strokeWidth != strokeWidth
        || oldDelegate.seed != seed;
  }
}

double addWiggle(Path path, {
  @required Offset origin,
  @required double width,
  @required int count,
  int extraCount = 0,
}) {
  final Radius wiggleRadius = Radius.circular(width / (count * 2.0));
  path.moveTo(origin.dx, origin.dy);
  double x = origin.dx;
  for (int index = 0; index < count + extraCount; index += 1) {
    x += wiggleRadius.x * 2.0;
    path.arcToPoint(Offset(x, origin.dy), radius: wiggleRadius, clockwise: index % 2 == 0);
  }
  return (wiggleRadius * 4.0).x;
}

double addSawtooth(Path path, {
  @required Offset origin,
  @required double width,
  @required int count,
  int extraCount = 0,
}) {
  final Radius wiggleRadius = Radius.circular(width / (count * 2.0));
  path.moveTo(origin.dx, origin.dy);
  double x = origin.dx;
  for (int index = 0; index < count + extraCount; index += 1) {
    x += wiggleRadius.x;
    path.lineTo(x, origin.dy - wiggleRadius.y);
    x += wiggleRadius.x;
    path.lineTo(x, origin.dy);
  }
  return (wiggleRadius * 4.0).x;
}

void addClothes(Path path, Rect rect, double strokeWidth, math.Random random) {
  Path pile = Path();
  double itemHeight = strokeWidth * 4.0;
  double dy = rect.bottom - itemHeight / 2.0;
  double index = 0;
  double delta = (rect.width * 0.15) / (rect.height / (itemHeight / 2.0));
  while (dy > rect.top) {
    dy -= itemHeight / 2.0;
    Path item = Path()..addOval(Rect.fromLTRB(
      rect.left + random.nextDouble() * rect.width / 6.0 + delta * index,
      dy,
      rect.right - random.nextDouble() * rect.width / 6.0 - delta * index,
      dy + itemHeight,
    ));
    pile = Path.combine(PathOperation.union, pile, item);
    index += 1;
  }
  path.addPath(pile, Offset.zero);
}