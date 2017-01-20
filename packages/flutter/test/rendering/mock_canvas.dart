// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

/// Signature for [PaintPattern.something] predicate argument.
///
/// Used by the [paints] matcher.
///
/// The `methodName` argument is a [Symbol], and can be compared with the symbol
/// literal syntax, for example:
///
/// ```dart
/// if (methodName == #drawCircle) { ... }
/// ```
typedef bool PaintPatternPredicate(Symbol methodName, List<dynamic> arguments);

/// Builder interface for patterns used to match display lists (canvas calls).
///
/// The [paints] matcher returns a [PaintPattern] so that you can build the
/// pattern in the [expect] call.
///
/// Patterns are subset matches, meaning that any calls not described by the
/// pattern are ignored. This allows, for instance, transforms to be skipped.
abstract class PaintPattern {
  /// Indicates that a translation transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.translate] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.translate] is found, then the matcher fails.
  void translate({ double x, double y });

  /// Indicates that a scale transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.scale] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.scale] is found, then the matcher fails.
  void scale({ double x, double y });

  /// Indicates that a rotate transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.rotate] is found. If the `angle`
  /// argument is provided here, the call's argument is compared to it. If that
  /// fails to match, or if no call to [Canvas.rotate] is found, then the
  /// matcher fails.
  void rotate({ double angle });

  /// Indicates that a save is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [restore], [saveRestore].
  void save();

  /// Indicates that a restore is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.restore] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [save], [saveRestore].
  void restore();

  /// Indicates that a matching pair of save/restore calls is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found, then, calls are
  /// skipped until the matching [Canvas.restore] call is found. If no matching
  /// pair of calls could be found, the matcher fails.
  ///
  /// See also: [save], [restore].
  void saveRestore();

  /// Indicates that a circle is expected next.
  ///
  /// The next circle is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawCircle] call's arguments and any
  /// mismatches result in failure.
  ///
  /// If no call to [Canvas.drawCircle] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawCircle] call are ignored.
  void circle({ double x, double y, double radius, Color color, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a rounded rectangle is expected next.
  ///
  /// The next rounded rectangle is examined. Any arguments that are passed to
  /// this method are compared to the actual [Canvas.drawRRect] call's arguments
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRRect] call are ignored.
  void rrect({ RRect rrect, Color color, bool hasMaskFilter, PaintingStyle style });

  /// Provides a custom matcher.
  ///
  /// Each method call after the last matched call (if any) will be passed to
  /// the given predicate, along with the values of its (positional) arguments.
  ///
  /// For each one, the predicate must either return a boolean or throw a [String].
  ///
  /// If the predicate returns true, the call is considered a successful match
  /// and the next step in the pattern is examined. If this was the last step,
  /// then any calls that were not yet matched are ignored and the [paints]
  /// [Matcher] is considered a success.
  ///
  /// If the predicate returns false, then the call is considered uninteresting
  /// and the predicate will be called again for the next [Canvas] call that was
  /// made by the [RenderObject] under test. If this was the last call, then the
  /// [paints] [Matcher] is considered to have failed.
  ///
  /// If the predicate throws a [String], then the [paints] [Matcher] is
  /// considered to have failed. The thrown string is used in the message
  /// displayed from the test framework and should be complete sentence
  /// describing the problem.
  void something(PaintPatternPredicate predicate);
}

/// Matches [RenderObject]s that paint a display list that matches the canvas
/// calls described by the pattern.
///
/// To specify the pattern, call the methods on the returned object. For example:
///
/// ```dart
///  expect(myRenderObject, paints..circle(radius: 10.0)..circle(radius: 20.0));
/// ```
///
/// This particular pattern would verify that the render object `myRenderObject`
/// paints, among other things, two circles of radius 10.0 and 20.0 (in that
/// order).
///
/// See [PaintPattern] for a discussion of the semantics of paint patterns.
PaintPattern get paints => new _TestRecordingCanvasPatternMatcher();

class _TestRecordingCanvasPatternMatcher extends Matcher implements PaintPattern {
  final List<_PaintPredicate> _predicates = <_PaintPredicate>[];

