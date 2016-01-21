// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../android/adb.dart';
import '../android/device_android.dart';
import '../base/logging.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import 'start.dart';
import 'stop.dart' as stop;

const String protocolVersion = '0.0.2';

// TODO(devoncarew): Pass logging data back to the client.

/// A server process command. This command will start up a long-lived server.
/// It reads JSON-RPC based commands from stdin, executes them, and returns
/// JSON-RPC based responses and events to stdout.
///
/// It can be shutdown with a `daemon.shutdown` command (or by killing the
/// process).
class DaemonCommand extends FlutterCommand {
  final String name = 'daemon';
  final String description = 'Run a persistent, JSON-RPC based server to communicate with devices.';

  Future<int> runInProject() async {
    print('Starting device daemon...');

    Stream<Map> commandStream = stdin
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
      .map((String line) {
        line = line.substring(1, line.length - 1);
        return JSON.decode(line);
      });

    await downloadApplicationPackagesAndConnectToDevices();

    Daemon daemon = new Daemon(commandStream, (Map command) {
      stdout.writeln('[${JSON.encode(command, toEncodable: _jsonEncodeObject)}]');
    }, daemonCommand: this);

    return await daemon.onExit;
  }

  dynamic _jsonEncodeObject(dynamic object) {
    if (object is Device)
      return _deviceToMap(object);

    return object;
  }
}

typedef void DispatchComand(Map<String, dynamic> command);

typedef Future<dynamic> CommandHandler(dynamic args);

class Daemon {
  Daemon(Stream<Map> commandStream, this.sendCommand, {this.daemonCommand}) {
    // Set up domains.
    _registerDomain(new DaemonDomain(this));
    _registerDomain(new AppDomain(this));
    _registerDomain(new DeviceDomain(this));

    // Start listening.
    commandStream.listen(
      (Map request) => _handleRequest(request),
      onDone: () => _onExitCompleter.complete(0)
    );
  }

  final DispatchComand sendCommand;
  final DaemonCommand daemonCommand;

  final Completer<int> _onExitCompleter = new Completer<int>();
  final Map<String, Domain> _domainMap = <String, Domain>{};

  void _registerDomain(Domain domain) {
    _domainMap[domain.name] = domain;
  }

  Future<int> get onExit => _onExitCompleter.future;

  void _handleRequest(Map request) {
    // {id, method, params}

    // [id] is an opaque type to us.
    dynamic id = request['id'];

    if (id == null) {
      logging.severe('no id for request: $request');
      return;
    }

    try {
      String method = request['method'];
      if (method.indexOf('.') == -1)
        throw 'method not understood: $method';

      String prefix = method.substring(0, method.indexOf('.'));
      String name = method.substring(method.indexOf('.') + 1);
      if (_domainMap[prefix] == null)
        throw 'no domain for method: $method';

      _domainMap[prefix].handleCommand(name, id, request['params']);
    } catch (error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      logging.warning('error handling $request', error, trace);
    }
  }

  void _send(Map map) => sendCommand(map);

  void shutdown() {
    _domainMap.values.forEach((Domain domain) => domain.dispose());
    if (!_onExitCompleter.isCompleted)
      _onExitCompleter.complete(0);
  }
}

abstract class Domain {
  Domain(this.daemon, this.name);

  final Daemon daemon;
  final String name;
  final Map<String, CommandHandler> _handlers = {};

  void registerHandler(String name, CommandHandler handler) {
    _handlers[name] = handler;
  }

  FlutterCommand get command => daemon.daemonCommand;

  String toString() => name;

  void handleCommand(String name, dynamic id, dynamic args) {
    new Future.sync(() {
      if (_handlers.containsKey(name))
        return _handlers[name](args);
      throw 'command not understood: $name';
    }).then((result) {
      if (result == null) {
        _send({'id': id});
      } else {
        _send({'id': id, 'result': _toJsonable(result)});
      }
    }).catchError((error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      logging.warning('error handling $name', error, trace);
    });
  }

  void sendEvent(String name, [dynamic args]) {
    Map<String, dynamic> map = { 'method': name };
    if (args != null)
      map['params'] = _toJsonable(args);
    _send(map);
  }

  void _send(Map map) => daemon._send(map);

  void dispose() { }
}

/// This domain responds to methods like [version] and [shutdown].
class DaemonDomain extends Domain {
  DaemonDomain(Daemon daemon) : super(daemon, 'daemon') {
    registerHandler('version', version);
    registerHandler('shutdown', shutdown);
  }

  Future<String> version(dynamic args) {
    return new Future.value(protocolVersion);
  }

  Future shutdown(dynamic args) {
    Timer.run(() => daemon.shutdown());
    return new Future.value();
  }
}

