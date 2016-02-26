// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class MenuDemo extends StatefulComponent {
  MenuDemo({ Key key }) : super(key: key);

  MenuDemoState createState() => new MenuDemoState();
}

class MenuDemoState extends State<MenuDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final String _simpleValue1 = 'Menu item value one';
  final String _simpleValue2 = 'Menu item value two';
  final String _simpleValue3 = 'Menu item value three';
  String _simpleValue;

  final String _checkedValue1 = 'One';
  final String _checkedValue2 = 'Two';
  final String _checkedValue3 = 'Free';
  final String _checkedValue4 = 'Four';
  List<String> _checkedValues;

  void initState() {
    super.initState();
    _simpleValue = _simpleValue2;
    _checkedValues = <String>[_checkedValue3];
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
     content: new Text(value)
    ));
  }

  void showMenuSelection(String value) {
    if (<String>[_simpleValue1, _simpleValue2, _simpleValue3].contains(value))
      _simpleValue = value;
    showInSnackBar('You selected: $value');
  }

  void showCheckedMenuSelections(String value) {
    if (_checkedValues.contains(value))
      _checkedValues.remove(value);
    else
      _checkedValues.add(value);

    showInSnackBar('Checked $_checkedValues');
  }

  bool isChecked(String value) => _checkedValues.contains(value);

  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      toolBar: new ToolBar(
        center: new Text('Menus'),
        right: <Widget>[
          new PopupMenuButton<String>(
            onSelected: showMenuSelection,
            items: <PopupMenuItem>[
              new PopupMenuItem(
                value: 'ToolBar Menu',
                child: new Text('ToolBar Menu')
              ),
              new PopupMenuItem(
                value: 'Right Here',
                child: new Text('Right Here')
              ),
              new PopupMenuItem(
                value: 'Hooray!',
                child: new Text('Hooray!')
              ),
            ]
          )
        ]
      ),
      body: new Block(
        padding: const EdgeDims.all(8.0),
        children: <Widget>[
          // Pressing the PopupMenuButton on the right of this item shows
          // a simple menu with one disabled item. Typically the contents
          // of this "contextual menu" would reflect the app's state.
          new ListItem(
            primary: new Text('An item with a context menu button'),
            right: new PopupMenuButton<String>(
              onSelected: showMenuSelection,
              items: <PopupMenuItem>[
                new PopupMenuItem(
                  value: _simpleValue1,
                  child: new Text('Context menu item one')
                ),
                new PopupMenuItem(
                  enabled: false,
                  child: new Text('A disabled menu item')
                ),
                new PopupMenuItem(
                  value: _simpleValue3,
                  child: new Text('Context menu item three')
                ),
              ]
            )
          ),
          // Pressing the PopupMenuButton on the right of this item shows
          // a menu whose items have text labels and icons and a divider
          // That separates the first three items from the last one.
          new ListItem(
            primary: new Text('An item with a sectioned menu'),
            right: new PopupMenuButton<String>(
              onSelected: showMenuSelection,
              items: <PopupMenuItem>[
                new PopupMenuItem(
                  value: 'Preview',
                  child: new ListItem(
                    left: new Icon(icon: 'action/visibility'),
                    primary: new Text('Preview')
                  )
                ),
                new PopupMenuItem(
                  value: 'Share',
                  child: new ListItem(
                    left: new Icon(icon: 'social/person_add'),
                    primary: new Text('Share')
                  )
                ),
                new PopupMenuItem(
                  value: 'Get Link',
                  hasDivider: true,
                  child: new ListItem(
                    left: new Icon(icon: 'content/link'),
                    primary: new Text('Get Link')
                  )
                ),
                new PopupMenuItem(
                  value: 'Remove',
                  child: new ListItem(
                    left: new Icon(icon: 'action/delete'),
                    primary: new Text('Remove')
                  )
                )
              ]
            )
          ),
          // This entire list item is a PopupMenuButton. Tapping anywhere shows
          // a menu whose current value is highlighted and aligned over the
          // list item's center line.
          new PopupMenuButton<String>(
            initialValue: _simpleValue,
            onSelected: showMenuSelection,
            child: new ListItem(
              primary: new Text('An item with a simple menu'),
              secondary: new Text(_simpleValue)
            ),
            items: <PopupMenuItem>[
              new PopupMenuItem(
                value: _simpleValue1,
                child: new Text(_simpleValue1)
              ),
              new PopupMenuItem(
                value: _simpleValue2,
                child: new Text(_simpleValue2)
              ),
              new PopupMenuItem(
                value: _simpleValue3,
                child: new Text(_simpleValue3)
              )
            ]
          ),
          // Pressing the PopupMenuButton on the right of this item shows a menu
          // whose items have checked icons that reflect this app's state.
          new ListItem(
            primary: new Text('An item with a checklist menu'),
            right: new PopupMenuButton<String>(
              onSelected: showCheckedMenuSelections,
              items: <PopupMenuItem>[
                new CheckedPopupMenuItem(
                  value: _checkedValue1,
                  checked: isChecked(_checkedValue1),
                  child: new Text(_checkedValue1)
                ),
                new CheckedPopupMenuItem(
                  enabled: false,
                  checked: isChecked(_checkedValue2),
                  child: new Text(_checkedValue2)
                ),
                new CheckedPopupMenuItem(
                  value: _checkedValue3,
                  checked: isChecked(_checkedValue3),
                  child: new Text(_checkedValue3)
                ),
                new CheckedPopupMenuItem(
                  value: _checkedValue4,
                  checked: isChecked(_checkedValue4),
                  child: new Text(_checkedValue4)
                )
              ]
            )
          )
        ]
      )
    );
  }
}
