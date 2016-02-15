// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';

export 'package:flutter/rendering.dart' show
    AutoLayoutParams,
    AutoLayoutDelegate;

class AutoLayout extends MultiChildRenderObjectWidget {
  AutoLayout({
    Key key,
    this.delegate,
    List<Widget> children: const <Widget>[]
  }) : super(key: key, children: children);

  final AutoLayoutDelegate delegate;

  RenderAutoLayout createRenderObject() => new RenderAutoLayout(delegate: delegate);

  void updateRenderObject(RenderAutoLayout renderObject, AutoLayout oldWidget) {
    renderObject.delegate = delegate;
  }
}

class AutoLayoutChild extends ParentDataWidget<AutoLayout> {
  AutoLayoutChild({ Key key, this.params, Widget child })
    : super(key: key, child: child);

  final AutoLayoutParams params;

  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is AutoLayoutParentData);
    final AutoLayoutParentData parentData = renderObject.parentData;
    // AutoLayoutParentData filters out redundant writes and marks needs layout
    // as appropriate.
    parentData.params = params;
  }
}
