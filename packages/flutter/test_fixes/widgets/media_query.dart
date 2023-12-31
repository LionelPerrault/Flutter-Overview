// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  // Change made in https://github.com/LionelPerrault/flutter/pull/128522
  MediaQueryData();
  MediaQueryData(textScaleFactor: 2.0)
    ..copyWith(textScaleFactor: 2.0)
    ..copyWith();
}
