// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'overscroll_painter.dart';
import 'theme.dart';

enum MaterialListType {
  oneLine,
  oneLineWithAvatar,
  twoLine,
  threeLine
}

Map<MaterialListType, double> kListItemExtent = const <MaterialListType, double>{
  MaterialListType.oneLine: kOneLineListItemHeight,
  MaterialListType.oneLineWithAvatar: kOneLineListItemWithAvatarHeight,
  MaterialListType.twoLine: kTwoLineListItemHeight,
  MaterialListType.threeLine: kThreeLineListItemHeight,
};

class MaterialList extends StatefulWidget {
  MaterialList({
    Key key,
    this.initialScrollOffset,
    this.onScroll,
    this.type: MaterialListType.twoLine,
    this.clampOverscrolls: false,
    this.children,
    this.scrollablePadding: EdgeInsets.zero,
    this.scrollableKey
  }) : super(key: key);

  final double initialScrollOffset;
  final ScrollListener onScroll;
  final MaterialListType type;
  final bool clampOverscrolls;
  final Iterable<Widget> children;
  final EdgeInsets scrollablePadding;
  final Key scrollableKey;

  @override
  _MaterialListState createState() => new _MaterialListState();
}

class _MaterialListState extends State<MaterialList> {
  ScrollableListPainter _overscrollPainter;

  Color _getOverscrollIndicatorColor() => Theme.of(context).accentColor.withOpacity(0.35);

  @override
  void initState() {
    super.initState();
    _overscrollPainter = new OverscrollPainter(getIndicatorColor: _getOverscrollIndicatorColor);
  }

  @override
  Widget build(BuildContext context) {
    return new ScrollableList(
      key: config.scrollableKey,
      initialScrollOffset: config.initialScrollOffset,
      scrollDirection: Axis.vertical,
      clampOverscrolls: config.clampOverscrolls,
      onScroll: config.onScroll,
      itemExtent: kListItemExtent[config.type],
      padding: const EdgeInsets.symmetric(vertical: 8.0) + config.scrollablePadding,
      scrollableListPainter: config.clampOverscrolls ? _overscrollPainter : null,
      children: config.children
    );
  }
}
