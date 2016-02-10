// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/test_context.dart';

main() => defineTests();

defineTests() {
  group('create', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // This test consistently times out on our windows bot. The code is already
    // covered on the linux one.
    // Also fails on mac, with create --out returning '69'
    // TODO(devoncarew): https://github.com/flutter/flutter/issues/1709
    if (Platform.isLinux) {
      // Verify that we create a project that is well-formed.
      testUsingContext('flutter-simple', () async {
        ArtifactStore.flutterRoot = '../..';
        CreateCommand command = new CreateCommand();
        CommandRunner runner = new CommandRunner('test_flutter', '')
          ..addCommand(command);
        await runner.run(['create', '--out', temp.path])
            .then((int code) => expect(code, equals(0)));

        String mainPath = path.join(temp.path, 'lib', 'main.dart');
        expect(new File(mainPath).existsSync(), true);
        ProcessResult exec = Process.runSync(
          sdkBinaryName('dartanalyzer'), ['--fatal-warnings', mainPath],
          workingDirectory: temp.path
        );
        if (exec.exitCode != 0) {
          print(exec.stdout);
          print(exec.stderr);
        }
        expect(exec.exitCode, 0);
      },
      // This test can take a while due to network requests.
      timeout: new Timeout(new Duration(minutes: 2)));
    }
  });
}
