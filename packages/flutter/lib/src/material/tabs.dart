// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'tab_controller.dart';
import 'theme.dart';

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeInsets _kTabLabelPadding = const EdgeInsets.symmetric(horizontal: 12.0);

/// A material design [TabBar] tab. If both [icon] and [text] are
/// provided, the text is displayed below the icon.
///
/// See also:
///
///  * [TabBar], which displays a row of tabs.
///  * [TabBarView], which displays a widget for the currently selected tab.
///  * [TabController], which coordinates tab selection between a [TabBar] and a [TabBarView].
///  * <https://material.google.com/components/tabs.html>
class Tab extends StatelessWidget {
  /// Creates a material design [TabBar] tab. At least one of [text] and [icon]
  /// must be non-null.
  Tab({
    Key key,
    this.text,
    this.icon,
  }) : super(key: key) {
    assert(text != null || icon != null);
  }

  /// The text to display as the tab's label.
  final String text;

  /// An icon to display as the tab's label.
  final Widget icon;

  Widget _buildLabelText() {
    return new Text(text, softWrap: false, overflow: TextOverflow.fade);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    double height;
    Widget label;
    if (icon == null) {
      height = _kTabHeight;
      label = _buildLabelText();
    } else if (text == null) {
      height = _kTabHeight;
      label = icon;
    } else {
      height = _kTextAndIconTabHeight;
      label = new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Container(
            child: icon,
            margin: const EdgeInsets.only(bottom: 10.0)
          ),
          _buildLabelText()
        ]
      );
    }

    return new Container(
      padding: _kTabLabelPadding,
      height: height,
      constraints: const BoxConstraints(minWidth: _kMinTabWidth),
      child: new Center(child: label),
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (text != null)
      description.add('text: $text');
    if (icon != null)
      description.add('icon: $icon');
  }
}

class _TabStyle extends AnimatedWidget {
  _TabStyle({
    Key key,
    Animation<double> animation,
    this.selected,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    @required this.child,
  }) : super(key: key, listenable: animation);

  final TextStyle labelStyle;
  final TextStyle unselectedLabelStyle;
  final bool selected;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle defaultStyle = labelStyle ?? themeData.primaryTextTheme.body2;
    final TextStyle defaultUnselectedStyle = unselectedLabelStyle ?? labelStyle ?? themeData.primaryTextTheme.body2;
    final TextStyle textStyle = selected
      ? defaultStyle
      : defaultUnselectedStyle;
    final Color selectedColor = labelColor ?? themeData.primaryTextTheme.body2.color;
    final Color unselectedColor = unselectedLabelColor ?? selectedColor.withAlpha(0xB2); // 70% alpha
    final Animation<double> animation = listenable;
    final Color color = selected
      ? Color.lerp(selectedColor, unselectedColor, animation.value)
      : Color.lerp(unselectedColor, selectedColor, animation.value);

    return new DefaultTextStyle(
      style: textStyle.copyWith(color: color),
      child: new IconTheme.merge(
        context: context,
        data: new IconThemeData(
          size: 24.0,
          color: color,
        ),
        child: child,
      ),
    );
  }
}

class _TabLabelBarRenderer extends RenderFlex {
  _TabLabelBarRenderer({
    List<RenderBox> children,
    Axis direction,
    MainAxisSize mainAxisSize,
    MainAxisAlignment mainAxisAlignment,
    CrossAxisAlignment crossAxisAlignment,
    TextBaseline textBaseline,
    @required this.onPerformLayout,
  }) : super(
    children: children,
    direction: direction,
    mainAxisSize: mainAxisSize,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textBaseline: textBaseline,
  ) {
    assert(onPerformLayout != null);
  }

  ValueChanged<List<double>> onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    RenderBox child = firstChild;
    final List<double> xOffsets = <double>[];
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      xOffsets.add(childParentData.offset.dx);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    xOffsets.add(size.width); // So xOffsets[lastTabIndex + 1] is valid.
    onPerformLayout(xOffsets);
  }
}

