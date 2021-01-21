import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart' as backend;
import 'common.dart';

// TODO(ianh): include information about the button if the value is known

class CloudBitsPage extends StatefulWidget {
  const CloudBitsPage({ Key key }) : super(key: key);

  @override
  _CloudBitsPageState createState() => _CloudBitsPageState();
}

class _CloudBitsPageState extends State<CloudBitsPage> {
  @override
  Widget build(BuildContext context) {
    return MainScreen(
      title: 'CloudBits',
      body: ListView.builder(
        itemCount: backend.cloudBits.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 24.0 : 0.0, left: 24.0, right: 24.0, bottom: 24.0),
            child: CloudBitCard(cloudBit: backend.cloudBits[index])
          );
        },
      ),
    );
  }
}

class CloudBitCard extends StatefulWidget {
  const CloudBitCard({Key key, this.cloudBit}) : super(key: key);

  final backend.Localbit cloudBit;

  @override
  _CloudBitCardState createState() => _CloudBitCardState();
}

class _CloudBitCardState extends State<CloudBitCard> {
  StreamSubscription<int> _subscription;
  int _inputNumber;
  double _inputVolts;
  int _inputBitfield;
  double _outputValue = 0.0;
  int _outputNumber;
  double _outputVolts;
  int _outputBitfield;

  @override
  void initState() {
    super.initState();
    _updateSubscription();
  }

