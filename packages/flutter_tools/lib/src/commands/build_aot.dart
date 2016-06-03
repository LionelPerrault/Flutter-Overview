// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../dart/sdk.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import 'run.dart';

const String _kDefaultAotOutputDir = 'build/aot';

// Files generated by the ahead-of-time snapshot builder.
const List<String> kAotSnapshotFiles = const <String>[
  'snapshot_aot_instr', 'snapshot_aot_isolate', 'snapshot_aot_rodata', 'snapshot_aot_vmisolate',
];

class BuildAotCommand extends FlutterCommand {
  BuildAotCommand() {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    argParser
      ..addOption('output-dir', defaultsTo: _kDefaultAotOutputDir)
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'ios']
      )
      ..addFlag('interpreter');
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<int> runInProject() async {
    String targetPlatform = argResults['target-platform'];
    TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null) {
      printError('Unknown platform: $targetPlatform');
      return 1;
    }

    String typeName = path.basename(tools.getEngineArtifactsDirectory(platform, getBuildMode()).path);
    Status status = logger.startProgress('Building AOT snapshot in ${getModeName(getBuildMode())} mode ($typeName)...');
    String outputPath = await buildAotSnapshot(
      findMainDartFile(argResults['target']),
      platform,
      getBuildMode(),
      outputPath: argResults['output-dir'],
      interpreter: argResults['interpreter']
    );
    status.stop(showElapsedTime: true);

    if (outputPath == null)
      return 1;

    printStatus('Built to $outputPath${Platform.pathSeparator}.');
    return 0;
  }
}

String _getSdkExtensionPath(String packagesPath, String package) {
  Directory packageDir = new Directory(path.join(packagesPath, package));
  return path.join(path.dirname(packageDir.resolveSymbolicLinksSync()), 'sdk_ext');
}

/// Build an AOT snapshot. Return `null` (and log to `printError`) if the method
/// fails.
Future<String> buildAotSnapshot(
  String mainPath,
  TargetPlatform platform,
  BuildMode buildMode, {
  String outputPath: _kDefaultAotOutputDir,
  bool interpreter: false
}) async {
  try {
    return _buildAotSnapshot(
      mainPath,
      platform,
      buildMode,
      outputPath: outputPath,
      interpreter: interpreter
    );
  } on String catch (error) {
    // Catch the String exceptions thrown from the `runCheckedSync` methods below.
    printError(error);
    return null;
  }
}

