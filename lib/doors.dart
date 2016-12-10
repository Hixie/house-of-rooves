import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

class DoorsPage extends StatefulWidget {
  @override
  _DoorsPageState createState() => new _DoorsPageState();
}

class _DoorsPageState extends State<DoorsPage> {
  @override
  void initState() {
    super.initState();
    backend.BitDemultiplexer doorBits = new backend.BitDemultiplexer(backend.cloud.getDevice(backend.houseSensorsId).values, 3);
    _bit1Subscription = doorBits[1].listen(_handleBit1);
    _bit2Subscription = doorBits[2].listen(_handleBit2);
    _bit3Subscription = doorBits[3].listen(_handleBit3);
  }

  StreamSubscription<bool> _bit1Subscription;
  StreamSubscription<bool> _bit2Subscription;
  StreamSubscription<bool> _bit3Subscription;

  @override
  void dispose() {
    _bit1Subscription.cancel();
    _bit2Subscription.cancel();
    _bit3Subscription.cancel();
    super.dispose();
  }

  bool _frontDoor;
  bool _garageDoor;
  bool _backDoor;

  void _handleBit1(bool value) {
    setState(() { _frontDoor = value; });
  }

  void _handleBit2(bool value) {
    setState(() { _garageDoor = value; });
  }

  void _handleBit3(bool value) {
    setState(() { _backDoor = value; });
  }

  @override
  Widget build(BuildContext context) {
    return new MainScreen(
      title: 'Doors',
      body: new Container(
        padding: new EdgeInsets.all(16.0),
        child: new SizedBox.expand(
          child: new FittedBox(
            child: new DoorDiagram(
              frontDoor: _frontDoor,
              garageDoor: _garageDoor,
              backDoor: _backDoor,
            ),
          ),
        ),
      ),
    );
  }
}

class DoorDiagram extends StatefulWidget {
  DoorDiagram({
    Key key,
    this.frontDoor,
    this.garageDoor,
    this.backDoor,
    this.duration: const Duration(milliseconds: 200),
    this.curve: Curves.fastOutSlowIn,
  }) : super(key: key);

  final bool frontDoor;
  final bool garageDoor;
  final bool backDoor;
  final Duration duration;
  final Curve curve;

  _DoorDiagramState createState() => new _DoorDiagramState();
}

class _DoorDiagramState extends State<DoorDiagram> with TickerProviderStateMixin {
  AnimationController _frontController;
  AnimationController _garageController;
  AnimationController _backController;

  Animation<double> _frontValue;
  Animation<double> _garageValue;
  Animation<double> _backValue;

  @override
  void initState() {
    super.initState();
    reassemble();
  }

  @override
  void reassemble() {
    super.reassemble();
    _frontController?.dispose();
    _frontValue?.removeListener(_tick);
    _frontController = _init(config.frontDoor);
    _frontValue = _curve(_frontController);
    _garageController?.dispose();
    _garageValue?.removeListener(_tick);
    _garageController = _init(config.garageDoor);
    _garageValue = _curve(_garageController);
    _backController?.dispose();
    _backValue?.removeListener(_tick);
    _backController = _init(config.backDoor);
    _backValue = _curve(_backController);
  }

  AnimationController _init(bool state) {
    return new AnimationController(
      duration: config.duration,
      value: state == true ? 1.0 : 0.0,
      vsync: this,
    );
  }

  Animation<double> _curve(Animation<double> parent) {
    return new CurvedAnimation(parent: parent, curve: config.curve)
      ..addListener(_tick);
  }

  void _tick() {
    setState(() { });
  }

  @override
  void didUpdateConfig(DoorDiagram oldWidget) {
    _update(_frontController, config.frontDoor, oldWidget.frontDoor);
    _update(_garageController, config.garageDoor, oldWidget.garageDoor);
    _update(_backController, config.backDoor, oldWidget.backDoor);
  }

