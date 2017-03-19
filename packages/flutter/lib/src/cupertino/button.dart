// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const TextStyle _kButtonTextStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 15.0,
  fontWeight: FontWeight.normal,
  color: CupertinoButton.kBlue,
  textBaseline: TextBaseline.alphabetic,
);

final TextStyle _kDisabledButtonTextStyle = _kButtonTextStyle.copyWith(
  color: CupertinoButton.kDisabledForeground,
);

final TextStyle _kBackgroundButtonTextStyle = _kButtonTextStyle.copyWith(
  color: CupertinoButton.kWhite,
);

const EdgeInsets _kButtonPadding = const EdgeInsets.all(16.0);
const EdgeInsets _kBackgroundButtonPadding =
    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 64.0);

/// An iOS style button.
///
/// Takes in a text or an icon that fades out and in on touch. May optionally have a
/// background.
///
/// See also:
///
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-controls/buttons/>
class CupertinoButton extends StatefulWidget {
  // TODO(xster): move this to a common Cupertino color palatte with the next yak.
  static const Color kBlue = const Color(0xFF007AFF);
  static const Color kWhite = const Color(0xFFFFFFFF);
  static const Color kDisabledBackground = const Color(0xFFA9A9A9);
  static const Color kDisabledForeground = const Color(0xFFC4C4C4);


  CupertinoButton({
    @required this.child,
    this.padding,
    this.color,
    this.minSize: 44.0,
    @required this.onPressed,
  });

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// The amount of space to surround the child inside the bounds of the button.
  ///
  /// Defaults to 16.0 pixels.
  final EdgeInsets padding;

  /// The color of the button's background.
  ///
  /// Defaults to null which produces a button with no background or border.
  final Color color;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Minimum size of the button.
  ///
  /// Defaults to 44.0 which the iOS Human Interface Guideline recommends as the
  /// minimum tappable area
  ///
  /// See also:
  ///
  /// * <https://developer.apple.com/ios/human-interface-guidelines/visual-design/layout/>
  final double minSize;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  _CupertinoButtonState createState() => new _CupertinoButtonState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (!enabled)
      description.add('disabled');
  }
}

class _CupertinoButtonState extends State<CupertinoButton> with SingleTickerProviderStateMixin {
  // Eyeballed values. Feel free to tweak.
  static const Duration kFadeOutDuration = const Duration(milliseconds: 10);
  static const Duration kFadeInDuration = const Duration(milliseconds: 350);

  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController = null;
    super.dispose();
  }

  void _handleTapDown(PointerDownEvent event) {
    _animationController.animateTo(0.1, duration: kFadeOutDuration);
  }

  void _handleTapUp(PointerUpEvent event) {
    _animationController.animateTo(1.0, duration: kFadeInDuration);
  }

  void _handleTapCancel(PointerCancelEvent event) {
    _animationController.animateTo(1.0, duration: kFadeInDuration);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = config.enabled;
    final Color backgroundColor = config.color;

    return new Listener(
      onPointerDown: enabled ? _handleTapDown : null,
      onPointerUp: enabled ? _handleTapUp : null,
      onPointerCancel: enabled ? _handleTapCancel : null,
      child: new GestureDetector(
        onTap: config.onPressed,
        child: new ConstrainedBox(
          constraints: new BoxConstraints(
            minWidth: config.minSize,
            minHeight: config.minSize,
          ),
          child: new FadeTransition(
            opacity: new CurvedAnimation(
              parent: _animationController,
              curve: Curves.decelerate,
            ),
            child: new DecoratedBox(
              decoration: new BoxDecoration(
                borderRadius: const BorderRadius.all(const Radius.circular(8.0)),
                backgroundColor: backgroundColor != null && !enabled
                    ? CupertinoButton.kDisabledBackground
                    : backgroundColor,
              ),
              child: new Padding(
                padding: config.padding != null
                    ? config.padding
                    : backgroundColor != null
                        ? _kBackgroundButtonPadding
                        : _kButtonPadding,
                child: new Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: new DefaultTextStyle(
                    style: backgroundColor != null
                        ? _kBackgroundButtonTextStyle
                        : enabled
                            ? _kButtonTextStyle
                            : _kDisabledButtonTextStyle,
                    child: config.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
