// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class _AutoFadeChildEntry {
  _AutoFadeChildEntry(this.widget, this.controller, this.animation);

  Widget widget;

  final AnimationController controller;

  final Animation<double> animation;
}

class AutoFade extends StatefulWidget {
  AutoFade({
    Key key,
    this.child,
    @required this.token,
    this.curve: Curves.linear,
    @required this.duration,
  }) : super(key: key) {
    assert(curve != null);
    assert(duration != null);
  }

  final Widget child;
  final dynamic token;
  final Curve curve;
  final Duration duration;

  @override
  _AutoFadeState createState() => new _AutoFadeState();
}

class _AutoFadeState extends State<AutoFade> with TickerProviderStateMixin {
  Set<_AutoFadeChildEntry> _children = new Set<_AutoFadeChildEntry>();
  _AutoFadeChildEntry _currentChild;

  @override
  void initState() {
    super.initState();
    addEntry(false);
  }

  @override
  void didUpdateConfig(AutoFade oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.token != oldConfig.token) {
      addEntry(true);
    } else {
      _currentChild.widget = config.child;
    }
  }

  void addEntry(bool animate) {
    AnimationController controller = new AnimationController(duration: config.duration, vsync: this);
    if (animate) {
      if (_currentChild != null) {
        _currentChild.controller.reverse();
        _children.add(_currentChild);
      }
      controller.forward();
    } else {
      assert(_currentChild == null);
      assert(_children.isEmpty);
      controller.value = 1.0;
    }
    Animation<double> animation = new CurvedAnimation(
      parent: controller,
      curve: config.curve,
    );
    _AutoFadeChildEntry entry = new _AutoFadeChildEntry(config.child, controller, animation);
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        assert(_children.contains(entry));
        setState(() { _children.remove(entry); });
        controller.dispose();
      }
    });
    _currentChild = entry;
  }

  @override
  void dispose() {
    if (_currentChild != null)
      _currentChild.controller.dispose();
    for (_AutoFadeChildEntry child in _children)
      child.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    for (_AutoFadeChildEntry child in _children) {
      children.add(
        new FadeTransition(
          key: new ObjectKey(child),
          opacity: child.animation,
          child: child.widget,
        ),
      );
    }
    if (_currentChild != null) {
      children.add(
        new FadeTransition(
          key: new ObjectKey(_currentChild),
          opacity: _currentChild.animation,
          child: _currentChild.widget,
        ),
      );
    }
    return new Stack(
      children: children,
    );
  }
}
