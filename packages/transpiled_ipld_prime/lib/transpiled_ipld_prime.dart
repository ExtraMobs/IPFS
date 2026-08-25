/// Port of `go-ipld-prime`'s `datamodel` package: the IPLD Data Model's
/// core interfaces (`Node`/`NodeBuilder`/`NodeAssembler`), `Kind`, `Path`,
/// and `Link`.
///
/// Everything else in go-ipld-prime -- `node/basicnode` (a concrete `Node`
/// implementation), `codec/*` (this umbrella already has original,
/// unaudited `dagcbor`/`dagjson`/`raw` codecs -- see
/// doc/transpilation/PROGRESS.md), `linking`/`linking/cid`, `storage`,
/// `traversal`/`traversal/selector`, `schema`/`schema/gen/go` (code
/// generation via Go reflection has no direct Dart equivalent and needs
/// its own design), and the ADL system -- is not ported yet.
library;

export 'src/datamodel/copy.dart' show copyNode;
export 'src/datamodel/equal.dart' show deepEqual;
export 'src/datamodel/errors.dart'
    show
        InvalidSegmentForListException,
        IteratorOverreadException,
        NotExistsException,
        RepeatedMapKeyException,
        WrongKindException;
export 'src/datamodel/kind.dart' show Kind, KindSet;
export 'src/datamodel/link.dart' show Link, LinkPrototype;
export 'src/datamodel/node.dart'
    show
        ByteReadSeeker,
        LargeBytesNode,
        ListIterator,
        MapIterator,
        Node,
        NodePrototype,
        NodePrototypeSupportingAmend,
        SeekOrigin,
        UintNode;
export 'src/datamodel/node_builder.dart'
    show ListAssembler, MapAssembler, NodeAssembler, NodeBuilder;
export 'src/datamodel/null_node.dart' show absentNode, nullNode;
export 'src/datamodel/path.dart' show Path;
export 'src/datamodel/path_segment.dart' show PathSegment;
