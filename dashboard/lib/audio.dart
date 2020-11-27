import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

abstract class Audio {
  static Audio of(BuildContext context, { bool nullOk = false }) {
    final _Audio audio = context.dependOnInheritedWidgetOfExactType<_Audio>();
    if (audio == null && nullOk)
      return null;
    assert(audio != null);
    return audio.audioState;
  }

  void long1(); // curved: 1500ms
  void long2(); // curved: 1500ms
  void short1();
  void short2();
  void open();
  void pageDown(); // curved: 150ms
  void transport(); // curved: 3000ms
  void checkOn(); // curved: 950ms
  void checkOff(); // curved: same as checkOn
}

class AudioProvider extends StatefulWidget {
  AudioProvider({
    Key key,
    this.enabled = true,
    this.version,
    this.child,
  }) : super(key: key);

  final bool enabled;

  final int version;

  final Widget child;

  State<AudioProvider> createState() => _AudioProviderState();
}

class _AudioProviderState extends State<AudioProvider> implements Audio {
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(AudioProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled)
      _init();
  }

  List<_AudioBank> _currentBanks;

  void _init() async {
    if (widget.enabled) {
      _currentBanks = [
        await _AudioBank.initCurved(),
        null,
        await _AudioBank.initStraight(),
      ];
    } else {
      // TODO(ianh): dispose of _currentBank's resources
      _currentBanks = [null, null, null];
    }
  }

  _AudioBank get _currentBank {
    if (_currentBanks == null)
      return null;
    return _currentBanks[widget.version];
  }

  void long1() { if (_currentBank == null) return; _currentBank.long1?.play(); }
  void long2() { if (_currentBank == null) return; _currentBank.long2?.play(); }
  void short1() { if (_currentBank == null) return; _currentBank.short1?.play(); }
  void short2() { if (_currentBank == null) return; _currentBank.short2?.play(); }
  void open() { if (_currentBank == null) return; _currentBank.open?.play(); }
  void pageDown() { if (_currentBank == null) return; _currentBank.pageDown?.play(); }
  void transport() { if (_currentBank == null) return; _currentBank.transport?.play(); }
  void checkOn() { if (_currentBank == null) return; _currentBank.checkOn?.play(); }
  void checkOff() { if (_currentBank == null) return; _currentBank.checkOff?.play(); }

  @override
  Widget build(BuildContext context) {
    return _Audio(audioState: this, child: widget.child);
  }
}

class _AudioFile {
  _AudioFile(this._soundpool, this._id);

  final Soundpool _soundpool;

  final int _id;

  void play() {
    _soundpool.play(_id);
  }
}

class _AudioBank {
  _AudioBank._(
    this.long1,
    this.long2,
    this.short1,
    this.short2,
    this.open,
    this.pageDown,
    this.transport,
    this.checkOn,
    this.checkOff,
  );

  static Future<_AudioBank> initCurved() async {
    final Soundpool soundpool = Soundpool(streamType: StreamType.notification, maxStreams: 16);
    return _AudioBank._(
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/long1.wav'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/long2.wav'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/short1.mp3'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/short2.mp3'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/open.mp3'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/page-down.wav'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/transport.wav'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/medium1.wav'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/curved/medium1.wav'))),
    );
  }

  static Future<_AudioBank> initStraight() async {
    final Soundpool soundpool = Soundpool(streamType: StreamType.notification, maxStreams: 16);
    return _AudioBank._(
      null,
      null,
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/straight/short1.mp3'))),
      null,
      null,
      null,
      null,
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/straight/check_on.mp3'))),
      _AudioFile(soundpool, await soundpool.load(await rootBundle.load('audio/straight/check_off.mp3'))),
    );
  }

  final _AudioFile long1;
  final _AudioFile long2;
  final _AudioFile short1;
  final _AudioFile short2;
  final _AudioFile open;
  final _AudioFile pageDown;
  final _AudioFile transport;
  final _AudioFile checkOn;
  final _AudioFile checkOff;
}

class _Audio extends InheritedWidget {
  const _Audio({
    Key key,
    @required this.audioState,
    @required Widget child,
  }) : assert(audioState != null),
       super(key: key, child: child);

  final _AudioProviderState audioState;

  bool updateShouldNotify(_Audio old) => audioState != old.audioState;
}
