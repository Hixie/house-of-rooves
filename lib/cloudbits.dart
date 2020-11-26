import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart' as backend;
import 'common.dart';

class CloudBitsPage extends StatefulWidget {
  @override
  _CloudBitsPageState createState() => new _CloudBitsPageState();
}

class _CloudBitsPageState extends State<CloudBitsPage> {
  List<backend.CloudBit> _cloudBits;
  backend.CloudBit _cloudBit;
  bool _loaded = false;

  Map<backend.CloudBit, String> _labels = <backend.CloudBit, String>{};

  void initState() {
    super.initState();
    initLabels().catchError((dynamic exception) {
      assert(() {
        print(exception);
      }());
    });
  }

  Future<void> initLabels() async {
    _cloudBits = await backend.cloud.listDevices().toList();
    _loaded = true;
    if (_cloudBits.isEmpty) {
      setState(() {
        _cloudBits = null;
      });
    } else {
      _selectCloudBit(_cloudBits.first);
    }
    if (_cloudBits == null) return null;
    for (backend.CloudBit bit in _cloudBits)
      setState(() {
        _labels[bit] = bit.displayName;
      });
  }

  void _selectCloudBit(backend.CloudBit value) {
    setState(() {
      _cloudBit = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MainScreen(
      title: 'CloudBits',
      body: new ListView(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(16.0),
            child: _loaded
                ? _cloudBits != null
                    ? new DropdownButton(
                        items: _cloudBits
                            .map/*<DropdownMenuItem<backend.CloudBit>>*/(
                                (backend.CloudBit bit) {
                          return new DropdownMenuItem(
                            value: bit,
                            child: new Text(_labels.containsKey(bit)
                                ? _labels[bit]
                                : bit.deviceId),
                          );
                        }).toList(),
                        value: _cloudBit,
                        onChanged: _selectCloudBit,
                      )
                    : new Text('No CloudBits.')
                : new Text('Connecting...'),
          ),
          new Padding(
            padding: new EdgeInsets.all(24.0),
            child: _cloudBit != null
                ? new CloudBitCard(cloudBit: _cloudBit)
                : new Card(
                    child: new Padding(
                      padding: new EdgeInsets.all(24.0),
                      child: new Text('No CloudBit selected.'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CloudBitCard extends StatefulWidget {
  CloudBitCard({Key key, this.cloudBit}) : super(key: key);
  final backend.CloudBit cloudBit;
  _CloudBitCardState createState() => new _CloudBitCardState();
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

  void initState() {
    super.initState();
    _updateSubscription();
  }

  @override
  void didUpdateWidget(CloudBitCard oldwidget) {
    super.didUpdateWidget(oldwidget);
    if (oldwidget.cloudBit != widget.cloudBit) _updateSubscription();
  }

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
      int number = value != null ? ((value / 1023.0) * 99.0).round() : null;
      double volts =
          value != null ? ((value / 1023.0) * 50.0).round() / 10.0 : null;
      int bitfield = value != null
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
    int number = value != null ? ((value / 1023.0) * 99.0).round() : null;
    double volts =
        value != null ? ((value / 1023.0) * 50.0).round() / 10.0 : null;
    int bitfield = value != null
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

  Widget build(BuildContext context) {
    final TextStyle labelStyle = Theme.of(context).textTheme.headline5;
    final TextStyle valueStyle =
        labelStyle.copyWith(color: Theme.of(context).accentColor);
    final TextStyle smallLabelStyle = Theme.of(context).textTheme.caption;
    final TextStyle smallValueStyle =
        smallLabelStyle.copyWith(color: Theme.of(context).accentColor);
    return new Card(
      child: new ListBody(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new RichText(
                  text: new TextSpan(
                    style: labelStyle,
                    text: 'Input value: ',
                    children: <TextSpan>[
                      new TextSpan(
                          text: _inputNumber != null ? '$_inputNumber' : '-',
                          style: valueStyle),
                      new TextSpan(text: ' (', style: labelStyle),
                      new TextSpan(
                          text: _inputVolts != null
                              ? _inputVolts.toStringAsFixed(1)
                              : '-',
                          style: valueStyle),
                      new TextSpan(
                          text: 'V',
                          style: labelStyle.apply(fontSizeFactor: 0.7)),
                      new TextSpan(text: ') ', style: labelStyle),
                    ],
                  ),
                ),
                new Leds(value: _inputBitfield, bitCount: 4, size: 15.0),
              ],
            ),
          ),
          new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new ListBody(
              children: <Widget>[
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new RichText(
                      text: new TextSpan(
                        style: labelStyle,
                        text: 'Output value: ',
                        children: <TextSpan>[
                          new TextSpan(
                              text: _outputNumber != null
                                  ? '$_outputNumber'
                                  : '-',
                              style: valueStyle),
                          new TextSpan(text: ' (', style: labelStyle),
                          new TextSpan(
                              text: _outputVolts != null
                                  ? _outputVolts.toStringAsFixed(1)
                                  : '-',
                              style: valueStyle),
                          new TextSpan(
                              text: 'V',
                              style: labelStyle.apply(fontSizeFactor: 0.7)),
                          new TextSpan(text: ') ', style: labelStyle),
                        ],
                      ),
                    ),
                    new Leds(value: _outputBitfield, bitCount: 4, size: 15.0),
                  ],
                ),
                new Slider(
                  value: _outputValue,
                  onChanged: _setOutputValue,
                  min: 0.0,
                  max: 1023.0,
                  label: _outputVolts?.toStringAsFixed(1) ?? '?',
                ),
              ],
            ),
          ),
          new Divider(height: 1.0),
          new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new RichText(
              text: new TextSpan(
                style: smallLabelStyle,
                text: 'Device ID: ',
                children: <TextSpan>[
                  new TextSpan(
                      text: widget.cloudBit != null
                          ? widget.cloudBit.deviceId
                          : '-',
                      style: smallValueStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Leds extends StatelessWidget {
  Leds({
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

  Widget build(BuildContext context) {
    Color color = value != null
        ? this.color ?? Theme.of(context).accentColor
        : Theme.of(context).disabledColor;
    List<Widget> dots = <Widget>[];
    for (int i = 1; i <= bitCount; i += 1) {
      dots.add(new Container(
        margin: new EdgeInsets.all(2.0),
        decoration: new BoxDecoration(
          color:
              (value != null) && (value & (1 << (i - 1)) != 0) ? color : null,
          shape: BoxShape.circle,
          border: new Border.all(width: size / 10.0, color: color),
        ),
        height: size,
        width: size,
      ));
    }
    return new Row(children: dots);
  }
}
