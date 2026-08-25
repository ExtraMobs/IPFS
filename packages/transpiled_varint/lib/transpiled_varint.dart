/// Port of `multiformats/go-varint`: unsigned LEB128 varint encoding used
/// throughout multiformats and libp2p (CID codec prefixes, multiaddr
/// protocol codes/lengths, etc.).
library;

export 'src/varint.dart' show encodeVarint, readVarint;
