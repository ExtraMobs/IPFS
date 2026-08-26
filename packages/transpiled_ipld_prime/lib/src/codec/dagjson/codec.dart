import 'dart:convert';
import 'dart:typed_data';

import 'package:transpiled_cid/transpiled_cid.dart';

import '../../datamodel/kind.dart';
import '../../datamodel/node.dart';
import '../../datamodel/node_builder.dart';
import '../../linking/cid/cid_link.dart';

/// Encode an IPLD node using the DAG-JSON representation.
void encodeDagJson(Node node, Sink<List<int>> writer) {
  writer.add(utf8.encode('${jsonEncode(_value(node))}\n'));
}

/// Decode a DAG-JSON value into an assembler.
void decodeDagJson(NodeAssembler assembler, Iterable<int> reader) {
  _assign(assembler, jsonDecode(utf8.decode(reader.toList(growable: false))));
}

Object? _value(Node node) => switch (node.kind()) {
      Kind.null_ => null,
      Kind.bool_ => node.asBool(),
      Kind.int_ => node.asInt(),
      Kind.float => node.asFloat(),
      Kind.string => node.asString(),
      Kind.bytes => {'/': 'base64${base64Encode(node.asBytes())}'},
      Kind.link => {'/': node.asLink().toString()},
      Kind.map => {
          for (final (key, value) in _entries(node)) key.asString(): _value(value),
        },
      Kind.list => [for (final value in _values(node)) _value(value)],
      Kind.invalid => throw const FormatException('cannot encode absent node'),
    };

Iterable<(Node, Node)> _entries(Node node) sync* {
  final iterator = node.mapIterator()!;
  while (!iterator.done()) yield iterator.next();
}

Iterable<Node> _values(Node node) sync* {
  final iterator = node.listIterator()!;
  while (!iterator.done()) yield iterator.next().$2;
}

void _assign(NodeAssembler assembler, Object? value) {
  switch (value) {
    case null: assembler.assignNull();
    case bool v: assembler.assignBool(v);
    case int v: assembler.assignInt(v);
    case double v: assembler.assignFloat(v);
    case String v: assembler.assignString(v);
    case List<Object?> v:
      final list = assembler.beginList(v.length);
      for (final item in v) _assign(list.assembleValue(), item);
      list.finish();
    case Map<String, Object?> v when v.length == 1 && v.containsKey('/'):
      final marker = v['/'];
      if (marker is! String) throw const FormatException('invalid DAG-JSON link');
      if (marker.startsWith('base64')) {
        assembler.assignBytes(Uint8List.fromList(base64Decode(marker.substring(6))));
      } else {
        assembler.assignLink(CidLink(CID.decode(marker)));
      }
    case Map<String, Object?> v:
      final map = assembler.beginMap(v.length);
      for (final entry in v.entries) _assign(map.assembleEntry(entry.key), entry.value);
      map.finish();
    default: throw const FormatException('unsupported DAG-JSON value');
  }
}
