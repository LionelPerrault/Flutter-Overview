// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// This demo is based on
// https://www.google.com/design/spec/components/dialogs.html#dialogs-full-screen-dialogs

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class DateTimeItem extends StatelessComponent {
  DateTimeItem({ Key key, DateTime dateTime, this.onChanged })
    : date = new DateTime(dateTime.year, dateTime.month, dateTime.day),
      time = new TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
      super(key: key) {
    assert(onChanged != null);
  }

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new DefaultTextStyle(
      style: theme.textTheme.subhead,
      child: new Row(
        children: <Widget>[
          new Flexible(
            child: new Container(
              padding: const EdgeDims.symmetric(vertical: 8.0),
              decoration: new BoxDecoration(
                border: new Border(bottom: new BorderSide(color: theme.dividerColor))
              ),
              child: new InkWell(
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: date.subtract(const Duration(days: 30)),
                    lastDate: date.add(const Duration(days: 30))
                  )
                  .then((DateTime value) {
                    onChanged(new DateTime(value.year, value.month, value.day, time.hour, time.minute));
                  });
                },
                child: new Row(
                  justifyContent: FlexJustifyContent.spaceBetween,
                  children: <Widget>[
                    new Text(new DateFormat('EEE, MMM d yyyy').format(date)),
                    new Icon(icon: Icons.arrow_drop_down, color: Colors.black54),
                  ]
                )
              )
            )
          ),
          new Container(
            margin: const EdgeDims.only(left: 8.0),
            padding: const EdgeDims.symmetric(vertical: 8.0),
            decoration: new BoxDecoration(
              border: new Border(bottom: new BorderSide(color: theme.dividerColor))
            ),
            child: new InkWell(
              onTap: () {
                showTimePicker(
                  context: context,
                  initialTime: time
                )
                .then((TimeOfDay value) {
                  onChanged(new DateTime(date.year, date.month, date.day, value.hour, value.minute));
                });
              },
              child: new Row(
                children: <Widget>[
                  new Text('$time'),
                  new Icon(icon: Icons.arrow_drop_down, color: Colors.black54),
                ]
              )
            )
          )
        ]
      )
    );
  }
}

class FullScreenDialogDemo extends StatefulComponent {
  FullScreenDialogDemoState createState() => new FullScreenDialogDemoState();
}

class FullScreenDialogDemoState extends State<FullScreenDialogDemo> {
  DateTime fromDateTime = new DateTime.now();
  DateTime toDateTime = new DateTime.now();
  bool allDayValue = false;
  bool saveNeeded = false;

  void handleDismissButton(BuildContext context) {
    if (!saveNeeded) {
      Navigator.pop(context, null);
      return;
    }

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    showDialog(
      context: context,
      child: new Dialog(
        content: new Text(
          'Discard new event?',
          style: dialogTextStyle
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text('CANCEL'),
            onPressed: () { Navigator.pop(context, DismissDialogAction.cancel); }
          ),
          new FlatButton(
            child: new Text('DISCARD'),
            onPressed: () {
              Navigator.openTransaction(context, (NavigatorTransaction transaction) {
                transaction.pop(DismissDialogAction.discard); // pop the cancel/discard dialog
                transaction.pop(null); // pop this route
              });
            }
          )
        ]
      )
    );
  }

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new Scaffold(
      toolBar: new ToolBar(
        left: new IconButton(
          icon: Icons.clear,
          onPressed: () { handleDismissButton(context); }
        ),
        center: new Text('New Event'),
        right: <Widget> [
          new FlatButton(
            child: new Text('SAVE', style: theme.textTheme.body1.copyWith(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context, DismissDialogAction.save);
            }
          )
        ]
      ),
      body: new Padding(
        padding: const EdgeDims.all(16.0),
        child: new ScrollableViewport(
          child: new Column(
            alignItems: FlexAlignItems.stretch,
            justifyContent: FlexJustifyContent.collapse,
            children: <Widget>[
              new Container(
                padding: const EdgeDims.symmetric(vertical: 8.0),
                decoration: new BoxDecoration(
                  border: new Border(bottom: new BorderSide(color: theme.dividerColor))
                ),
                child: new Align(
                  alignment: const FractionalOffset(0.0, 1.0),
                  child: new Text('Event name', style: theme.textTheme.display2)
                )
              ),
              new Container(
                padding: const EdgeDims.symmetric(vertical: 8.0),
                decoration: new BoxDecoration(
                  border: new Border(bottom: new BorderSide(color: theme.dividerColor))
                ),
                child: new Align(
                  alignment: const FractionalOffset(0.0, 1.0),
                  child: new Text('Location', style: theme.textTheme.title.copyWith(color: Colors.black54))
                )
              ),
              new Column(
                alignItems: FlexAlignItems.stretch,
                justifyContent: FlexJustifyContent.end,
                children: <Widget>[
                  new Text('From', style: theme.textTheme.caption),
                  new DateTimeItem(
                    dateTime: fromDateTime,
                    onChanged: (DateTime value) {
                      setState(() {
                        fromDateTime = value;
                        saveNeeded = true;
                      });
                    }
                  )
                ]
              ),
              new Column(
                alignItems: FlexAlignItems.stretch,
                justifyContent: FlexJustifyContent.end,
                children: <Widget>[
                  new Text('To', style: theme.textTheme.caption),
                  new DateTimeItem(
                    dateTime: toDateTime,
                    onChanged: (DateTime value) {
                      setState(() {
                        toDateTime = value;
                        saveNeeded = true;
                      });
                    }
                  )
                ]
              ),
              new Container(
                decoration: new BoxDecoration(
                  border: new Border(bottom: new BorderSide(color: theme.dividerColor))
                ),
                child: new Row(
                  children: <Widget> [
                    new Checkbox(
                      value: allDayValue,
                      onChanged: (bool value) {
                        setState(() {
                          allDayValue = value;
                          saveNeeded = true;
                        });
                      }
                    ),
                    new Text('All-day')
                  ]
                )
              )
            ]
            .map((Widget child) {
              return new Container(
                padding: const EdgeDims.symmetric(vertical: 8.0),
                height: 96.0,
                child: child
              );
            })
            .toList()
          )
        )
      )
    );
  }
}
