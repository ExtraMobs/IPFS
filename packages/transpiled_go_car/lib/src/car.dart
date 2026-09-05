import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

/// The CAR v1 header and its version field.
final class CarHeader {
  CarHeader({required Iterable<CID> roots, this.version = 1})
    : roots = List.unmodifiable(roots) {
    if (version < 0) throw ArgumentError.value(version, 'version');
  }

  final List<CID> roots;
  final int version;

  /// Returns whether headers have the same version and roots, independent of
  /// root ordering, as go-car's `CarHeader.Matches`.
  bool matches(CarHeader other) {
    if (version != other.version || roots.length != other.roots.length) {
      return false;
    }
    // ponytail: O(n²) root scan; hash-indexed roots only if large headers matter.
    for (final root in roots) {
      if (!other.roots.contains(root)) return false;
    }
    return true;
  }
}

/// A length-delimited CAR block section.
final class CarBlock {
  CarBlock(this.cid, Uint8List data) : data = Uint8List.fromList(data);

  final CID cid;
  final Uint8List data;
}

/// Raised when a section's CID does not hash to its bytes.
final class CarIntegrityException implements Exception {
  const CarIntegrityException(this.cid);
  final CID cid;

  @override
  String toString() => 'CAR block does not match CID: $cid';
}

/// Maximum CAR v1 header size used by go-car/v2.17.0 (32 MiB).
const int maxAllowedHeaderSize = 32 << 20;

/// Maximum CAR v1 block section size used by go-car/v2.17.0 (8 MiB).
const int maxAllowedSectionSize = 8 << 20;

/// Encodes a CAR v1 header as a varint-framed canonical DAG-CBOR section.
///
/// If [sink] is supplied, the encoded section is also added to it.
Uint8List writeHeader(CarHeader header, [Sink<List<int>>? sink]) {
  final cbor = _encodeHeader(header);
  final out = Uint8List.fromList([...encodeVarint(cbor.length), ...cbor]);
  sink?.add(out);
  return out;
}

/// Decodes a varint-framed CAR v1 header from [bytes].
///
/// [bytes] may contain subsequent CAR sections; they are left unread.
CarHeader readHeader(
  List<int> input, {
  int maxSectionSize = maxAllowedHeaderSize,
}) {
  final bytes = Uint8List.fromList(input);
  final (length, varintLength) = _readVarint(bytes, 0);
  _checkSectionLength(length, maxSectionSize);
  final end = varintLength + length;
  if (end > bytes.length) throw const FormatException('truncated CAR header');
  return _decodeHeader(bytes.sublist(varintLength, end));
}

/// Reads a CAR v1 header from a chunked byte stream.
Future<CarHeader> readHeaderFromStream(
  Stream<List<int>> input, {
  int maxSectionSize = maxAllowedHeaderSize,
}) async {
  final reader = _AsyncBytes(input);
  try {
    final length = await reader.readVarint();
    _checkSectionLength(length, maxSectionSize);
    return _decodeHeader(await reader.readExact(length));
  } on _CleanEof {
    throw const FormatException('truncated CAR header');
  }
}

/// Returns the encoded, framed size of [header].
int headerSize(CarHeader header) => writeHeader(header).length;

/// Validates [data] against [cid]'s multihash and throws on mismatch.
void validateBlock(CID cid, List<int> data) {
  if (cid.prefix.sum(Uint8List.fromList(data)) != cid) {
    throw CarIntegrityException(cid);
  }
}

/// Alias for [validateBlock] using the CID-oriented name used by callers.
void validateCid(CID cid, List<int> data) => validateBlock(cid, data);

typedef CarGet = FutureOr<List<int>> Function(CID cid);
typedef CarLinks = FutureOr<Iterable<CID>> Function(CID cid);
typedef CarLinksWithData =
    FutureOr<Iterable<CID>> Function(CID cid, Uint8List data);

/// Streams a depth-first, CID-deduplicated CAR v1 walk.
final class CarWriter {
  CarWriter({
    required Iterable<CID> roots,
    required this.get,
    this.links,
    this.linksWithData,
    this.maxSectionSize = maxAllowedSectionSize,
  }) : roots = List.unmodifiable(roots) {
    if (links == null && linksWithData == null) {
      throw ArgumentError('links or linksWithData is required');
    }
    if (maxSectionSize < 1)
      throw ArgumentError.value(maxSectionSize, 'maxSectionSize');
  }

  final List<CID> roots;
  final CarGet get;
  final CarLinks? links;
  final CarLinksWithData? linksWithData;
  final int maxSectionSize;

