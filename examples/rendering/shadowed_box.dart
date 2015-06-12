// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/flex.dart';
import 'package:sky/framework/theme2/colors.dart';
import 'package:sky/framework/theme2/shadows.dart';

AppView app;

void main() {
  var coloredBox = new RenderDecoratedBox(
    decoration: new BoxDecoration(
      gradient: new RadialGradient(
        center: Point.origin, radius: 500.0,
        colors: [Yellow[500], Blue[500]]),
      boxShadow: Shadow[3])
  );
  var paddedBox = new RenderPadding(
    padding: const EdgeDims.all(50.0),
    child: coloredBox);
  app = new AppView(root: new RenderDecoratedBox(
    decoration: const BoxDecoration(
      backgroundColor: const Color(0xFFFFFFFF)
    ),
    child: paddedBox
  ));
}
