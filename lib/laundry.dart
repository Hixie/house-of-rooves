import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';

class LaundryPage extends StatefulWidget {
  @override
  _LaundryPageState createState() => new _LaundryPageState();
}

class _LaundryPageState extends State<LaundryPage> {
  @override
  void initState() {
    super.initState();
    backend.BitDemultiplexer laundryBits = new backend.BitDemultiplexer(backend.cloud.getDevice(backend.laundryId).values, 4);
    _bit1Subscription = laundryBits[1].transform(debouncer).listen(_handleDoneLedBit); // 5 - Done
    _bit2Subscription = laundryBits[2].transform(debouncer).listen(_handleSensingLedBit); // 10 - Sensing
    _bit3Subscription = laundryBits[3].transform(debouncer).listen(_handleButtonBit); // 20 - Button
    _bit4Subscription = laundryBits[4].transform(debouncer).listen(_handleDryerBit); // 40 - Dryer
  }

  StreamSubscription<bool> _bit1Subscription;
  StreamSubscription<bool> _bit2Subscription;
  StreamSubscription<bool> _bit3Subscription;
  StreamSubscription<bool> _bit4Subscription;

  @override
  void dispose() {
    _bit1Subscription.cancel();
    _bit2Subscription.cancel();
    _bit3Subscription.cancel();
    _bit4Subscription.cancel();
    super.dispose();
  }

  bool _washerDoneLed;
  bool _washerSensorsLed;
  bool _washerFullButton;
  bool _dryerDrying;

  void _handleDoneLedBit(bool value) {
    setState(() { _washerDoneLed = value; });
  }

  void _handleSensingLedBit(bool value) {
    setState(() { _washerSensorsLed = value; });
  }

  void _handleButtonBit(bool value) {
    setState(() { _washerFullButton = value; });
  }

  void _handleDryerBit(bool value) {
    setState(() { _dryerDrying = value; });
  }

