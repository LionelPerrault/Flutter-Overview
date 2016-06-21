// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'raised_button.dart';

/// A horizontal arrangement of buttons.
///
/// Places the buttons horizontally according to the padding in the current
/// [ButtonTheme].
///
/// Used by [Dialog] to arrange the actions at the bottom of the dialog.
///
/// See also:
///
///  * [RaisedButton]
///  * [FlatButton]
///  * [Dialog]
///  * [ButtonTheme]
class ButtonBar extends StatelessWidget {
  /// Creates a button bar.
  ///
  /// The alignment argument defaults to [MainAxisAlignment.end].
  ButtonBar({
    Key key,
    this.alignment: MainAxisAlignment.end,
    this.mainAxisSize: MainAxisSize.max,
    this.children
  }) : super(key: key);

  /// How the children should be placed along the horizontal axis.
  final MainAxisAlignment alignment;

  /// How much horizontal space is available. See [Row.mainAxisSize].
  final MainAxisSize mainAxisSize;

  /// The buttons to arrange horizontally.
  ///
  /// Typically [RaisedButton] or [FlatButton] widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // We divide by 4.0 because we want half of the average of the left and right padding.
    final double paddingUnit = ButtonTheme.of(context).padding.horizontal / 4.0;
    return new Padding(
      padding: new EdgeInsets.symmetric(
        vertical: 2.0 * paddingUnit,
        horizontal: paddingUnit
      ),
      child: new Row(
        mainAxisAlignment: alignment,
        mainAxisSize: mainAxisSize,
        children: children.map/*<Widget>*/((Widget child) {
          return new Padding(
            padding: new EdgeInsets.symmetric(horizontal: paddingUnit),
            child: child
          );
        }).toList()
      )
    );
  }
}
