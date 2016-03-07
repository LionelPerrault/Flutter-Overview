// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

/// The end of the viewport from which the paint offset is computed.
enum ViewportAnchor {
  /// The start (e.g., top or left, depending on the axis) of the first item
  /// should be aligned with the start (e.g., top or left, depending on the
  /// axis) of the viewport.
  start,

  /// The end (e.g., bottom or right, depending on the axis) of the last item
  /// should be aligned with the end (e.g., bottom or right, depending on the
  /// axis) of the viewport.
  end,
}

/// The interior and exterior dimensions of a viewport.
class ViewportDimensions {
  const ViewportDimensions({
    this.contentSize: Size.zero,
    this.containerSize: Size.zero
  });

  /// A viewport that has zero size, both inside and outside.
  static const ViewportDimensions zero = const ViewportDimensions();

  /// The size of the content inside the viewport.
  final Size contentSize;

  /// The size of the outside of the viewport.
  final Size containerSize;

  bool get _debugHasAtLeastOneCommonDimension {
    return contentSize.width == containerSize.width
        || contentSize.height == containerSize.height;
  }

  /// Returns the offset at which to paint the content, accounting for the given
  /// anchor and the dimensions of the viewport.
  Offset getAbsolutePaintOffset({ Offset paintOffset, ViewportAnchor anchor }) {
    assert(_debugHasAtLeastOneCommonDimension);
    switch (anchor) {
      case ViewportAnchor.start:
        return paintOffset;
      case ViewportAnchor.end:
        return paintOffset + (containerSize - contentSize);
    }
  }

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! ViewportDimensions)
      return false;
    final ViewportDimensions typedOther = other;
    return contentSize == typedOther.contentSize &&
           containerSize == typedOther.containerSize;
  }

  int get hashCode => hashValues(contentSize, containerSize);

  String toString() => 'ViewportDimensions(container: $containerSize, content: $contentSize)';
}

/// An interface that indicates that an object has a scroll direction.
abstract class HasScrollDirection {
  /// Whether this object scrolls horizontally or vertically.
  Axis get scrollDirection;
}

/// A base class for render objects that are bigger on the inside.
///
/// This class holds the common fields for viewport render objects but does not
/// have a child model. See [RenderViewport] for a viewport with a single child
/// and [RenderVirtualViewport] for a viewport with multiple children.
class RenderViewportBase extends RenderBox implements HasScrollDirection {
  RenderViewportBase(
    Offset paintOffset,
    Axis scrollDirection,
    ViewportAnchor scrollAnchor,
    Painter overlayPainter
  ) : _paintOffset = paintOffset,
      _scrollDirection = scrollDirection,
      _scrollAnchor = scrollAnchor,
      _overlayPainter = overlayPainter {
    assert(paintOffset != null);
    assert(scrollDirection != null);
    assert(_offsetIsSane(_paintOffset, scrollDirection));
  }

  bool _offsetIsSane(Offset offset, Axis direction) {
    switch (direction) {
      case Axis.horizontal:
        return offset.dy == 0.0;
      case Axis.vertical:
        return offset.dx == 0.0;
    }
  }

  /// The offset at which to paint the child.
  ///
  /// The offset can be non-zero only in the [scrollDirection].
  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  void set paintOffset(Offset value) {
    assert(value != null);
    if (value == _paintOffset)
      return;
    assert(_offsetIsSane(value, scrollDirection));
    _paintOffset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The direction in which the child is permitted to be larger than the viewport
  ///
  /// If the viewport is scrollable in a particular direction (e.g., vertically),
  /// the child is given layout constraints that are fully unconstrainted in
  /// that direction (e.g., the child can be as tall as it wants).
  Axis get scrollDirection => _scrollDirection;
  Axis _scrollDirection;
  void set scrollDirection(Axis value) {
    assert(value != null);
    if (value == _scrollDirection)
      return;
    assert(_offsetIsSane(_paintOffset, value));
    _scrollDirection = value;
    markNeedsLayout();
  }

  /// The end of the viewport from which the paint offset is computed.
  ///
  /// See [ViewportAnchor] for more detail.
  ViewportAnchor get scrollAnchor => _scrollAnchor;
  ViewportAnchor _scrollAnchor;
  void set scrollAnchor(ViewportAnchor value) {
    assert(value != null);
    if (value == _scrollAnchor)
      return;
    _scrollAnchor = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Painter get overlayPainter => _overlayPainter;
  Painter _overlayPainter;
  void set overlayPainter(Painter value) {
    if (_overlayPainter == value)
      return;
    if (attached)
      _overlayPainter?.detach();
    _overlayPainter = value;
    if (attached)
      _overlayPainter?.attach(this);
    markNeedsPaint();
  }

  void attach() {
    super.attach();
    _overlayPainter?.attach(this);
  }

  void detach() {
    super.detach();
    _overlayPainter?.detach();
  }

  ViewportDimensions get dimensions => _dimensions;
  ViewportDimensions _dimensions = ViewportDimensions.zero;
  void set dimensions(ViewportDimensions value) {
    assert(debugDoingThisLayout);
    _dimensions = value;
  }

  Offset get _effectivePaintOffset {
    final double devicePixelRatio = ui.window.devicePixelRatio;
    int dxInDevicePixels = (_paintOffset.dx * devicePixelRatio).round();
    int dyInDevicePixels = (_paintOffset.dy * devicePixelRatio).round();
    return _dimensions.getAbsolutePaintOffset(
      paintOffset: new Offset(dxInDevicePixels / devicePixelRatio, dyInDevicePixels / devicePixelRatio),
      anchor: _scrollAnchor
    );
  }

  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Offset effectivePaintOffset = _effectivePaintOffset;
    super.applyPaintTransform(child, transform.translate(effectivePaintOffset.dx, effectivePaintOffset.dy));
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('paintOffset: $paintOffset');
    description.add('scrollDirection: $scrollDirection');
    description.add('scrollAnchor: $scrollAnchor');
    if (overlayPainter != null)
      description.add('overlay painter: $overlayPainter');
  }
}

typedef Offset ViewportDimensionsChangeCallback(ViewportDimensions dimensions);

/// A render object that's bigger on the inside.
///
/// The child of a viewport can layout to a larger size than the viewport
/// itself. If that happens, only a portion of the child will be visible through
/// the viewport. The portion of the child that is visible is controlled by the
/// paint offset.
class RenderViewport extends RenderViewportBase with RenderObjectWithChildMixin<RenderBox> {

