import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart' as backend;
import 'common.dart';
import 'components/app_bar_action.dart';
import 'components/auto_fade.dart';

const Duration _autoFadeDuration = Duration(milliseconds: 250);

String message;

class TelevisionPage extends StatefulWidget {
  const TelevisionPage({ Key key }) : super(key: key);
  @override
  _TelevisionPageState createState() => _TelevisionPageState();
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
        Timer.periodic(const Duration(seconds: 15), (Timer timer) {
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

  Future<void> _updateStatus() async {
    if (_checking)
      return;
    _requestedUpdater?.cancel();
    try {
      if (!mounted)
        return;
      setState(() {
        _checking = true;
      });
      final bool power = await backend.television.power;
      if (!mounted)
        return;
      setState(() {
        _power = power;
      });
      final backend.TelevisionChannel input = await backend.television.input;
      if (!mounted)
        return;
      setState(() {
        _input = input;
      });
      if (power) {
        final int volume = await backend.television.volume;
        if (!mounted)
          return;
        setState(() {
          _volume = volume;
        });
        final bool muted = await backend.television.muted;
        if (!mounted)
          return;
        setState(() {
          _muted = muted;
        });
        final int offTimer = await backend.television.offTimer;
        if (!mounted)
          return;
        setState(() {
          _offTimer = offTimer;
        });
        final String name = await backend.television.name;
        if (!mounted)
          return;
        setState(() {
          _name = name;
        });
        final String model = await backend.television.model;
        if (!mounted)
          return;
        setState(() {
          _model = model;
        });
        final String softwareVersion = await backend.television.softwareVersion;
        if (!mounted)
          return;
        setState(() {
          _softwareVersion = softwareVersion;
        });
        final bool demoOverlay = await backend.television.demoOverlay;
        if (!mounted)
          return;
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
      if (!mounted)
        return;
      _reportError(error, stack);
    }
    if (!mounted)
      return;
    setState(() {
      _checking = false;
    });
    _requestedUpdater = null;
  }

  void _triggerUpdate() {
    _requestedUpdater ??= Timer(const Duration(milliseconds: 200), _updateStatus);
  }

  @override
  void dispose() {
    _connectionListener.cancel();
    _periodicUpdater.cancel();
    _requestedUpdater?.cancel();
    _volumeUi?.cancel();
    super.dispose();
  }

  void _reportError(Object error, StackTrace stack) {
    debugPrint('Reporting error to user:\n$error\n$stack\n');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  // INPUT HANDLERS

  void _handleCancel() {
    backend.television.abort('Canceled request, disconnecting...');
    _triggerUpdate();
  }

  String get _powerMessage {
    if (_power == false)
      return 'OFF';
    if (_offTimer == null) {
      if (_power == true)
        return 'ON';
      return 'UNKNOWN';
    }
    if (_offTimer == 0)
      return 'OFF';
    return 'OFF IN $_offTimer MINUTES';
  }

  Future<void> _handlePowerOn() async {
    setState(() {
      _busy = true;
    });
    _triggerUpdate();
    try {
      await backend.television.setPower(true);
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
    if (!mounted)
      return;
    _triggerUpdate();
    setState(() {
      _busy = false;
    });
  }

  Future<void> _handlePowerTimerInput() async {
    final backend.TelevisionOffTimer offTimer = await showOffTimerDialog();
    if (offTimer != null) {
      try {
        await backend.television.setOffTimer(offTimer);
      } catch (error, stack) {
        if (!mounted)
          return;
        _reportError(error, stack);
      }
      if (!mounted)
        return;
      _triggerUpdate();
    }
  }

  Future<void> _handleRemote(backend.TelevisionRemote button) async {
    try {
      await backend.television.sendRemote(button);
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
    if (!mounted)
      return;
    _triggerUpdate();
  }

  Future<void> _handleSelectInput() async {
    final backend.TelevisionChannel channel = await showInputDialog();
    if (channel != null) {
      setState(() {
        _busy = true;
      });
      _triggerUpdate();
      try {
        await backend.television.setInput(channel);
      } catch (error, stack) {
        if (!mounted)
          return;
        _reportError(error, stack);
      }
      if (!mounted)
        return;
      _triggerUpdate();
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _handleNextInput() async {
    setState(() {
      _busy = true;
    });
    _triggerUpdate();
    try {
      await backend.television.nextInput();
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
    if (!mounted)
      return;
    _triggerUpdate();
    setState(() {
      _busy = false;
    });
  }

  bool _sendingVolume = false;
  Future<void> _handleVolumeChanged(double value) async {
    setState(() {
      _userVolume = value;
    });
    _volumeUi?.cancel();
    _volumeUi = Timer(
      const Duration(milliseconds: 250),
      () {
        if (!_sendingVolume)
          _userVolume = null;
      },
    );
    if (_sendingVolume)
      return;
    _sendingVolume = true;
    do {
      // send the value
      try {
        await backend.television.setVolume(_userVolume.round());
        if (!mounted)
          return;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted)
          return;
        // update volume and muted in the UI
        final int volume = await backend.television.volume;
        if (!mounted)
          return;
        setState(() {
          _volume = volume;
        });
        final bool muted = await backend.television.muted;
        if (!mounted)
          return;
        setState(() {
          _muted = muted;
        });
      } catch (error, stack) {
        if (!mounted)
          return;
        _reportError(error, stack);
      }
    } while (_volume != _userVolume.round());
    _sendingVolume = false;
  }

  Future<void> _handleMute() async {
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
      if (!mounted)
        return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted)
        return;
      final bool muted = await backend.television.muted;
      if (!mounted)
        return;
      setState(() {
        _muted = muted;
      });
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
    if (!mounted)
      return;
    setState(() {
      _busy = false;
    });
  }

  Future<void> _handleDisplayMessage(String message) async {
    try {
      await backend.television.showMessage(message);
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
  }

  Future<void> _handleDemoOverlay(bool value) async {
    try {
      await backend.television.setDemoOverlay(value);
      if (!mounted)
        return;
      final bool demoOverlay = await backend.television.demoOverlay;
      if (!mounted)
        return;
      setState(() {
        _demoOverlay = demoOverlay;
      });
    } catch (error, stack) {
      if (!mounted)
        return;
      _reportError(error, stack);
    }
  }

  // INTERFACE DESCRIPTIONS

  Future<backend.TelevisionChannel> showInputDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.off));
            },
            child: const Text('OFF'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi1));
            },
            child: const Text('HDMI1 (bristol)'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi2));
            },
            child: const Text('HDMI2 (kitten)'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi3));
            },
            child: const Text('HDMI3 (pi)'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.hdmi4));
            },
            child: const Text('HDMI4 (roku)'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.composite));
            },
            child: const Text('COMPOSITE'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.component));
            },
            child: const Text('COMPONENT'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.ethernet));
            },
            child: const Text('HOME NETWORK'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.storage));
            },
            child: const Text('SD CARD'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.miracast));
            },
            child: const Text('MIRACAST'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.bluetooth));
            },
            child: const Text('BLUETOOTH'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(
                  context,
                  backend.TelevisionChannel.fromSource(
                      backend.TelevisionSource.manual));
            },
            child: const Text('HELP SCREEN'),
          ),
        ],
      ),
    );
  }

  Future<backend.TelevisionOffTimer> showOffTimerDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: <Widget>[
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min30);
            },
            child: const Text('30 MINUTES'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min60);
            },
            child: const Text('60 MINUTES'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min90);
            },
            child: const Text('90 MINUTES'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.min120);
            },
            child: const Text('120 MINUTES'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, backend.TelevisionOffTimer.disabled);
            },
            child:
                Text(_offTimer != null ? 'CANCEL TIMER' : 'NO OFF TIMER'),
          ),
        ],
      ),
    );
  }

  Future<String> showMessageDialog() {
    String result;
    return showDialog(
      context: context,
      builder: (BuildContext context) => Form(
        child: Builder(builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('On-screen message'),
            content: ListView(
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(helperText: 'Message text?'),
                  onSubmitted: (String value) {
                    result = value;
                  },
                ),
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CANCEL'),
              ),
              OutlinedButton(
                onPressed: () {
                  Form.of(context).save();
                  Navigator.pop(context, result);
                },
                child: const Text('SEND'),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = const IconThemeData.fallback().size;
    final TextStyle headline = Theme.of(context).textTheme.headline5;
    final TextStyle title = Theme.of(context).textTheme.headline6;
    final TextStyle titleLight = title.copyWith(fontWeight: FontWeight.w100);
    final TextStyle caption = Theme.of(context).textTheme.caption;
    final TextStyle captionLight = caption.copyWith(fontWeight: FontWeight.w100);
    return MainScreen(
      title: 'Television',
      actions: <Widget>[
        AppBarAction(
          tooltip: 'Whether a connection to the television is active.',
          child: Icon(
            _connected ? Icons.cast_connected : Icons.cast,
          ),
        ),
        AutoFade(
          duration: _autoFadeDuration,
          token: _busy
              ? 0
              : _checking
                  ? 1
                  : 2,
          child: _busy
              ? IconButton(
                  onPressed: _handleCancel,
                  tooltip: 'Cancel and disconnect.',
                  icon: const Icon(Icons.cancel),
                )
              : _checking
                  ? AppBarAction(
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _triggerUpdate,
                      tooltip: 'Refresh the current state.',
                      icon: const Icon(Icons.refresh),
                    ),
        ),
      ],
      body: SizedBox.expand(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            SizedBox(
              height: ButtonTheme.of(context).height,
              child: AutoFade(
                duration: _autoFadeDuration,
                token: _power,
                child: _power == true
                    ? Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _name ?? '■■■■■■',
                              style: headline,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  text: 'MODEL ',
                                  style: captionLight,
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: _model ?? '■■■',
                                      style: caption,
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  text: 'FIRMWARE ',
                                  style: captionLight,
                                  children: <TextSpan>[
                                    TextSpan(
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: _handlePowerOn,
                            child: const Text('POWER ON'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'POWER ',
                      style: titleLight,
                      children: <TextSpan>[
                        TextSpan(
                          text: _powerMessage,
                          style: title,
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _power != false ? _handlePowerTimerInput : null,
                  child: const Text('TIMER'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'INPUT ',
                      style: titleLight,
                      children: <TextSpan>[
                        TextSpan(
                          text: _input != null ? _input.toString().toUpperCase() : 'UNKNOWN',
                          style: title,
                        ),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _handleSelectInput,
                  child: const Text('SELECT'),
                ),
                OutlinedButton(
                  onPressed: _busy || _power == false ? null : _handleNextInput,
                  child: const Text('NEXT'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.volume_down),
                  tooltip: 'Volume Down',
                  onPressed: _power != false && !_busy
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyVolDown);
                        }
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: _userVolume ?? _volume?.toDouble() ?? 0.0,
                    onChanged: _volume != null && !_busy ? _handleVolumeChanged : null,
                    max: 100.0,
                    divisions: 100,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Volume Up',
                  onPressed: _power != false && !_busy
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyVolUp);
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(_muted == true ? Icons.volume_off : Icons.volume_up),
                  tooltip: 'Mute',
                  onPressed: _power != false && !_busy ? _handleMute : null,
                ),
              ],
            ),
            Form(
              child: Builder(
                builder: (BuildContext context) {
                  //String message;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // https://github.com/flutter/flutter/issues/7037 :
                    // crossAxisAlignment: CrossAxisAlignment.baseline,
                    // textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Message to show on-screen',
                            hintText: 'Hello world!',
                          ),
                          onChanged: (String value) {
                            message = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: OutlinedButton(
                          onPressed: _power != false
                              ? () {
                                  Form.of(context).save();
                                  _handleDisplayMessage(message);
                                }
                              : null,
                          child: const Text('DISPLAY'),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.power_settings_new,
                  label: 'Power',
                  onPressed: () {
                    _handleRemote(backend.TelevisionRemote.keyPower);
                  },
                ),
                const TVButtonGap(),
                TVButton(
                  icon: Icons.help,
                  label: 'Manual',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyManual);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.settings_power,
                  label: 'Power (Source)',
                  onPressed: () {
                    _handleRemote(backend.TelevisionRemote.keyPowerSource);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.fast_rewind,
                  label: 'Rewind',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyRW);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyPlay);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.fast_forward,
                  label: 'Fast Forward',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyFF);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyPause);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.skip_previous,
                  label: 'Rewind',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyPrev);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.stop,
                  label: 'Play',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyStop);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.skip_next,
                  label: 'Fast Forward',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyNext);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.radio_button_checked,
                  label: 'Option',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyOption);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.picture_in_picture,
                  label: 'Display',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyDisplay);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.av_timer,
                  label: 'Sleep',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keySleep);
                        }
                      : null,
                ),
                const TVButtonGap(),
                TVButton(
                  icon: Icons.pause_circle_filled,
                  label: 'Freeze',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyFreeze);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key1);
                        }
                      : null,
                  child: const Text('1'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key2);
                        }
                      : null,
                  child: const Text('2'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key3);
                        }
                      : null,
                  child: const Text('3'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key4);
                        }
                      : null,
                  child: const Text('4'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key5);
                        }
                      : null,
                  child: const Text('5'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key6);
                        }
                      : null,
                  child: const Text('6'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key7);
                        }
                      : null,
                  child: const Text('7'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key8);
                        }
                      : null,
                  child: const Text('8'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key9);
                        }
                      : null,
                  child: const Text('9'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyDot);
                        }
                      : null,
                  child: const Text('·'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key0);
                        }
                      : null,
                  child: const Text('0'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyEnt);
                        }
                      : null,
                  child: const Text('ENT'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.closed_caption,
                  label: 'Closed Captions',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyClosedCaptions);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.invert_colors,
                  label: 'AV Mode',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyAvMode);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.settings_overscan,
                  label: 'View Mode',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyViewMode);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.replay,
                  label: 'Flashback',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyFlashback);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.volume_off,
                  label: 'Mute',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyMute);
                        }
                      : null,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TVButton(
                      icon: Icons.volume_up,
                      label: 'Volume Up',
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyVolUp);
                            }
                          : null,
                    ),
                    TVButton(
                      icon: Icons.volume_down,
                      label: 'Volume Down',
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyVolDown);
                            }
                          : null,
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TVButton(
                      icon: Icons.add,
                      label: 'Chanel Up',
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyChannelUp);
                            }
                          : null,
                    ),
                    TVButton(
                      icon: Icons.remove,
                      label: 'Chanel Down',
                      onPressed: _power != false
                          ? () {
                              _handleRemote(backend.TelevisionRemote.keyChannelDown);
                            }
                          : null,
                    ),
                  ],
                ),
                TVButton(
                  icon: Icons.settings_input_hdmi,
                  label: 'Input',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyInput);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.surround_sound,
                  label: '2D/3D',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.key2D3D);
                        }
                      : null,
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyMenu);
                        }
                      : null,
                  child: const Text('MENU'),
                ),
                TVButton(
                  icon: Icons.home,
                  label: 'Smart Central',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keySmartCentral);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const TVButtonGap(),
                TVButton(
                  icon: Icons.keyboard_arrow_up,
                  label: 'Up',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyUp);
                        }
                      : null,
                ),
                const TVButtonGap(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.keyboard_arrow_left,
                  label: 'Left',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyLeft);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.keyboard_return,
                  label: 'Enter',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyEnter);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.keyboard_arrow_right,
                  label: 'Right',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyRight);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const TVButtonGap(),
                TVButton(
                  icon: Icons.keyboard_arrow_down,
                  label: 'Down',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyDown);
                        }
                      : null,
                ),
                const TVButtonGap(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.close,
                  label: 'Exit',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyExit);
                        }
                      : null,
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyNetFlix);
                        }
                      : null,
                  child: const Text('NetFlix'),
                ),
                TVButton(
                  icon: Icons.undo,
                  label: 'Return',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyReturn);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.swap_horiz,
                  label: 'Last Channel',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyCh);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.looks_one,
                  label: 'App 1',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyApp1);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.looks_two,
                  label: 'App 2',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyApp2);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.looks_3,
                  label: 'App 3',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyApp3);
                        }
                      : null,
                ),
              ],
            ),
            ButtonTheme(
              minWidth: 52.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyA);
                          }
                        : null,
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.red[100])),
                    child: const Text('A'),
                  ),
                  OutlinedButton(
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyB);
                          }
                        : null,
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.green[100])),
                    child: const Text('B'),
                  ),
                  OutlinedButton(
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyC);
                          }
                        : null,
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[100])),
                    child: const Text('C'),
                  ),
                  OutlinedButton(
                    onPressed: _power != false
                        ? () {
                            _handleRemote(backend.TelevisionRemote.keyD);
                          }
                        : null,
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[100])),
                    child: const Text('D'),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TVButton(
                  icon: Icons.fiber_manual_record,
                  label: 'Record',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyRecord);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.fiber_smart_record,
                  label: 'Record Stop',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyRecordStop);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.power_input,
                  label: 'Power Saving',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyPowerSaving);
                        }
                      : null,
                ),
                TVButton(
                  icon: Icons.healing,
                  label: 'Support',
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyAAL);
                        }
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyReserved37);
                        }
                      : null,
                  child: const Text('Key 37'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyReserved48);
                        }
                      : null,
                  child: const Text('Key 48'),
                ),
                OutlinedButton(
                  onPressed: _power != false
                      ? () {
                          _handleRemote(backend.TelevisionRemote.keyReserved49);
                        }
                      : null,
                  child: const Text('Key 49'),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Expanded(
                  child: Text('Show demo overlay'),
                ),
                Switch(
                  value: _demoOverlay ?? false,
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
  const TVButton({
    Key key,
    this.icon,
    this.label,
    this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(icon),
        tooltip: label,
        onPressed: onPressed,
      ),
    );
  }
}

class TVButtonGap extends StatelessWidget {
  const TVButtonGap({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56.0,
      width: 56.0,
    );
  }
}
