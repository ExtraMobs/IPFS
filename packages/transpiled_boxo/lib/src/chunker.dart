import 'dart:async';
import 'dart:typed_data';

/// The fixed chunk size used by Kubo and Boxo by default (256 KiB).
const int defaultBlockSize = 256 * 1024;

/// Splits a byte stream into fixed-size chunks.
///
/// The final chunk is emitted at EOF, including when it is shorter than
/// [size]. Empty input emits no chunks.
class FixedSizeChunker {
  FixedSizeChunker(this.input, {this.size = defaultBlockSize})
    : assert(size > 0);

  factory FixedSizeChunker.fromBytes(
    Uint8List bytes, {
    int size = defaultBlockSize,
  }) => FixedSizeChunker(Stream.value(bytes), size: size);

  final Stream<List<int>> input;
  final int size;

  Stream<Uint8List> chunks() async* {
    final pending = BytesBuilder(copy: false);
    await for (final part in input) {
      if (part.isEmpty) continue;
      pending.add(part);
      while (pending.length >= size) {
        final bytes = pending.takeBytes();
        yield Uint8List.fromList(bytes.sublist(0, size));
        pending.add(bytes.sublist(size));
      }
    }
    if (pending.length != 0) yield pending.takeBytes();
  }
}

/// Creates a fixed-size splitter using [defaultBlockSize].
FixedSizeChunker defaultSplitter(Stream<List<int>> input) =>
    FixedSizeChunker(input);

/// Creates a fixed-size splitter of [size] bytes.
FixedSizeChunker newSizeSplitter(Stream<List<int>> input, int size) =>
    FixedSizeChunker(input, size: size);

/// Parses the fixed-size chunker forms accepted by the Boxo importer.
FixedSizeChunker fromString(
  Stream<List<int>> input, [
  String spec = 'default',
]) {
  if (spec.isEmpty || spec == 'default') return defaultSplitter(input);
  if (!spec.startsWith('size-')) {
    throw FormatException('unrecognized chunker option: $spec');
  }
  final size = int.tryParse(spec.substring(5));
  if (size == null || size <= 0)
    throw FormatException('invalid chunker size: $spec');
  return newSizeSplitter(input, size);
}

/// Compatibility name matching Boxo's size splitter.
typedef SizeSplitter = FixedSizeChunker;
