// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

import 'package:flutter/rendering.dart';

typedef void ExtentsChangedCallback(double contentExtent, double containerExtent);

abstract class VirtualViewport extends RenderObjectWidget {
  double get startOffset;
  ScrollDirection get scrollDirection;
  Iterable<Widget> get children;
}

abstract class VirtualViewportElement<T extends VirtualViewport> extends RenderObjectElement<T> {
  VirtualViewportElement(T widget) : super(widget);

  int get materializedChildBase;
  int get materializedChildCount;
  double get repaintOffsetBase;
  double get repaintOffsetLimit;

  List<Element> _materializedChildren = const <Element>[];

  RenderVirtualViewport get renderObject => super.renderObject;

  void visitChildren(ElementVisitor visitor) {
    if (_materializedChildren == null)
      return;
    for (Element child in _materializedChildren)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _iterator = null;
    _widgets = <Widget>[];
    renderObject.callback = layout;
    updateRenderObject();
  }

  void unmount() {
    renderObject.callback = null;
    super.unmount();
  }

  void update(T newWidget) {
    if (widget.children != newWidget.children) {
      _iterator = null;
      _widgets = <Widget>[];
    }
    super.update(newWidget);
    updateRenderObject();
    if (!renderObject.needsLayout)
      _materializeChildren();
  }

  void _updatePaintOffset() {
    switch (widget.scrollDirection) {
      case ScrollDirection.vertical:
        renderObject.paintOffset = new Offset(0.0, -(widget.startOffset - repaintOffsetBase));
        break;
      case ScrollDirection.horizontal:
        renderObject.paintOffset = new Offset(-(widget.startOffset - repaintOffsetBase), 0.0);
        break;
    }
  }

  double get _containerExtent {
    switch (widget.scrollDirection) {
      case ScrollDirection.vertical:
        return renderObject.size.height;
      case ScrollDirection.horizontal:
        return renderObject.size.width;
    }
  }

  void updateRenderObject() {
    renderObject.virtualChildCount = widget.children.length;

    if (repaintOffsetBase != null) {
      _updatePaintOffset();

      // If we don't already need layout, we need to request a layout if the
      // viewport has shifted to expose new children.
      if (!renderObject.needsLayout) {
        if (repaintOffsetBase != null && widget.startOffset < repaintOffsetBase)
          renderObject.markNeedsLayout();
        else if (repaintOffsetLimit != null && widget.startOffset + _containerExtent > repaintOffsetLimit)
          renderObject.markNeedsLayout();
      }
    }
  }

  void layout(BoxConstraints constraints) {
    assert(repaintOffsetBase != null);
    assert(repaintOffsetLimit != null);
    _updatePaintOffset();
    BuildableElement.lockState(_materializeChildren);
  }

  Iterator<Widget> _iterator;
  List<Widget> _widgets;

  void _populateWidgets(int limit) {
    if (limit <= _widgets.length)
      return;
    if (widget.children is List<Widget>) {
      _widgets = widget.children;
      return;
    }
    _iterator ??= widget.children.iterator;
    while (_widgets.length < limit) {
      bool moved = _iterator.moveNext();
      assert(moved);
      Widget current = _iterator.current;
      assert(current != null);
      _widgets.add(current);
    }
  }

  void _materializeChildren() {
    int base = materializedChildBase;
    int count = materializedChildCount;
    int length = renderObject.virtualChildCount;
    assert(base != null);
    assert(count != null);
    _populateWidgets(base + count);
    List<Widget> newWidgets = new List<Widget>(count);
    for (int i = 0; i < count; ++i) {
      int childIndex = base + i;
      Widget child = _widgets[childIndex % length];
      Key key = new ValueKey(child.key ?? childIndex);
      newWidgets[i] = new RepaintBoundary(key: key, child: child);
    }
    _materializedChildren = updateChildren(_materializedChildren, newWidgets);
  }

  void insertChildRenderObject(RenderObject child, Element slot) {
    RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child, before: nextSibling);
  }

  void moveChildRenderObject(RenderObject child, Element slot) {
    assert(child.parent == renderObject);
    RenderObject nextSibling = slot?.renderObject;
    renderObject.move(child, before: nextSibling);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }
}
