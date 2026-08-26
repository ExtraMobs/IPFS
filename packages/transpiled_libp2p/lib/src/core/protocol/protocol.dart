// ignore_for_file: public_member_api_docs

/// Core protocol identifiers and negotiation interfaces.
typedef ProtocolId = String;

List<ProtocolId> convertFromStrings(Iterable<String> ids) =>
    List.unmodifiable(ids);
List<String> convertToStrings(Iterable<ProtocolId> ids) =>
    List.unmodifiable(ids);

typedef HandlerFunc = Future<void> Function(ProtocolId protocol, Object stream);

abstract interface class Router {
  void addHandler(ProtocolId id, HandlerFunc handler);
  void addHandlerWithFunc(
    ProtocolId id,
    bool Function(ProtocolId) match,
    HandlerFunc handler,
  );
  void removeHandler(ProtocolId id);
  List<ProtocolId> protocols();
}

abstract interface class Negotiator {
  Future<(ProtocolId, HandlerFunc)> negotiate(Object stream);
  Future<void> handle(Object stream);
}

abstract interface class ProtocolSwitch implements Router, Negotiator {}
