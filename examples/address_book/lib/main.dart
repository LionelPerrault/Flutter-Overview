// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';
import 'package:sky/widgets.dart';

class Field extends StatelessComponent {
  Field({
    Key key,
    this.inputKey,
    this.icon,
    this.placeholder
  }) : super(key: key);

  final GlobalKey inputKey;
  final String icon;
  final String placeholder;

  Widget build(BuildContext context) {
    return new Row([
        new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Icon(type: icon, size: 24)
        ),
        new Flexible(
          child: new Input(
            key: inputKey,
            placeholder: placeholder
          )
        )
      ]
    );
  }
}

class AddressBookHome extends StatelessComponent {
  AddressBookHome({ this.navigator });

  final NavigatorState navigator;

  Widget buildToolBar(BuildContext context) {
    return new ToolBar(
        left: new IconButton(icon: "navigation/arrow_back"),
        right: [new IconButton(icon: "navigation/check")]
      );
  }

  Widget buildFloatingActionButton(BuildContext context) {
    return new FloatingActionButton(
      child: new Icon(type: 'image/photo_camera', size: 24),
      backgroundColor: Theme.of(context).accentColor
    );
  }

  static final GlobalKey nameKey = new GlobalKey();
  static final GlobalKey phoneKey = new GlobalKey();
  static final GlobalKey emailKey = new GlobalKey();
  static final GlobalKey addressKey = new GlobalKey();
  static final GlobalKey ringtoneKey = new GlobalKey();
  static final GlobalKey noteKey = new GlobalKey();
  static final GlobalKey fillKey = new GlobalKey();
  static final GlobalKey emoticonKey = new GlobalKey();

  Widget buildBody(BuildContext context) {
    return new Material(
      child: new Block([
        new AspectRatio(
          aspectRatio: 16.0 / 9.0,
          child: new Container(
            decoration: new BoxDecoration(backgroundColor: Colors.purple[300])
          )
        ),
        new Field(inputKey: nameKey, icon: "social/person", placeholder: "Name"),
        new Field(inputKey: phoneKey, icon: "communication/phone", placeholder: "Phone"),
        new Field(inputKey: emailKey, icon: "communication/email", placeholder: "Email"),
        new Field(inputKey: addressKey, icon: "maps/place", placeholder: "Address"),
        new Field(inputKey: ringtoneKey, icon: "av/volume_up", placeholder: "Ringtone"),
        new Field(inputKey: noteKey, icon: "content/add", placeholder: "Add note"),
      ])
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolbar: buildToolBar(context),
      body: buildBody(context),
      floatingActionButton: buildFloatingActionButton(context)
    );
  }
}

final ThemeData theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.teal,
  accentColor: Colors.pinkAccent[100]
);

void main() {
  runApp(new App(
    title: 'Address Book',
    theme: theme,
    routes: <String, RouteBuilder>{
      '/': (NavigatorState navigator, Route route) => new AddressBookHome(navigator: navigator)
    }
  ));
}