// This class and its renderer class only exist to report the widths of the tabs
// upon layout. The tab widths are only used at paint time (see _IndicatorPainter)
// or in response to input.
class _TabLabelBar extends Flex {
  _TabLabelBar({
    Key key,
    MainAxisAlignment mainAxisAlignment,
    CrossAxisAlignment crossAxisAlignment,
    List<Widget> children: const <Widget>[],
    this.onPerformLayout,
  }) : super(
    key: key,
    children: children,
    direction: Axis.horizontal,
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
  );

  final ValueChanged<List<double>> onPerformLayout;

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return new _TabLabelBarRenderer(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      onPerformLayout: onPerformLayout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _TabLabelBarRenderer renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.onPerformLayout = onPerformLayout;
  }
}

double _indexChangeProgress(TabController controller) {
  final double controllerValue = controller.animation.value;
  final double previousIndex = controller.previousIndex.toDouble();
  final double currentIndex = controller.index.toDouble();

  // The controller's offset is changing because the user is dragging the
  // TabBarView's PageView to the left or right.
  if (!controller.indexIsChanging)
    return (currentIndex -  controllerValue).abs().clamp(0.0, 1.0);

  // The TabController animation's value is changing from previousIndex to currentIndex.
  return (controllerValue - currentIndex).abs() / (currentIndex - previousIndex).abs();
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter(this.controller) : super(repaint: controller.animation);

  TabController controller;
  List<double> tabOffsets;
  Color color;
  Rect currentRect;

  // tabOffsets[index] is the offset of the left edge of the tab at index, and
  // tabOffsets[tabOffsets.length] is the right edge of the last tab.
  int get maxTabIndex => tabOffsets.length - 2;

  Rect indicatorRect(Size tabBarSize, int tabIndex) {
    assert(tabOffsets != null && tabIndex >= 0 && tabIndex <= maxTabIndex);
    final double tabLeft = tabOffsets[tabIndex];
    final double tabRight = tabOffsets[tabIndex + 1];
    final double tabTop = tabBarSize.height - _kTabIndicatorHeight;
    return new Rect.fromLTWH(tabLeft, tabTop, tabRight - tabLeft, _kTabIndicatorHeight);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.indexIsChanging) {
      final Rect targetRect = indicatorRect(size, controller.index);
      currentRect = Rect.lerp(targetRect, currentRect ?? targetRect, _indexChangeProgress(controller));
    } else {
      final int currentIndex = controller.index;
      final Rect left = currentIndex > 0 ? indicatorRect(size, currentIndex - 1) : null;
      final Rect middle = indicatorRect(size, currentIndex);
      final Rect right = currentIndex < maxTabIndex ? indicatorRect(size, currentIndex + 1) : null;

      final double index = controller.index.toDouble();
      final double value = controller.animation.value;
      if (value == index - 1.0)
        currentRect = left ?? middle;
      else if (value == index + 1.0)
        currentRect = right ?? middle;
      else if (value == index)
         currentRect = middle;
      else if (value < index)
        currentRect = left == null ? middle : Rect.lerp(middle, left, index - value);
      else
        currentRect = right == null ? middle : Rect.lerp(middle, right, value - index);
    }
    assert(currentRect != null);
    canvas.drawRect(currentRect, new Paint()..color = color);
  }

  static bool tabOffsetsNotEqual(List<double> a, List<double> b) {
    assert(a != null && b != null && a.length == b.length);
    for(int i = 0; i < a.length; i++) {
      if (a[i] != b[i])
        return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) {
    return controller != old.controller ||
      tabOffsets?.length != old.tabOffsets?.length ||
      tabOffsetsNotEqual(tabOffsets, old.tabOffsets) ||
      currentRect != old.currentRect;
  }
}

class _ChangeAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _ChangeAnimation(this.controller);

  final TabController controller;

  @override
  Animation<double> get parent => controller.animation;

  @override
  double get value => _indexChangeProgress(controller);
}

