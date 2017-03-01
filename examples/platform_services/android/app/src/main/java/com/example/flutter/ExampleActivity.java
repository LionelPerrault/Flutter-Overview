// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.plugin.common.FlutterMethodChannel.MethodCallHandler;
import io.flutter.plugin.common.FlutterMethodChannel.Response;
import io.flutter.plugin.common.MethodCall;
import io.flutter.view.FlutterView;

public class ExampleActivity extends FlutterActivity {
    private FlutterView flutterView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        new FlutterMethodChannel(getFlutterView(), "geo").setMethodCallHandler(new MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall call, Response response) {
                if (call.method.equals("getLocation")) {
                    if (!(call.arguments instanceof String)) {
                        throw new IllegalArgumentException("Invalid argument type, String expected");
                    }
                    getLocation((String) call.arguments, response);
                } else {
                    throw new IllegalArgumentException("Unknown method " + call.method);
                }
            }
        });
    }

    private void getLocation(String provider, Response response) {
        String locationProvider;
        if (provider.equals("network")) {
            locationProvider = LocationManager.NETWORK_PROVIDER;
        } else if (provider.equals("gps")) {
            locationProvider = LocationManager.GPS_PROVIDER;
        } else {
            throw new IllegalArgumentException("Unknown provider " + provider);
        }
        String permission = "android.permission.ACCESS_FINE_LOCATION";
        if (checkCallingOrSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            Location location = locationManager.getLastKnownLocation(locationProvider);
            if (location != null) {
                response.success(new double[] { location.getLatitude(), location.getLongitude() });
            } else {
                response.error("unknown", "Location unknown", null);
            }
        } else {
            response.error("permission", "Access denied", null);
        }
    }
}
