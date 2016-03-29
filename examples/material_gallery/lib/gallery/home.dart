// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'drawer.dart';
import 'header.dart';
import 'item.dart';

import '../demo/buttons_demo.dart';
import '../demo/cards_demo.dart';
import '../demo/colors_demo.dart';
import '../demo/chip_demo.dart';
import '../demo/date_picker_demo.dart';
import '../demo/dialog_demo.dart';
import '../demo/drop_down_demo.dart';
import '../demo/fitness_demo.dart';
import '../demo/flexible_space_demo.dart';
import '../demo/grid_list_demo.dart';
import '../demo/icons_demo.dart';
import '../demo/leave_behind_demo.dart';
import '../demo/list_demo.dart';
import '../demo/modal_bottom_sheet_demo.dart';
import '../demo/menu_demo.dart';
import '../demo/page_selector_demo.dart';
import '../demo/persistent_bottom_sheet_demo.dart';
import '../demo/progress_indicator_demo.dart';
import '../demo/toggle_controls_demo.dart';
import '../demo/slider_demo.dart';
import '../demo/snack_bar_demo.dart';
import '../demo/scrollable_tabs_demo.dart';
import '../demo/tabs_demo.dart';
import '../demo/tabs_fab_demo.dart';
import '../demo/text_field_demo.dart';
import '../demo/time_picker_demo.dart';
import '../demo/tooltip_demo.dart';
import '../demo/two_level_list_demo.dart';
import '../demo/typography_demo.dart';
import '../demo/weather_demo.dart';

const double _kFlexibleSpaceMaxHeight = 256.0;

class GalleryHome extends StatefulWidget {
  GalleryHome({ Key key }) : super(key: key);

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  final Key _homeKey = new ValueKey<String>("Gallery Home");
  final Key _listKey = new ValueKey<String>("Gallery List");

  @override
  Widget build(BuildContext context) {
    final double statusBarHight = (MediaQuery.of(context)?.padding ?? EdgeInsets.zero).top;

    return new Scaffold(
      key: _homeKey,
      drawer: new GalleryDrawer(),
      appBar: new AppBar(
        expandedHeight: _kFlexibleSpaceMaxHeight,
        flexibleSpace: (BuildContext context) =>  new FlexibleSpaceBar(
          image: new GalleryHeader(),
          title: new Text("Flutter Gallery")
        )
      ),
      scrollableKey: _listKey,
      appBarBehavior: AppBarBehavior.under,
      body: new TwoLevelList(
        scrollablePadding: new EdgeInsets.only(top: _kFlexibleSpaceMaxHeight + statusBarHight),
        type: MaterialListType.oneLine,
        scrollableKey: _listKey,
        items: <Widget>[
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.star),
            title: new Text("Demos"),
            children: <Widget>[
              new GalleryItem(title: "Weather", builder: () => new WeatherDemo()),
              new GalleryItem(title: "Fitness", builder: () => new FitnessDemo()),
            ]
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.extension),
            title: new Text("Components"),
            children: <Widget>[
              new GalleryItem(title: 'App Bar', builder: () => new FlexibleSpaceDemo()),
              new GalleryItem(title: 'Buttons', builder: () => new ButtonsDemo()),
              new GalleryItem(title: 'Buttons: Floating Action Button', builder: () => new TabsFabDemo()),
              new GalleryItem(title: 'Cards', builder: () => new CardsDemo()),
              new GalleryItem(title: 'Chips', builder: () => new ChipDemo()),
              new GalleryItem(title: 'Date Picker', builder: () => new DatePickerDemo()),
              new GalleryItem(title: 'Dialog', builder: () => new DialogDemo()),
              new GalleryItem(title: 'Dropdown Button', builder: () => new DropDownDemo()),
              new GalleryItem(title: 'Expand/Collapse List Control', builder: () => new TwoLevelListDemo()),
              new GalleryItem(title: 'Grid', builder: () => new GridListDemo()),
              new GalleryItem(title: 'Icons', builder: () => new IconsDemo()),
              new GalleryItem(title: 'Leave-behind List Items', builder: () => new LeaveBehindDemo()),
              new GalleryItem(title: 'List', builder: () => new ListDemo()),
              new GalleryItem(title: 'Modal Bottom Sheet', builder: () => new ModalBottomSheetDemo()),
              new GalleryItem(title: 'Menus', builder: () => new MenuDemo()),
              new GalleryItem(title: 'Page Selector', builder: () => new PageSelectorDemo()),
              new GalleryItem(title: 'Persistent Bottom Sheet', builder: () => new PersistentBottomSheetDemo()),
              new GalleryItem(title: 'Progress Indicators', builder: () => new ProgressIndicatorDemo()),
              new GalleryItem(title: 'Scrollable Tabs', builder: () => new ScrollableTabsDemo()),
              new GalleryItem(title: 'Selection Controls', builder: () => new ToggleControlsDemo()),
              new GalleryItem(title: 'Sliders', builder: () => new SliderDemo()),
              new GalleryItem(title: 'SnackBar', builder: () => new SnackBarDemo()),
              new GalleryItem(title: 'Tabs', builder: () => new TabsDemo()),
              new GalleryItem(title: 'Text Fields', builder: () => new TextFieldDemo()),
              new GalleryItem(title: 'Time Picker', builder: () => new TimePickerDemo()),
              new GalleryItem(title: 'Tooltips', builder: () => new TooltipDemo()),
            ]
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.color_lens),
            title: new Text("Style"),
            children: <Widget>[
              new GalleryItem(title: 'Colors', builder: () => new ColorsDemo()),
              new GalleryItem(title: 'Typography', builder: () => new TypographyDemo()),
            ]
          )
        ]
      )
    );
  }
}
