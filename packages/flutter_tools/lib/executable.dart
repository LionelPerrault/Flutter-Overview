// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:intl/intl_standalone.dart' as intl;
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/artifacts.dart';
import 'src/base/common.dart';
import 'src/base/config.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/os.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/utils.dart';
import 'src/cache.dart';
import 'src/commands/analyze.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/drive.dart';
import 'src/commands/format.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/crash_reporting.dart';
import 'src/devfs.dart';
import 'src/device.dart';
import 'src/doctor.dart';
import 'src/globals.dart';
import 'src/ios/mac.dart';
import 'src/ios/simulators.dart';
import 'src/run_hot.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/usage.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<Null> main(List<String> args) async {
  final bool verbose = args.contains('-v') || args.contains('--verbose');
  final bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  final bool verboseHelp = help && verbose;

  await run(args, <FlutterCommand>[
    new AnalyzeCommand(verboseHelp: verboseHelp),
    new BuildCommand(verboseHelp: verboseHelp),
    new ChannelCommand(),
    new ConfigCommand(),
    new CreateCommand(),
    new DaemonCommand(hidden: !verboseHelp),
    new DevicesCommand(),
    new DoctorCommand(),
    new DriveCommand(),
    new FormatCommand(),
    new InstallCommand(),
    new LogsCommand(),
    new PackagesCommand(),
    new PrecacheCommand(),
    new RunCommand(verboseHelp: verboseHelp),
    new ScreenshotCommand(),
    new StopCommand(),
    new TestCommand(),
    new TraceCommand(),
    new UpdatePackagesCommand(hidden: !verboseHelp),
    new UpgradeCommand(),
  ], verbose: verbose, verboseHelp: verboseHelp);
}

Future<int> run(List<String> args, List<FlutterCommand> subCommands, {
  bool verbose: false,
  bool verboseHelp: false,
  bool reportCrashes,
  String flutterVersion,
}) async {
  reportCrashes ??= !isRunningOnBot;

  if (verboseHelp) {
    // Remove the verbose option; for help, users don't need to see verbose logs.
    args = new List<String>.from(args);
    args.removeWhere((String option) => option == '-v' || option == '--verbose');
  }

  final FlutterCommandRunner runner = new FlutterCommandRunner(verboseHelp: verboseHelp);
  subCommands.forEach(runner.addCommand);

  // Construct a context.
  final AppContext _executableContext = new AppContext();

  // Make the context current.
  return await _executableContext.runInZone(() async {
    // Initialize the context with some defaults.
    // NOTE: Similar lists also exist in `bin/fuchsia_builder.dart` and
    // `test/src/context.dart`. If you update this list of defaults, look
    // in those locations as well to see if you need a similar update there.

    // Seed these context entries first since others depend on them
    context.putIfAbsent(Platform, () => const LocalPlatform());
    context.putIfAbsent(FileSystem, () => const LocalFileSystem());
    context.putIfAbsent(ProcessManager, () => const LocalProcessManager());
    context.putIfAbsent(Logger, () => platform.isWindows ? new WindowsStdoutLogger() : new StdoutLogger());
    context.putIfAbsent(Config, () => new Config());

    // Order-independent context entries
    context.putIfAbsent(DeviceManager, () => new DeviceManager());
    context.putIfAbsent(DevFSConfig, () => new DevFSConfig());
    context.putIfAbsent(Doctor, () => new Doctor());
    context.putIfAbsent(HotRunnerConfig, () => new HotRunnerConfig());
    context.putIfAbsent(Cache, () => new Cache());
    context.putIfAbsent(Artifacts, () => new CachedArtifacts());
    context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
    context.putIfAbsent(Xcode, () => new Xcode());
    context.putIfAbsent(IOSSimulatorUtils, () => new IOSSimulatorUtils());
    context.putIfAbsent(SimControl, () => new SimControl());
    context.putIfAbsent(Usage, () => new Usage());

    // Initialize the system locale.
    await intl.findSystemLocale();

    final Completer<int> runCompleter = new Completer<int>();
    Chain.capture<Future<Null>>(() async {
      await runner.run(args);
      await _exit(0);
      runCompleter.complete(0);
    }, onError: (dynamic error, Chain chain) {
      flutterVersion ??= FlutterVersion.getVersionString();
      _handleToolError(error, chain, verbose, args, reportCrashes, flutterVersion)
          .then(runCompleter.complete, onError: runCompleter.completeError);
    });
    return runCompleter.future;
  });
}

