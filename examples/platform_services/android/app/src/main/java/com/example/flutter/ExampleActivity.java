// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.os.BatteryManager;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.plugin.common.FlutterMethodChannel.MethodCallHandler;
import io.flutter.plugin.common.FlutterMethodChannel.Response;
import io.flutter.plugin.common.MethodCall;

public class ExampleActivity extends FlutterActivity {
  private static final String CHANNEL = "battery";

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    new FlutterMethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
        new MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, Response response) {
            if (call.method.equals("getBatteryLevel")) {
              getBatteryLevel(response);
            } else {
              throw new IllegalArgumentException("Unknown method " + call.method);
            }
          }
    });
  }

  private void getBatteryLevel(Response response) {
    BatteryManager batteryManager = (BatteryManager) getSystemService(BATTERY_SERVICE);
    if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      response.success(batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY));
    } else {
      response.error("Not available", "Battery level not available.", null);
    }
  }
}
