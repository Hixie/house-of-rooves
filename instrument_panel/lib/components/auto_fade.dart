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
  const AutoFade({
    Key key,
    this.child,
    @required this.token,
    this.curve = Curves.linear,
    @required this.duration,
  }) : assert(curve != null),
       assert(duration != null),
       super(key: key);

  final Widget child;
  final dynamic token;
  final Curve curve;
  final Duration duration;

  @override
  _AutoFadeState createState() => _AutoFadeState();
}

class _AutoFadeState extends State<AutoFade> with TickerProviderStateMixin {
  final Set<_AutoFadeChildEntry> _children = <_AutoFadeChildEntry>{};
  _AutoFadeChildEntry _currentChild;

  @override
  void initState() {
    super.initState();
    addEntry(animate: false);
  }

  @override
  void didUpdateWidget(AutoFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      addEntry(animate: true);
    } else {
      _currentChild.widget = widget.child;
    }
  }

  void addEntry({ @required bool animate }) {
    final AnimationController controller = AnimationController(duration: widget.duration, vsync: this);
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
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    );
    final _AutoFadeChildEntry entry =
        _AutoFadeChildEntry(widget.child, controller, animation);
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        assert(_children.contains(entry));
        setState(() {
          _children.remove(entry);
        });
        controller.dispose();
      }
    });
    _currentChild = entry;
  }

  @override
  void dispose() {
    if (_currentChild != null)
      _currentChild.controller.dispose();
    for (final _AutoFadeChildEntry child in _children)
      child.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (final _AutoFadeChildEntry child in _children) {
      children.add(
        FadeTransition(
          key: ObjectKey(child),
          opacity: child.animation,
          child: child.widget,
        ),
      );
    }
    if (_currentChild != null) {
      children.add(
        FadeTransition(
          key: ObjectKey(_currentChild),
          opacity: _currentChild.animation,
          child: _currentChild.widget,
        ),
      );
    }
    return Stack(
      children: children,
    );
  }
}
