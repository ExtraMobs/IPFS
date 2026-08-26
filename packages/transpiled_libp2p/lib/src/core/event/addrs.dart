// ignore_for_file: public_member_api_docs

import 'package:transpiled_libp2p/src/core/record/envelope.dart';
import 'package:transpiled_multiaddr/transpiled_multiaddr.dart';

enum AddrAction { unknown, added, maintained, removed }

final class UpdatedAddress {
  const UpdatedAddress({required this.address, required this.action});
  final Multiaddr address;
  final AddrAction action;
}

final class EvtLocalAddressesUpdated {
  const EvtLocalAddressesUpdated({
    required this.diffs,
    required this.current,
    this.removed = const [],
    this.signedPeerRecord,
  });
  final bool diffs;
  final List<UpdatedAddress> current;
  final List<UpdatedAddress> removed;
  final Envelope? signedPeerRecord;
}

final class EvtAutoRelayAddrsUpdated {
  const EvtAutoRelayAddrsUpdated(this.relayAddrs);
  final List<Multiaddr> relayAddrs;
}
