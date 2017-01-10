// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// Signature for [Notification] listeners.
///
/// Return true to cancel the notification bubbling. Return false to allow the
/// notification to continue to be dispatched to further ancestors.
///
/// Used by [NotificationListener.onNotification].
typedef bool NotificationListenerCallback<T extends Notification>(T notification);

/// A notification that can bubble up the widget tree.
abstract class Notification {
  /// Applied to each ancestor of the [dispatch] target.
  ///
  /// The [Notification] class implementation of this method dispatches the
  /// given [Notification] to each ancestor [NotificationListener] widget.
  ///
  /// Subclasses can override this to apply additional filtering or to update
  /// the notification as it is bubbled (for example, increasing a `depth` field
  /// for each ancestor of a particular type).
  @protected
  @mustCallSuper
  bool visitAncestor(Element element) {
    if (element is StatelessElement &&
        element.widget is NotificationListener<Notification>) {
      final NotificationListener<Notification> widget = element.widget;
      if (widget._dispatch(this, element)) // that function checks the type dynamically
        return false;
    }
    return true;
  }

  /// Start bubbling this notification at the given build context.
  ///
  /// To receive notifications, use a [NotificationListener].
  void dispatch(BuildContext target) {
    assert(target != null); // Only call dispatch if the widget's State is still mounted.
    target.visitAncestorElements(visitAncestor);
  }

  @override
  String toString() {
    List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [Notification] base class calls [debugFillDescription] to collect
  /// useful information from subclasses to incorporate into its return value.
  ///
  /// If you override this, make sure to start your method with a call to
  /// `super.debugFillDescription(description)`.
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) { }
}

/// A widget that listens for [Notification]s bubbling up the tree.
///
/// To dispatch notifications, use the [Notification.dispatch] method.
class NotificationListener<T extends Notification> extends StatelessWidget {
  /// Creates a widget that listens for notifications.
  NotificationListener({
    Key key,
    this.child,
    this.onNotification
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when a notification of the appropriate type arrives at this
  /// location in the tree.
  ///
  /// Return true to cancel the notification bubbling. Return false to allow the
  /// notification to continue to be dispatched to further ancestors.
  ///
  /// The notification's [Notification.visitAncestor] method is called for each
  /// ancestor, and invokes this callback as appropriate.
  final NotificationListenerCallback<T> onNotification;

  bool _dispatch(Notification notification, Element element) {
    if (onNotification != null && notification is T) {
      bool result = onNotification(notification);
      assert(() {
        if (result == null)
          throw new FlutterError(
            'NotificationListener<$T> handler returned null.\n'
            'The onNotification handler for the NotificationListener with the '
            'following element returned null:\n'
            '  $element\n'
            'The ancestor chain for this widget was as follows:\n'
            '  ${element.debugGetCreatorChain(12)}\n'
            'Notification listeners must return true to stop the notification bubbling, '
            'or false to allow it to continue (the common case is returning false).'
          );
        return true;
      });
      return result;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Indicates that the layout of one of the descendants of the object receiving
/// this notification has changed in some way, and that therefore any
/// assumptions about that layout are no longer valid.
///
/// Useful if, for instance, you're trying to align multiple descendants.
///
/// In the widgets library, only the [SizeChangedLayoutNotifier] class and
/// [Scrollable] classes dispatch this notification (specifically, they dispatch
/// [SizeChangedLayoutNotification]s and [ScrollNotification]s respectively).
/// Transitions, in particular, do not. Changing one's layout in one's build
/// function does not cause this notification to be dispatched automatically. If
/// an ancestor expects to be notified for any layout change, make sure you
/// either only use widgets that never change layout, or that notify their
/// ancestors when appropriate, or alternatively, dispatch the notifications
/// yourself when appropriate.
///
/// Also, since this notification is sent when the layout is changed, it is only
/// useful for paint effects that depend on the layout. If you were to use this
/// notification to change the build, for instance, you would always be one
/// frame behind, which would look really ugly and laggy.
class LayoutChangedNotification extends Notification { }