  @override
  void translate({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#translate, <dynamic>[x, y]));
  }

  @override
  void scale({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#scale, <dynamic>[x, y]));
  }

  @override
  void rotate({ double angle }) {
    _predicates.add(new _FunctionPaintPredicate(#rotate, <dynamic>[angle]));
  }

  @override
  void save() {
    _predicates.add(new _FunctionPaintPredicate(#save, <dynamic>[]));
  }

  @override
  void restore() {
    _predicates.add(new _FunctionPaintPredicate(#restore, <dynamic>[]));
  }

  @override
  void saveRestore() {
    _predicates.add(new _SaveRestorePairPaintPredicate());
  }

  @override
  void circle({ double x, double y, double radius, Color color, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _CirclePaintPredicate(x: x, y: y, radius: radius, color: color, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void rrect({ RRect rrect, Color color, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _RRectPaintPredicate(rrect: rrect, color: color, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void something(PaintPatternPredicate predicate) {
    _predicates.add(new _SomethingPaintPredicate(predicate));
  }

  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    if (object is! RenderObject)
      return false;
    final _TestRecordingCanvas canvas = new _TestRecordingCanvas();
    final _TestRecordingPaintingContext context = new _TestRecordingPaintingContext(canvas);
    final RenderObject renderObject = object;
    renderObject.paint(context, Offset.zero);
    final StringBuffer description = new StringBuffer();
    final bool result = _evaluatePredicates(canvas._invocations, description);
    if (!result) {
      const String indent = '\n            '; // the length of '   Which: ' in spaces, plus two more
      if (canvas._invocations.isNotEmpty)
        description.write(' The complete display list was:');
        for (Invocation call in canvas._invocations)
          description.write('$indent${_describeInvocation(call)}');
    }
    matchState[this] = description.toString();
    return result;
  }

  @override
  Description describe(Description description) {
    description.add('RenderObject painting: ');
    return description.addAll(
      '', ', ', '',
      _predicates.map((_PaintPredicate predicate) => predicate.toString()),
    );
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add(matchState[this]);
  }

  bool _evaluatePredicates(Iterable<Invocation> calls, StringBuffer description) {
    // If we ever want to have a matcher for painting nothing, create a separate
    // paintsNothing matcher.
    if (_predicates.isEmpty)
      throw new Exception('You must add a pattern to the paints matcher.');
    if (calls.isEmpty) {
      description.write('painted nothing.');
      return false;
    }
    Iterator<_PaintPredicate> predicate = _predicates.iterator;
    Iterator<Invocation> call = calls.iterator..moveNext();
    try {
      while (predicate.moveNext()) {
        if (call.current == null) {
          throw 'painted less on its canvas than the paint pattern expected. '
                'The first missing paint call was: ${predicate.current}';
        }
        predicate.current.match(call);
      }
      assert(predicate.current == null);
      // We allow painting more than expected.
    } on String catch (s) {
      description.write(s);
      return false;
    }
    return true;
  }
}

class _TestRecordingCanvas implements Canvas {
  final List<Invocation> _invocations = <Invocation>[];

  int _saveCount = 0;

  @override
  int getSaveCount() => _saveCount;

  @override
  void save() {
    _saveCount += 1;
    super.save(); // ends up in noSuchMethod
  }

  @override
  void restore() {
    _saveCount -= 1;
    assert(_saveCount >= 0);
    super.restore(); // ends up in noSuchMethod
  }

  @override
  void noSuchMethod(Invocation invocation) {
    _invocations.add(invocation);
  }
}

class _TestRecordingPaintingContext implements PaintingContext {
  _TestRecordingPaintingContext(this.canvas);

  @override
  final Canvas canvas;

  @override
  void noSuchMethod(Invocation invocation) {
  }
}

abstract class _PaintPredicate {
  void match(Iterator<Invocation> call);

  @override
  String toString() {
    throw new FlutterError('$runtimeType does not implement toString.');
  }
}

abstract class _DrawCommandPaintPredicate extends _PaintPredicate {
  _DrawCommandPaintPredicate(
    this.symbol, this.name, this.argumentCount, this.paintArgumentIndex,
    { this.color, this.hasMaskFilter, this.style }
  );

  final Symbol symbol;
  final String name;
  final int argumentCount;
  final int paintArgumentIndex;
  final Color color;
  final bool hasMaskFilter;
  final PaintingStyle style;

  String get methodName => _symbolName(symbol);

  @override
  void match(Iterator<Invocation> call) {
    int others = 0;
    Invocation firstCall = call.current;
    while (!call.current.isMethod || call.current.memberName != symbol) {
      others += 1;
      if (!call.moveNext())
        throw 'called $others other method${ others == 1 ? "" : "s" } on the canvas, '
              'the first of which was ${_describeInvocation(firstCall)}, but did not '
              'call $methodName at the time where $this was expected.';
    }
    final int actualArgumentCount = call.current.positionalArguments.length;
    if (actualArgumentCount != argumentCount)
      throw 'called $methodName with $actualArgumentCount argument${actualArgumentCount == 1 ? "" : "s"}; expected $argumentCount.';
    verifyArguments(call.current.positionalArguments);
    call.moveNext();
  }

  @protected
  @mustCallSuper
  void verifyArguments(List<dynamic> arguments) {
    final Paint paintArgument = arguments[paintArgumentIndex];
    if (color != null && paintArgument.color != color)
      throw 'called $methodName with a paint whose color, ${paintArgument.color}, was not exactly the expected color ($color).';
    if (hasMaskFilter != null && (paintArgument.maskFilter != null) != hasMaskFilter) {
      if (hasMaskFilter)
        throw 'called $methodName with a paint that did not have a mask filter, despite expecting one.';
      else
        throw 'called $methodName with a paint that did had a mask filter, despite not expecting one.';
    }
    if (style != null && paintArgument.style != style)
      throw 'called $methodName with a paint whose style, ${paintArgument.style}, was not exactly the expected style ($style).';
  }

  @override
  String toString() {
    List<String> description = <String>[];
    debugFillDescription(description);
    String result = name;
    if (description.isNotEmpty)
      result += ' with ${description.join(", ")}';
    return result;
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (color != null)
      description.add('$color');
    if (hasMaskFilter != null)
      description.add(hasMaskFilter ? 'a mask filter' : 'no mask filter');
    if (style != null)
      description.add('$style');
  }
}

class _CirclePaintPredicate extends _DrawCommandPaintPredicate {
  _CirclePaintPredicate({ this.x, this.y, this.radius, Color color, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawCircle, 'a circle', 3, 2, color: color, hasMaskFilter: hasMaskFilter, style: style
  );

  final double x;
  final double y;
  final double radius;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final Point pointArgument = arguments[0];
    if (x != null && y != null) {
      final Point point = new Point(x, y);
      if (point != pointArgument)
        throw 'called $methodName with a center coordinate, $pointArgument, which was not exactly the expected coordinate ($point).';
    } else {
      if (x != null && pointArgument.x != x)
        throw 'called $methodName with a center coordinate, $pointArgument, whose x-coordinate not exactly the expected coordinate (${x.toStringAsFixed(1)}).';
      if (y != null && pointArgument.y != y)
        throw 'called $methodName with a center coordinate, $pointArgument, whose y-coordinate not exactly the expected coordinate (${y.toStringAsFixed(1)}).';
    }
    final double radiusArgument = arguments[1];
    if (radius != null && radiusArgument != radius)
      throw 'called $methodName with radius, ${radiusArgument.toStringAsFixed(1)}, which was not exactly the expected radius (${radius.toStringAsFixed(1)}).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (x != null && y != null) {
      description.add('point ${new Point(x, y)}');
    } else {
      if (x != null)
        description.add('x-coordinate ${x.toStringAsFixed(1)}');
      if (y != null)
        description.add('y-coordinate ${y.toStringAsFixed(1)}');
    }
    if (radius != null)
      description.add('radius ${radius.toStringAsFixed(1)}');
  }
}

class _RRectPaintPredicate extends _DrawCommandPaintPredicate {
  _RRectPaintPredicate({ this.rrect, Color color, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawRRect, 'a rounded rectangle', 2, 1, color: color, hasMaskFilter: hasMaskFilter, style: style
  );

  final RRect rrect;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final RRect rrectArgument = arguments[0];
    if (rrect != null && rrectArgument != rrect)
      throw 'called $methodName with an rrect, $rrectArgument, which was not exactly the expected rrect ($rrect).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (rrect != null)
      description.add('$rrect');
  }
}

class _SomethingPaintPredicate extends _PaintPredicate {
  _SomethingPaintPredicate(this.predicate);

  final PaintPatternPredicate predicate;

  @override
  void match(Iterator<Invocation> call) {
    assert(predicate != null);
    Invocation currentCall;
    do {
      currentCall = call.current;
      if (currentCall == null)
        throw 'did not call anything that was matched by the predicate passed to a "something" step of the paint pattern.';
      if (!currentCall.isMethod)
        throw 'called ${_describeInvocation(currentCall)}, which was not a method, when the paint pattern expected a method call';
      call.moveNext();
    } while (!_runPredicate(currentCall.memberName, currentCall.positionalArguments));
  }

  bool _runPredicate(Symbol methodName, List<dynamic> arguments) {
    try {
      return predicate(methodName, arguments);
    } on String catch (s) {
      throw 'painted something that the predicate passed to a "something" step '
            'in the paint pattern considered incorrect:\n      $s\n  ';
    }
  }

  @override
  String toString() => 'a "something" step';
}

class _FunctionPaintPredicate extends _PaintPredicate {
  _FunctionPaintPredicate(this.symbol, this.arguments);

  final Symbol symbol;

  final List<dynamic> arguments;

  @override
  void match(Iterator<Invocation> call) {
    int others = 0;
    Invocation firstCall = call.current;
    while (!call.current.isMethod || call.current.memberName != symbol) {
      others += 1;
      if (!call.moveNext())
        throw 'called $others other method${ others == 1 ? "" : "s" } on the canvas, '
              'the first of which was ${_describeInvocation(firstCall)}, but did not '
              'call ${_symbolName(symbol)}() at the time where $this was expected.';
    }
    if (call.current.positionalArguments.length != arguments.length)
      throw 'called ${_symbolName(symbol)} with ${call.current.positionalArguments.length} arguments; expected ${arguments.length}.';
    for (int index = 0; index < arguments.length; index += 1) {
      final dynamic actualArgument = call.current.positionalArguments[index];
      final dynamic desiredArgument = arguments[index];
      if (desiredArgument != null && desiredArgument != actualArgument)
        throw 'called ${_symbolName(symbol)} with argument $index having value ${_valueName(actualArgument)} when ${_valueName(desiredArgument)} was expected.';
    }
    call.moveNext();
  }

  @override
  String toString() {
    List<String> adjectives = <String>[];
    for (int index = 0; index < arguments.length; index += 1)
      adjectives.add(arguments[index] != null ? _valueName(arguments[index]) : '...');
    return '${_symbolName(symbol)}(${adjectives.join(", ")})';
  }
}

class _SaveRestorePairPaintPredicate extends _PaintPredicate {
  @override
  void match(Iterator<Invocation> call) {
    int others = 0;
    Invocation firstCall = call.current;
    while (!call.current.isMethod || call.current.memberName != #save) {
      others += 1;
      if (!call.moveNext())
        throw 'called $others other method${ others == 1 ? "" : "s" } on the canvas, '
              'the first of which was ${_describeInvocation(firstCall)}, but did not '
              'call save() at the time where $this was expected.';
    }
    int depth = 1;
    while (depth > 0) {
      if (!call.moveNext())
        throw 'did not have a matching restore() for the save() that was found where $this was expected.';
      if (call.current.isMethod) {
        if (call.current.memberName == #save)
          depth += 1;
        else if (call.current.memberName == #restore)
          depth -= 1;
      }
    }
    call.moveNext();
  }

  @override
  String toString() => 'a matching save/restore pair';
}

String _valueName(Object value) {
  if (value is double)
    return value.toStringAsFixed(1);
  return value.toString();
}

// Workaround for https://github.com/dart-lang/sdk/issues/28372
String _symbolName(Symbol symbol) {
  // WARNING: Assumes a fixed format for Symbol.toString which is *not*
  // guaranteed anywhere.
  final String s = '$symbol';
  return s.substring(8, s.length - 2);
}

// Workaround for https://github.com/dart-lang/sdk/issues/28373
String _describeInvocation(Invocation call) {
  final StringBuffer buffer = new StringBuffer();
  buffer.write(_symbolName(call.memberName));
  if (call.isSetter) {
    buffer.write(call.positionalArguments[0].toString());
  } else if (call.isMethod) {
    buffer.write('(');
    buffer.writeAll(call.positionalArguments.map(_valueName), ', ');
    String separator = call.positionalArguments.isEmpty ? '' : ', ';
    call.namedArguments.forEach((Symbol name, Object value) {
      buffer.write(separator);
      buffer.write(_symbolName(name));
      buffer.write(': ');
      buffer.write(_valueName(value));
      separator = ', ';
    });
    buffer.write(')');
  }
  return buffer.toString();
}