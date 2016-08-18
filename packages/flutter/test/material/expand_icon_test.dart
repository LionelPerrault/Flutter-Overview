// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpandIcon test', (WidgetTester tester) async {
    bool expanded = false;

    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new ExpandIcon(
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
          )
        )
      )
    );

    expect(expanded, isFalse);
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isFalse);
  });

  testWidgets('ExpandIcon disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new Center(
          child: new ExpandIcon(
            onPressed: null
          )
        )
      )
    );

    IconTheme iconTheme = tester.firstWidget(find.byType(IconTheme));
    expect(iconTheme.data.color, equals(Colors.black26));
  });
}
