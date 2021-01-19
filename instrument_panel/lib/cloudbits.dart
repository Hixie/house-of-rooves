import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart' as backend;
import 'common.dart';

class CloudBitsPage extends StatefulWidget {
  const CloudBitsPage({ Key key }) : super(key: key);
  @override
  _CloudBitsPageState createState() => _CloudBitsPageState();
}

class _CloudBitsPageState extends State<CloudBitsPage> {
  List<backend.CloudBit> _cloudBits;
  backend.CloudBit _cloudBit;
  bool _loaded = false;

  final Map<backend.CloudBit, String> _labels = <backend.CloudBit, String>{};

  @override
  void initState() {
    super.initState();
    initLabels().catchError((Object exception) {
      assert(() {
        print(exception); // ignore: avoid_print
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
    if (_cloudBits == null)
      return;
    for (final backend.CloudBit bit in _cloudBits)
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
    return MainScreen(
      title: 'CloudBits',
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loaded
                ? _cloudBits != null
                    ? DropdownButton<backend.CloudBit>(
                        items: _cloudBits
                            .map<DropdownMenuItem<backend.CloudBit>>(
                                (backend.CloudBit bit) {
                          return DropdownMenuItem<backend.CloudBit>(
                            value: bit,
                            child: Text(_labels.containsKey(bit)
                                ? _labels[bit]
                                : bit.deviceId),
                          );
                        }).toList(),
                        value: _cloudBit,
                        onChanged: _selectCloudBit,
                      )
                    : const Text('No CloudBits.')
                : const Text('Connecting...'),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _cloudBit != null
                ? CloudBitCard(cloudBit: _cloudBit)
                : const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No CloudBit selected.'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CloudBitCard extends StatefulWidget {
  const CloudBitCard({Key key, this.cloudBit}) : super(key: key);
  final backend.CloudBit cloudBit;
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
            padding: const EdgeInsets.all(16.0),
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
          const Divider(height: 1.0),
          Padding(
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
