// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand {
  final String name = 'install';
  final String description = 'Install a Flutter app on an attached device.';

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackages();

    Device device = deviceForCommand;
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);

    printStatus('Installing $package to $device...');

    return installApp(device, package) ? 0 : 2;
  }
}

bool installApp(Device device, ApplicationPackage package) {
  if (package == null)
    return false;

  if (device.isAppInstalled(package))
    return true;

  return device.installApp(package);
}
