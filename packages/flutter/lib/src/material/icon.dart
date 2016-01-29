// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';

enum IconSize {
  s18,
  s24,
  s36,
  s48,
}

const Map<IconSize, int> _kIconSize = const <IconSize, int>{
  IconSize.s18: 18,
  IconSize.s24: 24,
  IconSize.s36: 36,
  IconSize.s48: 48,
};

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size: IconSize.s24,
    this.icon: '',
    this.colorTheme,
    this.color
  }) : super(key: key) {
    assert(size != null);
    assert(icon != null);
  }

  final IconSize size;
  final String icon;
  final IconThemeColor colorTheme;
  final Color color;

  String _getColorSuffix(BuildContext context) {
    IconThemeColor iconThemeColor = colorTheme;
    if (iconThemeColor == null) {
      IconThemeData iconThemeData = IconTheme.of(context);
      iconThemeColor = iconThemeData == null ? null : iconThemeData.color;
    }
    if (iconThemeColor == null) {
      ThemeBrightness themeBrightness = Theme.of(context).brightness;
      iconThemeColor = themeBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }
    switch(iconThemeColor) {
      case IconThemeColor.white:
        return "white";
      case IconThemeColor.black:
        return "black";
    }
  }

  Widget build(BuildContext context) {
    String category = '';
    String subtype = '';
    List<String> parts = icon.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }
    String colorSuffix = _getColorSuffix(context);
    int iconSize = _kIconSize[size];
    return new AssetImage(
      name: '$category/ic_${subtype}_${colorSuffix}_${iconSize}dp.png',
      width: iconSize.toDouble(),
      height: iconSize.toDouble(),
      color: color
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    description.add('size: $size');
  }
}
