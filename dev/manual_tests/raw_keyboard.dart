// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:sky_services/sky/input_event.mojom.dart' as mojom;

GlobalKey _key = new GlobalKey();

void main() {
  runApp(
    new MaterialApp(
      title: "Hardware Key Demo",
      routes: <String, RouteBuilder>{
        '/': (RouteArguments args) {
          return new Scaffold(
            toolBar: new ToolBar(
              center: new Text("Hardware Key Demo")
            ),
            body: new Material(
              child: new RawKeyboardDemo(
                key: _key
              )
            )
          );
        }
      }
    )
  );
}

class RawKeyboardDemo extends StatefulWidget {
  RawKeyboardDemo({ GlobalKey key }) : super(key: key);

  _HardwareKeyDemoState createState() => new _HardwareKeyDemoState();
}

class _HardwareKeyDemoState extends State<RawKeyboardDemo> {
  mojom.InputEvent _event;

  void _handleKey(mojom.InputEvent event) {
    setState(() {
      _event = event;
    });
  }

  Widget build(BuildContext context)  {
    bool focused = Focus.at(context);
    Widget child;
    if (!focused) {
      child = new GestureDetector(
        onTap: () {
          Focus.moveTo(config.key);
        },
        child: new Center(
          child: new Text('Tap to focus', style: Typography.black.display1)
        )
      );
    } else if (_event == null) {
      child = new Center(
        child: new Text('Press a key', style: Typography.black.display1)
      );
    } else {
      child = new Column(
        children: <Widget>[
          new Text('${_event.type}', style: Typography.black.body2),
          new Text('${_event.keyData.keyCode}', style: Typography.black.display4)
        ],
        justifyContent: FlexJustifyContent.center
      );
    }
    return new RawKeyboardListener(
      focused: focused,
      onKey: _handleKey,
      child: child
    );
  }
}
