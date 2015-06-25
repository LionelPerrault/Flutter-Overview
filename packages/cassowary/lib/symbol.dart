// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum _SymbolType { invalid, external, slack, error, dummy, }

class _Symbol {
  final _SymbolType type;
  int tick;

  _Symbol(this.type, this.tick);
}