class _DragAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _DragAnimation(this.controller, this.index);

  final TabController controller;
  final int index;

  @override
  Animation<double> get parent => controller.animation;

  @override
  double get value {
    assert(!controller.indexIsChanging);
    return (controller.animation.value - index.toDouble()).abs().clamp(0.0, 1.0);
  }
}

/// A material design widget that displays a horizontal row of tabs.
///
/// Typically created as part of an [AppBar] and in conjuction with a
/// [TabBarView].
///
/// If a [TabController] is not provided, then there must be a
/// [DefaultTabController] ancestor.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [TabBarView], which displays the contents that the tab bar is selecting
///    between.
class TabBar extends StatefulWidget implements AppBarBottomWidget {
  /// Creates a material design tab bar.
  ///
  /// The [tabs] argument must not be null and must have more than one widget.
  ///
  /// If a [TabController] is not provided, then there must be a
  /// [DefaultTabController] ancestor.
  TabBar({
    Key key,
    @required this.tabs,
    this.controller,
    this.isScrollable: false,
    this.indicatorColor,
    this.labelColor,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
  }) : super(key: key) {
    assert(tabs != null && tabs.length > 1);
    assert(isScrollable != null);
  }

  /// Typically a list of [Tab] widgets.
  final List<Widget> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If [isScrollable] is true then each tab is as wide as needed for its label
  /// and the entire [TabBar] is scrollable. Otherwise each tab gets an equal
  /// share of the available space.
  final bool isScrollable;

  /// The color of the line that appears below the selected tab. If this parameter
  /// is null then the value of the Theme's indicatorColor property is used.
  final Color indicatorColor;

  /// The color of selected tab labels.
  ///
  /// Unselected tab labels are rendered with the same color rendered at 70%
  /// opacity unless [unselectedLabelColor] is non-null.
  ///
  /// If this parameter is null then the color of the theme's body2 text color
  /// is used.
  final Color labelColor;

  /// The color of unselected tab labels.
  ///
  /// If this property is null, Unselected tab labels are rendered with the
  /// [labelColor] rendered at 70% opacity.
  final Color unselectedLabelColor;

  /// The text style of the selected tab labels. If [unselectedLabelStyle] is
  /// null then this text style will be used for both selected and unselected
  /// label styles.
  ///
  /// If this property is null then the text style of the theme's body2
  /// definition is used.
  final TextStyle labelStyle;

  /// The text style of the unselected tab labels
  ///
  /// If this property is null then the [labelStyle] value is used. If [labelStyle]
  /// is null then the text style of the theme's body2 definition is used.
  final TextStyle unselectedLabelStyle;

  @override
  double get bottomHeight {
    for (Widget item in tabs) {
      if (item is Tab) {
        final Tab tab = item;
        if (tab.text != null && tab.icon != null)
          return _kTextAndIconTabHeight + _kTabIndicatorHeight;
      }
    }
    return _kTabHeight + _kTabIndicatorHeight;
  }

  @override
  _TabBarState createState() => new _TabBarState();
}

class _TabBarState extends State<TabBar> {
  final ScrollController _scrollController = new ScrollController();

  TabController _controller;
  _IndicatorPainter _indicatorPainter;
  int _currentIndex;