  void _update(AnimationController door, bool newState, bool oldState) {
    if (newState == oldState || newState == null)
      return;
    if (oldState == null) {
      door.value = newState ? 1.0 : 0.0;
    } else if (newState) {
      door.forward();
    } else {
      door.reverse();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _frontController.dispose();
    _frontValue.removeListener(_tick);
    _garageController.dispose();
    _garageValue.removeListener(_tick);
    _backController.dispose();
    _backValue.removeListener(_tick);
  }

  Widget build(BuildContext context) {
    return new CustomPaint(
      size: const Size(100.0, 100.0),
      painter: new _DoorPainter(
        config.frontDoor == null ? null : 1.0 - _frontValue.value,
        config.garageDoor == null ? null : 1.0 - _garageValue.value,
        config.backDoor == null ? null : 1.0 - _backValue.value,
        Theme.of(context).accentColor
      ),
    );
  }
}

class _DoorPainter extends CustomPainter {
  _DoorPainter(this.front, this.garage, this.back, this.color) {
    _doorPaint = new Paint()
      ..strokeWidth = 100.0
      ..color = color
      ..style = PaintingStyle.stroke;
    _houseOutlinePaint = new Paint()
      ..strokeWidth = 200.0
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
  }

  final double front;
  final double garage;
  final double back;
  final Color color;

  Paint _doorPaint;
  Paint _houseOutlinePaint;

  void _paintSwingDoor(Canvas canvas, Point hinge, double length, double angle) {
    canvas.save();
    canvas.translate(hinge.x, hinge.y);
    canvas.rotate(angle);
    canvas.drawLine(Point.origin, new Point(length, 0.0), _doorPaint);
    canvas.restore();
  }

  void _paintSlideDoor(Canvas canvas, Point start, Point end, double state) {
    Offset dy = new Offset(0.0, _doorPaint.strokeWidth / 2.0);
    Point middle = end + (start - end) / 2.0;
    Offset slide = (middle - start) * state;
    canvas.drawLine((start + -dy), (middle + -dy), _doorPaint);
    canvas.drawLine((middle + dy) + -slide, (end + dy) + -slide, _doorPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 11710.0, size.height / 12090.0);
    canvas.translate(50.0, 50.0);
    Path houseOutline = new Path()
      ..moveTo(5410.0, 0.0)
      ..relativeMoveTo(1980.0, 0.0) // back window
      ..relativeLineTo(4220.0, 0.0)
      ..relativeLineTo(0.0, 3330.0)
      ..relativeLineTo(-635.0, 0.0)
      ..relativeLineTo(0.0, 1600.0) // compost nook
      ..relativeLineTo(635.0, 0.0)
      ..relativeLineTo(0.0, 2790.0)
      ..relativeLineTo(0.0, 4270.0)
      ..relativeLineTo(-4075.0, 0.0)
      ..relativeMoveTo(-1000.0, 0.0) // front door
      ..relativeLineTo(-600.0, 0.0)
      ..relativeLineTo(0.0, -2590.0)
      ..relativeLineTo(-5935.0, 0.0)
      ..relativeLineTo(0.0, -6270.0)
      ..relativeLineTo(610.0, 0.0)
      ..relativeLineTo(0.0, -3150.0)
      ..relativeLineTo(4800.0, 0.0)
      ..relativeMoveTo(-4800.0, 3150.0)
      ..relativeLineTo(5325.0, 0.0)
      ..relativeLineTo(0.0, 850.0)
      ..relativeMoveTo(0.0, 900.0)
      ..relativeLineTo(0.0, 4420.0);
    canvas.drawPath(houseOutline, _houseOutlinePaint);
    if (front != null)
      _paintSwingDoor(canvas, const Point(6535.0, 11990.0), 1000.0, -front);
    if (garage != null)
      _paintSwingDoor(canvas, const Point(5935.0, 4880.0), 900.0, math.PI * 3.0 / 2.0 + garage);
    if (back != null)
      _paintSlideDoor(canvas, const Point(5410.0, 0.0), const Point(7390.0, 0.0), back);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoorPainter oldDelegate) {
    return oldDelegate.front != front
        || oldDelegate.garage != garage
        || oldDelegate.back != back;
  }
}
