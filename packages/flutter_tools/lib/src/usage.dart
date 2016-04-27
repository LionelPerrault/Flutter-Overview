// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:usage/src/usage_impl_io.dart';
import 'package:usage/usage.dart';

import 'base/context.dart';
import 'runner/version.dart';

// TODO(devoncarew): We'll need to do some work on the user agent in order to
// correctly track usage by operating system (dart-lang/usage/issues/70).

// TODO(devoncarew): We'll want to find a way to send (sanitized) command parameters.

const String _kFlutterUA = 'UA-67589403-5';

class Usage {
  Usage() {
    String version = FlutterVersion.getVersionString(whitelistBranchName: true);
    _analytics = new AnalyticsIO(_kFlutterUA, 'flutter', version);
    _analytics.analyticsOpt = AnalyticsOpt.optOut;
  }

  /// Returns [Usage] active in the current app context.
  static Usage get instance => context[Usage] ?? (context[Usage] = new Usage());

  Analytics _analytics;

  bool get isFirstRun => _analytics.firstRun;

  bool get enabled => _analytics.enabled;

  /// Enable or disable reporting analytics.
  set enabled(bool value) {
    _analytics.enabled = value;
  }

  void sendCommand(String command) {
    if (!isFirstRun)
      _analytics.sendScreenView(command);
  }

  void sendEvent(String category, String parameter) {
    if (!isFirstRun)
      _analytics.sendEvent(category, parameter);
  }

  UsageTimer startTimer(String event) {
    if (isFirstRun)
      return new _MockUsageTimer();
    else
      return new UsageTimer._(event, _analytics.startTimer(event, category: 'flutter'));
  }

  void sendException(dynamic exception, StackTrace trace) {
    if (!isFirstRun)
      _analytics.sendException('${exception.runtimeType}; ${sanitizeStacktrace(trace)}');
  }

  /// Fires whenever analytics data is sent over the network; public for testing.
  Stream<Map<String, dynamic>> get onSend => _analytics.onSend;

  /// Returns when the last analytics event has been sent, or after a fixed
  /// (short) delay, whichever is less.
  Future<Null> ensureAnalyticsSent() {
    // TODO(devoncarew): This may delay tool exit and could cause some analytics
    // events to not be reported. Perhaps we could send the analytics pings
    // out-of-process from flutter_tools?
    return _analytics.waitForLastPing(timeout: new Duration(milliseconds: 250));
  }
}

class UsageTimer {
  UsageTimer._(this.event, this._timer);

  final String event;
  final AnalyticsTimer _timer;

  void finish() {
    _timer.finish();
  }
}

class _MockUsageTimer implements UsageTimer {
  @override
  String event;
  @override
  AnalyticsTimer _timer;

  @override
  void finish() { }
}
