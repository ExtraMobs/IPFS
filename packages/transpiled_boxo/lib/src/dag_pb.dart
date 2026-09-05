import 'dart:typed_data';
import 'dart:convert';

import 'package:transpiled_cid/transpiled_cid.dart';
import 'package:transpiled_varint/transpiled_varint.dart';

List<int> _field(int number, List<int> value) => <int>[
  (number << 3) | 2,
  ...encodeVarint(value.length),
  ...value,
];

List<int> _varintField(int number, int value) => <int>[
  number << 3,
  ...encodeVarint(value),
];

/// A DAG-PB link using the complete binary CID stored by Boxo.
class DagPbLink {
  DagPbLink({required this.hash, this.name = '', this.tsize = 0});

  factory DagPbLink.fromCid(CID cid, {String name = '', int? tsize}) =>
      DagPbLink(hash: cid.toBytes(), name: name, tsize: tsize ?? 0);

  final Uint8List hash;
  final String name;
  final int tsize;

  factory DagPbLink.fromBytes(Uint8List bytes) {
    Uint8List hash = Uint8List(0);
    var name = '';
    var tsize = 0;
    var offset = 0;
    while (offset < bytes.length) {
      final (tag, tagLength) = readVarint(bytes, offset);
      offset += tagLength;
      final field = tag >> 3;
      if ((tag & 7) == 2) {
        final (length, lengthLength) = readVarint(bytes, offset);
        offset += lengthLength;
        if (offset + length > bytes.length)
          throw const FormatException('truncated DAG-PB link');
        final value = bytes.sublist(offset, offset + length);
        offset += length;
        if (field == 1) hash = Uint8List.fromList(value);
        if (field == 2) name = utf8.decode(value);
      } else if ((tag & 7) == 0) {
        final (value, valueLength) = readVarint(bytes, offset);
        offset += valueLength;
        if (field == 3) tsize = value;
      } else {
        throw const FormatException('invalid DAG-PB link wire type');
      }
    }
    return DagPbLink(hash: hash, name: name, tsize: tsize);
  }

  Uint8List toBytes() {
    final out = <int>[..._field(1, hash)];
    // merkledag.GetPBNode initializes both pointers even for zero values.
    out.addAll(_field(2, utf8.encode(name)));
    out.addAll(_varintField(3, tsize));
    return Uint8List.fromList(out);
  }
}

/// A DAG-PB node in the canonical dag-pb order used by Boxo.
class DagPbNode {
  DagPbNode({
    List<int> data = const <int>[],
    Iterable<DagPbLink> links = const [],
  }) : data = Uint8List.fromList(data),
       links = List.unmodifiable(links);

  final Uint8List data;
  final List<DagPbLink> links;

  factory DagPbNode.fromBytes(Uint8List bytes) {
    var offset = 0;
    var data = Uint8List(0);
    final links = <DagPbLink>[];
    while (offset < bytes.length) {
      final (tag, tagLength) = readVarint(bytes, offset);
      offset += tagLength;
      if ((tag & 7) != 2)
        throw const FormatException('invalid DAG-PB node wire type');
      final (length, lengthLength) = readVarint(bytes, offset);
      offset += lengthLength;
      if (offset + length > bytes.length)
        throw const FormatException('truncated DAG-PB node');
      final value = Uint8List.fromList(bytes.sublist(offset, offset + length));
      offset += length;
      switch (tag >> 3) {
        case 1:
          data = value;
          break;
        case 2:
          links.add(DagPbLink.fromBytes(value));
          break;
      }
    }
    return DagPbNode(data: data, links: links);
  }

  Uint8List toBytes() {
    final out = <int>[];
    // go-codec-dagpb encodes Links before Data; this order affects every CID.
    for (final link in links) {
      out.addAll(_field(2, link.toBytes()));
    }
    if (data.isNotEmpty) out.addAll(_field(1, data));
    return Uint8List.fromList(out);
  }
}

/// Go package names retained as aliases for callers familiar with merkledag/pb.
typedef PBLink = DagPbLink;
typedef PBNode = DagPbNode;
