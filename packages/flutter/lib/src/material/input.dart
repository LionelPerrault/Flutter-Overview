// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'theme.dart';

export 'package:flutter/rendering.dart' show ValueChanged;
export 'package:flutter/services.dart' show KeyboardType;

/// A material design text input widget.
class Input extends Scrollable {
  Input({
    GlobalKey key,
    this.initialValue: '',
    this.placeholder,
    this.hideText: false,
    this.isDense: false,
    this.autofocus: false,
    this.onChanged,
    this.keyboardType: KeyboardType.text,
    this.onSubmitted
  }) : super(
    key: key,
    initialScrollOffset: 0.0,
    scrollDirection: Axis.horizontal
  ) {
    assert(key != null);
  }

  /// Initial editable text for the widget.
  final String initialValue;

  /// The type of keyboard to use for editing the text.
  final KeyboardType keyboardType;

  /// Hint text to show when the widget doesn't contain editable text.
  final String placeholder;

  /// Whether to hide the text being edited (e.g., for passwords).
  final bool hideText;

  /// Whether the input widget is part of a dense form (i.e., uses less vertical space).
  final bool isDense;

  /// Whether this input widget should focus itself is nothing else is already focused.
  final bool autofocus;

  /// Called when the text being edited changes.
  final ValueChanged<String> onChanged;

  /// Called when the user indicates that they are done editing the text in the widget.
  final ValueChanged<String> onSubmitted;

  InputState createState() => new InputState();
}

class InputState extends ScrollableState<Input> {
  String _value;
  EditableString _editableString;
  KeyboardHandle _keyboardHandle = KeyboardHandle.unattached;

  double _contentWidth = 0.0;
  double _containerWidth = 0.0;

  EditableString get editableValue => _editableString;

  void initState() {
    super.initState();
    _value = config.initialValue;
    _editableString = new EditableString(
      text: _value,
      onUpdated: _handleTextUpdated,
      onSubmitted: _handleTextSubmitted
    );
  }

  void _handleTextUpdated() {
    if (_value != _editableString.text) {
      setState(() {
        _value = _editableString.text;
      });
      if (config.onChanged != null)
        config.onChanged(_value);
    }
  }

  void _handleTextSubmitted() {
    if (config.onSubmitted != null)
      config.onSubmitted(_value);
  }

  Widget buildContent(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    ThemeData themeData = Theme.of(context);
    bool focused = Focus.at(context, autofocus: config.autofocus);

    if (focused && !_keyboardHandle.attached) {
      _keyboardHandle = keyboard.show(_editableString.stub, config.keyboardType);
      _keyboardHandle.setText(_editableString.text);
      _keyboardHandle.setSelection(_editableString.selection.start,
                                   _editableString.selection.end);
    } else if (!focused && _keyboardHandle.attached) {
      _keyboardHandle.release();
    }

    TextStyle textStyle = themeData.text.subhead;
    List<Widget> textChildren = <Widget>[];

    if (config.placeholder != null && _value.isEmpty) {
      Widget child = new Opacity(
        key: const ValueKey<String>('placeholder'),
        child: new Text(config.placeholder, style: textStyle),
        opacity: themeData.hintOpacity
      );
      textChildren.add(child);
    }

    Color focusHighlightColor = themeData.accentColor;
    Color cursorColor = themeData.accentColor;
    if (themeData.primarySwatch != null) {
      cursorColor = themeData.primarySwatch[200];
      focusHighlightColor = focused ? themeData.primarySwatch[400] : themeData.hintColor;
    }

    textChildren.add(new RawEditableLine(
      value: _editableString,
      focused: focused,
      style: textStyle,
      hideText: config.hideText,
      cursorColor: cursorColor,
      onContentSizeChanged: _handleContentSizeChanged,
      scrollOffset: scrollOffsetVector
    ));

    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (Focus.at(context)) {
          assert(_keyboardHandle.attached);
          _keyboardHandle.showByRequest();
        } else {
          Focus.moveTo(config.key);
          // we'll get told to rebuild and we'll take care of the keyboard then
        }
      },
      child: new SizeObserver(
        onSizeChanged: _handleContainerSizeChanged,
        child: new Container(
          child: new Stack(children: textChildren),
          margin: config.isDense ?
            const EdgeDims.symmetric(vertical: 4.0) :
            const EdgeDims.symmetric(vertical: 8.0),
          padding: const EdgeDims.symmetric(vertical: 8.0),
          decoration: new BoxDecoration(
            border: new Border(
              bottom: new BorderSide(
                color: focusHighlightColor,
                width: focused ? 2.0 : 1.0
              )
            )
          )
        )
      )
    );
  }

  void dispose() {
    if (_keyboardHandle.attached)
      _keyboardHandle.release();
    super.dispose();
  }

  ScrollBehavior createScrollBehavior() => new BoundedBehavior();
  BoundedBehavior get scrollBehavior => super.scrollBehavior;

  void _handleContainerSizeChanged(Size newSize) {
    _containerWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _handleContentSizeChanged(Size newSize) {
    _contentWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _updateScrollBehavior() {
    // Set the scroll offset to match the content width so that the cursor
    // (which is always at the end of the text) will be visible.
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: _contentWidth,
      containerExtent: _containerWidth,
      scrollOffset: _contentWidth
    ));
  }
}