  @override
  Widget build(BuildContext context) {
    return new MainScreen(
      title: 'Laundry',
      body: new Container(
        padding: new EdgeInsets.all(4.0),
        child: new SizedBox.expand(
          child: new FittedBox(
            alignment: new FractionalOffset(0.5, 0.15),
            child: new CustomPaint(
              size: const Size(100.0, 100.0),
              painter: new _LaundryPainter(
                washerSensorsLed: _washerSensorsLed,
                washerDoneLed: _washerDoneLed,
                dryerDrying: _dryerDrying,
                washerFullButton: _washerFullButton,
                color: Theme.of(context).accentColor,
                style: Theme.of(context).textTheme.body2.copyWith(letterSpacing: 0.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextPainterConfig {
  _TextPainterConfig({
    this.text,
    this.fontSize,
    this.textAlign,
    this.width,
    this.style,
  });
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final double width;
  final TextStyle style;

  TextPainter createTextPainter() {
    return new TextPainter(
      text: new TextSpan(
        text: text,
        style: style.copyWith(fontSize: fontSize),
      ),
      textAlign: textAlign,
    )
      ..layout(minWidth: width, maxWidth: width);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    _TextPainterConfig typedOther = other;
    return typedOther.text == text
        && typedOther.fontSize == fontSize
        && typedOther.textAlign == textAlign
        && typedOther.width == width
        && typedOther.style == style;
  }

  @override
  int get hashCode => hashValues(text, fontSize, textAlign, width, style);
}

class _LaundryPainter extends CustomPainter {
  _LaundryPainter({ this.washerSensorsLed, this.washerDoneLed, this.dryerDrying, this.washerFullButton, this.color, this.style }) {
    _ledOnPaint = new Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    _ledOffPaint = new Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    _outlinePaint = new Paint()
      ..strokeWidth = 2.0
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
  }

  final bool washerSensorsLed;
  final bool washerDoneLed;
  final bool dryerDrying;
  final bool washerFullButton;
  final Color color;
  final TextStyle style;

  Paint _ledOnPaint;
  Paint _ledOffPaint;
  Paint _outlinePaint;

  static Map<_TextPainterConfig, TextPainter> _painters = <_TextPainterConfig, TextPainter>{};

  void _paintLed(Canvas canvas, Point position, String text, { bool on, bool labelAfter, double radius, double width }) {
    canvas.drawCircle(position, radius, on == true ? _ledOnPaint : _ledOffPaint);
    _TextPainterConfig config = new _TextPainterConfig(
      text: text,
      fontSize: radius * 2.0,
      textAlign: labelAfter ? TextAlign.left : TextAlign.right,
      width: width,
      style: style,
    );
    TextPainter painter = _painters.putIfAbsent(config, () => config.createTextPainter());
    Offset textTopLeft = position - new Point(labelAfter ? radius * -2.0 : painter.size.width + radius * 2.0, radius * 1.5);
    painter.paint(canvas, textTopLeft);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double horizontalUnit = size.width / 13.0;
    double verticalUnit = size.height / 10.0;

    Path path = new Path()
      ..moveTo(horizontalUnit, verticalUnit * 2.0)
      ..relativeLineTo(5.0 * horizontalUnit, 0.0)
      ..relativeLineTo(0.0, 6.0 * verticalUnit)
      ..relativeLineTo(-5.0 * horizontalUnit, 0.0)
      ..close()
      ..moveTo(horizontalUnit, verticalUnit * 4.0)
      ..relativeLineTo(5.0 * horizontalUnit, 0.0)
      ..moveTo(horizontalUnit * 7.0, verticalUnit * 2.0)
      ..relativeLineTo(5.0 * horizontalUnit, 0.0)
      ..relativeLineTo(0.0, 6.0 * verticalUnit)
      ..relativeLineTo(-5.0 * horizontalUnit, 0.0)
      ..close()
      ..moveTo(horizontalUnit * 7.0, verticalUnit * 4.0)
      ..relativeLineTo(5.0 * horizontalUnit, 0.0);
    canvas.drawPath(path, _outlinePaint);
    
    _paintLed(canvas, new Point(horizontalUnit * 1.75, verticalUnit * 2.55), 'Sensing',
      on: washerSensorsLed, labelAfter: true, radius: horizontalUnit * 0.25, width: horizontalUnit * 3.25);
    _paintLed(canvas, new Point(horizontalUnit * 5.25, verticalUnit * 3.45), 'Done',
      on: washerDoneLed, labelAfter: false, radius: horizontalUnit * 0.25, width: horizontalUnit * 3.25);
    _paintLed(canvas, new Point(horizontalUnit * 8.0, verticalUnit * 3.0), 'Drying',
      on: dryerDrying, labelAfter: true, radius: horizontalUnit * 0.25, width: horizontalUnit * 3.0);
    _paintLed(canvas, new Point(horizontalUnit * 5.25, verticalUnit * 5.0), 'Button',
      on: washerFullButton, labelAfter: false, radius: horizontalUnit * 0.25, width: horizontalUnit * 3.25);

    _TextPainterConfig config;
    TextPainter painter;

    config = new _TextPainterConfig(
      text: 'WASHER',
      fontSize: verticalUnit * 0.25,
      textAlign: TextAlign.center,
      width: horizontalUnit * 5.0,
      style: style,
    );
    painter = _painters.putIfAbsent(config, () => config.createTextPainter());
    painter.paint(canvas, new Offset(horizontalUnit, verticalUnit * 8.5));

    config = new _TextPainterConfig(
      text: 'DRYER',
      fontSize: verticalUnit * 0.25,
      textAlign: TextAlign.center,
      width: horizontalUnit * 5.0,
      style: style,
    );
    painter = _painters.putIfAbsent(config, () => config.createTextPainter());
    painter.paint(canvas, new Offset(horizontalUnit * 7.0, verticalUnit * 8.5));
  }

  @override
  bool shouldRepaint(_LaundryPainter oldDelegate) {
    return washerSensorsLed != oldDelegate.washerSensorsLed
        || washerDoneLed != oldDelegate.washerDoneLed
        || dryerDrying != oldDelegate.dryerDrying
        || washerFullButton != oldDelegate.washerFullButton
        || color != oldDelegate.color;
  }
}
