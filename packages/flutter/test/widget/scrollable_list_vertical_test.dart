// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

Widget buildFrame() {
  return new ScrollableList(
  itemExtent: 290.0,
  scrollDirection: Axis.vertical,
  children: items.map((int item) {
    return new Container(
      child: new Text('$item')
    );
  })
  );
}

void main() {
  testWidgets('Drag vertically', (WidgetTester tester) {
    tester.pumpWidget(buildFrame());

    tester.pump();
    tester.scroll(find.text('1'), const Offset(0.0, -300.0));
    tester.pump();
    // screen is 600px high, and has the following items:
    //   -10..280 = 1
    //   280..570 = 2
    //   570..860 = 3
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    tester.pump();
    tester.scroll(find.text('2'), const Offset(0.0, -290.0));
    tester.pump();
    // screen is 600px high, and has the following items:
    //   -10..280 = 2
    //   280..570 = 3
    //   570..860 = 4
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);

    tester.pump();
    tester.scroll(find.text('3'), const Offset(-300.0, 0.0));
    tester.pump();
    // nothing should have changed
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('Drag vertically', (WidgetTester tester) {
    tester.pumpWidget(
      new ScrollableList(
        itemExtent: 290.0,
        padding: new EdgeInsets.only(top: 250.0),
        scrollDirection: Axis.vertical,
        children: items.map((int item) {
          return new Container(
            child: new Text('$item')
          );
        })
      )
    );

    tester.pump();
    // screen is 600px high, and has the following items:
    //   250..540 = 0
    //   540..830 = 1
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    tester.scroll(find.text('0'), const Offset(0.0, -300.0));
    tester.pump();
    // screen is 600px high, and has the following items:
    //   -50..240 = 0
    //   240..530 = 1
    //   530..820 = 2
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });
}