Future<int> _handleToolError(
    dynamic error,
    Chain chain,
    bool verbose,
    List<String> args,
    bool reportCrashes,
    String flutterVersion,
) async {
  if (error is UsageException) {
    stderr.writeln(error.message);
    stderr.writeln();
    stderr.writeln(
        "Run 'flutter -h' (or 'flutter <command> -h') for available "
            "flutter commands and options."
    );
    // Argument error exit code.
    return _exit(64);
  } else if (error is ToolExit) {
    if (error.message != null)
      stderr.writeln(error.message);
    if (verbose) {
      stderr.writeln();
      stderr.writeln(chain.terse.toString());
      stderr.writeln();
    }
    return _exit(error.exitCode ?? 1);
  } else if (error is ProcessExit) {
    // We've caught an exit code.
    if (error.immediate) {
      exit(error.exitCode);
      return error.exitCode;
    } else {
      return _exit(error.exitCode);
    }
  } else {
    // We've crashed; emit a log report.
    stderr.writeln();

    flutterUsage.sendException(error, chain);

    if (!reportCrashes) {
      // Print the stack trace on the bots - don't write a crash report.
      stderr.writeln('$error');
      stderr.writeln(chain.terse.toString());
      return _exit(1);
    } else {
      if (error is String)
        stderr.writeln('Oops; flutter has exited unexpectedly: "$error".');
      else
        stderr.writeln('Oops; flutter has exited unexpectedly.');

      await CrashReportSender.instance.sendReport(
        error: error,
        stackTrace: chain,
        flutterVersion: flutterVersion,
      );
      try {
        final File file = await _createLocalCrashReport(args, error, chain);
        stderr.writeln(
            'Crash report written to ${file.path};\n'
                'please let us know at https://github.com/flutter/flutter/issues.',
        );
        return _exit(1);
      } catch (error) {
        stderr.writeln(
            'Unable to generate crash report due to secondary error: $error\n'
                'please let us know at https://github.com/flutter/flutter/issues.',
        );
        // Any exception throw here (including one thrown by `_exit()`) will
        // get caught by our zone's `onError` handler. In order to avoid an
        // infinite error loop, we throw an error that is recognized above
        // and will trigger an immediate exit.
        throw new ProcessExit(1, immediate: true);
      }
    }
  }
}

/// File system used by the crash reporting logic.
///
/// We do not want to use the file system stored in the context because it may
/// be recording. Additionally, in the case of a crash we do not trust the
/// integrity of the [AppContext].
@visibleForTesting
FileSystem crashFileSystem = new LocalFileSystem();

/// Saves the crash report to a local file.
Future<File> _createLocalCrashReport(List<String> args, dynamic error, Chain chain) async {
  File crashFile = getUniqueFile(crashFileSystem.currentDirectory, 'flutter', 'log');

  final StringBuffer buffer = new StringBuffer();

  buffer.writeln('Flutter crash report; please file at https://github.com/flutter/flutter/issues.\n');

  buffer.writeln('## command\n');
  buffer.writeln('flutter ${args.join(' ')}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('$error\n');
  buffer.writeln('```\n${chain.terse}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await _doctorText()}```');

  try {
    await crashFile.writeAsString(buffer.toString());
  } on FileSystemException catch (_) {
    // Fallback to the system temporary directory.
    crashFile = getUniqueFile(crashFileSystem.systemTempDirectory, 'flutter', 'log');
    try {
      await crashFile.writeAsString(buffer.toString());
    } on FileSystemException catch (e) {
      printError('Could not write crash report to disk: $e');
      printError(buffer.toString());
    }
  }

  return crashFile;
}

Future<String> _doctorText() async {
  try {
    final BufferLogger logger = new BufferLogger();
    final AppContext appContext = new AppContext();

    appContext.setVariable(Logger, logger);

    await appContext.runInZone(() => doctor.diagnose());

    return logger.statusText;
  } catch (error, trace) {
    return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
  }
}

Future<int> _exit(int code) async {
  if (flutterUsage.isFirstRun)
    flutterUsage.printUsage();

  // Send any last analytics calls that are in progress without overly delaying
  // the tool's exit (we wait a maximum of 250ms).
  if (flutterUsage.enabled) {
    final Stopwatch stopwatch = new Stopwatch()..start();
    await flutterUsage.ensureAnalyticsSent();
    printTrace('ensureAnalyticsSent: ${stopwatch.elapsedMilliseconds}ms');
  }

  // Run shutdown hooks before flushing logs
  await runShutdownHooks();

  final Completer<Null> completer = new Completer<Null>();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    try {
      printTrace('exiting with code $code');
      exit(code);
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  });

  await completer.future;
  return code;
}
