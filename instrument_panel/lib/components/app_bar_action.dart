// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppBarAction extends StatelessWidget {
  const AppBarAction(
      {Key key,
      this.size: 24.0,
      this.padding: const EdgeInsets.all(8.0),
      this.alignment: FractionalOffset.center,
      @required this.child,
      this.color,
      this.tooltip})
      : super(key: key);

  final double size;
  final EdgeInsets padding;
  final FractionalOffset alignment;
  final Widget child;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Widget result = new Padding(
      padding: padding,
      child: new LimitedBox(
        maxWidth: size,
        maxHeight: size,
        child: new ConstrainedBox(
          constraints: new BoxConstraints.loose(new Size.square(
              math.max(size, Material.defaultSplashRadius * 2.0))),
          child: new Align(
            alignment: alignment,
            child: IconTheme.merge(
              data: new IconThemeData(
                size: size,
                color: color,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      result = new Tooltip(
        message: tooltip,
        child: result,
      );
    }
    return result;
  }
}
