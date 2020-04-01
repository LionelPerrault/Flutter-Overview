// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/gen_l10n_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

// Verify that the code generated by gen_l10n executes correctly.
// It can fail if gen_l10n produces a lib/l10n/app_localizations.dart that:
// - Does not analyze cleanly.
// - Can't be processed by the intl_translation:generate_from_arb tool.
// The generate_from_arb step can take close to a minute on a lightly
// loaded workstation, so the test could time out on a heavily loaded bot.
void main() {
  Directory tempDir;
  final GenL10nProject _project = GenL10nProject();
  FlutterRunTestDriver _flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('gen_l10n_test.');
    await _project.setUpIn(tempDir);
    _flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await _flutter.stop();
    tryToDelete(tempDir);
  });

  void runCommand(List<String> command) {
    final ProcessResult result = const LocalProcessManager().runSync(
      command,
      workingDirectory: tempDir.path,
      environment: <String, String>{ 'FLUTTER_ROOT': getFlutterRoot() },
    );
    if (result.exitCode != 0) {
      throw Exception('FAILED [${result.exitCode}]: ${command.join(' ')}\n${result.stderr}\n${result.stdout}');
    }
  }

  test('generated l10n classes produce expected localized strings', () async {
    // Get the intl packages before running gen_l10n.
    final String flutterBin = globals.platform.isWindows ? 'flutter.bat' : 'flutter';
    final String flutterPath = globals.fs.path.join(getFlutterRoot(), 'bin', flutterBin);
    runCommand(<String>[flutterPath, 'pub', 'get']);

    // Generate lib/l10n/app_localizations.dart
    final String genL10nPath = globals.fs.path.join(getFlutterRoot(), 'dev', 'tools', 'localization', 'bin', 'gen_l10n.dart');
    final String dartBin = globals.platform.isWindows ? 'dart.exe' : 'dart';
    final String dartPath = globals.fs.path.join(getFlutterRoot(), 'bin', 'cache', 'dart-sdk', 'bin', dartBin);
    runCommand(<String>[dartPath, genL10nPath]);

    // Run the app defined in GenL10nProject.main and wait for it to
    // send '#l10n END' to its stdout.
    final Completer<void> l10nEnd = Completer<void>();
    final StringBuffer stdout = StringBuffer();
    final StreamSubscription<String> subscription = _flutter.stdout.listen((String line) {
      if (line.contains('#l10n')) {
        stdout.writeln(line.substring(line.indexOf('#l10n')));
      }
      if (line.contains('#l10n END')) {
        l10nEnd.complete();
      }
    });
    await _flutter.run();
    await l10nEnd.future;
    await subscription.cancel();
    expect(stdout.toString(),
      '#l10n 0 (--- supportedLocales tests ---)\n'
      '#l10n 1 (supportedLocales[0]: languageCode: en, countryCode: null, scriptCode: null)\n'
      '#l10n 2 (supportedLocales[1]: languageCode: en, countryCode: CA, scriptCode: null)\n'
      '#l10n 3 (supportedLocales[2]: languageCode: en, countryCode: GB, scriptCode: null)\n'
      '#l10n 4 (--- countryCode (en_CA) tests ---)\n'
      '#l10n 5 (CA Hello World)\n'
      '#l10n 6 (Hello CA fallback World)\n'
      '#l10n 7 (--- countryCode (en_GB) tests ---)\n'
      '#l10n 8 (GB Hello World)\n'
      '#l10n 9 (Hello GB fallback World)\n'
      '#l10n 10 (--- General formatting tests ---)\n'
      '#l10n 11 (Hello World)\n'
      '#l10n 12 (Hello _NEWLINE_ World)\n'
      '#l10n 13 (Hello World)\n'
      '#l10n 14 (Hello World)\n'
      '#l10n 15 (Hello World on Friday, January 1, 1960)\n'
      '#l10n 16 (Hello world argument on 1/1/1960 at 00:00)\n'
      '#l10n 17 (Hello World from 1960 to 2020)\n'
      '#l10n 18 (Hello for 123)\n'
      '#l10n 19 (Hello for price USD123.00)\n'
      '#l10n 20 (Hello)\n'
      '#l10n 21 (Hello World)\n'
      '#l10n 22 (Hello two worlds)\n'
      '#l10n 23 (Hello)\n'
      '#l10n 24 (Hello new World)\n'
      '#l10n 25 (Hello two new worlds)\n'
      '#l10n 26 (Hello on Friday, January 1, 1960)\n'
      '#l10n 27 (Hello World, on Friday, January 1, 1960)\n'
      '#l10n 28 (Hello two worlds, on Friday, January 1, 1960)\n'
      '#l10n 29 (Hello other 0 worlds, with a total of 100 citizens)\n'
      '#l10n 30 (Hello World of 101 citizens)\n'
      '#l10n 31 (Hello two worlds with 102 total citizens)\n'
      '#l10n 32 ([Hello] -World- #123#)\n'
      '#l10n 33 (Flutter\'s amazing!)\n'
      '#l10n 34 (Flutter is "amazing"!)\n'
      '#l10n END\n'
    );
  });
}
