// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class PageSelectorDemo extends StatelessComponent {
  Widget _buildTabIndicator(BuildContext context, String iconName) {
    final Color color = Theme.of(context).primaryColor;
    final ColorTween _selectedColor = new ColorTween(begin: Colors.transparent, end: color);
    final ColorTween _previousColor = new ColorTween(begin: color, end: Colors.transparent);
    final TabBarSelectionState selection = TabBarSelection.of(context);

    CurvedAnimation animation = new CurvedAnimation(parent: selection.animation, curve: Curves.ease);
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        Color background = selection.value == iconName ? _selectedColor.end : _selectedColor.begin;
        if (selection.valueIsChanging) {
          // Then the selection's performance is animating from previousValue to value.
          if (selection.value == iconName)
            background = _selectedColor.evaluate(animation);
          else if (selection.previousValue == iconName)
            background = _previousColor.evaluate(animation);
        }
        return new Container(
          width: 12.0,
          height: 12.0,
          margin: new EdgeDims.all(4.0),
          decoration: new BoxDecoration(
            backgroundColor: background,
            border: new Border.all(color: _selectedColor.end),
            shape: BoxShape.circle
          )
        );
      }
    );
  }

  Widget _buildTabView(String iconName) {
    return new Container(
      key: new ValueKey<String>(iconName),
      padding: const EdgeDims.all(12.0),
      child: new Card(
        child: new Center(
          child: new Icon(icon: "action/$iconName", size:IconSize.s48)
        )
      )
    );
  }

  void _handleArrowButtonPress(BuildContext context, int delta) {
    final TabBarSelectionState selection = TabBarSelection.of(context);
    if (!selection.valueIsChanging)
      selection.value = selection.values[(selection.index + delta).clamp(0, selection.values.length - 1)];
  }

  Widget build(BuildContext notUsed) { // Can't find the TabBarSelection from this context.
    final List<String> iconNames = <String>["event", "home", "android", "alarm", "face", "language"];

    return new Scaffold(
      toolBar: new ToolBar(center: new Text("Page Selector")),
      body: new TabBarSelection(
        values: iconNames,
        child: new Builder(
          builder: (BuildContext context) {
            return new Column(
              children: <Widget>[
                new Container(
                  margin: const EdgeDims.only(top: 16.0),
                  child: new Row(
                    children: <Widget>[
                      new IconButton(
                        icon: "navigation/arrow_back",
                        onPressed: () { _handleArrowButtonPress(context, -1); },
                        tooltip: 'Back'
                      ),
                      new Row(
                        children: iconNames.map((String name) => _buildTabIndicator(context, name)).toList(),
                        justifyContent: FlexJustifyContent.collapse
                      ),
                      new IconButton(
                        icon: "navigation/arrow_forward",
                        onPressed: () { _handleArrowButtonPress(context, 1); },
                        tooltip: 'Forward'
                      )
                    ],
                    justifyContent: FlexJustifyContent.spaceBetween
                  )
                ),
                new Flexible(
                  child: new TabBarView(
                    children: iconNames.map(_buildTabView).toList()
                  )
                )
              ]
            );
          }
        )
      )
    );
  }
}
