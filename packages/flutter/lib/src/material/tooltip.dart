// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

const double _kDefaultTooltipBorderRadius = 2.0;
const double _kDefaultTooltipHeight = 32.0;
const EdgeDims _kDefaultTooltipPadding = const EdgeDims.symmetric(horizontal: 16.0);
const double _kDefaultVerticalTooltipOffset = 24.0;
const EdgeDims _kDefaultTooltipScreenEdgeMargin = const EdgeDims.all(10.0);
const Duration _kDefaultTooltipFadeDuration = const Duration(milliseconds: 200);
const Duration _kDefaultTooltipShowDuration = const Duration(seconds: 2);

class Tooltip extends StatefulComponent {
  Tooltip({
    Key key,
    this.message,
    this.backgroundColor,
    this.textColor,
    this.style,
    this.opacity: 0.9,
    this.borderRadius: _kDefaultTooltipBorderRadius,
    this.height: _kDefaultTooltipHeight,
    this.padding: _kDefaultTooltipPadding,
    this.verticalOffset: _kDefaultVerticalTooltipOffset,
    this.screenEdgeMargin: _kDefaultTooltipScreenEdgeMargin,
    this.preferBelow: true,
    this.fadeDuration: _kDefaultTooltipFadeDuration,
    this.showDuration: _kDefaultTooltipShowDuration,
    this.child
  }) : super(key: key) {
    assert(message != null);
    assert(opacity != null);
    assert(borderRadius != null);
    assert(height != null);
    assert(padding != null);
    assert(verticalOffset != null);
    assert(screenEdgeMargin != null);
    assert(preferBelow != null);
    assert(fadeDuration != null);
    assert(showDuration != null);
  }

  final String message;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle style;
  final double opacity;
  final double borderRadius;
  final double height;
  final EdgeDims padding;
  final double verticalOffset;
  final EdgeDims screenEdgeMargin;
  final bool preferBelow;
  final Duration fadeDuration;
  final Duration showDuration;
  final Widget child;

  _TooltipState createState() => new _TooltipState();
}

class _TooltipState extends State<Tooltip> {

  Performance _performance;
  OverlayEntry _entry;
  Timer _timer;

  void initState() {
    super.initState();
    _performance = new Performance(duration: config.fadeDuration)
      ..addStatusListener((PerformanceStatus status) {
        switch (status) {
          case PerformanceStatus.completed:
            assert(_entry != null);
            assert(_timer == null);
            resetShowTimer();
            break;
          case PerformanceStatus.dismissed:
            assert(_entry != null);
            assert(_timer == null);
            _entry.remove();
            _entry = null;
            break;
          default:
            break;
        }
      });
  }

  void didUpdateConfig(Tooltip oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.fadeDuration != oldConfig.fadeDuration)
      _performance.duration = config.fadeDuration;
    if (_entry != null &&
        (config.message != oldConfig.message ||
         config.backgroundColor != oldConfig.backgroundColor ||
         config.style != oldConfig.style ||
         config.textColor != oldConfig.textColor ||
         config.borderRadius != oldConfig.borderRadius ||
         config.height != oldConfig.height ||
         config.padding != oldConfig.padding ||
         config.opacity != oldConfig.opacity ||
         config.verticalOffset != oldConfig.verticalOffset ||
         config.screenEdgeMargin != oldConfig.screenEdgeMargin ||
         config.preferBelow != oldConfig.preferBelow))
      _entry.markNeedsBuild();
  }

  void resetShowTimer() {
    assert(_performance.status == PerformanceStatus.completed);
    assert(_entry != null);
    _timer = new Timer(config.showDuration, hideTooltip);
  }

  void showTooltip() {
    if (_entry == null) {
      RenderBox box = context.findRenderObject();
      Point target = box.localToGlobal(box.size.center(Point.origin));
      _entry = new OverlayEntry(builder: (BuildContext context) {
        TextStyle textStyle = (config.style ?? Theme.of(context).text.body1).copyWith(color: config.textColor ?? Colors.white);
        return new _TooltipOverlay(
          message: config.message,
          backgroundColor: config.backgroundColor ?? Colors.grey[700],
          style: textStyle,
          borderRadius: config.borderRadius,
          height: config.height,
          padding: config.padding,
          opacity: config.opacity,
          performance: _performance,
          target: target,
          verticalOffset: config.verticalOffset,
          screenEdgeMargin: config.screenEdgeMargin,
          preferBelow: config.preferBelow
        );
      });
      Overlay.of(context).insert(_entry);
    }
    _timer?.cancel();
    if (_performance.status != PerformanceStatus.completed) {
      _timer = null;
      _performance.forward();
    } else {
      resetShowTimer();
    }
  }

  void hideTooltip() {
    assert(_entry != null);
    _timer?.cancel();
    _timer = null;
    _performance.reverse();    
  }

  void deactivate() {
    if (_entry != null)
      hideTooltip();
    super.deactivate();
  }

  Widget build(BuildContext context) {
    assert(Overlay.of(context) != null);
    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: showTooltip,
      child: config.child
    );
  }
}

