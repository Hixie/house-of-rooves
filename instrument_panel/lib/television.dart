import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';
import 'components/app_bar_action.dart';
import 'components/auto_fade.dart';

const Duration _autoFadeDuration = const Duration(milliseconds: 250);

String message;

class TelevisionPage extends StatefulWidget {
  @override
  _TelevisionPageState createState() => new _TelevisionPageState();
}

class _TelevisionPageState extends State<TelevisionPage> {
  bool _connected = false;
  bool _checking = false;
  bool _busy = false;
  bool _power;
  backend.TelevisionChannel _input;
  int _volume;
  double _userVolume; // the value the user has picked
  bool _muted;
  int _offTimer;
  String _name;
  String _model;
  String _softwareVersion;
  bool _demoOverlay;

  @override
  void initState() {
    super.initState();
    _periodicUpdater =
        new Timer.periodic(const Duration(seconds: 15), (Timer timer) {
      _updateStatus();
    });
    _updateStatus();
    _connectionListener = backend.television.connected.listen((bool data) {
      setState(() {
        assert(data != null);
        _connected = data;
      });
    });
  }

  Timer _periodicUpdater;
  Timer _requestedUpdater;
  StreamSubscription<bool> _connectionListener;
  Timer _volumeUi;

  Future<Null> _updateStatus() async {
    if (_checking) return;
    _requestedUpdater?.cancel();
    try {
      if (!mounted) return;
      setState(() {
        _checking = true;
      });
      bool power = await backend.television.power;
      if (!mounted) return;
      setState(() {
        _power = power;
      });
      backend.TelevisionChannel input = await backend.television.input;
      if (!mounted) return;
      setState(() {
        _input = input;
      });
      if (power) {
        int volume = await backend.television.volume;
        if (!mounted) return;
        setState(() {
          _volume = volume;
        });
        bool muted = await backend.television.muted;
        if (!mounted) return;
        setState(() {
          _muted = muted;
        });
        int offTimer = await backend.television.offTimer;
        if (!mounted) return;
        setState(() {
          _offTimer = offTimer;
        });
        String name = await backend.television.name;
        if (!mounted) return;
        setState(() {
          _name = name;
        });
        String model = await backend.television.model;
        if (!mounted) return;
        setState(() {
          _model = model;
        });
        String softwareVersion = await backend.television.softwareVersion;
        if (!mounted) return;
        setState(() {
          _softwareVersion = softwareVersion;
        });
        bool demoOverlay = await backend.television.demoOverlay;
        if (!mounted) return;
        setState(() {
          _demoOverlay = demoOverlay;
        });
      } else {
        setState(() {
          _volume = null;
          _muted = null;
          _offTimer = 0;
          _name = null;
          _model = null;
          _softwareVersion = null;
        });
      }
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
    });
    _requestedUpdater = null;
  }

  void _triggerUpdate() {
    _requestedUpdater ??= new Timer(const Duration(milliseconds: 200), () {
      _updateStatus();
    });
  }

  void dispose() {
    _connectionListener.cancel();
    _periodicUpdater.cancel();
    _requestedUpdater?.cancel();
    _volumeUi?.cancel();
    super.dispose();
  }

  void _reportError(dynamic error, StackTrace stack) {
    debugPrint('Reporting error to user:\n$error\n$stack\n');
    Scaffold.of(context)
        .showSnackBar(new SnackBar(content: new Text(error.toString())));
  }

  // INPUT HANDLERS

  void _handleCancel() {
    backend.television.abort('Canceled request, disconnecting...');
    _triggerUpdate();
  }

  String get _powerMessage {
    if (_power == false) return 'OFF';
    if (_offTimer == null) {
      if (_power == true) return 'ON';
      return 'UNKNOWN';
    }
    if (_offTimer == 0) return 'OFF';
    return 'OFF IN $_offTimer MINUTES';
  }

  Future<Null> _handlePowerOn() async {
    setState(() {
      _busy = true;
    });
    _triggerUpdate();
    try {
      await backend.television.setPower(true);
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
    if (!mounted) return;
    _triggerUpdate();
    setState(() {
      _busy = false;
    });
  }

  Future<Null> _handlePowerTimerInput() async {
    backend.TelevisionOffTimer offTimer = await showOffTimerDialog();
    if (offTimer != null) {
      try {
        await backend.television.setOffTimer(offTimer);
      } catch (error, stack) {
        if (!mounted) return;
        _reportError(error, stack);
      }
      if (!mounted) return;
      _triggerUpdate();
    }
  }

  Future<Null> _handleRemote(backend.TelevisionRemote button) async {
    try {
      await backend.television.sendRemote(button);
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
    if (!mounted) return;
    _triggerUpdate();
  }

  Future<Null> _handleSelectInput() async {
    backend.TelevisionChannel channel = await showInputDialog();
    if (channel != null) {
      setState(() {
        _busy = true;
      });
      _triggerUpdate();
      try {
        await backend.television.setInput(channel);
      } catch (error, stack) {
        if (!mounted) return;
        _reportError(error, stack);
      }
      if (!mounted) return;
      _triggerUpdate();
      setState(() {
        _busy = false;
      });
    }
  }

  Future<Null> _handleNextInput() async {
    setState(() {
      _busy = true;
    });
    _triggerUpdate();
    try {
      await backend.television.nextInput();
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
    if (!mounted) return;
    _triggerUpdate();
    setState(() {
      _busy = false;
    });
  }

  bool _sendingVolume = false;
  Future<Null> _handleVolumeChanged(double value) async {
    setState(() {
      _userVolume = value;
    });
    _volumeUi?.cancel();
    _volumeUi = new Timer(
      const Duration(milliseconds: 250),
      () {
        if (!_sendingVolume) _userVolume = null;
      },
    );
    if (_sendingVolume) return;
    _sendingVolume = true;
    do {
      // send the new value
      try {
        await backend.television.setVolume(_userVolume.round());
        if (!mounted) return;
        await new Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
        // update volume and muted in the UI
        int volume = await backend.television.volume;
        if (!mounted) return;
        setState(() {
          _volume = volume;
        });
        bool muted = await backend.television.muted;
        if (!mounted) return;
        setState(() {
          _muted = muted;
        });
      } catch (error, stack) {
        if (!mounted) return;
        _reportError(error, stack);
      }
    } while (_volume != _userVolume.round());
    _sendingVolume = false;
  }

  Future<Null> _handleMute() async {
    setState(() {
      _busy = true;
    });
    try {
      if (_muted == true) {
        await backend.television.setMuted(false);
      } else if (_muted == false) {
        await backend.television.setMuted(true);
      } else {
        await backend.television.toggleMuted();
      }
      if (!mounted) return;
      await new Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      bool muted = await backend.television.muted;
      if (!mounted) return;
      setState(() {
        _muted = muted;
      });
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
  }

  Future<Null> _handleDisplayMessage(String message) async {
    try {
      await backend.television.displayMessage(message);
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
  }

  Future<Null> _handleDemoOverlay(bool value) async {
    try {
      await backend.television.setDemoOverlay(value);
      if (!mounted) return;
      bool demoOverlay = await backend.television.demoOverlay;
      if (!mounted) return;
      setState(() {
        _demoOverlay = demoOverlay;
      });
    } catch (error, stack) {
      if (!mounted) return;
      _reportError(error, stack);
    }
  }

  // INTERFACE DESCRIPTIONS

  Future<backend.TelevisionChannel> showInputDialog() {
    return showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.off));
            },
            child: new Text('OFF'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi1));
            },
            child: new Text('HDMI1 (bristol)'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi2));
            },
            child: new Text('HDMI2 (kitten)'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi3));
            },
            child: new Text('HDMI3 (pi)'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi4));
            },
            child: new Text('HDMI4 (roku)'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.composite));
            },
            child: new Text('COMPOSITE'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.component));
            },
            child: new Text('COMPONENT'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.ethernet));
            },
            child: new Text('HOME NETWORK'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.storage));
            },
            child: new Text('SD CARD'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.miracast));
            },
            child: new Text('MIRACAST'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.bluetooth));
            },
            child: new Text('BLUETOOTH'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  new backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.manual));
            },
            child: new Text('HELP SCREEN'),
          ),
        ],
      ),
    );
  }

  Future<backend.TelevisionOffTimer> showOffTimerDialog() {
    return showDialog(
      context: context,
      child: new SimpleDialog(
        children: <Widget>[
          new FlatButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min30);
            },
            child: new Text('30 MINUTES'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min60);
            },
            child: new Text('60 MINUTES'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min90);
            },
            child: new Text('90 MINUTES'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min120);
            },
            child: new Text('120 MINUTES'),
          ),
          new FlatButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.disabled);
            },
            child:
                new Text(_offTimer != null ? 'CANCEL TIMER' : 'NO OFF TIMER'),
          ),
        ],
      ),
    );
  }

  Future<String> showMessageDialog() {
    String result;
    return showDialog(
      context: context,
      child: new Form(
        child: new Builder(builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('On-screen message'),
            content: new ListView(
              children: <Widget>[
                new TextField(
                  decoration: InputDecoration(helperText: 'Message text?'),
                  onSubmitted: (String value) {
                    result = value;
                  },
                ),
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: new Text('CANCEL'),
              ),
              new FlatButton(
                onPressed: () {
                  Form.of(context).save();
                  Navigator.pop(context, result);
                },
                child: new Text('SEND'),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = IconThemeData.fallback().size;
    final TextStyle headline = Theme.of(context).textTheme.headline5;
    final TextStyle title = Theme.of(context).textTheme.headline6;
    final TextStyle titleLight = title.copyWith(fontWeight: FontWeight.w100);
    final TextStyle caption = Theme.of(context).textTheme.caption;
    final TextStyle captionLight =
        caption.copyWith(fontWeight: FontWeight.w100);
    return new MainScreen(
      title: 'Television',
      actions: <Widget>[
        new AppBarAction(
          tooltip: 'Whether a connection to the television is active.',
          child: new Icon(
            _connected ? Icons.cast_connected : Icons.cast,
          ),
        ),
        new AutoFade(
          duration: _autoFadeDuration,
          token: _busy ? 0 : _checking ? 1 : 2,
          child: _busy
              ? new IconButton(
                  onPressed: _handleCancel,
                  tooltip: 'Cancel and disconnect.',
                  icon: new Icon(Icons.cancel),
                )
              : _checking
                  ? new AppBarAction(
                      child: new SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: new CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : new IconButton(
                      onPressed: _triggerUpdate,
                      tooltip: 'Refresh the current state.',
                      icon: new Icon(Icons.refresh),
                    ),
        ),
      ],
      body: new SizedBox.expand(
        child: new ListView(
          padding: new EdgeInsets.all(16.0),
          children: <Widget>[
            new SizedBox(
              height: ButtonTheme.of(context).height,
              child: new AutoFade(
                duration: _autoFadeDuration,
                token: _power,
                child: _power == true
                    ? new Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Expanded(
                            child: new Text(
                              _name ?? '■■■■■■',
                              style: headline,
                            ),
                          ),
                          new Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              new RichText(
                                textAlign: TextAlign.right,
                                text: new TextSpan(
                                  text: 'MODEL ',
                                  style: captionLight,
                                  children: <TextSpan>[
                                    new TextSpan(
                                      text: _model ?? '■■■',
                                      style: caption,
                                    ),
                                  ],
                                ),
                              ),
                              new RichText(
                                textAlign: TextAlign.right,
                                text: new TextSpan(
                                  text: 'FIRMWARE ',
                                  style: captionLight,
                                  children: <TextSpan>[
                                    new TextSpan(
                                      text: _softwareVersion ?? '■■■',
                                      style: caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new FlatButton(
                            child: new Text('POWER ON'),
                            onPressed: _handlePowerOn,
                          ),
                        ],
                      ),
              ),
            ),
            new SizedBox(height: 16.0),
            new Row(
              children: <Widget>[
                new Expanded(
                  child: new RichText(
                    text: new TextSpan(
                      text: 'POWER ',
                      style: titleLight,
                      children: <TextSpan>[
                        new TextSpan(
                          text: _powerMessage,
                          style: title,
                        ),
                      ],
                    ),
                  ),
                ),
                new FlatButton(
                  child: new Text('TIMER'),
                  onPressed: _power != false ? _handlePowerTimerInput : null,
                ),
              ],
            ),
            new SizedBox(height: 8.0),
            new Row(
              children: <Widget>[
                new Expanded(
                  child: new RichText(
                    text: new TextSpan(
                      text: 'INPUT ',
                      style: titleLight,
                      children: <TextSpan>[
                        new TextSpan(
                          text: _input != null
                              ? _input.toString().toUpperCase()
                              : 'UNKNOWN',
                          style: title,
                        ),
                      ],
                    ),
                  ),
                ),
                new FlatButton(
                  child: new Text('SELECT'),
                  onPressed: _busy ? null : _handleSelectInput,
                ),
                new FlatButton(
                  child: new Text('NEXT'),
                  onPressed: _busy || _power == false ? null : _handleNextInput,
                ),
              ],
            ),
            new SizedBox(height: 8.0),
            new Row(
              children: <Widget>[
                new IconButton(
                    icon: new Icon(Icons.volume_down),
                    tooltip: 'Volume Down',
                    onPressed: _power != false && !_busy
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyVolDown);
                          }
                        : null),
                new Expanded(
                  child: new Slider(
                    value: _userVolume ?? _volume?.toDouble() ?? 0.0,
                    onChanged:
                        _volume != null && !_busy ? _handleVolumeChanged : null,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                  ),
                ),
                new IconButton(
                    icon: new Icon(Icons.volume_up),
                    tooltip: 'Volume Up',
                    onPressed: _power != false && !_busy
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyVolUp);
                          }
                        : null),
                new IconButton(
                  icon: new Icon(
                      _muted == true ? Icons.volume_off : Icons.volume_up),
                  tooltip: 'Mute',
                  onPressed: _power != false && !_busy
                      ? () {
                          _handleMute();
                        }
                      : null,
                ),
              ],
            ),
            new Form(
              child: new Builder(
                builder: (BuildContext context) {
                  //String message;
                  return new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // https://github.com/flutter/flutter/issues/7037 :
                    // crossAxisAlignment: CrossAxisAlignment.baseline,
                    // textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      new Expanded(
                        child: new TextField(
                          decoration: InputDecoration(
                            labelText: 'Message to show on-screen',
                            hintText: 'Hello world!',
                          ),
                          onChanged: (String value) {
                            message = value;
                          },
                        ),
                      ),
                      new Padding(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new FlatButton(
                          onPressed: _power != false
                              ? () {
                                  Form.of(context).save();
                                  _handleDisplayMessage(message);
                                }
                              : null,
                          child: new Text('DISPLAY'),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            new SizedBox(height: 24.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.power_settings_new,
                    label: 'Power',
                    onPressed: () {
                      _handleRemote(backend.TelevisionRemote.keyPower);
                    }),
                new TVButtonGap(),
                new TVButton(
                    icon: Icons.help,
                    label: 'Manual',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyManual);
                          }
                        : null),
                new TVButton(
                    icon: Icons.settings_power,
                    label: 'Power (Source)',
                    onPressed: () {
                      _handleRemote(backend.TelevisionRemote.keyPowerSource);
                    }),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.fast_rewind,
                    label: 'Rewind',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyRW);
                          }
                        : null),
                new TVButton(
                    icon: Icons.play_arrow,
                    label: 'Play',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyPlay);
                          }
                        : null),
                new TVButton(
                    icon: Icons.fast_forward,
                    label: 'Fast Forward',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyFF);
                          }
                        : null),
                new TVButton(
                    icon: Icons.pause,
                    label: 'Pause',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyPause);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.skip_previous,
                    label: 'Rewind',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyPrev);
                          }
                        : null),
                new TVButton(
                    icon: Icons.stop,
                    label: 'Play',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyStop);
                          }
                        : null),
                new TVButton(
                    icon: Icons.skip_next,
                    label: 'Fast Forward',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyNext);
                          }
                        : null),
                new TVButton(
                    icon: Icons.radio_button_checked,
                    label: 'Option',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyOption);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.picture_in_picture,
                    label: 'Display',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyDisplay);
                          }
                        : null),
                new TVButton(
                    icon: Icons.av_timer,
                    label: 'Sleep',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keySleep);
                          }
                        : null),
                new TVButtonGap(),
                new TVButton(
                    icon: Icons.pause_circle_filled,
                    label: 'Freeze',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyFreeze);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                    child: new Text('1'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key1);
                          }
                        : null),
                new FlatButton(
                    child: new Text('2'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key2);
                          }
                        : null),
                new FlatButton(
                    child: new Text('3'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key3);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                    child: new Text('4'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key4);
                          }
                        : null),
                new FlatButton(
                    child: new Text('5'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key5);
                          }
                        : null),
                new FlatButton(
                    child: new Text('6'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key6);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                    child: new Text('7'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key7);
                          }
                        : null),
                new FlatButton(
                    child: new Text('8'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key8);
                          }
                        : null),
                new FlatButton(
                    child: new Text('9'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key9);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                    child: new Text('·'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyDot);
                          }
                        : null),
                new FlatButton(
                    child: new Text('0'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key0);
                          }
                        : null),
                new FlatButton(
                    child: new Text('ENT'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyEnt);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.closed_caption,
                    label: 'Closed Captions',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyClosedCaptions);
                          }
                        : null),
                new TVButton(
                    icon: Icons.invert_colors,
                    label: 'AV Mode',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyAvMode);
                          }
                        : null),
                new TVButton(
                    icon: Icons.settings_overscan,
                    label: 'View Mode',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyViewMode);
                          }
                        : null),
                new TVButton(
                    icon: Icons.replay,
                    label: 'Flashback',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyFlashback);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.volume_off,
                    label: 'Mute',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyMute);
                          }
                        : null),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new TVButton(
                        icon: Icons.volume_up,
                        label: 'Volume Up',
                        onPressed: _power != false
                            ? () {
                                _handleRemote(
                                    backend.TelevisionRemote.keyVolUp);
                              }
                            : null),
                    new TVButton(
                        icon: Icons.volume_down,
                        label: 'Volume Down',
                        onPressed: _power != false
                            ? () {
                                _handleRemote(
                                    backend.TelevisionRemote.keyVolDown);
                              }
                            : null),
                  ],
                ),
                new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new TVButton(
                        icon: Icons.add,
                        label: 'Chanel Up',
                        onPressed: _power != false
                            ? () {
                                _handleRemote(
                                    backend.TelevisionRemote.keyChannelUp);
                              }
                            : null),
                    new TVButton(
                        icon: Icons.remove,
                        label: 'Chanel Down',
                        onPressed: _power != false
                            ? () {
                                _handleRemote(
                                    backend.TelevisionRemote.keyChannelDown);
                              }
                            : null),
                  ],
                ),
                new TVButton(
                    icon: Icons.settings_input_hdmi,
                    label: 'Input',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyInput);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.surround_sound,
                    label: '2D/3D',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.key2D3D);
                          }
                        : null),
                new FlatButton(
                    child: new Text('MENU'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyMenu);
                          }
                        : null),
                new TVButton(
                    icon: Icons.home,
                    label: 'Smart Central',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keySmartCentral);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButtonGap(),
                new TVButton(
                    icon: Icons.keyboard_arrow_up,
                    label: 'Up',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyUp);
                          }
                        : null),
                new TVButtonGap(),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.keyboard_arrow_left,
                    label: 'Left',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyLeft);
                          }
                        : null),
                new TVButton(
                    icon: Icons.keyboard_return,
                    label: 'Enter',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyEnter);
                          }
                        : null),
                new TVButton(
                    icon: Icons.keyboard_arrow_right,
                    label: 'Right',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyRight);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButtonGap(),
                new TVButton(
                    icon: Icons.keyboard_arrow_down,
                    label: 'Down',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyDown);
                          }
                        : null),
                new TVButtonGap(),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.close,
                    label: 'Exit',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyExit);
                          }
                        : null),
                new FlatButton(
                    child: new Text('NetFlix'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyNetFlix);
                          }
                        : null),
                new TVButton(
                    icon: Icons.undo,
                    label: 'Return',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyReturn);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.swap_horiz,
                    label: 'Last Channel',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyCh);
                          }
                        : null),
                new TVButton(
                    icon: Icons.looks_one,
                    label: 'App 1',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyApp1);
                          }
                        : null),
                new TVButton(
                    icon: Icons.looks_two,
                    label: 'App 2',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyApp2);
                          }
                        : null),
                new TVButton(
                    icon: Icons.looks_3,
                    label: 'App 3',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyApp3);
                          }
                        : null),
              ],
            ),
            new ButtonTheme(
              minWidth: 52.0,
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new FlatButton(
                      child: new Text('A'),
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyA);
                            }
                          : null,
                      color: Colors.red[100]),
                  new FlatButton(
                      child: new Text('B'),
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyB);
                            }
                          : null,
                      color: Colors.green[100]),
                  new FlatButton(
                      child: new Text('C'),
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyC);
                            }
                          : null,
                      color: Colors.blue[100]),
                  new FlatButton(
                      child: new Text('D'),
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyD);
                            }
                          : null,
                      color: Colors.yellow[100]),
                ],
              ),
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new TVButton(
                    icon: Icons.fiber_manual_record,
                    label: 'Record',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyRecord);
                          }
                        : null),
                new TVButton(
                    icon: Icons.fiber_smart_record,
                    label: 'Record Stop',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyRecordStop);
                          }
                        : null),
                new TVButton(
                    icon: Icons.power_input,
                    label: 'Power Saving',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyPowerSaving);
                          }
                        : null),
                new TVButton(
                    icon: Icons.healing,
                    label: 'Support',
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyAAL);
                          }
                        : null),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                    child: new Text('Key 37'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyReserved37);
                          }
                        : null),
                new FlatButton(
                    child: new Text('Key 48'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyReserved48);
                          }
                        : null),
                new FlatButton(
                    child: new Text('Key 49'),
                    onPressed: _power != false
                        ? () {
                            _handleRemote(
                                backend.TelevisionRemote.keyReserved49);
                          }
                        : null),
              ],
            ),
            new SizedBox(height: 24.0),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Expanded(
                  child: new Text('Show demo overlay'),
                ),
                new Switch(
                  value: _demoOverlay != null ? _demoOverlay : false,
                  onChanged: _power != false ? _handleDemoOverlay : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TVButton extends StatelessWidget {
  TVButton({
    Key key,
    this.icon,
    this.label,
    this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.all(8.0),
      child: new IconButton(
        icon: new Icon(icon),
        tooltip: label,
        onPressed: onPressed,
      ),
    );
  }
}

class TVButtonGap extends StatelessWidget {
  TVButtonGap({
    Key key,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return new SizedBox(
      height: 56.0,
      width: 56.0,
    );
  }
}
