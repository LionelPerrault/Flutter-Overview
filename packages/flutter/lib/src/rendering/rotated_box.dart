// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

const double _kQuarterTurnsInRadians = math.PI / 2.0;

/// Rotates its child by a integral number of quarter turns.
///
/// Unlike [RenderTransform], which applies a transform just prior to painting,
/// this object applies its rotation prior to layout, which means the entire
/// rotated box consumes only as much space as required by the rotated child.
class RenderRotatedBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  RenderRotatedBox({
    int quarterTurns,
    RenderBox child
  }) : _quarterTurns = quarterTurns {
    assert(quarterTurns != null);
    this.child = child;
  }

  /// The number of clockwise quarter turns the child should be rotated.
  int get quarterTurns => _quarterTurns;
  int _quarterTurns;
  void set quarterTurns(int value) {
    assert(value != null);
    if (_quarterTurns == value)
      return;
    _quarterTurns = value;
    markNeedsLayout();
  }

  bool get _isVertical => quarterTurns % 2 == 1;

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return _isVertical ? child.getMinIntrinsicHeight(constraints.flipped) : child.getMinIntrinsicWidth(constraints);
    return super.getMinIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return _isVertical ? child.getMaxIntrinsicHeight(constraints.flipped) : child.getMaxIntrinsicWidth(constraints);
    return super.getMaxIntrinsicWidth(constraints);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return _isVertical ? child.getMinIntrinsicWidth(constraints.flipped) : child.getMinIntrinsicHeight(constraints);
    return super.getMinIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    if (child != null)
      return _isVertical ? child.getMaxIntrinsicWidth(constraints.flipped) : child.getMaxIntrinsicHeight(constraints);
    return super.getMaxIntrinsicHeight(constraints);
  }

  Matrix4 _paintTransform;

  void performLayout() {
    _paintTransform = null;
    if (child != null) {
      child.layout(_isVertical ? constraints.flipped : constraints, parentUsesSize: true);
      size = _isVertical ? new Size(child.size.height, child.size.width) : child.size;
      _paintTransform = new Matrix4.identity()
        ..translate(size.width / 2.0, size.height / 2.0)
        ..rotateZ(_kQuarterTurnsInRadians * (quarterTurns % 4))
        ..translate(-child.size.width / 2.0, -child.size.height / 2.0);
    } else {
      performResize();
    }
  }

  bool hitTestChildren(HitTestResult result, { Point position }) {
    assert(_paintTransform != null || needsLayout || child == null);
    if (child == null || _paintTransform == null)
      return false;
    Matrix4 inverse = new Matrix4.inverted(_paintTransform);
    Vector3 position3 = new Vector3(position.x, position.y, 0.0);
    Vector3 transformed3 = inverse.transform3(position3);
    return child.hitTest(result, position: new Point(transformed3.x, transformed3.y));
  }

  void _paintChild(PaintingContext context, Offset offset) {
    context.paintChild(child, offset);
  }

  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.pushTransform(needsCompositing, offset, _paintTransform, _paintChild);
  }

  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_paintTransform != null)
      transform.multiply(_paintTransform);
    super.applyPaintTransform(child, transform);
  }
}
