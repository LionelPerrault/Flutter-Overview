// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/utils.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  @override
  final List<String> aliases = <String>['list'];

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    if (!doctor.canListAnything) {
      printError("Unable to locate a development device; please run 'flutter doctor' for "
        "information about installing additional components.");
      return 1;
    }

    List<Device> devices = await deviceManager.getAllConnectedDevices();

    if (devices.isEmpty) {
      printStatus('No connected devices.');
    } else {
      printStatus('${devices.length} connected ${pluralize('device', devices.length)}:\n');
      Device.printDevices(devices);
    }

    return 0;
  }
}
