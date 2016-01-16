// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';

bool debugCheckHasMaterial(BuildContext context) {
  assert(() {
    if (context.widget is! Material && context.ancestorWidgetOfExactType(Material) == null) {
      Element element = context;
      throw new WidgetError(
        'Missing Material widget.',
        '${context.widget} needs to be placed inside a Material widget. Ownership chain:\n${element.debugGetOwnershipChain(10)}'
      );
    }
    return true;
  });
  return true;
}