  /// Produces header and sections as they become available.
  Stream<Uint8List> stream() async* {
    yield writeHeader(CarHeader(roots: roots));
    final seen = <String>{};
    Future<Iterable<CID>> children(CID cid, Uint8List data) async {
      if (linksWithData != null) return linksWithData!(cid, data);
      return links!(cid);
    }

    Stream<Uint8List> walk(CID cid) async* {
      final key = cid.encode();
      if (!seen.add(key)) return;
      final data = Uint8List.fromList(await get(cid));
      validateBlock(cid, data);
      final section = Uint8List.fromList([...cid.toBytes(), ...data]);
      if (section.length > maxSectionSize) {
        throw FormatException(
          'CAR block section exceeds $maxSectionSize bytes',
        );
      }
      final framed = Uint8List.fromList([
        ...encodeVarint(section.length),
        ...section,
      ]);
      yield framed;
      for (final child in await children(cid, data)) {
        yield* walk(child);
      }
    }

    for (final root in roots) {
      yield* walk(root);
    }
  }

  /// Writes the stream to a Dart byte sink.
  Future<void> write(Sink<List<int>> sink) async {
    await for (final part in stream()) sink.add(part);
  }

  /// Materializes the stream, useful for small CARs and tests.
  Future<Uint8List> toBytes() async {
    final out = BytesBuilder(copy: false);
    await for (final part in stream()) out.add(part);
    return out.takeBytes();
  }
}

/// Reads CAR v1 sections incrementally and validates every block.
final class CarReader {
  CarReader(
    Object input, {
    this.maxHeaderSize = maxAllowedHeaderSize,
    this.maxSectionSize = maxAllowedSectionSize,
    this.errorOnEmptyRoots = true,
  }) : _bytes = input is List<int> ? Uint8List.fromList(input) : null,
       _stream = input is Stream<List<int>> ? input : null {
    if (_bytes == null && _stream == null) {
      throw ArgumentError('input must be List<int> or Stream<List<int>>');
    }
    if (maxSectionSize < 1)
      throw ArgumentError.value(maxSectionSize, 'maxSectionSize');
    if (maxHeaderSize < 1)
      throw ArgumentError.value(maxHeaderSize, 'maxHeaderSize');
    if (_bytes != null) {
      _header = readHeader(_bytes!, maxSectionSize: maxHeaderSize);
      _checkVersion(_header!);
      _offset = _headerEnd(_bytes!, maxHeaderSize);
      _checkEmptyRoots(_header!);
    }
  }

  final int maxHeaderSize;
  final int maxSectionSize;
  final bool errorOnEmptyRoots;
  final Uint8List? _bytes;
  final Stream<List<int>>? _stream;
  int _offset = 0;
  CarHeader? _header;
  _AsyncBytes? _async;
  bool _done = false;

  CarHeader? get header => _header;

  /// Reads and returns the header, consuming it once for stream input.
  Future<CarHeader> readHeaderAsync() async {
    if (_header != null) return _header!;
    _async ??= _AsyncBytes(_stream!);
    try {
      final length = await _async!.readVarint();
      _checkSectionLength(length, maxHeaderSize);
      _header = _decodeHeader(await _async!.readExact(length));
      _checkVersion(_header!);
      _checkEmptyRoots(_header!);
      return _header!;
    } on _CleanEof {
      throw const FormatException('truncated CAR header');
    }
  }

  /// Returns the next block, or null at clean end-of-file (byte input only).
  CarBlock? next() {
    final bytes = _bytes;
    if (bytes == null) {
      throw StateError('next() is synchronous; use nextAsync() for a stream');
    }
    if (_done || _offset == bytes.length) {
      _done = true;
      return null;
    }
    final (length, varintLength) = _readVarint(bytes, _offset);
    _checkSectionLength(length, maxSectionSize);
    final start = _offset + varintLength;
    final end = start + length;
    if (end > bytes.length)
      throw const FormatException('truncated CAR section');
    _offset = end;
    return _decodeBlock(bytes.sublist(start, end));
  }

  /// Returns the next block, or null at clean end-of-file.
  Future<CarBlock?> nextAsync() async {
    if (_bytes != null) return next();
    if (_done) return null;
    _async ??= _AsyncBytes(_stream!);
    await readHeaderAsync();
    try {
      final length = await _async!.readVarint();
      _checkSectionLength(length, maxSectionSize);
      return _decodeBlock(await _async!.readExact(length));
    } on _CleanEof {
      _done = true;
      return null;
    }
  }

