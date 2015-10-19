// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cipher/cipher.dart';
import 'package:cipher/impl/client.dart';
import 'package:yaml/yaml.dart';

import '../signing.dart';
import '../toolchain.dart';
import 'flutter_command.dart';

const String _kSnapshotKey = 'snapshot_blob.bin';
const List<String> _kDensities = const ['drawable-xxhdpi'];
const List<String> _kThemes = const ['white', 'black'];
const List<int> _kSizes = const [24];

class _Asset {
  final String base;
  final String key;

  _Asset({ this.base, this.key });
}

Iterable<_Asset> _parseAssets(Map manifestDescriptor, String manifestPath) sync* {
  if (manifestDescriptor == null || !manifestDescriptor.containsKey('assets'))
    return;
  String basePath = new File(manifestPath).parent.path;
  for (String asset in manifestDescriptor['assets'])
    yield new _Asset(base: basePath, key: asset);
}

class _MaterialAsset {
  final String name;
  final String density;
  final String theme;
  final int size;

  _MaterialAsset(Map descriptor)
    : name = descriptor['name'],
      density = descriptor['density'],
      theme = descriptor['theme'],
      size = descriptor['size'];

  String get key {
    List<String> parts = name.split('/');
    String category = parts[0];
    String subtype = parts[1];
    return '$category/$density/ic_${subtype}_${theme}_${size}dp.png';
  }
}

List _generateValues(Map assetDescriptor, String key, List defaults) {
  if (assetDescriptor.containsKey(key))
    return [assetDescriptor[key]];
  return defaults;
}

Iterable<_MaterialAsset> _generateMaterialAssets(Map assetDescriptor) sync* {
  Map currentAssetDescriptor = new Map.from(assetDescriptor);
  for (String density in _generateValues(assetDescriptor, 'density', _kDensities)) {
    currentAssetDescriptor['density'] = density;
    for (String theme in _generateValues(assetDescriptor, 'theme', _kThemes)) {
      currentAssetDescriptor['theme'] = theme;
      for (int size in _generateValues(assetDescriptor, 'size', _kSizes)) {
        currentAssetDescriptor['size'] = size;
        yield new _MaterialAsset(currentAssetDescriptor);
      }
    }
  }
}

Iterable<_MaterialAsset> _parseMaterialAssets(Map manifestDescriptor) sync* {
  if (manifestDescriptor == null || !manifestDescriptor.containsKey('material-design-icons'))
    return;
  for (Map assetDescriptor in manifestDescriptor['material-design-icons']) {
    for (_MaterialAsset asset in _generateMaterialAssets(assetDescriptor)) {
      yield asset;
    }
  }
}

dynamic _loadManifest(String manifestPath) {
  if (manifestPath == null)
    return null;
  String manifestDescriptor = new File(manifestPath).readAsStringSync();
  return loadYaml(manifestDescriptor);
}

ArchiveFile _createFile(String key, String assetBase) {
  File file = new File('${assetBase}/${key}');
  if (!file.existsSync())
    return null;
  List<int> content = file.readAsBytesSync();
  return new ArchiveFile.noCompress(key, content.length, content);
}

// Writes a 32-bit length followed by the content of [bytes].
void _writeBytesWithLength(File outputFile, List<int> bytes) {
  if (bytes == null)
    bytes = new Uint8List(0);
  assert(bytes.length < 0xffffffff);
  ByteData length = new ByteData(4)..setUint32(0, bytes.length, Endianness.LITTLE_ENDIAN);
  outputFile.writeAsBytesSync(length.buffer.asUint8List(), mode: FileMode.APPEND);
  outputFile.writeAsBytesSync(bytes, mode: FileMode.APPEND);
}

ArchiveFile _createSnapshotFile(String snapshotPath) {
  File file = new File(snapshotPath);
  List<int> content = file.readAsBytesSync();
  return new ArchiveFile(_kSnapshotKey, content.length, content);
}

const String _kDefaultAssetBase = 'packages/material_design_icons/icons';
const String _kDefaultMainPath = 'lib/main.dart';
const String _kDefaultOutputPath = 'app.flx';
const String _kDefaultSnapshotPath = 'snapshot_blob.bin';
const String _kDefaultPrivateKeyPath = 'privatekey.der';

class BuildCommand extends FlutterCommand {
  final String name = 'build';
  final String description = 'Create a Flutter app.';

  BuildCommand() {
    argParser.addOption('asset-base', defaultsTo: _kDefaultAssetBase);

    argParser.addOption('compiler');
    argParser.addOption('main', defaultsTo: _kDefaultMainPath);
    argParser.addOption('manifest');
    argParser.addOption('private-key', defaultsTo: _kDefaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: _kDefaultOutputPath);
    argParser.addOption('snapshot', defaultsTo: _kDefaultSnapshotPath);
  }

  @override
  Future<int> run() async {
    initCipher();
    String compilerPath = argResults['compiler'];

    if (compilerPath == null)
      await downloadToolchain();
    else
      toolchain = new Toolchain(compiler: new Compiler(compilerPath));

    return await build(
      assetBase: argResults['asset-base'],
      mainPath: argResults['main'],
      manifestPath: argResults['manifest'],
      outputPath: argResults['output-file'],
      snapshotPath: argResults['snapshot'],
      privateKeyPath: argResults['private-key']
    );
  }

  Future<int> build({
    String assetBase: _kDefaultAssetBase,
    String mainPath: _kDefaultMainPath,
    String manifestPath,
    String outputPath: _kDefaultOutputPath,
    String snapshotPath: _kDefaultSnapshotPath,
    String privateKeyPath: _kDefaultPrivateKeyPath
  }) async {
    Map manifestDescriptor = _loadManifest(manifestPath);

    Iterable<_Asset> assets = _parseAssets(manifestDescriptor, manifestPath);
    Iterable<_MaterialAsset> materialAssets = _parseMaterialAssets(manifestDescriptor);

    Archive archive = new Archive();

    int result = await toolchain.compiler.compile(mainPath: mainPath, snapshotPath: snapshotPath);
    if (result != 0)
      return result;

    archive.addFile(_createSnapshotFile(snapshotPath));

    for (_Asset asset in assets)
      archive.addFile(_createFile(asset.key, asset.base));

    for (_MaterialAsset asset in materialAssets) {
      ArchiveFile file = _createFile(asset.key, assetBase);
      if (file != null)
        archive.addFile(file);
    }

    ECPrivateKey privateKey = await loadPrivateKey(privateKeyPath);
    ECPublicKey publicKey = publicKeyFromPrivateKey(privateKey);

    File outputFile = new File(outputPath);
    outputFile.writeAsStringSync('#!mojo mojo:sky_viewer\n');
    Uint8List zipBytes = new Uint8List.fromList(new ZipEncoder().encode(archive));
    Uint8List manifestBytes = serializeManifest(manifestDescriptor, publicKey, zipBytes);
    _writeBytesWithLength(outputFile, signManifest(manifestBytes, privateKey));
    _writeBytesWithLength(outputFile, manifestBytes);
    outputFile.writeAsBytesSync(zipBytes, mode: FileMode.APPEND, flush: true);
    return 0;
  }
}