  void _updateTabController() {
    final TabController newController = widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw new FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    });
    if (newController == _controller)
      return;

    if (_controller != null) {
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
      _controller.removeListener(_handleTabControllerTick);
    }
    _controller = newController;
    if (_controller != null) {
      _controller.animation.addListener(_handleTabControllerAnimationTick);
      _controller.addListener(_handleTabControllerTick);
      _currentIndex = _controller.index;
      final List<double> offsets = _indicatorPainter?.tabOffsets;
      _indicatorPainter = new _IndicatorPainter(_controller)..tabOffsets = offsets;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
  }

  @override
  void didUpdateWidget(TabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller)
      _updateTabController();
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
      _controller.removeListener(_handleTabControllerTick);
    }
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  // tabOffsets[index] is the offset of the left edge of the tab at index, and
  // tabOffsets[tabOffsets.length] is the right edge of the last tab.
  int get maxTabIndex => _indicatorPainter.tabOffsets.length - 2;

  double _tabCenteredScrollOffset(int tabIndex) {
    final List<double> tabOffsets = _indicatorPainter.tabOffsets;
    assert(tabOffsets != null && tabIndex >= 0 && tabIndex <= maxTabIndex);

    final ScrollPosition position = _scrollController.position;
    final double tabCenter = (tabOffsets[tabIndex] + tabOffsets[tabIndex + 1]) / 2.0;
    return (tabCenter - position.viewportDimension / 2.0)
      .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  void _scrollToCurrentIndex() {
    final double offset = _tabCenteredScrollOffset(_currentIndex);
    _scrollController.animateTo(offset, duration: kTabScrollDuration, curve: Curves.ease);
  }

  void _scrollToControllerValue() {
    final double left = _currentIndex > 0 ? _tabCenteredScrollOffset(_currentIndex - 1) : null;
    final double middle = _tabCenteredScrollOffset(_currentIndex);
    final double right = _currentIndex < maxTabIndex ? _tabCenteredScrollOffset(_currentIndex + 1) : null;

    final double index = _controller.index.toDouble();
    final double value = _controller.animation.value;
    double offset;
    if (value == index - 1.0)
      offset = left ?? middle;
    else if (value == index + 1.0)
      offset = right ?? middle;
    else if (value == index)
       offset = middle;
    else if (value < index)
      offset = left == null ? middle : lerpDouble(middle, left, index - value);
    else
      offset = right == null ? middle : lerpDouble(middle, right, value - index);

    _scrollController.jumpTo(offset);
  }

  void _handleTabControllerAnimationTick() {
    assert(mounted);
    if (!_controller.indexIsChanging && widget.isScrollable) {
      // Sync the TabBar's scroll position with the TabBarView's PageView.
      _currentIndex = _controller.index;
      _scrollToControllerValue();
    }
  }

  void _handleTabControllerTick() {
    setState(() {
      // Rebuild the tabs after a (potentially animated) index change
      // has completed.
    });
  }

  void _saveTabOffsets(List<double> tabOffsets) {
    _indicatorPainter?.tabOffsets = tabOffsets;
  }

  void _handleTap(int index) {
    assert(index >= 0 && index < widget.tabs.length);
    _controller.animateTo(index);
  }

  Widget _buildStyledTab(Widget child, bool selected, Animation<double> animation) {
    return new _TabStyle(
      animation: animation,
      selected: selected,
      labelColor: widget.labelColor,
      unselectedLabelColor: widget.unselectedLabelColor,
      labelStyle: widget.labelStyle,
      unselectedLabelStyle: widget.unselectedLabelStyle,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> wrappedTabs = new List<Widget>.from(widget.tabs, growable: false);

    // If the controller was provided by DefaultTabController and we're part
    // of a Hero (typically the AppBar), then we will not be able to find the
    // controller during a Hero transition. See https://github.com/flutter/flutter/issues/213.
    if (_controller != null) {
      _indicatorPainter.color = widget.indicatorColor ?? Theme.of(context).indicatorColor;
      if (_indicatorPainter.color == Material.of(context).color) {
        // ThemeData tries to avoid this by having indicatorColor avoid being the
        // primaryColor. However, it's possible that the tab bar is on a
        // Material that isn't the primaryColor. In that case, if the indicator
        // color ends up clashing, then this overrides it. When that happens,
        // automatic transitions of the theme will likely look ugly as the
        // indicator color suddenly snaps to white at one end, but it's not clear
        // how to avoid that any further.
        _indicatorPainter.color = Colors.white;
      }

      if (_controller.index != _currentIndex) {
        _currentIndex = _controller.index;
        if (widget.isScrollable)
          _scrollToCurrentIndex();
      }

      final int previousIndex = _controller.previousIndex;

      if (_controller.indexIsChanging) {
        // The user tapped on a tab, the tab controller's animation is running.
        assert(_currentIndex != previousIndex);
        final Animation<double> animation = new _ChangeAnimation(_controller);
        wrappedTabs[_currentIndex] = _buildStyledTab(wrappedTabs[_currentIndex], true, animation);
        wrappedTabs[previousIndex] = _buildStyledTab(wrappedTabs[previousIndex], false, animation);
      } else {
        // The user is dragging the TabBarView's PageView left or right.
        final int tabIndex = _currentIndex;
        final Animation<double> centerAnimation = new _DragAnimation(_controller, tabIndex);
        wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], true, centerAnimation);
        if (_currentIndex > 0) {
          final int tabIndex = _currentIndex - 1;
          final Animation<double> leftAnimation = new _DragAnimation(_controller, tabIndex);
          wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], true, leftAnimation);
        }
        if (_currentIndex < widget.tabs.length - 1) {
          final int tabIndex = _currentIndex + 1;
          final Animation<double> rightAnimation = new _DragAnimation(_controller, tabIndex);
          wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], true, rightAnimation);
        }
      }
    }

    // Add the tap handler to each tab. If the tab bar is scrollable
    // then give all of the tabs equal flexibility so that their widths
    // reflect the intrinsic width of their labels.
    for (int index = 0; index < widget.tabs.length; index++) {
      wrappedTabs[index] = new InkWell(
        onTap: () { _handleTap(index); },
        child: wrappedTabs[index],
      );
      if (!widget.isScrollable)
        wrappedTabs[index] = new Expanded(child: wrappedTabs[index]);
    }

    Widget tabBar = new CustomPaint(
      painter: _indicatorPainter,
      child: new Padding(
        padding: const EdgeInsets.only(bottom: _kTabIndicatorHeight),
        child: new _TabStyle(
          animation: kAlwaysDismissedAnimation,
          selected: false,
          labelColor: widget.labelColor,
          unselectedLabelColor: widget.unselectedLabelColor,
          labelStyle: widget.labelStyle,
          unselectedLabelStyle: widget.unselectedLabelStyle,
          child: new _TabLabelBar(
            onPerformLayout: _saveTabOffsets,
            children:  wrappedTabs,
          ),
        ),
      ),
    );

    if (widget.isScrollable) {
      tabBar = new SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: tabBar,
      );
    }

    return tabBar;
  }
}

