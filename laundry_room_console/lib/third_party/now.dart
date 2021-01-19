// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// An inherited widget that reports the current date/time and
/// ticks once per day.
class Now extends InheritedNotifier<ValueNotifier<DateTime>> {
  /// For production.
  Now({
    Key key,
    Widget child,
  }) : super(
          key: key,
          notifier: _Clock(),
          child: child,
        );

  /// For tests.
  Now.fixed({
    Key key,
    @required DateTime dateTime,
    Widget child,
  })  : assert(dateTime != null),
        super(
          key: key,
          notifier: ValueNotifier<DateTime>(dateTime),
          child: child,
        );

  static DateTime of(BuildContext context) {
    final Now now = context.dependOnInheritedWidgetOfExactType<Now>();
    assert(now != null);
    return now.notifier.value;
  }
}

class _Clock extends ValueNotifier<DateTime> {
  _Clock() : super(null);

  Timer _timer;

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      assert(_timer == null);
      value = DateTime.now();
      _scheduleTick();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners && _timer != null) {
      _timer.cancel();
      _timer = null;
      value = null;
    }
  }

  void _tick() {
    value = DateTime.now();
    _scheduleTick();
    notifyListeners();
  }

  void _scheduleTick() {
    _timer = Timer(Duration(milliseconds: Duration.millisecondsPerDay - (value.millisecondsSinceEpoch % Duration.millisecondsPerDay)), _tick);
  }
}
