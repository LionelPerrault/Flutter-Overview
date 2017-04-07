// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TestState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) => null;
}

void main() {
  testWidgets('UniqueKey control test', (WidgetTester tester) async {
    final Key key = new UniqueKey();
    expect(key, hasOneLineDescription);
    expect(key, isNot(equals(new UniqueKey())));
  });

  testWidgets('ObjectKey control test', (WidgetTester tester) async {
    final Object a = new Object();
    final Object b = new Object();
    final Key keyA = new ObjectKey(a);
    final Key keyA2 = new ObjectKey(a);
    final Key keyB = new ObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalObjectKey control test', (WidgetTester tester) async {
    final Object a = new Object();
    final Object b = new Object();
    final Key keyA = new GlobalObjectKey(a);
    final Key keyA2 = new GlobalObjectKey(a);
    final Key keyB = new GlobalObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalKey duplication 1 - double appearance', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(
          key: const ValueKey<int>(1),
          child: new SizedBox(key: key),
        ),
        new Container(
          key: const ValueKey<int>(2),
          child: new Placeholder(key: key),
        ),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 2 - splitting and changing type', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');

    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(
          key: const ValueKey<int>(1),
        ),
        new Container(
          key: const ValueKey<int>(2),
        ),
        new Container(
          key: key
        ),
      ],
    ));

    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(
          key: const ValueKey<int>(1),
          child: new SizedBox(key: key),
        ),
        new Container(
          key: const ValueKey<int>(2),
          child: new Placeholder(key: key),
        ),
      ],
    ));

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 3 - splitting and changing type', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new SizedBox(key: key),
        new Placeholder(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 4 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Placeholder(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 5 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Placeholder(key: key),
        new Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 6 - splitting and not changing type', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 7 - appearing later', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(2), child: new Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 8 - appearing earlier', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1)),
        new Container(key: const ValueKey<int>(2), child: new Container(key: key)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(2), child: new Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 9 - moving and appearing later', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(1)),
        new Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(2), child: new Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 10 - moving and appearing earlier', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1)),
        new Container(key: const ValueKey<int>(2)),
        new Container(key: const ValueKey<int>(3), child: new Container(key: key)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(2), child: new Container(key: key)),
        new Container(key: const ValueKey<int>(3)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 11 - double sibling appearance', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 12 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = new GlobalKey(debugLabel: 'problematic');
    final Key key2 = new GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = new GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key1),
        new Container(key: key1),
        new Container(key: key2),
        new Container(key: key1),
        new Container(key: key1),
        new Container(key: key2),
        new Container(key: key1),
        new Container(key: key1),
        new Row(
          children: <Widget>[
            new Container(key: key1),
            new Container(key: key1),
            new Container(key: key2),
            new Container(key: key2),
            new Container(key: key2),
            new Container(key: key3),
            new Container(key: key2),
          ],
        ),
        new Row(
          children: <Widget>[
            new Container(key: key1),
            new Container(key: key1),
            new Container(key: key3),
          ],
        ),
        new Container(key: key3),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 13 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = new GlobalKey(debugLabel: 'problematic');
    final Key key2 = new GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = new GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key1),
        new Container(key: key2),
        new Container(key: key3),
      ]),
    );
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key1),
        new Container(key: key1),
        new Container(key: key2),
        new Container(key: key1),
        new Container(key: key1),
        new Container(key: key2),
        new Container(key: key1),
        new Container(key: key1),
        new Row(
          children: <Widget>[
            new Container(key: key1),
            new Container(key: key1),
            new Container(key: key2),
            new Container(key: key2),
            new Container(key: key2),
            new Container(key: key3),
            new Container(key: key2),
          ],
        ),
        new Row(
          children: <Widget>[
            new Container(key: key1),
            new Container(key: key1),
            new Container(key: key3),
          ],
        ),
        new Container(key: key3),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 14 - moving during build - before', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 15 - duplicating during build - before', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: key),
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 16 - moving during build - after', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1)),
        new Container(key: key),
      ],
    ));
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 17 - duplicating during build - after', (WidgetTester tester) async {
    final Key key = new GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1)),
        new Container(key: key),
      ],
    ));
    int count = 0;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      expect(details.exception, isFlutterError);
      count += 1;
    };
    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(key: const ValueKey<int>(0)),
        new Container(key: const ValueKey<int>(1), child: new Container(key: key)),
        new Container(key: key),
      ],
    ));
    FlutterError.onError = oldHandler;
    expect(count, 2);
  });

  testWidgets('Defunct setState throws exception', (WidgetTester tester) async {
    StateSetter setState;

    await tester.pumpWidget(new StatefulBuilder(
      builder: (BuildContext context, StateSetter setter) {
        setState = setter;
        return new Container();
      },
    ));

    // Control check that setState doesn't throw an exception.
    setState(() { });

    await tester.pumpWidget(new Container());

    expect(() { setState(() { }); }, throwsFlutterError);
  });

  testWidgets('State toString', (WidgetTester tester) async {
    final TestState state = new TestState();
    expect(state.toString(), contains('no config'));
  });

  testWidgets('debugPrintGlobalKeyedWidgetLifecycle control test', (WidgetTester tester) async {
    expect(debugPrintGlobalKeyedWidgetLifecycle, isFalse);

    final DebugPrintCallback oldCallback = debugPrint;
    debugPrintGlobalKeyedWidgetLifecycle = true;

    final List<String> log = <String>[];
    debugPrint = (String message, { int wrapWidth }) {
      log.add(message);
    };

    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new Container(key: key));
    expect(log, isEmpty);
    await tester.pumpWidget(new Placeholder());
    debugPrint = oldCallback;
    debugPrintGlobalKeyedWidgetLifecycle = false;

    expect(log.length, equals(2));
    expect(log[0], matches('Deactivated'));
    expect(log[1], matches('Discarding .+ from inactive elements list.'));
  });

  testWidgets('MultiChildRenderObjectElement.children', (WidgetTester tester) async {
    GlobalKey key0, key1, key2;
    await tester.pumpWidget(new Column(
      key: key0 = new GlobalKey(),
      children: <Widget>[
        new Container(),
        new Container(key: key1 = new GlobalKey()),
        new Container(child: new Container()),
        new Container(key: key2 = new GlobalKey()),
        new Container(),
      ],
    ));
    final MultiChildRenderObjectElement element = key0.currentContext;
    expect(
      element.children.map((Element element) => element.widget.key), // ignore: INVALID_USE_OF_PROTECTED_MEMBER
      <Key>[null, key1, null, key2, null],
    );
  });
}
