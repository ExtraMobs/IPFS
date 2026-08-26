// ignore_for_file: public_member_api_docs

import '../network/network.dart';
import '../peer/peer_id.dart';

/// Emitted when a peer's aggregate connectedness changes.
final class EvtPeerConnectednessChanged {
  const EvtPeerConnectednessChanged({
    required this.peer,
    required this.connectedness,
  });

  final PeerId peer;
  final Connectedness connectedness;
}
