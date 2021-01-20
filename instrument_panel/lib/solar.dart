import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

// TODO(ianh): fix this page, it throws on open today

class SolarPage extends StatefulWidget {
  const SolarPage({ Key key }) : super(key: key);
  @override
  _SolarPageState createState() => _SolarPageState();
}

class _SolarPageState extends State<SolarPage> {
  @override
  void initState() {
    super.initState();
    _subscription = backend.solar.power.listen(_handleData);
    _initCloudbit();
  }

  Future<void> _initCloudbit() async {
    final Stream<int> value =
        (await backend.cloud.getDevice(backend.solarDisplayId)).values;
    if (!mounted)
      return;
    _monitor = value.listen(_handleMonitor);
  }

  StreamSubscription<double> _subscription;
  StreamSubscription<int> _monitor;

  @override
  void dispose() {
    _subscription.cancel();
    _monitor?.cancel();
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
    return MainScreen(
      title: 'Solar Power',
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListBody(
                children: <Widget>[
                  FittedBox(
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      width: 300.0,
                      height: 150.0,
                      child: DialMeter(low: 0.0, high: 5.0, value: _power),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: Text(
                      'Not connected.',
                      style: Theme.of(context).textTheme.headline3,
                      textAlign: TextAlign.center,
                    ),
                    firstCurve: Curves.fastOutSlowIn,
                    secondChild: Text(
                      'Generating\n${_powerString}kW',
                      style: Theme.of(context).textTheme.headline3,
                      textAlign: TextAlign.center,
                    ),
                    secondCurve: Curves.fastOutSlowIn,
                    sizeCurve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _power == null
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
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
  const DialMeter({Key key, this.low, this.high, this.value}) : super(key: key);

  final double low;
  final double high;
  final double value;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _DialPainter(low, high, value, Theme.of(context)));
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.low, this.high, this.value, this.theme);

  final double low;
  final double high;
  final double value;
  final ThemeData theme;

  double _angleForValue(double value) {
    return math.pi * (1.0 - (value - low) / (high - low));
  }

  Offset _offsetForValue(double value, double radius, Offset center) {
    final double theta = _angleForValue(value);
    return Offset(
      center.dx + radius * math.cos(theta),
      center.dy - radius * math.sin(theta),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.height;
    final Offset center = Offset(size.width / 2.0, radius);
    final Rect box = Rect.fromCircle(
      center: center,
      radius: radius,
    );
    final Paint rimBackground = Paint()..color = theme.cardColor;
    final Paint rimBorder = Paint()
      ..color = theme.accentColor
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;
    canvas
      ..drawArc(box, math.pi, math.pi, false, rimBackground)
      ..drawArc(box, math.pi, math.pi, false, rimBorder);
    final Paint needlePaint = Paint()
      ..color = theme.accentColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    if (value != null)
      canvas.drawLine(
          center, _offsetForValue(value, radius * 0.9, center), needlePaint);
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) {
    return oldDelegate.low != low ||
        oldDelegate.high != high ||
        oldDelegate.value != value ||
        oldDelegate.theme != theme;
  }
}
