// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'error.dart';
import 'message.dart';

const List<Type> _supportedKeyValueTypes = const <Type>[String, int];

/// Command to find an element.
class Find extends Command {
  final String kind = 'find';

  Find(this.searchSpec);

  final SearchSpecification searchSpec;

  Map<String, String> serialize() => searchSpec.serialize();

  static Find deserialize(Map<String, String> json) {
    return new Find(SearchSpecification.deserialize(json));
  }

  static _throwInvalidKeyValueType(String invalidType) {
    throw new DriverError('Unsupported key value type $invalidType. Flutter Driver only supports ${_supportedKeyValueTypes.join(", ")}');
  }
}

/// Describes how to the driver should search for elements.
abstract class SearchSpecification {
  String get searchSpecType;

  static SearchSpecification deserialize(Map<String, String> json) {
    String searchSpecType = json['searchSpecType'];
    switch(searchSpecType) {
      case 'ByValueKey': return ByValueKey.deserialize(json);
      case 'ByTooltipMessage': return ByTooltipMessage.deserialize(json);
      case 'ByText': return ByText.deserialize(json);
    }
    throw new DriverError('Unsupported search specification type $searchSpecType');
  }

  Map<String, String> serialize() => {
    'searchSpecType': searchSpecType,
  };
}

/// Tells [Find] to search by tooltip text.
class ByTooltipMessage extends SearchSpecification {
  final String searchSpecType = 'ByTooltipMessage';

  ByTooltipMessage(this.text);

  /// Tooltip message text.
  final String text;

  Map<String, String> serialize() => super.serialize()..addAll({
    'text': text,
  });

  static ByTooltipMessage deserialize(Map<String, String> json) {
    return new ByTooltipMessage(json['text']);
  }
}

/// Tells [Find] to search for `Text` widget by text.
class ByText extends SearchSpecification {
  final String searchSpecType = 'ByText';

  ByText(this.text);

  final String text;

  Map<String, String> serialize() => super.serialize()..addAll({
    'text': text,
  });

  static ByText deserialize(Map<String, String> json) {
    return new ByText(json['text']);
  }
}

/// Tells [Find] to search by `ValueKey`.
class ByValueKey extends SearchSpecification {
  final String searchSpecType = 'ByValueKey';

  ByValueKey(dynamic keyValue)
    : this.keyValue = keyValue,
      this.keyValueString = '$keyValue',
      this.keyValueType = '${keyValue.runtimeType}' {
    if (!_supportedKeyValueTypes.contains(keyValue.runtimeType))
      _throwInvalidKeyValueType('$keyValue.runtimeType');
  }

  /// The true value of the key.
  final dynamic keyValue;

  /// Stringified value of the key (we can only send strings to the VM service)
  final String keyValueString;

  /// The type name of the key.
  ///
  /// May be one of "String", "int". The list of supported types may change.
  final String keyValueType;

  Map<String, String> serialize() => super.serialize()..addAll({
    'keyValueString': keyValueString,
    'keyValueType': keyValueType,
  });

  static ByValueKey deserialize(Map<String, String> json) {
    String keyValueString = json['keyValueString'];
    String keyValueType = json['keyValueType'];
    switch(keyValueType) {
      case 'int':
        return new ByValueKey(int.parse(keyValueString));
      case 'String':
        return new ByValueKey(keyValueString);
      default:
        return _throwInvalidKeyValueType(keyValueType);
    }
  }

  static _throwInvalidKeyValueType(String invalidType) {
    throw new DriverError('Unsupported key value type $invalidType. Flutter Driver only supports ${_supportedKeyValueTypes.join(", ")}');
  }
}

/// Command to read the text from a given element.
class GetText extends CommandWithTarget {
  final String kind = 'get_text';

  static GetText deserialize(Map<String, String> json) {
    return new GetText(new ObjectRef(json['targetRef']));
  }

  /// [targetRef] identifies an element that contains a piece of text.
  GetText(ObjectRef targetRef) : super(targetRef);

  Map<String, String> serialize() => super.serialize();
}

class GetTextResult extends Result {
  static GetTextResult fromJson(Map<String, dynamic> json) {
    return new GetTextResult(json['text']);
  }

  GetTextResult(this.text);

  final String text;

  Map<String, dynamic> toJson() => {
    'text': text,
  };
}