/// A page view that displays the widget which corresponds to the currently
/// selected tab. Typically used in conjuction with a [TabBar].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
class TabBarView extends StatefulWidget {
  /// Creates a page view with one child per tab.
  ///
  /// The length of [children] must be the same as the [controller]'s length.
  TabBarView({
    Key key,
    @required this.children,
    this.controller,
  }) : super(key: key) {
    assert(children != null && children.length > 1);
  }

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// One widget per tab.
  final List<Widget> children;

  @override
  _TabBarViewState createState() => new _TabBarViewState();
}

final PageScrollPhysics _kTabBarViewPhysics = const PageScrollPhysics().applyTo(const ClampingScrollPhysics());

class _TabBarViewState extends State<TabBarView> {
  TabController _controller;
  PageController _pageController;
  List<Widget> _children;
  int _currentIndex;
  int _warpUnderwayCount = 0;

  void _updateTabController() {
    final TabController newController = widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw new FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    });
    if (newController == _controller)
      return;

    if (_controller != null)
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
    _controller = newController;
    if (_controller != null)
      _controller.animation.addListener(_handleTabControllerAnimationTick);
  }

  @override
  void initState() {
    super.initState();
    _children = widget.children;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
    _currentIndex = _controller?.index;
    _pageController = new PageController(initialPage: _currentIndex ?? 0);
  }

  @override
  void didUpdateWidget(TabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller)
      _updateTabController();
    if (widget.children != oldWidget.children && _warpUnderwayCount == 0)
      _children = widget.children;
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  void _handleTabControllerAnimationTick() {
    if (_warpUnderwayCount > 0 || !_controller.indexIsChanging)
      return; // This widget is driving the controller's animation.

    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      _warpToCurrentIndex();
    }
  }

  Future<Null> _warpToCurrentIndex() async {
    if (!mounted)
      return new Future<Null>.value();

    if (_pageController.page == _currentIndex.toDouble())
      return new Future<Null>.value();

    final int previousIndex = _controller.previousIndex;
    if ((_currentIndex - previousIndex).abs() == 1)
      return _pageController.animateToPage(_currentIndex, duration: kTabScrollDuration, curve: Curves.ease);

    assert((_currentIndex - previousIndex).abs() > 1);
    int initialPage;
    setState(() {
      _warpUnderwayCount += 1;
      _children = new List<Widget>.from(widget.children, growable: false);
      if (_currentIndex > previousIndex) {
        _children[_currentIndex - 1] = _children[previousIndex];
        initialPage = _currentIndex - 1;
      } else {
        _children[_currentIndex + 1] = _children[previousIndex];
        initialPage = _currentIndex + 1;
      }
    });

    _pageController.jumpToPage(initialPage);

    await _pageController.animateToPage(_currentIndex, duration: kTabScrollDuration, curve: Curves.ease);
    if (!mounted)
      return new Future<Null>.value();

    setState(() {
      _warpUnderwayCount -= 1;
      _children = widget.children;
    });
  }

  // Called when the PageView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0)
      return false;

    if (notification.depth != 0)
      return false;

    _warpUnderwayCount += 1;
    if (notification is ScrollUpdateNotification && !_controller.indexIsChanging) {
      if ((_pageController.page - _controller.index).abs() > 1.0) {
        _controller.index = _pageController.page.floor();
        _currentIndex=_controller.index;
      }
      _controller.offset = (_pageController.page - _controller.index).clamp(-1.0, 1.0);
    } else if (notification is ScrollEndNotification) {
      _controller.index = _pageController.page.floor();
      _currentIndex = _controller.index;
    }
    _warpUnderwayCount -= 1;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new PageView(
        controller: _pageController,
        physics: _kTabBarViewPhysics,
        children: _children,
      ),
    );
  }
}

