// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class Inside extends StatefulWidget {
  InsideState createState() => new InsideState();
}

class InsideState extends State<Inside> {
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: new Text('INSIDE')
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }
}

class Middle extends StatefulWidget {
  Middle({ this.child });

  final Inside child;

  MiddleState createState() => new MiddleState();
}

class MiddleState extends State<Middle> {
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: config.child
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }
}

class Outside extends StatefulWidget {
  OutsideState createState() => new OutsideState();
}

class OutsideState extends State<Outside> {
  Widget build(BuildContext context) {
    return new Middle(child: new Inside());
  }
}

void main() {
  test('setState() smoke test', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Outside());
      Point location = tester.getCenter(tester.findText('INSIDE'));
      TestGesture gesture = tester.startGesture(location);
      tester.pump();
      gesture.up();
      tester.pump();
    });
  });
}
