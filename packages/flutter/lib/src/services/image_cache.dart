// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;

import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:sky/src/services/fetch.dart';
import 'package:sky/src/services/image_decoder.dart';
import 'package:sky/src/services/image_resource.dart';

Future<sky.Image> _fetchImage(String url) async {
  UrlResponse response = await fetchUrl(url);
  if (response.statusCode >= 400) {
    print("Failed (${response.statusCode}) to load image ${url}");
    return null;
  }
  return await decodeImageFromDataPipe(response.body);
}

class _ImageCache {
  _ImageCache._();

  final HashMap<String, ImageResource> _cache = new Map<String, ImageResource>();

  ImageResource load(String url) {
    return _cache.putIfAbsent(url, () {
      return new ImageResource(_fetchImage(url));
    });
  }
}

final _ImageCache imageCache = new _ImageCache._();