  RenderViewport({
    RenderBox child,
    Offset paintOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    Painter overlayPainter,
    this.onPaintOffsetUpdateNeeded
  }) : super(paintOffset, scrollDirection, scrollAnchor, overlayPainter) {
    this.child = child;
  }

  /// Called during [layout] to report the dimensions of the viewport
  /// and its child.
  ViewportDimensionsChangeCallback onPaintOffsetUpdateNeeded;

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    BoxConstraints innerConstraints;
    switch (scrollDirection) {
      case Axis.horizontal:
        innerConstraints = constraints.heightConstraints();
        break;
      case Axis.vertical:
        innerConstraints = constraints.widthConstraints();
        break;
    }
    return innerConstraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return constraints.constrainWidth(child.getMinIntrinsicWidth(_getInnerConstraints(constraints)));
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return constraints.constrainWidth(child.getMaxIntrinsicWidth(_getInnerConstraints(constraints)));
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return constraints.constrainHeight(child.getMinIntrinsicHeight(_getInnerConstraints(constraints)));
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return constraints.constrainHeight(child.getMaxIntrinsicHeight(_getInnerConstraints(constraints)));
    return super.getMaxIntrinsicHeight(constraints);
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll the RenderViewport, it would shift in its parent if the
  // parent was baseline-aligned, which makes no sense.

  void performLayout() {
    ViewportDimensions oldDimensions = dimensions;
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = Offset.zero;
      dimensions = new ViewportDimensions(containerSize: size, contentSize: child.size);
    } else {
      performResize();
      dimensions = new ViewportDimensions(containerSize: size);
    }
    if (onPaintOffsetUpdateNeeded != null && dimensions != oldDimensions)
      paintOffset = onPaintOffsetUpdateNeeded(dimensions);
    assert(paintOffset != null);
  }

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    return paintOffset < Offset.zero || !(Offset.zero & size).contains((paintOffset & child.size).bottomRight);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Offset effectivePaintOffset = _effectivePaintOffset;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child, offset + effectivePaintOffset);
        _overlayPainter?.paint(context, offset);
      }

      if (_shouldClipAtPaintOffset(effectivePaintOffset)) {
        context.pushClipRect(needsCompositing, offset, Point.origin & size, paintContents);
      } else {
        paintContents(context, offset);
      }
    }
  }

  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtPaintOffset(_effectivePaintOffset))
      return Point.origin & size;
    return null;
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    if (child != null) {
      assert(child.parentData is BoxParentData);
      Point transformed = position + -_effectivePaintOffset;
      return child.hitTest(result, position: transformed);
    }
    return false;
  }
}

abstract class RenderVirtualViewport<T extends ContainerBoxParentDataMixin<RenderBox>>
    extends RenderViewportBase with ContainerRenderObjectMixin<RenderBox, T>,
                                    RenderBoxContainerDefaultsMixin<RenderBox, T> {
  RenderVirtualViewport({
    int virtualChildCount,
    LayoutCallback callback,
    Offset paintOffset: Offset.zero,
    Axis scrollDirection: Axis.vertical,
    ViewportAnchor scrollAnchor: ViewportAnchor.start,
    Painter overlayPainter
  }) : _virtualChildCount = virtualChildCount,
       _callback = callback,
       super(paintOffset, scrollDirection, scrollAnchor, overlayPainter);

  int get virtualChildCount => _virtualChildCount;
  int _virtualChildCount;
  void set virtualChildCount(int value) {
    if (_virtualChildCount == value)
      return;
    _virtualChildCount = value;
    markNeedsLayout();
  }

  /// Called during [layout] to determine the render object's children.
  ///
  /// Typically the callback will mutate the child list appropriately, for
  /// example so the child list contains only visible children.
  LayoutCallback get callback => _callback;
  LayoutCallback _callback;
  void set callback(LayoutCallback value) {
    if (value == _callback)
      return;
    _callback = value;
    markNeedsLayout();
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position + -_effectivePaintOffset);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    defaultPaint(context, offset + _effectivePaintOffset);
    _overlayPainter?.paint(context, offset);
  }

  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
  }

  Rect describeApproximatePaintClip(RenderObject child) => Point.origin & size;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('virtual child count: $virtualChildCount');
  }
}