class _TooltipPositionDelegate extends OneChildLayoutDelegate {
  _TooltipPositionDelegate({
    this.target,
    this.verticalOffset,
    this.screenEdgeMargin,
    this.preferBelow
  });
  final Point target;
  final double verticalOffset;
  final EdgeDims screenEdgeMargin;
  final bool preferBelow;

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  Offset getPositionForChild(Size size, Size childSize) {
    // VERTICAL DIRECTION
    final bool fitsBelow = target.y + verticalOffset + childSize.height <= size.height - screenEdgeMargin.bottom;
    final bool fitsAbove = target.y - verticalOffset - childSize.height >= screenEdgeMargin.top;
    final bool tooltipBelow = preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
    double y;
    if (tooltipBelow)
      y = math.min(target.y + verticalOffset, size.height - screenEdgeMargin.bottom);
    else
      y = math.max(target.y - verticalOffset - childSize.height, screenEdgeMargin.top);
    // HORIZONTAL DIRECTION
    double normalizedTargetX = target.x.clamp(screenEdgeMargin.left, size.width - screenEdgeMargin.right);
    double x;
    if (normalizedTargetX < screenEdgeMargin.left + childSize.width / 2.0) {
      x = screenEdgeMargin.left;
    } else if (normalizedTargetX > size.width - screenEdgeMargin.right - childSize.width / 2.0) {
      x = size.width - screenEdgeMargin.right - childSize.width;
    } else {
      x = normalizedTargetX + childSize.width / 2.0;
    }
    return new Offset(x, y);
  }

  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != target
        || verticalOffset != verticalOffset
        || screenEdgeMargin != screenEdgeMargin
        || preferBelow != preferBelow;
  }
}

class _TooltipOverlay extends StatelessComponent {
  _TooltipOverlay({
    Key key,
    this.message,
    this.backgroundColor,
    this.style,
    this.borderRadius,
    this.height,
    this.padding,
    this.opacity,
    this.performance,
    this.target,
    this.verticalOffset,
    this.screenEdgeMargin,
    this.preferBelow
  }) : super(key: key);

  final String message;
  final Color backgroundColor;
  final TextStyle style;
  final double opacity;
  final double borderRadius;
  final double height;
  final EdgeDims padding;
  final PerformanceView performance;
  final Point target;
  final double verticalOffset;
  final EdgeDims screenEdgeMargin;
  final bool preferBelow;

  Widget build(BuildContext context) {
    return new Positioned(
      top: 0.0,
      left: 0.0,
      right: 0.0,
      bottom: 0.0,
      child: new IgnorePointer(
        child: new CustomOneChildLayout(
          delegate: new _TooltipPositionDelegate(
            target: target,
            verticalOffset: verticalOffset,
            screenEdgeMargin: screenEdgeMargin,
            preferBelow: preferBelow
          ),
          child: new FadeTransition(
            performance: performance,
            opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.ease),
            child: new Opacity(
              opacity: opacity,
              child: new Container(
                decoration: new BoxDecoration(
                  backgroundColor: backgroundColor,
                  borderRadius: borderRadius
                ),
                height: height,
                padding: padding,
                child: new Center(
                  widthFactor: 1.0,
                  child: new Text(message, style: style)
                )
              )
            )
          )
        )
      )
    );
  }
}
