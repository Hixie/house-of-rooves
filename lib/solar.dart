import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

class SolarPage extends StatefulWidget {
  @override
  _SolarPageState createState() => new _SolarPageState();
}

class _SolarPageState extends State<SolarPage> {
  @override
  void initState() {
    super.initState();
    _subscription = backend.solar.power.listen(_handleData);
    _monitor = backend.cloud.getDevice(backend.solarDisplayId).values.listen(_handleMonitor);
  }

  StreamSubscription<double> _subscription;
  StreamSubscription<int> _monitor;

  @override
  void dispose() {
    _subscription.cancel();
    _monitor.cancel();
    super.dispose();
  }

  double _power;
  String _powerString = '-';

  void _handleData(double power) {
    setState(() {
      _power = power;
      if (_power != null)
        _powerString = _power.toStringAsFixed(1);
    });
  }

  bool _monitorConnected = false;

  void _handleMonitor(int monitor) {
    setState(() {
      _monitorConnected = monitor != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MainScreen(
      title: 'Solar Power',
      body: new Block(
        padding: new EdgeInsets.all(24.0),
        children: <Widget>[
          new Card(
            child: new Padding(
              padding: new EdgeInsets.all(24.0),
              child: new BlockBody(
                children: <Widget>[
                  new FittedBox(
                    child: new Container(
                      padding: new EdgeInsets.all(24.0),
                      width: 300.0,
                      height: 150.0,
                      child: new DialMeter(low: 0.0, high: 5.0, value: _power),
                    ),
                  ),
                  new AnimatedCrossFade(
                    firstChild: new Text(
                      'Not connected.',
                      style: Theme.of(context).textTheme.display2,
                      textAlign: TextAlign.center,
                    ),
                    firstCurve: Curves.fastOutSlowIn,
                    secondChild: new Text(
                      'Generating\n${_powerString}kW',
                      style: Theme.of(context).textTheme.display2,
                      textAlign: TextAlign.center,
                    ),
                    secondCurve: Curves.fastOutSlowIn,
                    sizeCurve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _power == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  ),
                ],
              ),
            ),
          ),
          new SizedBox(height: 24.0),
          new Card(
            child: new Padding(
              padding: new EdgeInsets.all(24.0),
              child: new Text(
                'Living room wall-mounted status display ${_monitorConnected ? "active" : "offline"}.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DialMeter extends StatelessWidget {
  DialMeter({ Key key, this.low, this.high, this.value }) : super(key: key);

  final double low;
  final double high;
  final double value;

  Widget build(BuildContext context) {
    return new CustomPaint(painter: new _DialPainter(low, high, value, Theme.of(context)));
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.low, this.high, this.value, this.theme);

  final double low;
  final double high;
  final double value;
  final ThemeData theme;

  double _angleForValue(double value) {
    return math.PI * (1.0 - (value - low) / (high - low));
  }

  Point _pointForValue(double value, double radius, Point center) {
    double theta = _angleForValue(value);
    return new Point(
      center.x + radius * math.cos(theta),
      center.y - radius * math.sin(theta),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.height;
    Point center = new Point(size.width / 2.0, radius);
    Rect box = new Rect.fromCircle(
      center: center,
      radius: radius,
    );
    Paint rimBackground = new Paint()
      ..color = theme.cardColor;
    Paint rimBorder = new Paint()
      ..color = theme.accentColor
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(box, math.PI, math.PI, false, rimBackground);
    canvas.drawArc(box, math.PI, math.PI, false, rimBorder);
    Paint needlePaint = new Paint()
      ..color = theme.accentColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    if (value != null)
      canvas.drawLine(center, _pointForValue(value, radius * 0.9, center), needlePaint);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) {
    return oldDelegate.low != low
        || oldDelegate.high != high
        || oldDelegate.value != value
        || oldDelegate.theme != theme;
  }
}
