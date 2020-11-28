import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_automation_tools/all.dart';
import 'package:plexiglass/plexiglass.dart';

import 'audio.dart';
import 'credentials.dart';

const bool _soundEnabled = true;
const int _initialDesign = 0; // curved, beveled, straight
const int _maxDesign = 2; // 0..2

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Credentials credentials = Credentials('credentials.cfg');
  SecurityContext securityContext = SecurityContext()..setTrustedCertificatesBytes(File(credentials.certificatePath).readAsBytesSync());
  DatabaseStreamingClient database = DatabaseStreamingClient(
    credentials.databaseHost,
    credentials.databasePort,
    securityContext,
    0x00001001,
    64,
  );

  SystemChrome.setEnabledSystemUIOverlays([]);
  allTests();
  runApp(Dashboard(stream: database.stream));
}

class Dashboard extends StatefulWidget {
  Dashboard({ Key key, this.stream }) : super(key: key);

  final Stream<TableRecord> stream;

  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _designNumber = _initialDesign;

  Design get _design {
    switch (_designNumber) {
      case 0: return curvedDesign();
      case 1: return beveledDesign();
      case 2: return straightEdgeDesign();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AudioProvider(
      enabled: _soundEnabled,
      version: _designNumber,
      child: PlexiglassStyle(
        design: _design,
        child: Panel(
          stream: widget.stream,
          onChangeDesign: () { setState(() {
            _designNumber += 1;
            if (_designNumber > _maxDesign)
              _designNumber = 0;
          }); },
        ),
      ),
    );
  }
}

class Panel extends StatefulWidget {
  Panel({
    Key key,
    this.stream,
    this.onChangeDesign,
  }) : super(key: key);

  final Stream<TableRecord> stream;

  final VoidCallback onChangeDesign;

  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  static const double _scale = 0.5;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Style.lookup<PlexiglassScreenFrameStyle>(context).backgroundColor,
      builder: (BuildContext context, Widget navigator) => SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FittedBox(
            child: SizedBox(
              width: 1600.0 * _scale,
              height: 900.0 * _scale,
              child: BoxToFrameAdapter(
                minimumContentArea: Size(8.0, 8.0),
                frame: ScreenFrame(
                  frame: ComboFrame(
                    axis: Axis.vertical,
                    frames: <Widget>[
                      ComboChild.fixed(
                        extent: 150.0,
                        frame: DirectionFrame(
                          verticalDirection: VerticalDirection.up,
                          horizontalDirection: TextDirection.rtl,
                          frame: CornerFrame(
                            contents: DirectionFrame(
                              verticalDirection: VerticalDirection.down,
                              frame: ComboFrame(
                                axis: Axis.vertical,
                                frames: <Widget>[
                                  ComboChild.fixed(
                                    extent: 36.0,
                                    frame: FrameToItemAdapter(
                                      item: HeadingItem(value: 'HOUSE OF ROOVES DATABASE', className: 'plain-yellow'),
                                    ),
                                  ),
                                  ComboChild.fixed(
                                    extent: 1.0,
                                    frame: ComboFrame(),
                                  ),
                                  ComboChild.flex(
                                    flex: 1.0,
                                    frame: DatabaseWatcher(stream: widget.stream),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      ComboChild.flex(
                        flex: 4.0,
                        frame: DirectionFrame(
                          horizontalDirection: TextDirection.rtl,
                          frame: CornerFrame(
                            vertical: <Widget>[
                              //VerticalButton(label: 'STYLE', onPressed: widget.onChangeDesign),
                            ],
                            contents: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Button extends StatelessWidget {
  Button({ Key key, this.label, this.onPressed }) : super(key: key);

  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ButtonItem(
      value: label,
      onPressed: onPressed == null ? null : () async {
        onPressed();
        Audio.of(context).short1();
      },
    );
  }
}

class VerticalButton extends StatelessWidget {
  VerticalButton({ Key key, this.label, this.onPressed }) : super(key: key);

  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Length.fixed(
      Style.lookup<Design>(context).buttonHeight,
      item: ButtonItem(
        value: label,
        onPressed: onPressed == null ? null : () async {
          onPressed();
          Audio.of(context).short2();
        },
      ),
    );
  }
}

class VerticalCheckbox extends StatelessWidget {
  VerticalCheckbox({ Key key, this.label, this.value, this.className, this.onChanged }) : super(key: key);

  final String label;

  final bool value;

  final String className;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Length.fixed(
      Style.lookup<Design>(context).buttonHeight,
      item: CheckboxItem(
        label: label,
        value: value,
        className: className,
        onChanged: onChanged == null ? null : (bool newValue) async {
          onChanged(newValue);
          if (newValue)
            Audio.of(context).checkOn();
          else
            Audio.of(context).checkOff();
        },
      ),
    );
  }
}

class DatabaseWatcher extends StatefulWidget {
  DatabaseWatcher({ Key key, this.stream }) : super(key: key);

  final Stream<TableRecord> stream;

  @override
  State<DatabaseWatcher> createState() => _DatabaseWatcherState();
}

class _DatabaseWatcherState extends State<DatabaseWatcher> {
  Timer _timer;
  final List<String> _lines = <String>[];
  bool _recent = false;
  StreamSubscription<TableRecord> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen(_handleRecord);
  }

  @override
  void didUpdateWidget(DatabaseWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      _subscription.cancel();
      _subscription = widget.stream.listen(_handleRecord);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _handleRecord(TableRecord record) {
    setState(() {
      if (_lines.length >= 4)
        _lines.clear();
      final MeasurementPacket packet = parseFamilyRoomSensorsRecord(record);
      _lines.add(packet.parameters.map<String>((Measurement measurement) => '$measurement').join(' '));
      _recent = true;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 100), () { setState(() { _recent = false; }); });
    });
  }

  Widget _cell(line, { bool current = false }) {
    return Cell(key: Key(line), length: ItemFillWholeRemainder(), height: ItemFixed(12.0), item: TextItem(line, className: _recent && current ? 'current' : null));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = <Widget>[];
    for (int index = 0; index < _lines.length; index += 1) {
      body.add(_cell(_lines[index], current: index == _lines.length - 1));
    }
    return GridFrame(
      items: body,
    );
  }
}
