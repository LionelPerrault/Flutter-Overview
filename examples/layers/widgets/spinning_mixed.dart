// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/src/solid_color_box.dart';

// Solid colour, RenderObject version
void addFlexChildSolidColor(RenderFlex parent, Color backgroundColor, { int flex: 0 }) {
  RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
  parent.add(child);
  FlexParentData childParentData = child.parentData;
  childParentData.flex = flex;
}

// Solid colour, Widget version
class Rectangle extends StatelessWidget {
  Rectangle(this.color, { Key key }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return new Flexible(
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: color)
      )
    );
  }
}

double value;
RenderObjectToWidgetElement<RenderBox> element;
BuildOwner owner = new BuildOwner();
void attachWidgetTreeToRenderTree(RenderProxyBox container) {
  element = new RenderObjectToWidgetAdapter<RenderBox>(
    container: container,
    child: new Container(
      height: 300.0,
      child: new Column(
        children: <Widget>[
          new Rectangle(const Color(0xFF00FFFF)),
          new Material(
            child: new Container(
              padding: new EdgeInsets.all(10.0),
              margin: new EdgeInsets.all(10.0),
              child: new Row(
                children: <Widget>[
                  new RaisedButton(
                    child: new Row(
                      children: <Widget>[
                        new NetworkImage(src: "http://flutter.io/favicon.ico"),
                        new Text('PRESS ME'),
                      ]
                    ),
                    onPressed: () {
                      value = value == null ? 0.1 : (value + 0.1) % 1.0;
                      attachWidgetTreeToRenderTree(container);
                    }
                  ),
                  new CircularProgressIndicator(value: value),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceAround
              )
            )
          ),
          new Rectangle(const Color(0xFFFFFF00)),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween
      )
    )
  ).attachToRenderTree(owner, element);
}

Duration timeBase;
RenderTransform transformBox;

void rotate(Duration timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase).inMicroseconds.toDouble() / Duration.MICROSECONDS_PER_SECOND; // radians

  transformBox.setIdentity();
  transformBox.translate(transformBox.size.width / 2.0, transformBox.size.height / 2.0);
  transformBox.rotateZ(delta);
  transformBox.translate(-transformBox.size.width / 2.0, -transformBox.size.height / 2.0);
}

void main() {
  WidgetFlutterBinding.ensureInitialized();
  RenderProxyBox proxy = new RenderProxyBox();
  attachWidgetTreeToRenderTree(proxy);

  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);
  addFlexChildSolidColor(flexRoot, const Color(0xFFFF00FF), flex: 1);
  flexRoot.add(proxy);
  addFlexChildSolidColor(flexRoot, const Color(0xFF0000FF), flex: 1);

  transformBox = new RenderTransform(child: flexRoot, transform: new Matrix4.identity());
  RenderPadding root = new RenderPadding(padding: new EdgeInsets.all(80.0), child: transformBox);

  WidgetFlutterBinding.instance.renderView.child = root;
  WidgetFlutterBinding.instance.addPersistentFrameCallback(rotate);
}
