// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('overflow should not affect baseline', () {
    RenderBox root, child, text;
    double baseline1, baseline2, height1, height2;

    root = new RenderPositionedBox(
      child: new RenderCustomPaint(
        child: child = text = new RenderParagraph(
          const TextSpan(text: 'Hello World'),
          textDirection: TextDirection.ltr,
        ),
        painter: new TestCallbackPainter(
          onPaint: () {
            baseline1 = child.getDistanceToBaseline(TextBaseline.alphabetic);
            height1 = text.size.height;
          },
        ),
      ),
    );
    layout(root, phase: EnginePhase.paint);

    root = new RenderPositionedBox(
      child: new RenderCustomPaint(
        child: child = new RenderConstrainedOverflowBox(
          child: text = new RenderParagraph(
            const TextSpan(text: 'Hello World'),
            textDirection: TextDirection.ltr,
          ),
          maxHeight: height1 / 2.0,
          alignment: Alignment.topLeft,
        ),
        painter: new TestCallbackPainter(
          onPaint: () {
            baseline2 = child.getDistanceToBaseline(TextBaseline.alphabetic);
            height2 = text.size.height;
          },
        ),
      ),
    );
    layout(root, phase: EnginePhase.paint);

    expect(baseline1, lessThan(height1));
    expect(height2, equals(height1 / 2.0));
    expect(baseline2, equals(baseline1));
    expect(baseline2, greaterThan(height2));
  });
}
