// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/install.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('install', () {
    testUsingContext('returns 0 when Android is connected and ready for an install', () {
      InstallCommand command = new InstallCommand();
      applyMocksToCommand(command);

      MockAndroidDevice device = new MockAndroidDevice();
      when(device.isAppInstalled(any)).thenReturn(false);
      when(device.installApp(any)).thenReturn(true);
      testDeviceManager.addDevice(device);

      return createTestCommandRunner(command).run(<String>['install']).then((int code) {
        expect(code, 0);
      });
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () {
      InstallCommand command = new InstallCommand();
      applyMocksToCommand(command);

      MockIOSDevice device = new MockIOSDevice();
      when(device.isAppInstalled(any)).thenReturn(false);
      when(device.installApp(any)).thenReturn(true);
      testDeviceManager.addDevice(device);

      return createTestCommandRunner(command).run(<String>['install']).then((int code) {
        expect(code, 0);
      });
    });
  });
}