/// This domain responds to methods like [start] and [stopAll].
///
/// It'll be extended to fire events for when applications start, stop, and
/// log data.
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('start', start);
    registerHandler('stopAll', stopAll);
  }

  Future<dynamic> start(dynamic args) async {
    // TODO: Add the ability to pass args: target, http, checked

    await Future.wait([
      command.downloadToolchain(),
      command.downloadApplicationPackagesAndConnectToDevices(),
    ], eagerError: true);

    return startApp(
      command.devices,
      command.applicationPackages,
      command.toolchain
    ).then((int result) => null);
  }

  Future<bool> stopAll(dynamic args) {
    return stop.stopAll(command.devices, command.applicationPackages);
  }
}

/// This domain lets callers list and monitor connected devices.
///
/// It exports a `getDevices()` call, as well as firing `device.added`,
/// `device.removed`, and `device.changed` events.
class DeviceDomain extends Domain {
  DeviceDomain(Daemon daemon) : super(daemon, 'device') {
    registerHandler('getDevices', getDevices);

    _androidDeviceDiscovery = new AndroidDeviceDiscovery();
    _androidDeviceDiscovery.onAdded.listen((Device device) {
      sendEvent('device.added', _deviceToMap(device));
    });
    _androidDeviceDiscovery.onRemoved.listen((Device device) {
      sendEvent('device.removed', _deviceToMap(device));
    });
    _androidDeviceDiscovery.onChanged.listen((Device device) {
      sendEvent('device.changed', _deviceToMap(device));
    });
  }

  AndroidDeviceDiscovery _androidDeviceDiscovery;

  Future<List<Device>> getDevices(dynamic args) {
    List<Device> devices = <Device>[];
    devices.addAll(_androidDeviceDiscovery.getDevices());
    return new Future.value(devices);
  }

  void dispose() {
    _androidDeviceDiscovery.dispose();
  }
}

class AndroidDeviceDiscovery {
  AndroidDeviceDiscovery() {
    _initAdb();

    if (_adb != null) {
      _subscription = _adb.trackDevices().listen(_handleNewDevices);
    }
  }

  Adb _adb;
  StreamSubscription _subscription;
  Map<String, AndroidDevice> _devices = new Map<String, AndroidDevice>();

  StreamController<Device> addedController = new StreamController<Device>.broadcast();
  StreamController<Device> removedController = new StreamController<Device>.broadcast();
  StreamController<Device> changedController = new StreamController<Device>.broadcast();

  List<Device> getDevices() => _devices.values.toList();

  Stream<Device> get onAdded => addedController.stream;
  Stream<Device> get onRemoved => removedController.stream;
  Stream<Device> get onChanged => changedController.stream;

  void _initAdb() {
    if (_adb == null) {
      _adb = new Adb(AndroidDevice.getAdbPath());
      if (!_adb.exists())
        _adb = null;
    }
  }

  void _handleNewDevices(List<AdbDevice> newDevices) {
    List<AndroidDevice> currentDevices = new List.from(getDevices());

    for (AdbDevice device in newDevices) {
      AndroidDevice androidDevice = _devices[device.id];

      if (androidDevice == null) {
        // device added
        androidDevice = new AndroidDevice(
          id: device.id,
          productID: device.productID,
          modelID: device.modelID,
          deviceCodeName: device.deviceCodeName,
          connected: device.isAvailable
        );
        _devices[androidDevice.id] = androidDevice;
        addedController.add(androidDevice);
      } else {
        currentDevices.remove(androidDevice);

        // check state
        if (androidDevice.isConnected() != device.isAvailable) {
          androidDevice.setConnected(device.isAvailable);
          changedController.add(androidDevice);
        }
      }
    }

    // device removed
    for (AndroidDevice device in currentDevices) {
      _devices.remove(device.id);

      // I don't know the purpose of this cache or if it's a good idea. We should
      // probably have a DeviceManager singleton class to coordinate known devices
      // and different device discovery mechanisms.
      Device.removeFromCache(device.id);

      removedController.add(device);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

Map<String, dynamic> _deviceToMap(Device device) {
  return <String, dynamic>{
    'id': device.id,
    'platform': _enumToString(device.platform),
    'available': device.isConnected()
  };
}

/// Take an enum value and get the best string representation of that.
///
/// toString() on enums returns 'EnumType.enumName'.
String _enumToString(dynamic enumValue) {
  String str = '$enumValue';
  if (str.contains('.'))
    return str.substring(str.indexOf('.') + 1);
  return str;
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map || obj is List || obj == null)
    return obj;
  if (obj is Device)
    return obj;
  return '$obj';
}
