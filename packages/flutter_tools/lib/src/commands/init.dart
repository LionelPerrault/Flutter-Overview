// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as p;

import '../artifacts.dart';
import '../process.dart';

class InitCommand extends Command {
  final String name = 'init';
  final String description = 'Create a new Flutter project.';

  InitCommand() {
    argParser.addOption('out', abbr: 'o', help: 'The output directory.');
    argParser.addFlag('pub',
        defaultsTo: true,
        help: 'Whether to run pub after the project has been created.');
  }

  @override
  Future<int> run() async {
    if (!argResults.wasParsed('out')) {
      print('No option specified for the output directory.');
      print(argParser.usage);
      return 2;
    }

    if (ArtifactStore.flutterRoot == null) {
      stderr.writeln('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment');
      stderr.writeln('variable was specified. Unable to find package:flutter.');
      return 2;
    }
    String flutterRoot = p.absolute(ArtifactStore.flutterRoot);

    String flutterPackagePath = p.join(flutterRoot, 'packages', 'flutter');
    if (!FileSystemEntity.isFileSync(p.join(flutterPackagePath, 'pubspec.yaml'))) {
      print('Unable to find package:flutter in ${flutterPackagePath}');
      return 2;
    }

    // TODO: Confirm overwrite of an existing directory with the user.
    Directory out = new Directory(argResults['out']);

    new FlutterSimpleTemplate().generateInto(out, flutterPackagePath);

    print('');

    String message = '''All done! To run your application:

  \$ cd ${out.path}
  \$ flutter start
''';

    if (argResults['pub']) {
      print("Running pub get...");
      int code = await runCommandAndStreamOutput(
        [sdkBinaryName('pub'), 'get'],
        workingDirectory: out.path
      );
      if (code != 0)
        return code;
    }

    print(message);
    return 0;
  }
}

abstract class Template {
  final String name;
  final String description;

  Map<String, String> files = {};

  Template(this.name, this.description);

  void generateInto(Directory dir, String flutterPackagePath) {
    String dirPath = p.normalize(dir.absolute.path);
    String projectName = _normalizeProjectName(p.basename(dirPath));
    print('Creating ${p.basename(projectName)}...');
    dir.createSync(recursive: true);

    String relativeFlutterPackagePath = p.relative(flutterPackagePath, from: dirPath);

    files.forEach((String path, String contents) {
      Map m = {'projectName': projectName, 'description': description, 'flutterPackagePath': relativeFlutterPackagePath};
      contents = mustache.render(contents, m);
      path = path.replaceAll('/', Platform.pathSeparator);
      File file = new File(p.join(dir.path, path));
      file.parent.createSync();
      file.writeAsStringSync(contents);
      print(file.path);
    });
  }

  String toString() => name;
}

class FlutterSimpleTemplate extends Template {
  FlutterSimpleTemplate() : super('flutter-simple', 'A minimal Flutter project.') {
    files['.gitignore'] = _gitignore;
    files['flutter.yaml'] = _flutterYaml;
    files['pubspec.yaml'] = _pubspec;
    files['README.md'] = _readme;
    files['lib/main.dart'] = _libMain;
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.'))
    name = name.substring(0, name.indexOf('.'));
  return name;
}

const String _gitignore = r'''
.DS_Store
.idea
.packages
.pub/
build/
packages
pubspec.lock
''';

const String _readme = r'''
# {{projectName}}

{{description}}

## Getting Started

For help getting started with Flutter, view our online
[documentation](http://flutter.io/).
''';

const String _pubspec = r'''
name: {{projectName}}
description: {{description}}
dependencies:
  flutter:
    path: {{flutterPackagePath}}
''';

const String _flutterYaml = r'''
name: {{projectName}}
material-design-icons:
  - name: content/add
''';

const String _libMain = r'''
import 'package:flutter/material.dart';

void main() {
  runApp(
    new MaterialApp(
      title: "Flutter Demo",
      routes: {
        '/': (RouteArguments args) => new FlutterDemo()
      }
    )
  );
}

class FlutterDemo extends StatelessComponent {
  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Flutter Demo")
      ),
      body: new Material(
        child: new Center(
          child: new Text("Hello world!")
        )
      ),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(
          icon: 'content/add'
        )
      )
    );
  }
}
''';
