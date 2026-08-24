// lib/src/cid/multibase.dart
import 'dart:typed_data';

import 'package:multibase/multibase.dart' as mb;

/// Helpers for multibase encoding/decoding used by CID and other multiformats.
///
/// This class is a thin, stable wrapper around `package:multibase` that exposes
/// only the bases used by dart_ipfs_core.
///
/// **base32 is handled separately, not delegated to `package:multibase`.**
/// Verified empirically (see `test/multibase_base32_test.dart`): for a
/// 123-case sweep of all-zero, leading-zero, and random byte sequences at
/// every length 0..40, `package:multibase`'s `Multibase.base32` codec
/// diverges from RFC 4648 in 107/123 encodings -- not a rare edge case, the
/// general case. It appears to convert the byte array through a big
/// integer rather than RFC 4648's fixed 5-bit grouping, which silently
/// drops leading zero bytes/groups (mathematically insignificant for an
/// integer, but semantically wrong for a byte string) and produces a
/// different digit sequence than the spec for most other inputs too. This
/// was confirmed against real content: encoding a raw-codec CIDv1 byte
/// sequence with [_base32LowerEncode] reproduces the well-known
/// `afkrei...` prefix used by real-world raw-block CIDs; `package:multibase`
/// does not. All other bases are left untouched -- only base32 was
/// verified broken.
class MultibaseUtils {
  // Private constructor to prevent instantiation.
  MultibaseUtils._();

  /// Decodes a multibase-encoded string into raw bytes.
  ///
  /// The input string must include the multibase prefix character.
  static Uint8List decode(String input) {
    if (input.isNotEmpty && input[0] == 'b') {
      return _base32LowerDecode(input.substring(1));
    }
    return Uint8List.fromList(mb.multibaseDecode(input));
  }

  /// Encodes raw bytes using the requested [base].
  static String encode(mb.Multibase base, Uint8List bytes) {
    if (base == mb.Multibase.base32) {
      return 'b${_base32LowerEncode(bytes)}';
    }
    return mb.multibaseEncode(base, bytes);
  }

  /// Encodes raw bytes using the requested base name.
  ///
  /// Falls back to base32 if the name is unknown.
  static String encodeWithName(String name, Uint8List bytes) {
    final base = _baseFromName(name);
    return encode(base, bytes);
  }

  /// Parses a base name into a [mb.Multibase] enum value.
  static mb.Multibase _baseFromName(String name) {
    switch (name.toLowerCase()) {
      case 'base16':
      case 'base16lower':
        return mb.Multibase.base16;
      case 'base16upper':
        return mb.Multibase.base16upper;
      case 'base32':
      case 'base32lower':
        return mb.Multibase.base32;
      case 'base32upper':
        return mb.Multibase.base32upper;
      case 'base58':
      case 'base58btc':
        return mb.Multibase.base58btc;
      case 'base64':
        return mb.Multibase.base64;
      case 'base64url':
        return mb.Multibase.base64url;
      case 'base64urlpad':
        return mb.Multibase.base64urlpad;
      default:
        return mb.Multibase.base32;
    }
  }
}

const _base32LowerAlphabet = 'abcdefghijklmnopqrstuvwxyz234567';

/// Encodes [data] to a lowercase, unpadded RFC 4648 base32 string.
///
/// Uses a straightforward bit-accumulator (mirrors [_base32LowerDecode]'s
/// structure, just inverted) rather than hand-unrolling each of the four
/// possible final-group remainders. That hand-unrolled version is how
/// `EncodingUtils.base32LowerEncode` in the umbrella package
/// (`lib/src/utils/encoding.dart`) is written, and porting it verbatim here
/// first surfaced a real bug in it: for inputs whose length is 4 mod 5, it
/// emits one spurious extra character (traced by hand against RFC 4648's
/// own "foob" -> "MZXW6YQ" test vector, which it fails, producing an
/// erroneous extra character between the correct 4th and 5th groups). The
/// umbrella's version -- and therefore every base32 CID encoding made by
/// the currently shipping `dart_ipfs` package for byte lengths of that
/// shape -- has this same bug; worth reporting upstream separately from
/// this refactor.
String _base32LowerEncode(Uint8List data) {
  if (data.isEmpty) return '';
  final result = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final byte in data) {
    buffer = (buffer << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      result.write(_base32LowerAlphabet[(buffer >> bits) & 31]);
    }
  }
  if (bits > 0) {
    result.write(_base32LowerAlphabet[(buffer << (5 - bits)) & 31]);
  }
  return result.toString();
}

/// Decodes a lowercase, unpadded RFC 4648 base32 string to bytes.
Uint8List _base32LowerDecode(String encoded) {
  if (encoded.isEmpty) return Uint8List(0);
  final out = <int>[];
  var buffer = 0;
  var bits = 0;
  for (var i = 0; i < encoded.length; i++) {
    final c = encoded[i];
    final value = _base32LowerAlphabet.indexOf(c);
    if (value < 0) {
      throw FormatException('Invalid base32 character: $c');
    }
    buffer = (buffer << 5) | value;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.add((buffer >> bits) & 0xFF);
    }
  }
  return Uint8List.fromList(out);
}
