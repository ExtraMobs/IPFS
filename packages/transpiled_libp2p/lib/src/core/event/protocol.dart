// ignore_for_file: public_member_api_docs

import '../peer/peer_id.dart';
import '../protocol/protocol.dart';

final class EvtPeerProtocolsUpdated {
  const EvtPeerProtocolsUpdated({
    required this.peer,
    this.added = const [],
    this.removed = const [],
  });
  final PeerId peer;
  final List<ProtocolId> added;
  final List<ProtocolId> removed;
}

final class EvtLocalProtocolsUpdated {
  const EvtLocalProtocolsUpdated({
    this.added = const [],
    this.removed = const [],
  });
  final List<ProtocolId> added;
  final List<ProtocolId> removed;
}
