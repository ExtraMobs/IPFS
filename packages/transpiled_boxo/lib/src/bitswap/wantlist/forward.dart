// Port of boxo/bitswap/wantlist/forward.go.
//
// Deprecated: use bitswap/client/wantlist instead.
import 'package:transpiled_cid/transpiled_cid.dart';

import '../client/wantlist/wantlist.dart' as client;

/// Deprecated: use [client.Entry] instead.
typedef Entry = client.Entry;

/// Deprecated: use [client.Wantlist] instead.
typedef Wantlist = client.Wantlist;

/// Deprecated: use [client.Wantlist.new] instead.
Wantlist newWantlist() => client.Wantlist();

/// Deprecated: use [client.newRefEntry] instead.
Entry newRefEntry(CID cid, int priority) => client.newRefEntry(cid, priority);
