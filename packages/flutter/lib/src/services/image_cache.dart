// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;

import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:sky/src/services/image_resource.dart';
import 'package:sky/src/services/fetch.dart';

class _ImageCache {
  _ImageCache._();

  final HashMap<String, ImageResource> _cache = new Map<String, ImageResource>();

  ImageResource load(String url) {
    return _cache.putIfAbsent(url, () {
      Completer<sky.Image> completer = new Completer<sky.Image>();
      fetchUrl(url).then((UrlResponse response) {
        if (response.statusCode >= 400) {
          print("Failed (${response.statusCode}) to load image ${url}");
          completer.complete(null);
        } else {
          new sky.ImageDecoder(completer.complete)
                 ..initWithConsumer(response.body.handle.h);
        }
      });
      return new ImageResource(completer.future);
    });
  }
}

final _ImageCache imageCache = new _ImageCache._();
