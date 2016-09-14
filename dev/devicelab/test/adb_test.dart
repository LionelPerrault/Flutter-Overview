// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:collection/collection.dart';

import 'package:flutter_devicelab/framework/adb.dart';

void main() {
  group('adb', () {
    Adb device;

    setUp(() {
      FakeAdb.resetLog();
      adb = null;
      device = new FakeAdb();
    });

    tearDown(() {
      adb = realAdbGetter;
    });

    group('isAwake/isAsleep', () {
      test('reads Awake', () async {
        FakeAdb.pretendAwake();
        expect(await device.isAwake(), isTrue);
        expect(await device.isAsleep(), isFalse);
      });

      test('reads Asleep', () async {
        FakeAdb.pretendAsleep();
        expect(await device.isAwake(), isFalse);
        expect(await device.isAsleep(), isTrue);
      });
    });

    group('togglePower', () {
      test('sends power event', () async {
        await device.togglePower();
        expectLog(<CommandArgs>[
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('wakeUp', () {
      test('when awake', () async {
        FakeAdb.pretendAwake();
        await device.wakeUp();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
        ]);
      });

      test('when asleep', () async {
        FakeAdb.pretendAsleep();
        await device.wakeUp();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('sendToSleep', () {
      test('when asleep', () async {
        FakeAdb.pretendAsleep();
        await device.sendToSleep();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
        ]);
      });

      test('when awake', () async {
        FakeAdb.pretendAwake();
        await device.sendToSleep();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '26']),
        ]);
      });
    });

    group('unlock', () {
      test('sends unlock event', () async {
        FakeAdb.pretendAwake();
        await device.unlock();
        expectLog(<CommandArgs>[
          cmd(command: 'dumpsys', arguments: <String>['power']),
          cmd(command: 'input', arguments: <String>['keyevent', '82']),
        ]);
      });
    });
  });
}

void expectLog(List<CommandArgs> log) {
  expect(FakeAdb.commandLog, log);
}

CommandArgs cmd({ String command, List<String> arguments, Map<String, String> env }) => new CommandArgs(
  command: command,
  arguments: arguments,
  env: env
);

typedef dynamic ExitErrorFactory();

class CommandArgs {
  CommandArgs({ this.command, this.arguments, this.env });

  final String command;
  final List<String> arguments;
  final Map<String, String> env;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, env: $env)';

  @override
  bool operator==(Object other) {
    if (other.runtimeType != CommandArgs)
      return false;

    CommandArgs otherCmd = other;
    return otherCmd.command == this.command &&
      const ListEquality<String>().equals(otherCmd.arguments, this.arguments) &&
      const MapEquality<String, String>().equals(otherCmd.env, this.env);
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnv;

  int get _hashArguments => arguments != null
    ? const ListEquality<String>().hash(arguments)
    : null.hashCode;

  int get _hashEnv => env != null
    ? const MapEquality<String, String>().hash(env)
    : null.hashCode;
}

class FakeAdb extends Adb {
  FakeAdb({ String deviceId: null }) : super(deviceId: deviceId);

  static String output = '';
  static ExitErrorFactory exitErrorFactory = () => null;

  static List<CommandArgs> commandLog = <CommandArgs>[];

  static void resetLog() {
    commandLog.clear();
  }

  static void pretendAwake() {
    output = '''
      mWakefulness=Awake
    ''';
  }

  static void pretendAsleep() {
    output = '''
      mWakefulness=Asleep
    ''';
  }

  @override
  Future<String> shellEval(String command, List<String> arguments, {Map<String, String> env}) async {
    commandLog.add(new CommandArgs(
      command: command,
      arguments: arguments,
      env: env
    ));
    return output;
  }

  @override
  Future<Null> shellExec(String command, List<String> arguments, {Map<String, String> env}) async {
    commandLog.add(new CommandArgs(
      command: command,
      arguments: arguments,
      env: env
    ));
    dynamic exitError = exitErrorFactory();
    if (exitError != null)
      throw exitError;
  }
}
