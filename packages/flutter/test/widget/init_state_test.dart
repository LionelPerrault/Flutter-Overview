// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

List<String> ancestors = <String>[];

class TestWidget extends StatefulWidget {
  TestWidgetState createState() => new TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {
  void initState() {
    super.initState();
    context.visitAncestorElements((Element element) {
      ancestors.add(element.widget.runtimeType.toString());
      return true;
    });
  }

  Widget build(BuildContext context) => new Container();
}

void main() {
  test('initState() is called when we are in the tree', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Container(child: new TestWidget()));
      expect(ancestors, equals(<String>['Container', 'RenderObjectToWidgetAdapter<RenderBox>']));
    });
  });
}
