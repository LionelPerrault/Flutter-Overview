// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'drawer.dart';
import 'item.dart';

const double _kFlexibleSpaceMaxHeight = 256.0;

List<GalleryItem> _itemsWithCategory(String category) {
  return kAllGalleryItems.where((GalleryItem item) => item.category == category).toList();
}

final List<GalleryItem> _demoItems = _itemsWithCategory('Demos');
final List<GalleryItem> _componentItems = _itemsWithCategory('Components');
final List<GalleryItem> _styleItems = _itemsWithCategory('Style');

class GalleryHome extends StatefulWidget {
  GalleryHome({
    Key key,
    this.useLightTheme,
    this.onThemeChanged,
    this.timeDilation,
    this.onTimeDilationChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
    assert(onShowPerformanceOverlayChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  GalleryHomeState createState() => new GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome> {
  final Key _homeKey = new ValueKey<String>("Gallery Home");

  @override
  Widget build(BuildContext context) {
    final double statusBarHight = (MediaQuery.of(context)?.padding ?? EdgeInsets.zero).top;

    return new Scaffold(
      key: _homeKey,
      drawer: new GalleryDrawer(
        useLightTheme: config.useLightTheme,
        onThemeChanged: config.onThemeChanged,
        timeDilation: config.timeDilation,
        onTimeDilationChanged: config.onTimeDilationChanged,
        showPerformanceOverlay: config.showPerformanceOverlay,
        onShowPerformanceOverlayChanged: config.onShowPerformanceOverlayChanged
      ),
      appBar: new AppBar(
        expandedHeight: _kFlexibleSpaceMaxHeight,
        flexibleSpace: new FlexibleSpaceBar(
          background: new AssetImage(
            name: 'packages/flutter_gallery_assets/appbar_background.jpg',
            fit: ImageFit.cover,
            height: _kFlexibleSpaceMaxHeight
          ),
          title: new Text('Flutter gallery')
        )
      ),
      appBarBehavior: AppBarBehavior.under,
      body: new TwoLevelList(
        padding: new EdgeInsets.only(top: _kFlexibleSpaceMaxHeight + statusBarHight),
        type: MaterialListType.oneLine,
        children: <Widget>[
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.star),
            title: new Text('Demos'),
            children: _demoItems
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.extension),
            title: new Text('Components'),
            children: _componentItems
          ),
          new TwoLevelSublist(
            leading: new Icon(icon: Icons.color_lens),
            title: new Text('Style'),
            children: _styleItems
          )
        ]
      )
    );
  }
}
