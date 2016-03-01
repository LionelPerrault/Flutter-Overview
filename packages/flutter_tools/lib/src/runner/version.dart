// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/process.dart';

String getVersion(String flutterRoot) {
  String upstream = runSync([
    'git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{u}'
  ], workingDirectory: flutterRoot).trim();
  String repository;
  int slash = upstream.indexOf('/');
  if (slash != -1) {
    String remote = upstream.substring(0, slash);
    repository = runSync([
      'git', 'ls-remote', '--get-url', remote
    ], workingDirectory: flutterRoot).trim();
    upstream = upstream.substring(slash + 1);
  }
  String revision = runSync([
    'git', 'log', '-n', '1', '--pretty=format:%H (%ar)'
  ], workingDirectory: flutterRoot).trim();

  String from = repository == null ? 'Flutter from unknown source' : 'Flutter from $repository (on $upstream)';
  String flutterVersion = 'Framework: $revision';
  String engineRevision = 'Engine:    ${ArtifactStore.engineRevision}';

  return '$from\n$flutterVersion\n$engineRevision';
}