  Stream<CarBlock> blocks() async* {
    while (true) {
      final block = await nextAsync();
      if (block == null) return;
      yield block;
    }
  }

  void _checkEmptyRoots(CarHeader h) {
    if (errorOnEmptyRoots && h.roots.isEmpty)
      throw const FormatException('empty car, no roots');
  }

  void _checkVersion(CarHeader h) {
    if (h.version != 1) {
      throw FormatException('invalid car version: ${h.version}');
    }
  }
}

typedef CarPut = FutureOr<void> Function(CarBlock block);

/// Loads and validates every CAR block into [put].
Future<CarHeader> loadCar(
  Object input,
  Object put, {
  int maxSectionSize = maxAllowedSectionSize,
  bool errorOnEmptyRoots = true,
}) async {
  final reader = CarReader(
    input,
    maxSectionSize: maxSectionSize,
    errorOnEmptyRoots: errorOnEmptyRoots,
  );
  await for (final block in reader.blocks()) {
    if (put is CarPut) {
      await put(block);
    } else {
      // Also accept the natural `(cid, data)` callback shape.
      await (put as dynamic)(block.cid, block.data);
    }
  }
  return reader.header!;
}

Uint8List _encodeHeader(CarHeader h) {
  final out = BytesBuilder();
  // Canonical DAG-CBOR orders "roots" before "version" (shorter key first).
  out.addByte(0xa2);
  out.add(const [0x65, 0x72, 0x6f, 0x6f, 0x74, 0x73]);
  out.add(encodeVarint(h.roots.length)); // roots are always small in practice.
  // Replace the varint with CBOR's definite-length argument when it is > 23.
  // CAR headers with large root lists are still encoded correctly below.
  if (h.roots.length <= 23) {
    final bytes = out.takeBytes();
    final fixed = BytesBuilder()
      ..add(bytes.sublist(0, 7))
      ..addByte(0x80 | h.roots.length);
    out.add(fixed.takeBytes());
  } else {
    final prefix = out.takeBytes();
    final rootCount = _cborLength(4, h.roots.length);
    out.add(prefix.sublist(0, 7));
    out.add(rootCount);
  }
  for (final cid in h.roots) {
    final bytes = cid.toBytes();
    out.add(const [0xd8, 0x2a]);
    out.add(_cborLength(2, bytes.length + 1));
    out.addByte(0);
    out.add(bytes);
  }
  out.add(const [0x67, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x01]);
  return out.takeBytes();
}

Uint8List _cborLength(int major, int length) {
  if (length < 24) return Uint8List.fromList([(major << 5) | length]);
  if (length <= 0xff) return Uint8List.fromList([(major << 5) | 24, length]);
  if (length <= 0xffff)
    return Uint8List.fromList([(major << 5) | 25, length >> 8, length]);
  if (length <= 0xffffffff) {
    return Uint8List.fromList([
      (major << 5) | 26,
      length >> 24,
      length >> 16,
      length >> 8,
      length,
    ]);
  }
  throw RangeError('CBOR length too large');
}

CarHeader _decodeHeader(Uint8List bytes) {
  final parser = _CborParser(bytes);
  final value = parser.value();
  if (!parser.done) throw const FormatException('trailing bytes in CAR header');
  if (value is! Map<Object?, Object?>)
    throw const FormatException('CAR header is not a map');
  final rootsValue = value['roots'];
  final versionValue = value['version'];
  if (rootsValue is! List || versionValue is! int)
    throw const FormatException('invalid CAR header fields');
  final roots = <CID>[];
  for (final root in rootsValue) {
    if (root is! _CborTag || root.tag != 42 || root.value is! Uint8List) {
      throw const FormatException('invalid CAR root CID');
    }
    final raw = root.value as Uint8List;
    if (raw.isEmpty || raw[0] != 0)
      throw const FormatException('invalid CAR root CID bytes');
    roots.add(_decodeCidExact(raw.sublist(1)));
  }
  return CarHeader(roots: roots, version: versionValue);
}