  @override
  void didUpdateWidget(CloudBitCard oldwidget) {
    super.didUpdateWidget(oldwidget);
    if (oldwidget.cloudBit != widget.cloudBit)
      _updateSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateSubscription() {
    _subscription?.cancel();
    _inputNumber = null;
    _inputVolts = null;
    _inputBitfield = null;
    _outputValue = 0.0;
    _outputNumber = null;
    _outputVolts = null;
    _subscription = widget.cloudBit.values.listen((int value) {
      final int number = value != null ? ((value / 1023.0) * 99.0).round() : null;
      final double volts = value != null ? ((value / 1023.0) * 50.0).round() / 10.0 : null;
      final int bitfield = value != null
          ? backend.BitDemultiplexer.valueToBitField(value, 4)
          : null;
      setState(() {
        _inputNumber = number;
        _inputVolts = volts;
        _inputBitfield = bitfield;
      });
    });
  }

  void _setOutputValue(double value) {
    final int number = value != null ? ((value / 1023.0) * 99.0).round() : null;
    final double volts = value != null ? ((value / 1023.0) * 50.0).round() / 10.0 : null;
    final int bitfield = value != null
        ? backend.BitDemultiplexer.valueToBitField(value.round(), 4)
        : null;
    setState(() {
      _outputValue = value;
      _outputNumber = number;
      _outputVolts = volts;
      _outputBitfield = bitfield;
    });
    widget.cloudBit.setValue(value.round());
  }

  Widget _buildLed(backend.LedColor color) {
    return CloudBitLedButton(
      color: color,
      onPressed: () {
        widget.cloudBit.setLedColor(color);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Theme.of(context).textTheme.headline5;
    final TextStyle valueStyle =
        labelStyle.copyWith(color: Theme.of(context).accentColor);
    final TextStyle smallLabelStyle = Theme.of(context).textTheme.caption;
    final TextStyle smallValueStyle =
        smallLabelStyle.copyWith(color: Theme.of(context).accentColor);
    return Card(
      child: ListBody(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
            child: Text(widget.cloudBit.displayName, style: Theme.of(context).textTheme.headline4),
          ),
          const Divider(),
          if (_inputNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      style: labelStyle,
                      text: 'Input value: ',
                      children: <TextSpan>[
                        TextSpan(
                            text: _inputNumber != null ? '$_inputNumber' : '-',
                            style: valueStyle),
                        TextSpan(text: ' (', style: labelStyle),
                        TextSpan(
                            text: _inputVolts != null
                                ? _inputVolts.toStringAsFixed(1)
                                : '-',
                            style: valueStyle),
                        TextSpan(
                            text: 'V',
                            style: labelStyle.apply(fontSizeFactor: 0.7)),
                        TextSpan(text: ') ', style: labelStyle),
                      ],
                    ),
                  ),
                  Leds(value: _inputBitfield, bitCount: 4, size: 15.0),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: ListBody(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                        style: labelStyle,
                        text: 'Output value: ',
                        children: <TextSpan>[
                          TextSpan(
                              text: _outputNumber != null
                                  ? '$_outputNumber'
                                  : '-',
                              style: valueStyle),
                          TextSpan(text: ' (', style: labelStyle),
                          TextSpan(
                              text: _outputVolts != null
                                  ? _outputVolts.toStringAsFixed(1)
                                  : '-',
                              style: valueStyle),
                          TextSpan(
                              text: 'V',
                              style: labelStyle.apply(fontSizeFactor: 0.7)),
                          TextSpan(text: ') ', style: labelStyle),
                        ],
                      ),
                    ),
                    Leds(value: _outputBitfield, bitCount: 4, size: 15.0),
                  ],
                ),
                Slider(
                  value: _outputValue,
                  onChanged: _setOutputValue,
                  max: 1023.0,
                  label: _outputVolts?.toStringAsFixed(1) ?? '?',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 48.0),
              child: FittedBox(
                child: Row(children: backend.LedColor.values.map<Widget>(_buildLed).toList()),
              ),
            ),
          ),
          const Divider(height: 1.0),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      style: smallLabelStyle,
                      text: 'Device ID: ',
                      children: <TextSpan>[
                        TextSpan(
                          text: widget.cloudBit != null
                              ? widget.cloudBit.deviceId
                              : '-',
                          style: smallValueStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RichText(
                  text: TextSpan(
                    style: smallLabelStyle,
                    text: 'Hostname: ',
                    children: <TextSpan>[
                      TextSpan(
                        text: widget.cloudBit != null
                            ? widget.cloudBit.hostname
                            : '-',
                        style: smallValueStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Leds extends StatelessWidget {
  const Leds({
    Key key,
    @required this.value,
    @required this.bitCount,
    this.color,
    @required this.size,
  }) : super(key: key);

  final int value;
  final int bitCount;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = value != null
        ? this.color ?? Theme.of(context).accentColor
        : Theme.of(context).disabledColor;
    final List<Widget> dots = <Widget>[];
    for (int i = 1; i <= bitCount; i += 1) {
      dots.add(Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color:
              (value != null) && (value & (1 << (i - 1)) != 0) ? color : null,
          shape: BoxShape.circle,
          border: Border.all(width: size / 10.0, color: color),
        ),
        height: size,
        width: size,
      ));
    }
    return Row(children: dots);
  }
}

class CloudBitLedButton extends StatefulWidget {
  const CloudBitLedButton({ Key key, this.onPressed, this.color }) : super(key: key);

  final VoidCallback onPressed;
  final backend.LedColor color;

  @override
  _CloudBitLedButton createState() => _CloudBitLedButton();
}

class _CloudBitLedButton extends State<CloudBitLedButton> {
  Timer _timer;
  Stopwatch _pressed;

  static const Duration _highlightDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    super.dispose();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color((0xFF000000)
      | ((widget.color.index & 0x02 > 0) ? 0x00FF0000 : 0)
      | ((widget.color.index & 0x04 > 0) ? 0x0000FF00 : 0)
      | ((widget.color.index & 0x01 > 0) ? 0x000000FF : 0)
    );
    return AnimatedContainer(
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      height: 8.0,
      width: 8.0,
      decoration: ShapeDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: _pressed == null ? <Color>[Color.lerp(Colors.white, color, 0.5), color]
                                   : <Color>[color, Color.lerp(Colors.black, color, 0.5)],
        ),
        shape: const CircleBorder(
          side: BorderSide(width: 0.0, color: Colors.grey),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutQuart,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          setState(() {
            _timer?.cancel();
            _timer = null;
            _pressed = Stopwatch()..start();
          });
        },
        onTapUp: (TapUpDetails details) {
          if (widget.onPressed != null)
            widget.onPressed();
          _timer = Timer(_highlightDuration - _pressed.elapsed, () {
            if (mounted) {
              setState(() {
                _timer = null;
                _pressed = null;
              });
            }
          });
        },
        onTapCancel: () {
          setState(() {
            _timer?.cancel();
            _timer = null;
            _pressed = null;
          });
        },
      ),
    );
  }
}