/// Displays a row of small circular indicators, one per tab. The selected
/// tab's indicator is highlighted. Often used in conjuction with a [TabBarView].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
class TabPageSelector extends StatelessWidget {
  /// Creates a compact widget that indicates which tab has been selected.
  TabPageSelector({ Key key, this.controller }) : super(key: key);

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  Widget _buildTabIndicator(
    int tabIndex,
    TabController tabController,
    ColorTween selectedColor,
    ColorTween previousColor,
  ) {
    Color background;
    if (tabController.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      if (tabController.index == tabIndex)
        background = selectedColor.lerp(_indexChangeProgress(tabController));
      else if (tabController.previousIndex == tabIndex)
        background = previousColor.lerp(_indexChangeProgress(tabController));
      else
        background = selectedColor.begin;
    } else {
      background = tabController.index == tabIndex ? selectedColor.end : selectedColor.begin;
    }
    return new Container(
      width: 12.0,
      height: 12.0,
      margin: const EdgeInsets.all(4.0),
      decoration: new BoxDecoration(
        backgroundColor: background,
        border: new Border.all(color: selectedColor.end),
        shape: BoxShape.circle
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).accentColor;
    final ColorTween selectedColor = new ColorTween(begin: Colors.transparent, end: color);
    final ColorTween previousColor = new ColorTween(begin: color, end: Colors.transparent);
    final TabController tabController = controller ?? DefaultTabController.of(context);
    assert(() {
      if (tabController == null) {
        throw new FlutterError(
          'No TabController for $runtimeType.\n'
          'When creating a $runtimeType, you must either provide an explicit TabController '
          'using the "controller" property, or you must ensure that there is a '
          'DefaultTabController above the $runtimeType.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    });
    final Animation<double> animation = new CurvedAnimation(
      parent: tabController.animation,
      curve: Curves.fastOutSlowIn,
    );
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return new Semantics(
          label: 'Page ${tabController.index + 1} of ${tabController.length}',
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: new List<Widget>.generate(tabController.length, (int tabIndex) {
              return _buildTabIndicator(tabIndex, tabController, selectedColor, previousColor);
            }).toList(),
          ),
        );
      }
    );
  }
}
