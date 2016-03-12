// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// Return true to cancel the notification bubbling.
typedef bool NotificationListenerCallback<T extends Notification>(T notification);

/// A notification that can bubble up the widget tree.
abstract class Notification {
  /// Start bubbling this notification at the given build context.
  void dispatch(BuildContext target) {
    target.visitAncestorElements((Element element) {
      if (element is StatelessElement &&
          element.widget is NotificationListener<dynamic>) {
        final NotificationListener<dynamic> widget = element.widget;
        if (widget._dispatch(this)) // that function checks the type dynamically
          return false;
      }
      return true;
    });
  }
}

/// Listens for [Notification]s bubbling up the tree.
class NotificationListener<T extends Notification> extends StatelessWidget {
  NotificationListener({
    Key key,
    this.child,
    this.onNotification
  }) : super(key: key);

  final Widget child;

  /// Called when a notification of the appropriate type arrives at this location in the tree.
  final NotificationListenerCallback<T> onNotification;

  bool _dispatch(Notification notification) {
    if (onNotification != null && notification is T)
      return onNotification(notification);
    return false;
  }

  Widget build(BuildContext context) => child;
}

/// Indicates that the layout of one of the descendants of the object receiving
/// this notification has changed in some way, and that therefore any
/// assumptions about that layout are no longer valid.
///
/// Useful if, for instance, you're trying to align multiple descendants.
///
/// Be aware that in the widgets library, only the [Scrollable] classes dispatch
/// this notification. (Transitions, in particular, do not.) Changing one's
/// layout in one's build function does not cause this notification to be
/// dispatched automatically. If an ancestor expects to be notified for any
/// layout change, make sure you only use widgets that either never change
/// layout, or that do notify their ancestors when appropriate.
class LayoutChangedNotification extends Notification { }
