// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:newton/newton.dart';

void main() {
  test('test_friction', () {
    expect(nearEqual(5.0, 6.0, 2.0), isTrue);
    expect(nearEqual(6.0, 5.0, 2.0), isTrue);
    expect(nearEqual(5.0, 6.0, 0.5), isFalse);
    expect(nearEqual(6.0, 5.0, 0.5), isFalse);
  });
}
