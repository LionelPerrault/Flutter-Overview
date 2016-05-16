// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:test/test.dart' as test_package;

import 'binding.dart';
import 'controller.dart';
import 'finders.dart';
import 'test_async_utils.dart';

export 'package:test/test.dart' hide expect;

/// Signature for callback to [testWidgets] and [benchmarkWidgets].
typedef Future<Null> WidgetTesterCallback(WidgetTester widgetTester);

/// Runs the [callback] inside the Flutter test environment.
///
/// Use this function for testing custom [StatelessWidget]s and
/// [StatefulWidget]s.
///
/// The callback can be asynchronous (using `async`/`await` or
/// using explicit [Future]s).
///
/// This function uses the [test] function in the test package to
/// register the given callback as a test. The callback, when run,
/// will be given a new instance of [WidgetTester]. The [find] object
/// provides convenient widget [Finder]s for use with the
/// [WidgetTester].
///
/// Example:
///
///     testWidgets('MyWidget', (WidgetTester tester) {
///       tester.pumpWidget(new MyWidget());
///       tester.tap(find.text('Save'));
///       expect(tester, hasWidget(find.text('Success')));
///     });
void testWidgets(String description, WidgetTesterCallback callback, {
  bool skip: false,
  test_package.Timeout timeout
}) {
  TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  WidgetTester tester = new WidgetTester._(binding);
  timeout ??= binding.defaultTestTimeout;
  test_package.group('-', () {
    test_package.test(description, () => binding.runTest(() => callback(tester)), skip: skip);
    test_package.tearDown(binding.postTest);
  }, timeout: timeout);
}

/// Runs the [callback] inside the Flutter benchmark environment.
///
/// Use this function for benchmarking custom [StatelessWidget]s and
/// [StatefulWidget]s when you want to be able to use features from
/// [TestWidgetsFlutterBinding]. The callback, when run, will be given
/// a new instance of [WidgetTester]. The [find] object provides
/// convenient widget [Finder]s for use with the [WidgetTester].
///
/// The callback can be asynchronous (using `async`/`await` or using
/// explicit [Future]s). If it is, then [benchmarkWidgets] will return
/// a [Future] that completes when the callback's does. Otherwise, it
/// will return a widget that is always complete.
///
/// Benchmarks must not be run in checked mode. To avoid this, this
/// function will assert if it is run in checked mode.
///
/// Example:
///
///     main() async {
///       await benchmarkWidgets((WidgetTester tester) {
///         tester.pumpWidget(new MyWidget());
///         final Stopwatch timer = new Stopwatch()..start();
///         for (int index = 0; index < 10000; index += 1) {
///           tester.tap(find.text('Tap me'));
///           tester.pump();
///         }
///         timer.stop();
///         debugPrint('Time taken: ${timer.elapsedMilliseconds}ms');
///       });
///       exit(0);
///     }
Future<Null> benchmarkWidgets(WidgetTesterCallback callback) {
  assert(false); // Don't run benchmarks in checked mode.
  TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  assert(binding is! AutomatedTestWidgetsFlutterBinding);
  WidgetTester tester = new WidgetTester._(binding);
  return binding.runTest(() => callback(tester)) ?? new Future<Null>.value();
}

/// Assert that `actual` matches `matcher`.
///
/// See [test_package.expect] for details. This is a variant of that function
/// that additionally verifies that there are no asynchronous APIs
/// that have not yet resolved.
void expect(dynamic actual, dynamic matcher, {
  String reason,
  bool verbose: false,
  dynamic formatter
}) {
  TestAsyncUtils.guardSync();
  test_package.expect(actual, matcher, reason: reason, verbose: verbose, formatter: formatter);
}

/// Assert that `actual` matches `matcher`.
///
/// See [test_package.expect] for details. This variant will _not_ check that
/// there are no outstanding asynchronous API requests. As such, it can be
/// called from, e.g., callbacks that are run during build or layout, or in the
/// completion handlers of futures that execute in response to user input.
///
/// Generally, it is better to use [expect], which does include checks to ensure
/// that asynchronous APIs are not being called.
void expectSync(dynamic actual, dynamic matcher, {
  String reason,
  bool verbose: false,
  dynamic formatter
}) {
  test_package.expect(actual, matcher, reason: reason, verbose: verbose, formatter: formatter);
}

/// Class that programmatically interacts with widgets and the test environment.
class WidgetTester extends WidgetController {
  WidgetTester._(TestWidgetsFlutterBinding binding) : super(binding);

  /// The binding instance used by the testing framework.
  @override
  TestWidgetsFlutterBinding get binding => super.binding;

  /// Renders the UI from the given [widget].
  ///
  /// Calls [runApp] with the given widget, then triggers a frame sequence and
  /// flushes microtasks, by calling [pump] with the same duration (if any).
  /// The supplied [EnginePhase] is the final phase reached during the pump pass;
  /// if not supplied, the whole pass is executed.
  Future<Null> pumpWidget(Widget widget, [
    Duration duration,
    EnginePhase phase = EnginePhase.sendSemanticsTree
  ]) {
    return TestAsyncUtils.guard(() {
      runApp(widget);
      return binding.pump(duration, phase);
    });
  }

  /// Triggers a sequence of frames for [duration] amount of time.
  ///
  /// This is a convenience function that just calls
  /// [TestWidgetsFlutterBinding.pump].
  Future<Null> pump([
    Duration duration,
    EnginePhase phase = EnginePhase.sendSemanticsTree
  ]) {
    return TestAsyncUtils.guard(() => binding.pump(duration, phase));
  }

  /// Returns the exception most recently caught by the Flutter framework.
  ///
  /// See [TestWidgetsFlutterBinding.takeException] for details.
  dynamic takeException() {
    return binding.takeException();
  }

  /// Acts as if the application went idle.
  ///
  /// Runs all remaining microtasks, including those scheduled as a result of
  /// running them, until there are no more microtasks scheduled.
  ///
  /// Does not run timers. May result in an infinite loop or run out of memory
  /// if microtasks continue to recursively schedule new microtasks.
  Future<Null> idle() {
    return TestAsyncUtils.guard(() => binding.idle());
  }
}
