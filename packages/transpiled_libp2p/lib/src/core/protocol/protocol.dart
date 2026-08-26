// ignore_for_file: public_member_api_docs

/// Core protocol identifiers and negotiation interfaces.
typedef ProtocolId = String;

List<ProtocolId> convertFromStrings(Iterable<String> ids) => List.unmodifiable(ids);
List<String> convertToStrings(Iterable<ProtocolId> ids) => List.unmodifiable(ids);

typedef HandlerFunc = Future<void> Function(Object stream, ProtocolId protocol);

abstract interface class Router {
  void addHandler(ProtocolId id, HandlerFunc handler);
  void removeHandler(ProtocolId id);
}

abstract interface class Negotiator {
  Future<(Object, ProtocolId)> negotiate(Object stream, List<ProtocolId> protocols);
}

abstract interface class ProtocolSwitch implements Router, Negotiator {
  List<ProtocolId> protocols();
}
