// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.flutter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import io.flutter.app.FlutterActivity;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterView;

import java.io.File;
import org.json.JSONException;
import org.json.JSONObject;

public class ExampleActivity extends FlutterActivity {
    private static final String TAG = "ExampleActivity";
    private FlutterView flutterView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        flutterView = getFlutterView();
        flutterView.addOnMessageListener("getLocation",
            new FlutterView.OnMessageListener() {
                @Override
                public String onMessage(FlutterView view, String message) {
                    return onGetLocation(message);
                }
            });
    }

    private String onGetLocation(String json) {
        String provider;
        try {
            JSONObject message = new JSONObject(json);
            provider = message.getString("provider");
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return null;
        }

        String locationProvider;
        if (provider.equals("network")) {
            locationProvider = LocationManager.NETWORK_PROVIDER;
        } else if (provider.equals("gps")) {
            locationProvider = LocationManager.GPS_PROVIDER;
        } else {
            return null;
        }

        String permission = "android.permission.ACCESS_FINE_LOCATION";
        Location location = null;
        if (checkCallingOrSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            location = locationManager.getLastKnownLocation(locationProvider);
        }

        JSONObject reply = new JSONObject();
        try {
            if (location != null) {
              reply.put("latitude", location.getLatitude());
              reply.put("longitude", location.getLongitude());
            } else {
              reply.put("latitude", 0);
              reply.put("longitude", 0);
            }
        } catch (JSONException e) {
            Log.e(TAG, "JSON exception", e);
            return null;
        }

        return reply.toString();
    }
}