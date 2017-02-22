// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Version implements Comparable<Version> {
  static final RegExp versionPattern =
      new RegExp(r'^(\d+)(\.(\d+)(\.(\d+))?)?');

  /// The major version number: "1" in "1.2.3".
  final int major;

  /// The minor version number: "2" in "1.2.3".
  final int minor;

  /// The patch version number: "3" in "1.2.3".
  final int patch;

  /// The original string representation of the version number.
  ///
  /// This preserves textual artifacts like leading zeros that may be left out
  /// of the parsed version.
  final String _text;

  /// Creates a new [Version] object.
  factory Version(int major, int minor, int patch, {String text}) {
    if (text == null) {
      text = major == null ? '0' : '$major';
      if (minor != null) text = '$text.$minor';
      if (patch != null) text = '$text.$patch';
    }

    return new Version._(major ?? 0, minor ?? 0, patch ?? 0, text);
  }

  Version._(this.major, this.minor, this.patch, this._text) {
    if (major < 0)
      throw new ArgumentError('Major version must be non-negative.');
    if (minor < 0)
      throw new ArgumentError('Minor version must be non-negative.');
    if (patch < 0)
      throw new ArgumentError('Patch version must be non-negative.');
  }

  /// Creates a new [Version] by parsing [text].
  factory Version.parse(String text) {
    Match match = versionPattern.firstMatch(text);
    if (match == null) {
      throw new FormatException('Could not parse "$text".');
    }

    try {
      int major = int.parse(match[1] ?? '0');
      int minor = int.parse(match[3] ?? '0');
      int patch = int.parse(match[5] ?? '0');
      return new Version._(major, minor, patch, text);
    } on FormatException {
      throw new FormatException('Could not parse "$text".');
    }
  }

  static Version get unknown => new Version(0, 0, 0, text: 'unknown');

  /// Two [Version]s are equal if their version numbers are. The version text
  /// is ignored.
  @override
  bool operator ==(dynamic other) {
    if (other is! Version)
      return false;
    return major == other.major && minor == other.minor && patch == other.patch;
  }

  @override
  int get hashCode => major ^ minor ^ patch;

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >=(Version other) => compareTo(other) >= 0;

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => _text;
}
