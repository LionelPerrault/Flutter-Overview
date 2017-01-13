// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ticker mute control test', (WidgetTester tester) async {
    int tickCount = 0;
    void handleTick(Duration duration) {
      ++tickCount;
    }

    Ticker ticker = new Ticker(handleTick);

    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isFalse);

    ticker.start();

    expect(ticker.isTicking, isTrue);
    expect(ticker.isActive, isTrue);
    expect(tickCount, equals(0));

    await tester.pump(const Duration(milliseconds: 10));

    expect(tickCount, equals(1));

    ticker.muted = true;
    await tester.pump(const Duration(milliseconds: 10));

    expect(tickCount, equals(1));
    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isTrue);

    ticker.muted = false;
    await tester.pump(const Duration(milliseconds: 10));

    expect(tickCount, equals(2));
    expect(ticker.isTicking, isTrue);
    expect(ticker.isActive, isTrue);

    ticker.muted = true;
    await tester.pump(const Duration(milliseconds: 10));

    expect(tickCount, equals(2));
    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isTrue);

    ticker.stop();

    expect(tickCount, equals(2));
    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isFalse);

    ticker.muted = false;

    expect(tickCount, equals(2));
    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isFalse);

    await tester.pump(const Duration(milliseconds: 10));

    expect(tickCount, equals(2));
    expect(ticker.isTicking, isFalse);
    expect(ticker.isActive, isFalse);
  });
}