CarBlock _decodeBlock(Uint8List section) {
  final cid = CID.fromBytes(section);
  final cidLength = cid.toBytes().length;
  if (cidLength >= section.length)
    throw const FormatException('CAR section has no block data');
  if (!_sameBytes(section.sublist(0, cidLength), cid.toBytes()))
    throw const FormatException('non-canonical CID bytes');
  final data = Uint8List.fromList(section.sublist(cidLength));
  validateBlock(cid, data);
  return CarBlock(cid, data);
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

CID _decodeCidExact(Uint8List bytes) {
  if (bytes.length < 2) throw const FormatException('truncated CID');
  final cid = CID.fromBytes(bytes);
  final size = cid.toBytes().length;
  if (size != bytes.length)
    throw const FormatException('CID has trailing bytes');
  return cid;
}

int _headerEnd(Uint8List bytes, int maxHeaderSize) {
  final (length, varintLength) = _readVarint(bytes, 0);
  _checkSectionLength(length, maxHeaderSize);
  return varintLength + length;
}

(int, int) _readVarint(Uint8List bytes, int offset) {
  if (offset < 0 || offset >= bytes.length)
    throw const FormatException('truncated CAR varint');
  var value = 0;
  var shift = 0;
  for (var i = 0; i < 10; i++) {
    final byte = bytes[offset + i];
    if (i == 9 && byte > 1) throw const FormatException('CAR varint overflow');
    value |= (byte & 0x7f) << shift;
    if ((byte & 0x80) == 0) return (value, i + 1);
    shift += 7;
    if (offset + i + 1 == bytes.length)
      throw const FormatException('truncated CAR varint');
  }
  throw const FormatException('CAR varint too long');
}

void _checkSectionLength(int length, int max) {
  if (length < 0 || length > max)
    throw FormatException('CAR section exceeds limit: $length');
}

final class _CborTag {
  _CborTag(this.tag, this.value);
  final int tag;
  final Object? value;
}

final class _CborParser {
  _CborParser(this.bytes);
  final Uint8List bytes;
  int offset = 0;
  int depth = 0;
  bool get done => offset == bytes.length;

  Object? value() {
    if (++depth > 64)
      throw const FormatException('CAR header nesting too deep');
    if (offset >= bytes.length)
      throw const FormatException('truncated CBOR header');
    final initial = bytes[offset++];
    final major = initial >> 5;
    final additional = initial & 0x1f;
    if (additional == 31)
      throw const FormatException(
        'indefinite CBOR is not allowed in CAR header',
      );
    final argument = _argument(additional);
    Object? result;
    switch (major) {
      case 0:
        result = argument;
      case 2:
        result = _bytes(argument);
      case 3:
        result = utf8.decode(_bytes(argument));
      case 4:
        result = [for (var i = 0; i < argument; i++) value()];
      case 5:
        final map = <Object?, Object?>{};
        for (var i = 0; i < argument; i++) {
          final key = value();
          if (map.containsKey(key))
            throw const FormatException('duplicate CAR header key');
          map[key] = value();
        }
        result = map;
      case 6:
        result = _CborTag(argument, value());
      default:
        throw const FormatException('unsupported CBOR type in CAR header');
    }
    depth--;
    return result;
  }

  int _argument(int additional) {
    if (additional < 24) return additional;
    final count = 1 << (additional - 24);
    if (additional > 27 || offset + count > bytes.length) {
      throw const FormatException('invalid CBOR length');
    }
    var result = 0;
    for (var i = 0; i < count; i++) result = (result << 8) | bytes[offset++];
    if (result < 24 && additional != 24)
      throw const FormatException('non-canonical CBOR integer');
    return result;
  }

  Uint8List _bytes(int length) {
    if (length < 0 || offset + length > bytes.length)
      throw const FormatException('truncated CBOR bytes');
    final result = Uint8List.fromList(bytes.sublist(offset, offset + length));
    offset += length;
    return result;
  }
}

final class _CleanEof implements Exception {
  const _CleanEof();
}

final class _AsyncBytes {
  _AsyncBytes(Stream<List<int>> input) : _iterator = StreamIterator(input);
  final StreamIterator<List<int>> _iterator;
  Uint8List _chunk = Uint8List(0);
  int _offset = 0;

  Future<int?> _byte() async {
    while (_offset == _chunk.length) {
      if (!await _iterator.moveNext()) return null;
      _chunk = Uint8List.fromList(_iterator.current);
      _offset = 0;
    }
    return _chunk[_offset++];
  }

  Future<int> readVarint() async {
    var value = 0;
    var shift = 0;
    for (var i = 0; i < 10; i++) {
      final byte = await _byte();
      if (byte == null) {
        if (i == 0) throw const _CleanEof();
        throw const FormatException('truncated CAR varint');
      }
      if (i == 9 && byte > 1)
        throw const FormatException('CAR varint overflow');
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) return value;
      shift += 7;
    }
    throw const FormatException('CAR varint too long');
  }

  Future<Uint8List> readExact(int length) async {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      final byte = await _byte();
      if (byte == null) throw const FormatException('truncated CAR section');
      out[i] = byte;
    }
    return out;
  }
}
