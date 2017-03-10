// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:mockito/mockito_no_mirrors.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'common.dart';

/// Return the test logger. This assumes that the current Logger is a BufferLogger.
BufferLogger get testLogger => context[Logger];

MockDeviceManager get testDeviceManager => context[DeviceManager];
MockDoctor get testDoctor => context[Doctor];

typedef dynamic Generator();

typedef void ContextInitializer(AppContext testContext);

void _defaultInitializeContext(AppContext testContext) {
  testContext.putIfAbsent(DeviceManager, () => new MockDeviceManager());
  testContext.putIfAbsent(DevFSConfig, () => new DevFSConfig());
  testContext.putIfAbsent(Doctor, () => new MockDoctor());
  testContext.putIfAbsent(HotRunnerConfig, () => new HotRunnerConfig());
  testContext.putIfAbsent(Cache, () => new Cache());
  testContext.putIfAbsent(Artifacts, () => new CachedArtifacts());
  testContext.putIfAbsent(OperatingSystemUtils, () => new MockOperatingSystemUtils());
  testContext.putIfAbsent(Xcode, () => new Xcode());
  testContext.putIfAbsent(IOSSimulatorUtils, () {
    final MockIOSSimulatorUtils mock = new MockIOSSimulatorUtils();
    when(mock.getAttachedDevices()).thenReturn(<IOSSimulator>[]);
    return mock;
  });
  testContext.putIfAbsent(SimControl, () => new MockSimControl());
  testContext.putIfAbsent(Usage, () => new MockUsage());
}

void testUsingContext(String description, dynamic testMethod(), {
  Timeout timeout,
  Map<Type, Generator> overrides: const <Type, Generator>{},
  ContextInitializer initializeContext: _defaultInitializeContext,
  bool skip, // should default to `false`, but https://github.com/dart-lang/test/issues/545 doesn't allow this
}) {
  test(description, () async {
    final AppContext testContext = new AppContext();

    // The context always starts with these value since others depend on them.
    testContext.putIfAbsent(Platform, () => const LocalPlatform());
    testContext.putIfAbsent(FileSystem, () => const LocalFileSystem());
    testContext.putIfAbsent(ProcessManager, () => const LocalProcessManager());
    testContext.putIfAbsent(Logger, () => new BufferLogger());
    testContext.putIfAbsent(Config, () => new Config());

    // Apply the initializer after seeding the base value above.
    initializeContext(testContext);

    final String flutterRoot = getFlutterRoot();

    try {
      return await testContext.runInZone(() async {
        // Apply the overrides to the test context in the zone since their
        // instantiation may reference items already stored on the context.
        overrides.forEach((Type type, dynamic value()) {
          context.setVariable(type, value());
        });
        // Provide a sane default for the flutterRoot directory. Individual
        // tests can override this.
        Cache.flutterRoot = flutterRoot;
        return await testMethod();
      }, onError: (dynamic error, StackTrace stackTrace) {
        _printBufferedErrors(testContext);
        throw error;
      });
    } catch (error) {
      _printBufferedErrors(testContext);
      rethrow;
    }

  }, timeout: timeout, skip: skip);
}

void _printBufferedErrors(AppContext testContext) {
  if (testContext[Logger] is BufferLogger) {
    final BufferLogger bufferLogger = testContext[Logger];
    if (bufferLogger.errorText.isNotEmpty)
      print(bufferLogger.errorText);
    bufferLogger.clear();
  }
}

class MockDeviceManager implements DeviceManager {
  List<Device> devices = <Device>[];

  @override
  String specifiedDeviceId;

  @override
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  @override
  Future<List<Device>> getAllConnectedDevices() => new Future<List<Device>>.value(devices);

  @override
  Future<List<Device>> getDevicesById(String deviceId) async {
    return devices.where((Device device) => device.id == deviceId).toList();
  }

  @override
  Future<List<Device>> getDevices() async {
    if (specifiedDeviceId == null) {
      return getAllConnectedDevices();
    } else {
      return getDevicesById(specifiedDeviceId);
    }
  }

  void addDevice(Device device) => devices.add(device);
}

class MockDoctor extends Doctor {
  // True for testing.
  @override
  bool get canListAnything => true;

  // True for testing.
  @override
  bool get canLaunchAnything => true;
}

class MockSimControl extends Mock implements SimControl {
  MockSimControl() {
    when(this.getConnectedDevices()).thenReturn(<SimDevice>[]);
  }
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

class MockIOSSimulatorUtils extends Mock implements IOSSimulatorUtils {}

class MockUsage implements Usage {
  @override
  bool get isFirstRun => false;

  @override
  bool get suppressAnalytics => false;

  @override
  set suppressAnalytics(bool value) { }

  @override
  bool get enabled => true;

  @override
  set enabled(bool value) { }

  @override
  void sendCommand(String command) { }

  @override
  void sendEvent(String category, String parameter) { }

  @override
  void sendTiming(String category, String variableName, Duration duration) { }

  @override
  UsageTimer startTimer(String event) => new _MockUsageTimer(event);

  @override
  void sendException(dynamic exception, StackTrace trace) { }

  @override
  Stream<Map<String, dynamic>> get onSend => null;

  @override
  Future<Null> ensureAnalyticsSent() => new Future<Null>.value();

  @override
  void printUsage() { }
}

class _MockUsageTimer implements UsageTimer {
  _MockUsageTimer(this.event);

  @override
  final String event;

  @override
  void finish() { }
}
