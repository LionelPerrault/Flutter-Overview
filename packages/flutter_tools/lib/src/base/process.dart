// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'context.dart';

/// This runs the command and streams stdout/stderr from the child process to
/// this process' stdout/stderr.
Future<int> runCommandAndStreamOutput(List<String> cmd, {
  String prefix: '',
  RegExp filter,
  String workingDirectory
}) async {
  printTrace(cmd.join(' '));
  Process process = await Process.start(
    cmd[0],
    cmd.sublist(1),
    workingDirectory: workingDirectory
  );
  process.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .where((String line) => filter == null ? true : filter.hasMatch(line))
    .listen((String line) {
      printStatus('$prefix$line');
    });
  process.stderr
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .where((String line) => filter == null ? true : filter.hasMatch(line))
    .listen((String line) {
      printError('$prefix$line');
    });
  return await process.exitCode;
}

Future runAndKill(List<String> cmd, Duration timeout) {
  Future<Process> proc = runDetached(cmd);
  return new Future.delayed(timeout, () async {
    printTrace('Intentionally killing ${cmd[0]}');
    Process.killPid((await proc).pid);
  });
}

Future<Process> runDetached(List<String> cmd) {
  printTrace(cmd.join(' '));
  Future<Process> proc = Process.start(
      cmd[0], cmd.getRange(1, cmd.length).toList(),
      mode: ProcessStartMode.DETACHED);
  return proc;
}

/// Run cmd and return stdout.
/// Throws an error if cmd exits with a non-zero value.
String runCheckedSync(List<String> cmd, { String workingDirectory }) {
  return _runWithLoggingSync(cmd, workingDirectory: workingDirectory, checked: true);
}

/// Run cmd and return stdout.
String runSync(List<String> cmd, { String workingDirectory }) {
  return _runWithLoggingSync(cmd, workingDirectory: workingDirectory);
}

/// Return the platform specific name for the given Dart SDK binary. So, `pub`
/// ==> `pub.bat`.
String sdkBinaryName(String name) {
  return Platform.isWindows ? '$name.bat' : name;
}

String _runWithLoggingSync(List<String> cmd, {
  bool checked: false,
  String workingDirectory
}) {
  printTrace(cmd.join(' '));
  ProcessResult results =
      Process.runSync(cmd[0], cmd.getRange(1, cmd.length).toList(), workingDirectory: workingDirectory);
  if (results.exitCode != 0) {
    String errorDescription = 'Error code ${results.exitCode} '
        'returned when attempting to run command: ${cmd.join(' ')}';
    printTrace(errorDescription);
    if (results.stderr.length > 0)
      printTrace('Errors logged: ${results.stderr.trim()}');
    if (checked)
      throw errorDescription;
  }
  if (results.stdout.trim().isNotEmpty)
    printTrace(results.stdout.trim());
  return results.stdout;
}

class ProcessExit implements Exception {
  final int exitCode;
  ProcessExit(this.exitCode);
  String get message => 'ProcessExit: $exitCode';
  String toString() => message;
}
