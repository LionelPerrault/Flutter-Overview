// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

Future<int> _runPub(Directory directory, { bool upgrade: false }) async {
  int updateCount = 0;
  for (FileSystemEntity dir in directory.listSync()) {
    if (dir is Directory && FileSystemEntity.isFileSync(dir.path + Platform.pathSeparator + 'pubspec.yaml')) {
      updateCount++;
      await pubGet(directory: dir.path, upgrade: upgrade, checkLastModified: false);
    }
  }
  return updateCount;
}

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ hideCommand: false }) : _hideCommand = hideCommand {
    argParser.addFlag(
      'upgrade',
      help: 'Run "pub upgrade" rather than "pub get".',
      defaultsTo: false
    );
  }

  final String name = 'update-packages';
  final String description = 'Update the packages inside the Flutter repo.';

  bool get hidden => _hideCommand;
  final bool _hideCommand;

  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    Stopwatch timer = new Stopwatch()..start();
    int count = 0;
    bool upgrade = argResults['upgrade'];
    count += await _runPub(new Directory("${ArtifactStore.flutterRoot}/packages"), upgrade: upgrade);
    count += await _runPub(new Directory("${ArtifactStore.flutterRoot}/examples"), upgrade: upgrade);
    printStatus('Ran "pub" $count time${count == 1 ? "" : "s"} in ${timer.elapsedMilliseconds} ms');
    return 0;
  }
}
