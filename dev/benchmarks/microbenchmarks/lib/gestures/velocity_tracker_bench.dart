// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import '../common.dart';
import 'data/velocity_tracker_data.dart';

const int _kNumIters = 10000;

void main() {
  final VelocityTracker tracker = new VelocityTracker();
  final Stopwatch watch = new Stopwatch();
  print('Velocity tracker benchmark...');
  watch.start();
  for (int i = 0; i < _kNumIters; i += 1) {
    for (PointerEvent event in velocityEventData) {
      if (event is PointerDownEvent || event is PointerMoveEvent)
        tracker.addPosition(event.timeStamp, event.position);
      if (event is PointerUpEvent)
        tracker.getVelocity();
    }
  }
  watch.stop();

  BenchmarkResultPrinter printer = new BenchmarkResultPrinter();
  printer.addResult(
    description: 'Velocity tracker',
    value: watch.elapsedMicroseconds / _kNumIters,
    unit: 'µs per iteration',
    name: 'velocity_tracker_iteration',
  );
  printer.printToStdout();
}
