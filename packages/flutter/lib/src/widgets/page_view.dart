// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_controller.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

/// A controller for [PageView].
///
/// A page controller lets you manipulate which page is visible in a [PageView].
///
/// See also:
///
///  - [PageView], which is the widget this object controls.
class PageController extends ScrollController {
  /// Creates a page controller.
  ///
  /// The [initialPage] and [viewportFraction] arguments must not be null.
  PageController({
    this.initialPage: 0,
    this.viewportFraction: 1.0,
  }) {
    assert(initialPage != null);
    assert(viewportFraction != null);
    assert(viewportFraction > 0.0);
  }

  /// The page to show when first creating the [PageView].
  final int initialPage;

  /// The fraction of the viewport that each page should occupy.
  ///
  /// Defaults to 1.0, which means each page fills the viewport in the scrolling
  /// direction.
  final double viewportFraction;

  /// The current page displayed in the controlled [PageView].
  double get page {
    final _PagePosition position = this.position;
    return position.page;
  }

  /// Animates the controlled [PageView] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<Null> animateToPage(int page, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final _PagePosition position = this.position;
    return position.animateTo(position.getPixelsFromPage(page.toDouble()), duration: duration, curve: curve);
  }

  /// Changes which page is displayed in the controlled [PageView].
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  void jumpToPage(int page) {
    final _PagePosition position = this.position;
    position.jumpTo(position.getPixelsFromPage(page.toDouble()));
  }

  /// Animates the controlled [PageView] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  void nextPage({ @required Duration duration, @required Curve curve }) {
    animateToPage(page.round() + 1, duration: duration, curve: curve);
  }

  /// Animates the controlled [PageView] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  void previousPage({ @required Duration duration, @required Curve curve }) {
    animateToPage(page.round() - 1, duration: duration, curve: curve);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, AbstractScrollState state, ScrollPosition oldPosition) {
    return new _PagePosition(
      physics: physics,
      state: state,
      initialPage: initialPage,
      viewportFraction: viewportFraction,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _PagePosition pagePosition = position;
    pagePosition.viewportFraction = viewportFraction;
  }
}

/// Metrics for a [PageView].
///
/// The metrics are available on [ScrollNotification]s generated from
/// [PageView]s.
class PageMetrics extends ScrollMetrics {
  /// Creates page metrics that add the given information to the `parent`
  /// metrics.
  PageMetrics({
    ScrollMetrics parent,
    this.page,
  }) : super.clone(parent);

  /// The current page displayed in the [PageView].
  final double page;
}

class _PagePosition extends ScrollPosition {
  _PagePosition({
    ScrollPhysics physics,
    AbstractScrollState state,
    this.initialPage: 0,
    double viewportFraction: 1.0,
    ScrollPosition oldPosition,
  }) : _viewportFraction = viewportFraction, super(
    physics: physics,
    state: state,
    initialPixels: null,
    oldPosition: oldPosition,
  ) {
    assert(initialPage != null);
    assert(viewportFraction != null);
    assert(viewportFraction > 0.0);
  }

  final int initialPage;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double newValue) {
    if (_viewportFraction == newValue)
      return;
    final double oldPage = page;
    _viewportFraction = newValue;
    if (oldPage != null)
      correctPixels(getPixelsFromPage(oldPage));
  }

  double getPageFromPixels(double pixels, double viewportDimension) {
    return math.max(0.0, pixels) / math.max(1.0, viewportDimension * viewportFraction);
  }

  double getPixelsFromPage(double page) {
    return page * viewportDimension * viewportFraction;
  }

  double get page => pixels == null ? null : getPageFromPixels(pixels.clamp(minScrollExtent, maxScrollExtent), viewportDimension);

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double oldViewportDimensions = this.viewportDimension;
    final bool result = super.applyViewportDimension(viewportDimension);
    final double oldPixels = pixels;
    final double page = (oldPixels == null || oldViewportDimensions == 0.0) ? initialPage.toDouble() : getPageFromPixels(oldPixels, oldViewportDimensions);
    final double newPixels = getPixelsFromPage(page);
    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  PageMetrics getMetrics() {
    return new PageMetrics(
      parent: super.getMetrics(),
      page: page,
    );
  }
}

