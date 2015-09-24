// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.run_mojo;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts.dart';
import 'process.dart';

final Logger _logging = new Logger('sky_tools.run_mojo');

class RunMojoCommand extends Command {
  final name = 'run_mojo';
  final description = 'Run a Flutter app in mojo.';
  RunMojoCommand() {
    argParser.addFlag('android', negatable: false, help: 'Run on an Android device');
    argParser.addOption('app', defaultsTo: 'app.flx');
    argParser.addOption('mojo-path', help: 'Path to directory containing mojo_shell and services');
    argParser.addOption('package-root', defaultsTo: 'packages');
  }

  Future<String> _makePathAbsolute(String relativePath) async {
    File file = new File(relativePath);
    if (!await file.exists()) {
      throw new Exception("Path \"${relativePath}\" does not exist");
    }
    return file.absolute.path;
  }

  Future<int> _runAndroid(ArgResults results, String appPath, ArtifactStore artifacts) async {
    String skyViewerUrl = artifacts.googleStorageUrl('viewer', 'android-arm');
    String command = await _makePathAbsolute(path.join(results['mojo-path'], 'mojo', 'devtools', 'common', 'mojo_run'));
    String appName = path.basename(appPath);
    String appDir = path.dirname(appPath);
    List<String> args = [
      '--android',
      '--release',
      'http://app/$appName',
      '--map-origin=http://app/=$appDir',
      '--map-origin=http://sky_viewer/=$skyViewerUrl',
      '--url-mappings=mojo:sky_viewer=http://sky_viewer/sky_viewer.mojo',
    ];
    if (_logging.level <= Level.INFO) {
      args.add('--verbose');
      if (_logging.level <= Level.FINE) {
        args.add('--verbose');
      }
    }
    args.addAll(results.rest);
    return runCommandAndStreamOutput(command, args);
  }

  Future<int> _runLinux(ArgResults results, String appPath, ArtifactStore artifacts) async {
    String viewerPath = await _makePathAbsolute(await artifacts.getPath(Artifact.SkyViewerMojo));
    String mojoShellPath = await _makePathAbsolute(path.join(results['mojo-path'], 'out', 'Release', 'mojo_shell'));
    List<String> args = [
      'file://${appPath}',
      '--url-mappings=mojo:sky_viewer=file://${viewerPath}'
    ];
    args.addAll(results.rest);
    return runCommandAndStreamOutput(mojoShellPath, args);
  }

  @override
  Future<int> run() async {
    if (argResults['mojo-path'] == null) {
      _logging.severe('Must specify --mojo-path to mojo_run');
      return 1;
    }
    String packageRoot = argResults['package-root'];
    ArtifactStore artifacts = new ArtifactStore(packageRoot);
    String appPath = await _makePathAbsolute(argResults['app']);
    if (argResults['android']) {
      return _runAndroid(argResults, appPath, artifacts);
    } else {
      return _runLinux(argResults, appPath, artifacts);
    }
  }
}
