// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of stocks;

class StockList extends StatelessComponent {
  StockList({ Key key, this.keySalt, this.stocks, this.onOpen, this.onShow, this.onAction }) : super(key: key);

  final Object keySalt;
  final List<Stock> stocks;
  final StockRowActionCallback onOpen;
  final StockRowActionCallback onShow;
  final StockRowActionCallback onAction;

  Widget build(BuildContext context) {
    return new ScrollableList2(
      itemExtent: StockRow.kHeight,
      children: stocks.map((Stock stock) {
        return new StockRow(
          keySalt: keySalt,
          stock: stock,
          onPressed: onOpen,
          onDoubleTap: onShow,
          onLongPressed: onAction
        );
      })
    );
  }
}
