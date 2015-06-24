// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Param extends EquationMember {
  final Variable variable;

  Param.withVariable(this.variable);
  Param(double value) : this.variable = new Variable(value);

  bool get isConstant => false;

  double get value => variable.value;

  Expression asExpression() => new Expression([new Term(variable, 1.0)], 0.0);
}