Future<String> _buildAotSnapshot(
  String mainPath,
  TargetPlatform platform,
  BuildMode buildMode, {
  String outputPath: _kDefaultAotOutputDir,
  bool interpreter: false
}) async {
  if (!isAotBuildMode(buildMode) && !interpreter) {
    printError('${toTitleCase(getModeName(buildMode))} mode does not support AOT compilation.');
    return null;
  }

  if (platform != TargetPlatform.android_arm && platform != TargetPlatform.ios) {
    printError('${getNameForTargetPlatform(platform)} does not support AOT compilation.');
    return null;
  }

  String entryPointsDir, dartEntryPointsDir, genSnapshot;

  String engineSrc = tools.engineSrcPath;
  if (engineSrc != null) {
    entryPointsDir  = path.join(engineSrc, 'sky', 'engine', 'bindings');
    dartEntryPointsDir = path.join(engineSrc, 'dart', 'runtime', 'bin');
    String engineOut = tools.getEngineArtifactsDirectory(platform, buildMode).path;
    if (platform == TargetPlatform.ios) {
      genSnapshot = path.join(engineOut, 'clang_x64', 'gen_snapshot');
    } else {
      String host32BitToolchain = getCurrentHostPlatform() == HostPlatform.darwin_x64 ? 'clang_i386' : 'clang_x86';
      genSnapshot = path.join(engineOut, host32BitToolchain, 'gen_snapshot');
    }
  } else {
    String artifactsDir = tools.getEngineArtifactsDirectory(platform, buildMode).path;
    entryPointsDir = artifactsDir;
    dartEntryPointsDir = entryPointsDir;
    if (platform == TargetPlatform.ios) {
      genSnapshot = path.join(artifactsDir, 'gen_snapshot');
    } else {
      String hostToolsDir = path.join(artifactsDir, getNameForHostPlatform(getCurrentHostPlatform()));
      genSnapshot = path.join(hostToolsDir, 'gen_snapshot');
    }
  }

  Directory outputDir = new Directory(outputPath);
  outputDir.createSync(recursive: true);
  String vmIsolateSnapshot = path.join(outputDir.path, 'snapshot_aot_vmisolate');
  String isolateSnapshot = path.join(outputDir.path, 'snapshot_aot_isolate');
  String instructionsBlob = path.join(outputDir.path, 'snapshot_aot_instr');
  String rodataBlob = path.join(outputDir.path, 'snapshot_aot_rodata');

  String vmEntryPoints = path.join(entryPointsDir, 'dart_vm_entry_points.txt');
  String ioEntryPoints = path.join(dartEntryPointsDir, 'dart_io_entries.txt');

  String packagesPath = path.absolute(Directory.current.path, 'packages');
  if (!FileSystemEntity.isDirectorySync(packagesPath)) {
    printStatus('Missing packages directory; running `pub get` (to work around https://github.com/dart-lang/sdk/issues/26362).');
    // We don't use [pubGet] because we explicitly want to avoid --no-package-symlinks.
    runCheckedSync(<String>[sdkBinaryName('pub'), 'get', '--no-precompile']);
  }
  if (!FileSystemEntity.isDirectorySync(packagesPath)) {
    printError('Could not find packages directory: $packagesPath\n' +
               'Did you run `pub get` in this directory?');
    printError('This is needed to work around ' +
               'https://github.com/dart-lang/sdk/issues/26362');
    return null;
  }

  String mojoSdkExt = _getSdkExtensionPath(packagesPath, 'mojo');
  String mojoInternalPath = path.join(mojoSdkExt, 'internal.dart');

  String skyEngineSdkExt = _getSdkExtensionPath(packagesPath, 'sky_engine');
  String uiPath = path.join(skyEngineSdkExt, 'dart_ui.dart');
  String jniPath = path.join(skyEngineSdkExt, 'dart_jni', 'jni.dart');
  String vmServicePath = path.join(skyEngineSdkExt, 'dart', 'runtime', 'bin', 'vmservice', 'vmservice_io.dart');

  List<String> filePaths = <String>[
    genSnapshot,
    vmEntryPoints,
    ioEntryPoints,
    mojoInternalPath,
    uiPath,
    jniPath,
    vmServicePath,
  ];

  // These paths are used only on Android.
  String vmEntryPointsAndroid;

  // These paths are used only on iOS.
  String snapshotDartIOS;
  String assembly;

  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      vmEntryPointsAndroid = path.join(entryPointsDir, 'dart_vm_entry_points_android.txt');
      filePaths.addAll(<String>[
        vmEntryPointsAndroid,
      ]);
      break;
    case TargetPlatform.ios:
      snapshotDartIOS = path.join(entryPointsDir, 'snapshot.dart');
      assembly = path.join(outputDir.path, 'snapshot_assembly.S');
      filePaths.addAll(<String>[
        snapshotDartIOS,
      ]);
      break;
    case TargetPlatform.darwin_x64:
    case TargetPlatform.linux_x64:
      assert(false);
  }

  List<String> missingFiles = filePaths.where((String p) => !FileSystemEntity.isFileSync(p)).toList();
  if (missingFiles.isNotEmpty) {
    printError('Missing files: $missingFiles');
    return null;
  }

  List<String> genSnapshotCmd = <String>[
    genSnapshot,
    '--vm_isolate_snapshot=$vmIsolateSnapshot',
    '--isolate_snapshot=$isolateSnapshot',
    '--package_root=$packagesPath',
    '--url_mapping=dart:mojo.internal,$mojoInternalPath',
    '--url_mapping=dart:ui,$uiPath',
    '--url_mapping=dart:jni,$jniPath',
    '--url_mapping=dart:vmservice_sky,$vmServicePath',
  ];

  if (!interpreter) {
    genSnapshotCmd.add('--embedder_entry_points_manifest=$vmEntryPoints');
    genSnapshotCmd.add('--embedder_entry_points_manifest=$ioEntryPoints');
  }

  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      genSnapshotCmd.addAll(<String>[
        '--rodata_blob=$rodataBlob',
        '--instructions_blob=$instructionsBlob',
        '--embedder_entry_points_manifest=$vmEntryPointsAndroid',
        '--no-sim-use-hardfp',
      ]);
      break;
    case TargetPlatform.ios:
      genSnapshotCmd.add(interpreter ? snapshotDartIOS : '--assembly=$assembly');
      break;
    case TargetPlatform.darwin_x64:
    case TargetPlatform.linux_x64:
      assert(false);
  }

  if (buildMode != BuildMode.release) {
    genSnapshotCmd.addAll(<String>[
      '--no-checked',
      '--conditional_directives',
    ]);
  }

  genSnapshotCmd.add(mainPath);

  RunResult results = await runAsync(genSnapshotCmd);
  if (results.exitCode != 0) {
    printStatus(results.toString());
    return null;
  }

  // On iOS, we use Xcode to compile the snapshot into a dynamic library that the
  // end-developer can link into their app.
  if (platform == TargetPlatform.ios) {
    printStatus('Building app.so...');

    // These names are known to from the engine.
    const String kDartVmIsolateSnapshotBuffer = 'kDartVmIsolateSnapshotBuffer';
    const String kDartIsolateSnapshotBuffer = 'kDartIsolateSnapshotBuffer';

    runCheckedSync(<String>['mv', vmIsolateSnapshot, path.join(outputDir.path, kDartVmIsolateSnapshotBuffer)]);
    runCheckedSync(<String>['mv', isolateSnapshot, path.join(outputDir.path, kDartIsolateSnapshotBuffer)]);

    String kDartVmIsolateSnapshotBufferC = path.join(outputDir.path, '$kDartVmIsolateSnapshotBuffer.c');
    String kDartIsolateSnapshotBufferC = path.join(outputDir.path, '$kDartIsolateSnapshotBuffer.c');

    runCheckedSync(<String>[
      'xxd', '--include', kDartVmIsolateSnapshotBuffer, path.basename(kDartVmIsolateSnapshotBufferC)
    ], workingDirectory: outputDir.path);
    runCheckedSync(<String>[
      'xxd', '--include', kDartIsolateSnapshotBuffer, path.basename(kDartIsolateSnapshotBufferC)
    ], workingDirectory: outputDir.path);

    String assemblyO = path.join(outputDir.path, 'snapshot_assembly.o');
    String kDartVmIsolateSnapshotBufferO = path.join(outputDir.path, '$kDartVmIsolateSnapshotBuffer.o');
    String kDartIsolateSnapshotBufferO = path.join(outputDir.path, '$kDartIsolateSnapshotBuffer.o');

    List<String> commonBuildOptions = <String>['-arch', 'arm64', '-miphoneos-version-min=8.0'];
    if (!interpreter)
      runCheckedSync(<String>['xcrun', 'cc']
        ..addAll(commonBuildOptions)
        ..addAll(<String>['-c', assembly, '-o', assemblyO]));
    runCheckedSync(<String>['xcrun', 'cc']
      ..addAll(commonBuildOptions)
      ..addAll(<String>['-c', kDartVmIsolateSnapshotBufferC, '-o', kDartVmIsolateSnapshotBufferO]));
    runCheckedSync(<String>['xcrun', 'cc']
      ..addAll(commonBuildOptions)
      ..addAll(<String>['-c', kDartIsolateSnapshotBufferC, '-o', kDartIsolateSnapshotBufferO]));

    String appSo = path.join(outputDir.path, 'app.so');

    List<String> linkCommand = <String>['xcrun', 'clang']
      ..addAll(commonBuildOptions)
      ..addAll(<String>[
        '-dynamiclib',
        '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
        '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
        '-install_name', '@rpath/app.so',
        '-o', appSo,
        kDartVmIsolateSnapshotBufferO,
        kDartIsolateSnapshotBufferO,
    ]);
    if (!interpreter)
      linkCommand.add(assemblyO);
    runCheckedSync(linkCommand);
  }

  return outputPath;
}
