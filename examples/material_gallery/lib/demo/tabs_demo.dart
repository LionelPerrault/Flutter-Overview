// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

final List<String> _iconNames = <String>["event", "home", "android", "alarm", "face", "language"];
final TabBarSelection _selection = new TabBarSelection(maxIndex: _iconNames.length - 1);

Widget buildTabBar(_) {
  return new TabBar(
    selection: _selection,
    isScrollable: true,
    labels: _iconNames.map((String iconName) => new TabLabel(text: iconName, icon: "action/$iconName")).toList()
  );
}

class TabsDemo extends StatefulComponent {
  _TabsDemoState createState() => new _TabsDemoState();
}

class _TabsDemoState extends State<TabsDemo> {
  Widget build(_) {
    return new TabBarView<String>(
      selection: _selection,
      items: _iconNames,
      itemBuilder: (BuildContext context, String iconName, int index) {
        return new Container(
          key: new ValueKey<String>(iconName),
          padding: const EdgeDims.all(12.0),
          child: new Card(
            child: new Center(child: new Icon(icon: "action/$iconName", size:IconSize.s48))
          )
        );
      }
    );
  }
}

final WidgetDemo kTabsDemo = new WidgetDemo(
  title: 'Tabs',
  routeName: '/tabs',
  tabBarBuilder: buildTabBar,
  builder: (_) => new TabsDemo()
);
