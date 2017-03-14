// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'scroll_configuration.dart';
import 'scroll_controller.dart';
import 'scroll_notification.dart';
import 'scroll_position.dart';
import 'ticker_provider.dart';
import 'viewport.dart';

export 'package:flutter/physics.dart' show Tolerance;

typedef Widget ViewportBuilder(BuildContext context, ViewportOffset position);

class Scrollable extends StatefulWidget {
  Scrollable({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.controller,
    this.physics,
    @required this.viewportBuilder,
  }) : super (key: key) {
    assert(axisDirection != null);
    assert(viewportBuilder != null);
  }

  final AxisDirection axisDirection;

  final ScrollController controller;

  final ScrollPhysics physics;

  final ViewportBuilder viewportBuilder;

  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  ScrollableState createState() => new ScrollableState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    if (physics != null)
      description.add('physics: $physics');
  }

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ScrollableState scrollable = Scrollable.of(context);
  /// ```
  static ScrollableState of(BuildContext context) {
    return context.ancestorStateOfType(const TypeMatcher<ScrollableState>());
  }

  /// Scrolls the closest enclosing scrollable to make the given context visible.
  static Future<Null> ensureVisible(BuildContext context, {
    double alignment: 0.0,
    Duration duration: Duration.ZERO,
    Curve curve: Curves.ease,
  }) {
    final List<Future<Null>> futures = <Future<Null>>[];

    ScrollableState scrollable = Scrollable.of(context);
    while (scrollable != null) {
      futures.add(scrollable.position.ensureVisible(
        context.findRenderObject(),
        alignment: alignment,
        duration: duration,
        curve: curve,
      ));
      context = scrollable.context;
      scrollable = Scrollable.of(context);
    }

    if (futures.isEmpty || duration == Duration.ZERO)
      return new Future<Null>.value();
    if (futures.length == 1)
      return futures.first;
    return Future.wait<Null>(futures);
  }
}

/// State object for a [Scrollable] widget.
///
/// To manipulate a [Scrollable] widget's scroll position, use the object
/// obtained from the [position] property.
///
/// To be informed of when a [Scrollable] widget is scrolling, use a
/// [NotificationListener] to listen for [ScrollNotification] notifications.
///
/// This class is not intended to be subclassed. To specialize the behavior of a
/// [Scrollable], provide it with a [ScrollPhysics].
class ScrollableState extends State<Scrollable> with TickerProviderStateMixin
    implements AbstractScrollState {
  /// The controller for this [Scrollable] widget's viewport position.
  ///
  /// To control what kind of [ScrollPosition] is created for a [Scrollable],
  /// provide it with custom [ScrollPhysics] that creates the appropriate
  /// [ScrollPosition] controller in its [ScrollPhysics.createScrollPosition]
  /// method.
  ScrollPosition get position => _position;
  ScrollPosition _position;

  ScrollBehavior _configuration;

  // only call this from places that will definitely trigger a rebuild
  void _updatePosition() {
    _configuration = ScrollConfiguration.of(context);
    ScrollPhysics physics = _configuration.getScrollPhysics(context);
    if (config.physics != null)
      physics = config.physics.applyTo(physics);
    final ScrollController controller = config.controller;
    final ScrollPosition oldPosition = position;
    if (oldPosition != null) {
      controller?.detach(oldPosition);
      // It's important that we not dispose the old position until after the
      // viewport has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldPosition.dispose);
    }

    _position = controller?.createScrollPosition(physics, this, oldPosition)
      ?? ScrollController.createDefaultScrollPosition(physics, this, oldPosition);
    assert(position != null);
    controller?.attach(position);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePosition();
  }

  bool _shouldUpdatePosition(Scrollable oldConfig) {
    return config.physics?.runtimeType != oldConfig.physics?.runtimeType
        || config.controller?.runtimeType != oldConfig.controller?.runtimeType;
  }

  @override
  void didUpdateConfig(Scrollable oldConfig) {
    super.didUpdateConfig(oldConfig);

    if (config.controller != oldConfig.controller) {
      oldConfig.controller?.detach(position);
      config.controller?.attach(position);
    }

    if (_shouldUpdatePosition(oldConfig))
      _updatePosition();
  }

  @override
  void dispose() {
    config.controller?.detach(position);
    position.dispose();
    super.dispose();
  }


  // GESTURE RECOGNITION AND POINTER IGNORING

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = new GlobalKey<RawGestureDetectorState>();
  final GlobalKey _ignorePointerKey = new GlobalKey();

  // This field is set during layout, and then reused until the next time it is set.
  Map<Type, GestureRecognizerFactory> _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
  bool _shouldIgnorePointer = false;

  bool _lastCanDrag;
  Axis _lastAxisDirection;

  @override
  @protected
  void setCanDrag(bool canDrag) {
    if (canDrag == _lastCanDrag && (!canDrag || config.axis == _lastAxisDirection))
      return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      switch (config.axis) {
        case Axis.vertical:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            VerticalDragGestureRecognizer: (VerticalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/7173
              return (recognizer ??= new VerticalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
          break;
        case Axis.horizontal:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer: (HorizontalDragGestureRecognizer recognizer) {  // ignore: map_value_type_not_assignable, https://github.com/flutter/flutter/issues/7173
              return (recognizer ??= new HorizontalDragGestureRecognizer())
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd;
            }
          };
          break;
      }
    }
    _lastCanDrag = canDrag;
    _lastAxisDirection = config.axis;
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState.replaceGestureRecognizers(_gestureRecognizers);
  }

  @override
  TickerProvider get vsync => this;

  @override
  @protected
  void setIgnorePointer(bool value) {
    if (_shouldIgnorePointer == value)
      return;
    _shouldIgnorePointer = value;
    if (_ignorePointerKey.currentContext != null) {
      final RenderIgnorePointer renderBox = _ignorePointerKey.currentContext.findRenderObject();
      renderBox.ignoring = _shouldIgnorePointer;
    }
  }

  @override
  @protected
  void dispatchNotification(Notification notification) {
    assert(mounted);
    notification.dispatch(_gestureDetectorKey.currentContext);
  }

  // TOUCH HANDLERS

  DragScrollActivity _drag;

  bool get _reverseDirection {
    assert(config.axisDirection != null);
    switch (config.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        return true;
      case AxisDirection.down:
      case AxisDirection.right:
        return false;
    }
    return null;
  }

  void _handleDragDown(DragDownDetails details) {
    assert(_drag == null);
    position.touched();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_drag == null);
    _drag = position.beginDragActivity(details);
    assert(_drag != null);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // _drag might be null if the drag activity ended and called didEndDrag.
    _drag?.update(details, reverse: _reverseDirection);
  }

  void _handleDragEnd(DragEndDetails details) {
    // _drag might be null if the drag activity ended and called didEndDrag.
    _drag?.end(details, reverse: _reverseDirection);
    assert(_drag == null);
  }

  @override
  @protected
  void didEndDrag() {
    _drag = null;
  }


  // DESCRIPTION

  @override
  Widget build(BuildContext context) {
    assert(position != null);
    // TODO(ianh): Having all these global keys is sad.
    final Widget result = new RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: _gestureRecognizers,
      behavior: HitTestBehavior.opaque,
      child: new IgnorePointer(
        key: _ignorePointerKey,
        ignoring: _shouldIgnorePointer,
        child: config.viewportBuilder(context, position),
      ),
    );
    return _configuration.buildViewportChrome(context, result, config.axisDirection);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('position: $position');
  }
}
