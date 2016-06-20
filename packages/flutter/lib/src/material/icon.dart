// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'theme.dart';

/// A material design icon.
///
/// Available icons are shown on this page:
/// <https://design.google.com/icons/>
///
/// Icons are identified by their name (as given on that page), with
/// spaces converted to underscores, from the [Icons] class. For
/// example, the "alarm add" icon is [Icons.alarm_add].
///
/// To use this class, make sure you set `uses-material-design: true`
/// in your project's `flutter.yaml` file. This ensures that the
/// MaterialIcons font is included in your application. This font is
/// used to display the icons.
///
/// See also:
///
///  * [IconButton], for interactive icons.
///  * [Icons], for the list of available icons for use with this class.
///  * [IconTheme], which provides ambient configuration for icons.
class Icon extends StatelessWidget {
  /// Creates an icon.
  ///
  /// The [size] and [color] default to the value given by the current [IconTheme].
  const Icon({
    Key key,
    this.icon,
    this.size,
    this.color
  }) : super(key: key);

  /// The icon to display. The available icons are described in [Icons].
  ///
  /// If null, no icon is shown.
  final IconData icon;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  final double size;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the current [IconTheme] color, if any. If there is
  /// no [IconTheme], then it defaults to white if the theme is dark
  /// and black if the theme is light. See [Theme] to set the current
  /// theme and [ThemeData.brightness] for setting the current theme's
  /// brightness.
  ///
  /// The given color will be adjusted by the opacity of the current
  /// [IconTheme], if any.
  final Color color;

  Color _getDefaultColorForBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
    assert(brightness != null);
    return null;
  }

  Color _getDefaultColor(BuildContext context) {
    return IconTheme.of(context)?.color ?? _getDefaultColorForBrightness(Theme.of(context).brightness);
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = size ?? IconTheme.of(context)?.size ?? 24.0;

    if (icon == null)
      return new SizedBox(width: iconSize, height: iconSize);

    final double iconOpacity = IconTheme.of(context)?.opacity ?? 1.0;
    Color iconColor = color ?? _getDefaultColor(context);
    if (iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);

    return new ExcludeSemantics(
      child: new SizedBox(
        width: iconSize,
        height: iconSize,
        child: new Center(
          child: new Text(
            new String.fromCharCode(icon.codePoint),
            style: new TextStyle(
              inherit: false,
              color: iconColor,
              fontSize: iconSize,
              fontFamily: 'MaterialIcons'
            )
          )
        )
      )
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (icon != null) {
      description.add('$icon');
    } else {
      description.add('<empty>');
    }
    if (size != null)
      description.add('size: $size');
    if (color != null)
      description.add('color: $color');
  }
}