/// Scroll physics used by a [PageView].
///
/// These physics cause the page view to snap to page boundaries.
class PageScrollPhysics extends ScrollPhysics {
  /// Creates physics for a [PageView].
  const PageScrollPhysics({ ScrollPhysics parent }) : super(parent);

  @override
  PageScrollPhysics applyTo(ScrollPhysics parent) => new PageScrollPhysics(parent: parent);

  double _getPage(ScrollPosition position) {
    if (position is _PagePosition)
      return position.page;
    return position.pixels / position.viewportDimension;
  }

  double _getPixels(ScrollPosition position, double page) {
    if (position is _PagePosition)
      return position.getPixelsFromPage(page);
    return page * position.viewportDimension;
  }

  double _getTargetPixels(ScrollPosition position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity)
      page -= 0.5;
    else if (velocity > tolerance.velocity)
      page += 0.5;
    return _getPixels(position, page.roundToDouble());
  }

  @override
  Simulation createBallisticSimulation(ScrollPosition position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    return new ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }
}

// Having this global (mutable) page controller is a bit of a hack. We need it
// to plumb in the factory for _PagePosition, but it will end up accumulating
// a large list of scroll positions. As long as you don't try to actually
// control the scroll positions, everything should be fine.
final PageController _defaultPageController = new PageController();
const PageScrollPhysics _kPagePhysics = const PageScrollPhysics();

/// A scrollable list that works page by page.
// TODO(ianh): More documentation here.
///
/// See also:
///
/// * [SingleChildScrollView], when you need to make a single child scrollable.
/// * [ListView], for a scrollable list of boxes.
/// * [GridView], for a scrollable grid of boxes.
class PageView extends StatefulWidget {
  PageView({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics,
    this.onPageChanged,
    List<Widget> children: const <Widget>[],
  }) : controller = controller ?? _defaultPageController,
       childrenDelegate = new SliverChildListDelegate(children),
       super(key: key);

  PageView.builder({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics,
    this.onPageChanged,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : controller = controller ?? _defaultPageController,
       childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
       super(key: key);

  PageView.custom({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics,
    this.onPageChanged,
    @required this.childrenDelegate,
  }) : controller = controller ?? _defaultPageController, super(key: key) {
    assert(childrenDelegate != null);
  }

  final Axis scrollDirection;

  final bool reverse;

  final PageController controller;

  final ScrollPhysics physics;

  final ValueChanged<int> onPageChanged;

  final SliverChildDelegate childrenDelegate;

  @override
  _PageViewState createState() => new _PageViewState();
}

class _PageViewState extends State<PageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = config.controller.initialPage;
  }

  AxisDirection _getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (config.scrollDirection) {
      case Axis.horizontal:
        return config.reverse ? AxisDirection.left : AxisDirection.right;
      case Axis.vertical:
        return config.reverse ? AxisDirection.up : AxisDirection.down;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 && config.onPageChanged != null && notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics;
          final int currentPage = metrics.page.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            config.onPageChanged(currentPage);
          }
        }
        return false;
      },
      child: new Scrollable(
        axisDirection: axisDirection,
        controller: config.controller,
        physics: config.physics == null ? _kPagePhysics : _kPagePhysics.applyTo(config.physics),
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return new Viewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: <Widget>[
              new SliverFill(
                viewportFraction: config.controller.viewportFraction,
                delegate: config.childrenDelegate
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${config.scrollDirection}');
    if (config.reverse)
      description.add('reversed');
    description.add('${config.controller}');
    description.add('${config.physics}');
  }
}
