// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A message encoding/decoding mechanism.
///
/// Both operations throw [FormatException], if conversion fails.
///
/// See also:
///
/// * [PlatformMessageChannel], which use [MessageCodec]s for communication
///   between Flutter and platform plugins.
abstract class MessageCodec<T> {
  /// Encodes the specified [message] in binary.
  ///
  /// Returns `null` if the message is `null`.
  ByteData encodeMessage(T message);

  /// Decodes the specified [message] from binary.
  ///
  /// Returns `null` if the message is `null`.
  T decodeMessage(ByteData message);
}

/// A codec for method calls and enveloped results.
///
/// Result envelopes are binary messages with enough structure that the codec can
/// distinguish between a successful result and an error. In the former case,
/// the codec must be able to extract the result payload, possibly `null`. In
/// the latter case, the codec must be able to extract an error code string,
/// a (human-readable) error message string, and a value providing any
/// additional error details, possibly `null`. These data items are used to
/// populate a [PlatformException].
///
/// All operations throw [FormatException], if conversion fails.
///
/// See also:
///
/// * [PlatformMethodChannel], which use [MethodCodec]s for communication
///   between Flutter and platform plugins.
abstract class MethodCodec {
  /// Encodes the specified method call in binary.
  ///
  /// The [name] of the method must be non-null. The [arguments] may be `null`.
  ByteData encodeMethodCall(String name, dynamic arguments);

  /// Decodes the specified result [envelope] from binary.
  ///
  /// Throws [PlatformException], if [envelope] represents an error.
  dynamic decodeEnvelope(ByteData envelope);
}


/// Thrown to indicate that a platform interaction failed in the platform
/// plugin.
///
/// See also:
///
/// * [MethodCodec], which throws a [PlatformException], if a received result
///   envelope represents an error.
/// * [PlatformMethodChannel.invokeMethod], which completes the returned future
///   with a [PlatformException], if invoking the platform plugin method
///   results in an error envelope.
/// * [PlatformMethodChannel.receiveBroadcastStream], which emits
///   [PlatformException]s as error events, whenever an event received from the
///   platform plugin is wrapped in an error envelope.
class PlatformException implements Exception {
  /// Creates a [PlatformException] with the specified error [code] and optional
  /// [message], and with the optional error [details] which must be a valid
  /// value for the [MethodCodec] involved in the interaction.
  PlatformException({
    @required this.code,
    this.message,
    this.details,
  }) {
    assert(code != null);
  }

  /// An error code.
  final String code;

  /// A human-readable error message, possibly `null`.
  final String message;

  /// Error details, possibly `null`.
  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}
