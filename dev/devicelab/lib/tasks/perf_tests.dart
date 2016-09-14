// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:meta/meta.dart';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

TaskFunction createComplexLayoutScrollPerfTest({ @required bool ios: false }) {
  return new PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
    ios: ios
  );
}

TaskFunction createFlutterGalleryStartupTest({ bool ios: false }) {
  return new StartupTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    ios: ios
  );
}

TaskFunction createComplexLayoutStartupTest({ bool ios: false }) {
  return new StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    ios: ios
  );
}

TaskFunction createFlutterGalleryBuildTest() {
  return new BuildTest('${flutterDirectory.path}/examples/flutter_gallery');
}

TaskFunction createComplexLayoutBuildTest() {
  return new BuildTest('${flutterDirectory.path}/dev/benchmarks/complex_layout');
}

/// Measure application startup performance.
class StartupTest {
  static const Duration _startupTimeout = const Duration(minutes: 2);

  StartupTest(this.testDirectory, { this.ios });

  final String testDirectory;
  final bool ios;

  Future<TaskResult> call() async {
    return await inDirectory(testDirectory, () async {
      String deviceId = await getUnlockedDeviceId(ios: ios);
      await pub('get');

      if (ios) {
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('run', options: <String>[
        '--profile',
        '--trace-startup',
        '-d',
        deviceId,
      ]).timeout(_startupTimeout);
      Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/start_up_info.json').readAsStringSync());
      return new TaskResult.success(data, benchmarkScoreKeys: <String>[
        'engineEnterTimestampMicros',
        'timeToFirstFrameMicros',
      ]);
    });
  }
}

/// Measures application runtime performance, specifically per-frame
/// performance.
class PerfTest {

  PerfTest(this.testDirectory, this.testTarget, this.timelineFileName, { this.ios });

  final String testDirectory;
  final String testTarget;
  final String timelineFileName;
  final bool ios;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      String deviceId = await getUnlockedDeviceId(ios: ios);
      await pub('get');

      if (ios) {
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('drive', options: <String>[
        '-v',
        '--profile',
        '--trace-startup', // Enables "endless" timeline event buffering.
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);
      Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/$timelineFileName.timeline_summary.json').readAsStringSync());
      return new TaskResult.success(data, benchmarkScoreKeys: <String>[
        'average_frame_build_time_millis',
        'worst_frame_build_time_millis',
        'missed_frame_build_budget_count',
      ]);
    });
  }
}

class BuildTest {

  BuildTest(this.testDirectory);

  final String testDirectory;

  Future<TaskResult> call() async {
    return await inDirectory(testDirectory, () async {
      Adb device = await adb();
      await device.unlock();
      await pub('get');

      Stopwatch watch = new Stopwatch()..start();
      await flutter('build', options: <String>[
        'aot',
        '--profile',
        '--no-pub',
        '--target-platform', 'android-arm'  // Generate blobs instead of assembly.
      ]);
      watch.stop();

      int vmisolateSize = file("$testDirectory/build/aot/snapshot_aot_vmisolate").lengthSync();
      int isolateSize = file("$testDirectory/build/aot/snapshot_aot_isolate").lengthSync();
      int instructionsSize = file("$testDirectory/build/aot/snapshot_aot_instr").lengthSync();
      int rodataSize = file("$testDirectory/build/aot/snapshot_aot_rodata").lengthSync();
      int totalSize = vmisolateSize + isolateSize + instructionsSize + rodataSize;

      Map<String, dynamic> data = <String, dynamic>{
        'aot_snapshot_build_millis': watch.elapsedMilliseconds,
        'aot_snapshot_size_vmisolate': vmisolateSize,
        'aot_snapshot_size_isolate': isolateSize,
        'aot_snapshot_size_instructions': instructionsSize,
        'aot_snapshot_size_rodata': rodataSize,
        'aot_snapshot_size_total': totalSize,
      };
      return new TaskResult.success(data, benchmarkScoreKeys: <String>[
        'aot_snapshot_build_millis',
        'aot_snapshot_size_vmisolate',
        'aot_snapshot_size_isolate',
        'aot_snapshot_size_instructions',
        'aot_snapshot_size_rodata',
        'aot_snapshot_size_total',
      ]);
    });
  }
}
