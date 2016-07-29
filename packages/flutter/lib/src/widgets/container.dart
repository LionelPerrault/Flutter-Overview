// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';

/// A widget that paints a [Decoration] either before or after its child paints.
///
/// [Container] insets its child by the widths of the borders; this widget does
/// not.
///
/// Commonly used with [BoxDecoration].
class DecoratedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that paints a [Decoration].
  ///
  /// The [decoration] and [position] arguments must not be null. By default the
  /// decoration paints behind the child.
  DecoratedBox({
    Key key,
    @required this.decoration,
    this.position: DecorationPosition.background,
    Widget child
  }) : super(key: key, child: child) {
    assert(decoration != null);
    assert(position != null);
  }

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  final Decoration decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  @override
  RenderDecoratedBox createRenderObject(BuildContext context) {
    return new RenderDecoratedBox(
      decoration: decoration,
      position: position,
      configuration: createLocalImageConfiguration(context)
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDecoratedBox renderObject) {
    renderObject
      ..decoration = decoration
      ..configuration = createLocalImageConfiguration(context)
      ..position = position;
  }
}

/// A convenience widget that combines common painting, positioning, and sizing
/// widgets.
///
/// A container first surrounds the child with [padding] (inflated by any
/// borders present in the [decoration]) and then applies additional
/// [constraints] to the padded extent (incorporating the [width] and [height]
/// as constraints, if either is non-null). The container is then surrounded by
/// additional empty space described from the [margin].
///
/// During painting, the container first applies the given [transform], then
/// paints the [decoration] to fill the padded extent, then it paints the child,
/// and finally paints the [foregroundDecoration], also filling the padded
/// extent.
class Container extends StatelessWidget {
  /// Creates a widget that combines common painting, positioning, and sizing widgets.
  Container({
    Key key,
    this.align,
    this.padding,
    this.decoration,
    this.foregroundDecoration,
    double width,
    double height,
    BoxConstraints constraints,
    this.margin,
    this.transform,
    this.child
  }) : constraints =
        (width != null || height != null)
          ? constraints?.tighten(width: width, height: height)
            ?? new BoxConstraints.tightFor(width: width, height: height)
          : constraints,
       super(key: key) {
    assert(margin == null || margin.isNonNegative);
    assert(padding == null || padding.isNonNegative);
    assert(decoration == null || decoration.debugAssertValid());
  }

  /// The child contained by the container.
  ///
  /// If null, the container will expand to fill all available space in its parent.
  final Widget child;

  /// Align the child within the container.
  ///
  /// If non-null, the container will expand to fill its parent and position its
  /// child within itself according to the given value.
  final FractionalOffset align;

  /// Empty space to inscribe inside the decoration.
  final EdgeInsets padding;

  /// The decoration to paint behind the child.
  final Decoration decoration;

  /// The decoration to paint in front of the child.
  final Decoration foregroundDecoration;

  /// Additional constraints to apply to the child.
  final BoxConstraints constraints;

  /// Empty space to surround the decoration.
  final EdgeInsets margin;

  /// The transformation matrix to apply before painting the container.
  final Matrix4 transform;

  EdgeInsets get _paddingIncludingDecoration {
    if (decoration == null || decoration.padding == null)
      return padding;
    EdgeInsets decorationPadding = decoration.padding;
    if (padding == null)
      return decorationPadding;
    return padding + decorationPadding;
  }

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    if (child == null && (constraints == null || !constraints.isTight))
      current = new ConstrainedBox(constraints: const BoxConstraints.expand());

    if (align != null)
      current = new Align(alignment: align, child: current);

    EdgeInsets effectivePadding = _paddingIncludingDecoration;
    if (effectivePadding != null)
      current = new Padding(padding: effectivePadding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (foregroundDecoration != null) {
      current = new DecoratedBox(
        decoration: foregroundDecoration,
        position: DecorationPosition.foreground,
        child: current
      );
    }

    if (constraints != null)
      current = new ConstrainedBox(constraints: constraints, child: current);

    if (margin != null)
      current = new Padding(padding: margin, child: current);

    if (transform != null)
      current = new Transform(transform: transform, child: current);

    return current;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (constraints != null)
      description.add('$constraints');
    if (decoration != null)
      description.add('bg: $decoration');
    if (foregroundDecoration != null)
      description.add('fg: $foregroundDecoration');
    if (margin != null)
      description.add('margin: $margin');
    if (padding != null)
      description.add('padding: $padding');
    if (transform != null)
      description.add('has transform');
  }
}
