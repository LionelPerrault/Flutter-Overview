// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import '../android/android_device.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../commands/daemon.dart';
import '../compile.dart';
import '../daemon.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../fuchsia/fuchsia_device.dart';
import '../ios/devices.dart';
import '../ios/simulators.dart';
import '../macos/macos_ipad_device.dart';
import '../mdns_discovery.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../resident_runner.dart';
import '../run_cold.dart';
import '../run_hot.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

/// A Flutter-command that attaches to applications that have been launched
/// without `flutter run`.
///
/// With an application already running, a HotRunner can be attached to it
/// with:
/// ```
/// $ flutter attach --debug-url http://127.0.0.1:12345/QqL7EFEDNG0=/
/// ```
///
/// If `--disable-service-auth-codes` was provided to the application at startup
/// time, a HotRunner can be attached with just a port:
/// ```
/// $ flutter attach --debug-port 12345
/// ```
///
/// Alternatively, the attach command can start listening and scan for new
/// programs that become active:
/// ```
/// $ flutter attach
/// ```
/// As soon as a new VM Service is detected the command attaches to it and
/// enables hot reloading.
///
/// To attach to a flutter mod running on a fuchsia device, `--module` must
/// also be provided.
class AttachCommand extends FlutterCommand {
  AttachCommand({
    bool verboseHelp = false,
    HotRunnerFactory? hotRunnerFactory,
    required Artifacts? artifacts,
    required Stdio stdio,
    required Logger logger,
    required Terminal terminal,
    required Signals signals,
    required Platform platform,
    required ProcessInfo processInfo,
    required FileSystem fileSystem,
  }): _artifacts = artifacts,
      _hotRunnerFactory = hotRunnerFactory ?? HotRunnerFactory(),
      _stdio = stdio,
      _logger = logger,
      _terminal = terminal,
      _signals = signals,
      _platform = platform,
      _processInfo = processInfo,
      _fileSystem = fileSystem {
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false, excludeRelease: true);
    usesTargetOption();
    usesPortOptions(verboseHelp: verboseHelp);
    usesIpv6Flag(verboseHelp: verboseHelp);
    usesFilesystemOptions(hide: !verboseHelp);
    usesFuchsiaOptions(hide: !verboseHelp);
    usesDartDefineOption();
    usesDeviceUserOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesInitializeFromDillOption(hide: !verboseHelp);
    argParser
      ..addOption(
        'debug-port',
        hide: !verboseHelp,
        help: '(deprecated) Device port where the Dart VM Service is listening. Requires '
              '"--disable-service-auth-codes" to also be provided to the Flutter '
              'application at launch, otherwise this command will fail to connect to '
              'the application. In general, "--debug-url" should be used instead.',
      )..addOption(
        'debug-url',
        aliases: <String>[ 'debug-uri' ], // supported for historical reasons
        help: 'The URL at which the Dart VM Service is listening.',
      )..addOption(
        'app-id',
        help: 'The package name (Android) or bundle identifier (iOS) for the app. '
              'This can be specified to avoid being prompted if multiple Dart VM Service ports '
              'are advertised.\n'
              'If you have multiple devices or emulators running, you should include the '
              'device hostname as well, e.g. "com.example.myApp@my-iphone".\n'
              'This parameter is case-insensitive.',
      )..addOption(
        'pid-file',
        help: 'Specify a file to write the process ID to. '
              'You can send SIGUSR1 to trigger a hot reload '
              'and SIGUSR2 to trigger a hot restart. '
              'The file is created when the signal handlers '
              'are hooked and deleted when they are removed.',
      )..addFlag(
        'report-ready',
        help: 'Print "ready" to the console after handling a keyboard command.\n'
              'This is primarily useful for tests and other automation, but consider '
              'using "--machine" instead.',
        hide: !verboseHelp,
      )..addOption(
        'project-root',
        hide: !verboseHelp,
        help: 'Normally used only in run target.',
      )..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input and provide output '
              'and progress in machine-friendly format.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addDdsOptions(verboseHelp: verboseHelp);
    addDevToolsOptions(verboseHelp: verboseHelp);
    addServeObservatoryOptions(verboseHelp: verboseHelp);
    usesDeviceTimeoutOption();
  }

  final HotRunnerFactory _hotRunnerFactory;
  final Artifacts? _artifacts;
  final Stdio _stdio;
  final Logger _logger;
  final Terminal _terminal;
  final Signals _signals;
  final Platform _platform;
  final ProcessInfo _processInfo;
  final FileSystem _fileSystem;

  @override
  final String name = 'attach';

  @override
  final String description = r'''
Attach to a running app.

For attaching to Android or iOS devices, simply using `flutter attach` is
usually sufficient. The tool will search for a running Flutter app or module,
if available. Otherwise, the tool will wait for the next Flutter app or module
to launch before attaching.

For Fuchsia, the module name must be provided, e.g. `$flutter attach
--module=mod_name`. This can be called either before or after the application
is started.

If the app or module is already running and the specific vmService port is
known, it can be explicitly provided to attach via the command-line, e.g.
`$ flutter attach --debug-port 12345`''';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  int? get debugPort {
    if (argResults!['debug-port'] == null) {
      return null;
    }
    try {
      return int.parse(stringArg('debug-port')!);
    } on Exception catch (error) {
      throwToolExit('Invalid port for `--debug-port`: $error');
    }
  }

  Uri? get debugUri {
    final String? debugUrl = stringArg('debug-url');
    if (debugUrl == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(debugUrl);
    if (uri == null) {
      throwToolExit('Invalid `--debug-url`: $debugUrl');
    }
    if (!uri.hasPort) {
      throwToolExit('Port not specified for `--debug-url`: $uri');
    }
    return uri;
  }

  bool get serveObservatory => boolArg('serve-observatory');

  String? get appId {
    return stringArg('app-id');
  }

  String? get userIdentifier => stringArg(FlutterOptions.kDeviceUser);

  @override
  Future<void> validateCommand() async {
    // ARM macOS as an iOS target is hidden, except for attach.
    MacOSDesignedForIPadDevices.allowDiscovery = true;

    await super.validateCommand();
    if (await findTargetDevice() == null) {
      throwToolExit(null);
    }
    debugPort;
    if (debugPort == null && debugUri == null && argResults!.wasParsed(FlutterCommand.ipv6Flag)) {
      throwToolExit(
        'When the --debug-port or --debug-url is unknown, this command determines '
        'the value of --ipv6 on its own.',
      );
    }
    if (debugPort == null && debugUri == null && argResults!.wasParsed(FlutterCommand.vmServicePortOption)) {
      throwToolExit(
        'When the --debug-port or --debug-url is unknown, this command does not use '
        'the value of --vm-service-port.',
      );
    }
    if (debugPort != null && debugUri != null) {
      throwToolExit(
        'Either --debug-port or --debug-url can be provided, not both.');
    }

    if (userIdentifier != null) {
      final Device? device = await findTargetDevice();
      if (device is! AndroidDevice) {
        throwToolExit('--${FlutterOptions.kDeviceUser} is only supported for Android');
      }
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await _validateArguments();

    final Device? device = await findTargetDevice();

    if (device == null) {
      throwToolExit('Did not find any valid target devices.');
    }

    final Artifacts? overrideArtifacts = device.artifactOverrides ?? _artifacts;
    await context.run<void>(
      body: () => _attachToDevice(device),
      overrides: <Type, Generator>{
        Artifacts: () => overrideArtifacts,
      },
    );

    return FlutterCommandResult.success();
  }

  Future<void> _attachToDevice(Device device) async {
    final FlutterProject flutterProject = FlutterProject.current();

    final Daemon? daemon = boolArg('machine')
      ? Daemon(
          DaemonConnection(
            daemonStreams: DaemonStreams.fromStdio(_stdio, logger: _logger),
            logger: _logger,
          ),
          notifyingLogger: (_logger is NotifyingLogger)
            ? _logger as NotifyingLogger
            : NotifyingLogger(verbose: _logger.isVerbose, parent: _logger),
          logToStdout: true,
        )
      : null;

    Stream<Uri>? vmServiceUri;
    bool usesIpv6 = ipv6!;
    final String ipv6Loopback = InternetAddress.loopbackIPv6.address;
    final String ipv4Loopback = InternetAddress.loopbackIPv4.address;
    final String hostname = usesIpv6 ? ipv6Loopback : ipv4Loopback;
    final bool isNetworkDevice = (device is IOSDevice) && device.isWirelesslyConnected;

    if ((debugPort == null && debugUri == null) || isNetworkDevice) {
      if (device is FuchsiaDevice) {
        final String? module = stringArg('module');
        if (module == null) {
          throwToolExit("'--module' is required for attaching to a Fuchsia device");
        }
        usesIpv6 = device.ipv6;
        FuchsiaIsolateDiscoveryProtocol? isolateDiscoveryProtocol;
        try {
          isolateDiscoveryProtocol = device.getIsolateDiscoveryProtocol(module);
          vmServiceUri = Stream<Uri>.value(await isolateDiscoveryProtocol.uri).asBroadcastStream();
        } on Exception {
          isolateDiscoveryProtocol?.dispose();
          final List<ForwardedPort> ports = device.portForwarder.forwardedPorts.toList();
          for (final ForwardedPort port in ports) {
            await device.portForwarder.unforward(port);
          }
          rethrow;
        }
      } else if ((device is IOSDevice) || (device is IOSSimulator) || (device is MacOSDesignedForIPadDevice)) {
        // Protocol Discovery relies on logging. On iOS earlier than 13, logging is gathered using syslog.
        // syslog is not available for iOS 13+. For iOS 13+, Protocol Discovery gathers logs from the VMService.
        // Since we don't have access to the VMService yet, Protocol Discovery cannot be used for iOS 13+.
        // Also, network devices must be found using mDNS and cannot use Protocol Discovery.
        final bool compatibleWithProtocolDiscovery = (device is IOSDevice) &&
          device.majorSdkVersion < IOSDeviceLogReader.minimumUniversalLoggingSdkVersion &&
          !isNetworkDevice;

        _logger.printStatus('Waiting for a connection from Flutter on ${device.name}...');
        final Status discoveryStatus = _logger.startSpinner(
          timeout: const Duration(seconds: 30),
          slowWarningCallback: () {
            // If relying on mDNS to find Dart VM Service, remind the user to allow local network permissions.
            if (!compatibleWithProtocolDiscovery) {
              return 'The Dart VM Service was not discovered after 30 seconds. This is taking much longer than expected...\n\n'
                'Click "Allow" to the prompt asking if you would like to find and connect devices on your local network. '
                'If you selected "Don\'t Allow", you can turn it on in Settings > Your App Name > Local Network. '
                "If you don't see your app in the Settings, uninstall the app and rerun to see the prompt again.\n";
            }

            return 'The Dart VM Service was not discovered after 30 seconds. This is taking much longer than expected...\n';
          },
        );

        int? devicePort;
        if (debugPort != null) {
          devicePort = debugPort;
        } else if (debugUri != null) {
          devicePort = debugUri?.port;
        } else if (deviceVmservicePort != null) {
          devicePort = deviceVmservicePort;
        }

        final Future<Uri?> mDNSDiscoveryFuture = MDnsVmServiceDiscovery.instance!.getVMServiceUriForAttach(
          appId,
          device,
          usesIpv6: usesIpv6,
          isNetworkDevice: isNetworkDevice,
          deviceVmservicePort: devicePort,
        );

        Future<Uri?>? protocolDiscoveryFuture;
        if (compatibleWithProtocolDiscovery) {
          final ProtocolDiscovery vmServiceDiscovery = ProtocolDiscovery.vmService(
            device.getLogReader(),
            portForwarder: device.portForwarder,
            ipv6: ipv6!,
            devicePort: devicePort,
            hostPort: hostVmservicePort,
            logger: _logger,
          );
          protocolDiscoveryFuture = vmServiceDiscovery.uri;
        }

        final Uri? foundUrl;
        if (protocolDiscoveryFuture == null) {
          foundUrl = await mDNSDiscoveryFuture;
        } else {
          foundUrl = await Future.any(
            <Future<Uri?>>[mDNSDiscoveryFuture, protocolDiscoveryFuture]
          );
        }
        discoveryStatus.stop();

        vmServiceUri = foundUrl == null
          ? null
          : Stream<Uri>.value(foundUrl).asBroadcastStream();
      }
      // If MDNS discovery fails or we're not on iOS, fallback to ProtocolDiscovery.
      if (vmServiceUri == null) {
        final ProtocolDiscovery vmServiceDiscovery =
          ProtocolDiscovery.vmService(
            // If it's an Android device, attaching relies on past log searching
            // to find the service protocol.
            await device.getLogReader(includePastLogs: device is AndroidDevice),
            portForwarder: device.portForwarder,
            ipv6: ipv6!,
            devicePort: deviceVmservicePort,
            hostPort: hostVmservicePort,
            logger: _logger,
          );
        _logger.printStatus('Waiting for a connection from Flutter on ${device.name}...');
        vmServiceUri = vmServiceDiscovery.uris;
        // Determine ipv6 status from the scanned logs.
        usesIpv6 = vmServiceDiscovery.ipv6;
      }
    } else {
      vmServiceUri = Stream<Uri>
        .fromFuture(
          buildVMServiceUri(
            device,
            debugUri?.host ?? hostname,
            debugPort ?? debugUri!.port,
            hostVmservicePort,
            debugUri?.path,
          )
        ).asBroadcastStream();
    }

    _terminal.usesTerminalUi = daemon == null;

    try {
      int? result;
      if (daemon != null) {
        final ResidentRunner runner = await createResidentRunner(
          vmServiceUris: vmServiceUri,
          device: device,
          flutterProject: flutterProject,
          usesIpv6: usesIpv6,
        );
        late AppInstance app;
        try {
          app = await daemon.appDomain.launch(
            runner,
            ({Completer<DebugConnectionInfo>? connectionInfoCompleter,
              Completer<void>? appStartedCompleter}) {
              return runner.attach(
                connectionInfoCompleter: connectionInfoCompleter,
                appStartedCompleter: appStartedCompleter,
                allowExistingDdsInstance: true,
                enableDevTools: boolArg(FlutterCommand.kEnableDevTools),
              );
            },
            device,
            null,
            true,
            _fileSystem.currentDirectory,
            LaunchMode.attach,
            _logger as AppRunLogger,
          );
        } on Exception catch (error) {
          throwToolExit(error.toString());
        }
        result = await app.runner!.waitForAppToFinish();
        return;
      }
      while (true) {
        final ResidentRunner runner = await createResidentRunner(
          vmServiceUris: vmServiceUri,
          device: device,
          flutterProject: flutterProject,
          usesIpv6: usesIpv6,
        );
        final Completer<void> onAppStart = Completer<void>.sync();
        TerminalHandler? terminalHandler;
        unawaited(onAppStart.future.whenComplete(() {
          terminalHandler = TerminalHandler(
            runner,
            logger: _logger,
            terminal: _terminal,
            signals: _signals,
            processInfo: _processInfo,
            reportReady: boolArg('report-ready'),
            pidFile: stringArg('pid-file'),
          )
            ..registerSignalHandlers()
            ..setupTerminal();
        }));
        result = await runner.attach(
          appStartedCompleter: onAppStart,
          allowExistingDdsInstance: true,
          enableDevTools: boolArg(FlutterCommand.kEnableDevTools),
        );
        if (result != 0) {
          throwToolExit(null, exitCode: result);
        }
        terminalHandler?.stop();
        assert(result != null);
        if (runner.exited || !runner.isWaitingForVmService) {
          break;
        }
        _logger.printStatus('Waiting for a new connection from Flutter on ${device.name}...');
      }
    } on RPCError catch (err) {
      if (err.code == RPCErrorCodes.kServiceDisappeared) {
        throwToolExit('Lost connection to device.');
      }
      rethrow;
    } finally {
      final List<ForwardedPort> ports = device.portForwarder!.forwardedPorts.toList();
      for (final ForwardedPort port in ports) {
        await device.portForwarder!.unforward(port);
      }
    }
  }

  Future<ResidentRunner> createResidentRunner({
    required Stream<Uri> vmServiceUris,
    required Device device,
    required FlutterProject flutterProject,
    required bool usesIpv6,
  }) async {
    final BuildInfo buildInfo = await getBuildInfo();

    final FlutterDevice flutterDevice = await FlutterDevice.create(
      device,
      target: targetFile,
      targetModel: TargetModel(stringArg('target-model')!),
      buildInfo: buildInfo,
      userIdentifier: userIdentifier,
      platform: _platform,
    );
    flutterDevice.vmServiceUris = vmServiceUris;
    final List<FlutterDevice> flutterDevices =  <FlutterDevice>[flutterDevice];
    final DebuggingOptions debuggingOptions = DebuggingOptions.enabled(
      buildInfo,
      enableDds: enableDds,
      ddsPort: ddsPort,
      devToolsServerAddress: devToolsServerAddress,
      serveObservatory: serveObservatory,
    );

    return buildInfo.isDebug
      ? _hotRunnerFactory.build(
          flutterDevices,
          target: targetFile,
          debuggingOptions: debuggingOptions,
          packagesFilePath: globalResults!['packages'] as String?,
          projectRootPath: stringArg('project-root'),
          dillOutputPath: stringArg('output-dill'),
          ipv6: usesIpv6,
          flutterProject: flutterProject,
        )
      : ColdRunner(
          flutterDevices,
          target: targetFile,
          debuggingOptions: debuggingOptions,
          ipv6: usesIpv6,
        );
  }

  Future<void> _validateArguments() async { }
}

class HotRunnerFactory {
  HotRunner build(
    List<FlutterDevice> devices, {
    required String target,
    required DebuggingOptions debuggingOptions,
    bool benchmarkMode = false,
    File? applicationBinary,
    bool hostIsIde = false,
    String? projectRootPath,
    String? packagesFilePath,
    String? dillOutputPath,
    bool stayResident = true,
    bool ipv6 = false,
    FlutterProject? flutterProject,
  }) => HotRunner(
    devices,
    target: target,
    debuggingOptions: debuggingOptions,
    benchmarkMode: benchmarkMode,
    applicationBinary: applicationBinary,
    hostIsIde: hostIsIde,
    projectRootPath: projectRootPath,
    dillOutputPath: dillOutputPath,
    stayResident: stayResident,
    ipv6: ipv6,
  );
}
