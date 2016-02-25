// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:den_api/den_api.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class AnalyzeCommand extends FlutterCommand {
  String get name => 'analyze';
  String get description => 'Analyze the project\'s Dart code.';

  AnalyzeCommand() {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('preamble', help: 'Display the number of files that will be analyzed.', defaultsTo: true);
    argParser.addFlag('congratulate', help: 'Show output even when there are no errors, warnings, hints, or lints.', defaultsTo: true);
  }

  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    Stopwatch stopwatch = new Stopwatch()..start();
    Set<String> pubSpecDirectories = new HashSet<String>();
    List<String> dartFiles = argResults.rest.toList();

    bool foundAnyInCurrentDirectory = false;
    bool foundAnyInFlutterRepo = false;

    for (String file in dartFiles) {
      file = path.normalize(path.absolute(file));
      String root = path.rootPrefix(file);
      while (file != root) {
        file = path.dirname(file);
        if (FileSystemEntity.isFileSync(path.join(file, 'pubspec.yaml'))) {
          pubSpecDirectories.add(file);
          if (file == path.normalize(path.absolute(ArtifactStore.flutterRoot))) {
            foundAnyInFlutterRepo = true;
          } else if (file == path.normalize(path.absolute(path.current))) {
            foundAnyInCurrentDirectory = true;
          }
          break;
        }
      }
    }

    if (argResults['flutter-repo']) {
      // .../examples/*/*.dart
      // .../examples/*/lib/main.dart
      Directory examples = new Directory(path.join(ArtifactStore.flutterRoot, 'examples'));
      for (FileSystemEntity entry in examples.listSync()) {
        if (entry is Directory) {
          bool foundOne = false;
          for (FileSystemEntity subentry in entry.listSync()) {
            if (subentry is File && subentry.path.endsWith('.dart')) {
              dartFiles.add(subentry.path);
              foundOne = true;
            } else if (subentry is Directory && path.basename(subentry.path) == 'lib') {
              String mainPath = path.join(subentry.path, 'main.dart');
              if (FileSystemEntity.isFileSync(mainPath)) {
                dartFiles.add(mainPath);
                foundOne = true;
              }
            }
          }
          if (foundOne)
            pubSpecDirectories.add(entry.path);
        }
      }

      // .../packages/*/bin/*.dart
      // .../packages/*/lib/main.dart
      // .../packages/*/test/*_test.dart
      // .../packages/*/test/*/*_test.dart
      // .../packages/*/benchmark/*/*_bench.dart
      Directory packages = new Directory(path.join(ArtifactStore.flutterRoot, 'packages'));
      for (FileSystemEntity entry in packages.listSync()) {
        if (entry is Directory) {
          bool foundOne = false;

          Directory binDirectory = new Directory(path.join(entry.path, 'bin'));
          if (binDirectory.existsSync()) {
            for (FileSystemEntity subentry in binDirectory.listSync()) {
              if (subentry is File && subentry.path.endsWith('.dart')) {
                dartFiles.add(subentry.path);
                foundOne = true;
              }
            }
          }

          String mainPath = path.join(entry.path, 'lib', 'main.dart');
          if (FileSystemEntity.isFileSync(mainPath)) {
            dartFiles.add(mainPath);
            foundOne = true;
          }

          Directory testDirectory = new Directory(path.join(entry.path, 'test'));
          if (testDirectory.existsSync()) {
            for (FileSystemEntity entry in testDirectory.listSync()) {
              if (entry is Directory) {
                for (FileSystemEntity subentry in entry.listSync()) {
                  if (subentry is File && subentry.path.endsWith('_test.dart')) {
                    dartFiles.add(subentry.path);
                    foundOne = true;
                  }
                }
              } else if (entry is File && entry.path.endsWith('_test.dart')) {
                dartFiles.add(entry.path);
                foundOne = true;
              }
            }
          }

          Directory benchmarkDirectory = new Directory(path.join(entry.path, 'benchmark'));
          if (benchmarkDirectory.existsSync()) {
            for (FileSystemEntity entry in benchmarkDirectory.listSync()) {
              if (entry is Directory) {
                for (FileSystemEntity subentry in entry.listSync()) {
                  if (subentry is File && subentry.path.endsWith('_bench.dart')) {
                    dartFiles.add(subentry.path);
                    foundOne = true;
                  }
                }
              } else if (entry is File && entry.path.endsWith('_bench.dart')) {
                dartFiles.add(entry.path);
                foundOne = true;
              }
            }
          }

          if (foundOne)
            pubSpecDirectories.add(entry.path);
        }
      }
    }

    if (argResults['current-directory']) {
      // ./*.dart
      Directory currentDirectory = new Directory('.');
      bool foundOne = false;
      for (FileSystemEntity entry in currentDirectory.listSync()) {
        if (entry is File && entry.path.endsWith('.dart')) {
          dartFiles.add(entry.path);
          foundOne = true;
        }
      }
      if (foundOne) {
        pubSpecDirectories.add('.');
        foundAnyInCurrentDirectory = true;
      }
    }

    if (argResults['current-package']) {
      // ./lib/main.dart
      String mainPath = 'lib/main.dart';
      if (FileSystemEntity.isFileSync(mainPath)) {
        dartFiles.add(mainPath);
        pubSpecDirectories.add('.');
        foundAnyInCurrentDirectory = true;
      }
    }

    // prepare a Dart file that references all the above Dart files
    StringBuffer mainBody = new StringBuffer();
    for (int index = 0; index < dartFiles.length; index += 1)
      mainBody.writeln('import \'${path.normalize(path.absolute(dartFiles[index]))}\' as file$index;');
    mainBody.writeln('void main() { }');

    // prepare a union of all the .packages files
    Map<String, String> packages = <String, String>{};
    bool hadInconsistentRequirements = false;
    for (Directory directory in pubSpecDirectories.map((path) => new Directory(path))) {
      String pubSpecYamlPath = path.join(directory.path, 'pubspec.yaml');
      File pubSpecYamlFile = new File(pubSpecYamlPath);
      if (pubSpecYamlFile.existsSync()) {
        Pubspec pubSpecYaml = await Pubspec.load(pubSpecYamlPath);
        String packageName = pubSpecYaml.name;
        String packagePath = path.normalize(path.absolute(path.join(directory.path, 'lib')));
        if (packages.containsKey(packageName) && packages[packageName] != packagePath) {
          printError('Inconsistent requirements for $packageName; using $packagePath (and not ${packages[packageName]}).');
          hadInconsistentRequirements = true;
        }
        packages[packageName] = packagePath;
      }
      File dotPackages = new File(path.join(directory.path, '.packages'));
      if (dotPackages.existsSync()) {
        Map<String, String> dependencies = <String, String>{};
        dotPackages
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.startsWith(new RegExp(r'^ *#')))
          .forEach((line) {
            int colon = line.indexOf(':');
            if (colon > 0)
              dependencies[line.substring(0, colon)] = path.normalize(path.absolute(directory.path, path.fromUri(line.substring(colon+1))));
          });
        for (String package in dependencies.keys) {
          if (packages.containsKey(package)) {
            if (packages[package] != dependencies[package]) {
              printError('Inconsistent requirements for $package; using ${packages[package]} (and not ${dependencies[package]}).');
              hadInconsistentRequirements = true;
            }
          } else {
            packages[package] = dependencies[package];
          }
        }
      }
    }
    if (hadInconsistentRequirements) {
      if (foundAnyInFlutterRepo)
        printError('You may need to run "dart ${path.normalize(path.relative(path.join(ArtifactStore.flutterRoot, 'dev/update_packages.dart')))} --upgrade".');
      if (foundAnyInCurrentDirectory)
        printError('You may need to run "pub upgrade".');
    }

    String buildDir = buildConfigurations.firstWhere((BuildConfiguration config) => config.testable, orElse: () => null)?.buildDir;
    if (buildDir != null) {
      packages['sky_engine'] = path.join(buildDir, 'gen/dart-pkg/sky_engine/lib');
      packages['sky_services'] = path.join(buildDir, 'gen/dart-pkg/sky_services/lib');
    }

    StringBuffer packagesBody = new StringBuffer();
    for (String package in packages.keys)
      packagesBody.writeln('$package:${path.toUri(packages[package])}');

    /// specify analysis options
    /// note that until there is a default "all-in" lint rule-set we need
    /// to opt-in to all desired lints (https://github.com/dart-lang/sdk/issues/25843)
    String optionsBody = '''
analyzer:
  errors:
    # we allow overriding fields (if they use super, ideally...)
    strong_mode_invalid_field_override: ignore
    # we allow type narrowing
    strong_mode_invalid_method_override: ignore
    todo: ignore
linter:
  rules:
    - camel_case_types
    # sometimes we have no choice (e.g. when matching other platforms)
    # - constant_identifier_names
    - empty_constructor_bodies
    # disabled until regexp fix is pulled in (https://github.com/flutter/flutter/pull/1996)
    # - library_names
    - library_prefixes
    - non_constant_identifier_names
    # too many false-positives; code review should catch real instances
    # - one_member_abstracts
    - slash_for_doc_comments
    - super_goes_last
    - type_init_formals
    - unnecessary_brace_in_string_interp
''';

    // save the Dart file and the .packages file to disk
    Directory host = Directory.systemTemp.createTempSync('flutter-analyze-');
    File mainFile = new File(path.join(host.path, 'main.dart'))..writeAsStringSync(mainBody.toString());
    File optionsFile = new File(path.join(host.path, '_analysis.options'))..writeAsStringSync(optionsBody.toString());
    File packagesFile = new File(path.join(host.path, '.packages'))..writeAsStringSync(packagesBody.toString());

    List<String> cmd = <String>[
      sdkBinaryName('dartanalyzer'),
      // do not set '--warnings', since that will include the entire Dart SDK
      '--ignore-unrecognized-flags',
      '--supermixin',
      '--enable-strict-call-checks',
      '--enable_type_checks',
      '--strong',
      '--package-warnings',
      '--fatal-warnings',
      '--strong-hints',
      '--fatal-hints',
      // defines lints
      '--options', optionsFile.path,
      '--packages', packagesFile.path,
      mainFile.path
    ];

    if (argResults['preamble']) {
      if (dartFiles.length == 1) {
        printStatus('Analyzing ${dartFiles.first}...');
      } else {
        printStatus('Analyzing ${dartFiles.length} files...');
      }
    }

    Process process = await Process.start(
      cmd[0],
      cmd.sublist(1),
      workingDirectory: host.path
    );
    int errorCount = 0;
    StringBuffer output = new StringBuffer();
    process.stdout.transform(UTF8.decoder).listen((String data) {
      output.write(data);
    });
    process.stderr.transform(UTF8.decoder).listen((String data) {
      // dartanalyzer doesn't seem to ever output anything on stderr
      errorCount += 1;
      printError(data);
    });

    int exitCode = await process.exitCode;

    host.deleteSync(recursive: true);

    List<Pattern> patternsToSkip = <Pattern>[
      'Analyzing [${mainFile.path}]...',
      new RegExp('^\\[(hint|error)\\] Unused import \\(${mainFile.path},'),
      new RegExp(r'^\[.+\] .+ \(.+/\.pub-cache/.+'),
      new RegExp('^\\[error\\] The argument type \'List<T>\' cannot be assigned to the parameter type \'List<.+>\''), // until we have generic methods, there's not much choice if you want to use map()
      new RegExp(r'^\[error\] Type check failed: .*\(dynamic\) is not of type'), // allow unchecked casts from dynamic
      //new RegExp('\\[warning\\] Missing concrete implementation of \'RenderObject\\.applyPaintTransform\''), // https://github.com/dart-lang/sdk/issues/25232
      new RegExp(r'[0-9]+ (error|warning|hint|lint).+found\.'),
      new RegExp(r'^$'),
    ];

    RegExp generalPattern = new RegExp(r'^\[(error|warning|hint|lint)\] (.+) \(([^(),]+), line ([0-9]+), col ([0-9]+)\)$');
    RegExp allowedIdentifiersPattern = new RegExp(r'_?([A-Z]|_+)\b');
    RegExp constructorTearOffsPattern = new RegExp('.+#.+// analyzer doesn\'t like constructor tear-offs');
    RegExp ignorePattern = new RegExp(r'// analyzer says "([^"]+)"');

    List<String> errorLines = output.toString().split('\n');
    for (String errorLine in errorLines) {
      if (patternsToSkip.every((Pattern pattern) => pattern.allMatches(errorLine).isEmpty)) {
        Match groups = generalPattern.firstMatch(errorLine);
        if (groups != null) {
          String level = groups[1];
          String filename = groups[3];
          String errorMessage = groups[2];
          int lineNumber = int.parse(groups[4]);
          int colNumber = int.parse(groups[5]);
          File source = new File(filename);
          List<String> sourceLines = source.readAsLinesSync();
          String sourceLine = (lineNumber < sourceLines.length) ? sourceLines[lineNumber-1] : '';
          bool shouldIgnore = false;
          if (filename.endsWith('.mojom.dart')) {
            // autogenerated code - TODO(ianh): Fix the Dart mojom compiler
            shouldIgnore = true;
          } else if ((sourceLines[0] == '/**') && (' * DO NOT EDIT. This is code generated'.matchAsPrefix(sourceLines[1]) != null)) {
            // autogenerated code - TODO(ianh): Fix the intl package resource generator
            shouldIgnore = true;
          } else if (level == 'lint' && errorMessage == 'Name non-constant identifiers using lowerCamelCase.') {
            if (allowedIdentifiersPattern.matchAsPrefix(sourceLine, colNumber-1) != null)
              shouldIgnore = true;
          } else if (constructorTearOffsPattern.allMatches(sourceLine).isNotEmpty) {
            shouldIgnore = true;
          } else {
            Iterable<Match> ignoreGroups = ignorePattern.allMatches(sourceLine);
            for (Match ignoreGroup in ignoreGroups) {
              if (errorMessage.contains(ignoreGroup[1])) {
                shouldIgnore = true;
                break;
              }
            }
          }
          if (shouldIgnore)
            continue;
        }
        printError(errorLine);
        errorCount += 1;
      }
    }
    stopwatch.stop();
    String elapsed = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

    if (exitCode < 0 || exitCode > 3) // 0 = nothing, 1 = hints, 2 = warnings, 3 = errors
      return exitCode;

    if (errorCount > 0)
      return 1; // Doesn't this mean 'hints' per the above comment?
    if (argResults['congratulate'])
      printStatus('No analyzer warnings! (ran in ${elapsed}s)');
    return 0;
  }
}
