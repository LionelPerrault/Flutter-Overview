// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';
import 'tool_bar.dart';
import 'snack_bar.dart';

const double _kFloatingActionButtonMargin = 16.0; // TODO(hmuller): should be device dependent

enum _Child { body, toolBar, bottomSheet, snackBar, floatingActionButton }

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  void performLayout(Size size, BoxConstraints constraints) {

    // This part of the layout has the same effect as putting the toolbar and
    // body in a column and making the body flexible. What's different is that
    // in this case the toolbar appears -after- the body in the stacking order,
    // so the toolbar's shadow is drawn on top of the body.

    final BoxConstraints toolBarConstraints = constraints.loosen().tightenWidth(size.width);
    Size toolBarSize = Size.zero;

    if (isChild(_Child.toolBar)) {
      toolBarSize = layoutChild(_Child.toolBar, toolBarConstraints);
      positionChild(_Child.toolBar, Point.origin);
    }

    if (isChild(_Child.body)) {
      final double bodyHeight = size.height - toolBarSize.height;
      final BoxConstraints bodyConstraints = toolBarConstraints.tightenHeight(bodyHeight);
      layoutChild(_Child.body, bodyConstraints);
      positionChild(_Child.body, new Point(0.0, toolBarSize.height));
    }

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height.
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // _kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by _kFloatingActionButtonMargin.

    final BoxConstraints fullWidthConstraints = constraints.loosen().tightenWidth(size.width);
    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;

    if (isChild(_Child.bottomSheet)) {
      bottomSheetSize = layoutChild(_Child.bottomSheet, fullWidthConstraints);
      positionChild(_Child.bottomSheet, new Point(0.0, size.height - bottomSheetSize.height));
    }

    if (isChild(_Child.snackBar)) {
      snackBarSize = layoutChild(_Child.snackBar, fullWidthConstraints);
      positionChild(_Child.snackBar, new Point(0.0, size.height - snackBarSize.height));
    }

    if (isChild(_Child.floatingActionButton)) {
      final Size fabSize = layoutChild(_Child.floatingActionButton, constraints.loosen());
      final double fabX = size.width - fabSize.width - _kFloatingActionButtonMargin;
      double fabY = size.height - fabSize.height - _kFloatingActionButtonMargin;
      if (snackBarSize.height > 0.0)
        fabY = math.min(fabY, size.height - snackBarSize.height - fabSize.height - _kFloatingActionButtonMargin);
      if (bottomSheetSize.height > 0.0)
        fabY = math.min(fabY, size.height - bottomSheetSize.height - fabSize.height / 2.0);
      positionChild(_Child.floatingActionButton, new Point(fabX, fabY));
    }
  }
}

final _ScaffoldLayout _scaffoldLayout = new _ScaffoldLayout();

class Scaffold extends StatefulComponent {
  Scaffold({
    Key key,
    this.toolBar,
    this.body,
    this.bottomSheet,
    this.floatingActionButton
  }) : super(key: key);

  final ToolBar toolBar;
  final Widget body;
  final Widget bottomSheet; // this is for non-modal bottom sheets
  final Widget floatingActionButton;

  static ScaffoldState of(BuildContext context) => context.ancestorStateOfType(ScaffoldState);

  ScaffoldState createState() => new ScaffoldState();
}

class ScaffoldState extends State<Scaffold> {

  Queue<SnackBar> _snackBars = new Queue<SnackBar>();
  Performance _snackBarPerformance;
  Timer _snackBarTimer;

  void showSnackBar(SnackBar snackbar) {
    _snackBarPerformance ??= SnackBar.createPerformance()
      ..addStatusListener(_handleSnackBarStatusChange);
    setState(() {
      _snackBars.addLast(snackbar.withPerformance(_snackBarPerformance));
    });
  }

  void _handleSnackBarStatusChange(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.dismissed:
        assert(_snackBars.isNotEmpty);
        setState(() {
          _snackBars.removeFirst();
        });
        break;
      case PerformanceStatus.completed:
        setState(() {
          assert(_snackBarTimer == null);
          // build will create a new timer if necessary to dismiss the snack bar
        });
        break;
      case PerformanceStatus.forward:
      case PerformanceStatus.reverse:
        break;
    }
  }

  void _hideSnackBar() {
    _snackBarPerformance.reverse();
    _snackBarTimer = null;
  }

  void dispose() {
    _snackBarPerformance?.stop();
    _snackBarPerformance = null;
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    super.dispose();
  }

  void _addIfNonNull(List<LayoutId> children, Widget child, Object childId) {
    if (child != null)
      children.add(new LayoutId(child: child, id: childId));
  }

  Widget build(BuildContext context) {
    final Widget paddedToolBar = config.toolBar?.withPadding(new EdgeDims.only(top: ui.window.padding.top));
    final Widget materialBody = config.body != null ? new Material(child: config.body) : null;

    if (_snackBars.length > 0) {
      if (_snackBarPerformance.isDismissed)
        _snackBarPerformance.forward();
      ModalRoute route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarPerformance.isCompleted && _snackBarTimer == null)
          _snackBarTimer = new Timer(_snackBars.first.duration, _hideSnackBar);
      } else {
        _snackBarTimer?.cancel();
        _snackBarTimer = null;
      }
    }

    final List<LayoutId>children = new List<LayoutId>();
    _addIfNonNull(children, materialBody, _Child.body);
    _addIfNonNull(children, paddedToolBar, _Child.toolBar);
    _addIfNonNull(children, config.bottomSheet, _Child.bottomSheet);
    if (_snackBars.isNotEmpty)
      _addIfNonNull(children, _snackBars.first, _Child.snackBar);
    _addIfNonNull(children, config.floatingActionButton, _Child.floatingActionButton);

    return new CustomMultiChildLayout(children, delegate: _scaffoldLayout);
  }

}
