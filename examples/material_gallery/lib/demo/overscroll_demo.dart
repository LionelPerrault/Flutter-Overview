// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum IndicatorType { overscroll, refresh }

class OverscrollDemo extends StatefulWidget {
  OverscrollDemo({ Key key }) : super(key: key);

  @override
  OverscrollDemoState createState() => new OverscrollDemoState();
}

class OverscrollDemoState extends State<OverscrollDemo> {
  static final List<String> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
  ];

  IndicatorType _type = IndicatorType.refresh;

  Future<Null> refresh() {
    Completer<Null> completer = new Completer<Null>();
    new Timer(new Duration(seconds: 3), () { completer.complete(null); });
    return completer.future;
  }


  @override
  Widget build(BuildContext context) {
    String  indicatorTypeText;
    switch(_type) {
      case IndicatorType.overscroll:
        indicatorTypeText = 'Over-scroll indicator';
        break;
      case IndicatorType.refresh:
        indicatorTypeText = 'Refresh indicator';
        break;
    }

    Widget body = new MaterialList(
      type: MaterialListType.threeLine,
      padding: const EdgeInsets.all(8.0),
      children: _items.map((String item) {
        return new ListItem(
          isThreeLine: true,
          leading: new CircleAvatar(child: new Text(item)),
          title: new Text('This item represents $item.'),
          subtitle: new Text('Even more additional list item information appears on line three.')
        );
      })
    );
    switch(_type) {
      case IndicatorType.overscroll:
        body = new OverscrollIndicator(child: body);
        break;
      case IndicatorType.refresh:
        body = new RefreshIndicator(child: body, refresh: refresh);
        break;
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('$indicatorTypeText'),
        actions: <Widget>[
          new IconButton(
            icon: Icons.refresh,
            tooltip: 'Pull to refresh',
            onPressed: () {
              setState(() {
                _type = IndicatorType.refresh;
              });
            }
          ),
          new IconButton(
            icon: Icons.play_for_work,
            tooltip: 'Over-scroll indicator',
            onPressed: () {
              setState(() {
                _type = IndicatorType.overscroll;
              });
            }
          )
        ]
      ),
      body: body
    );
  }

}
