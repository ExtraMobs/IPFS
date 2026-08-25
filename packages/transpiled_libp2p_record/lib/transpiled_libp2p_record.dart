/// Port of `go-libp2p-record`.
library;

export 'src/pubkey_validator.dart' show PublicKeyValidator;
export 'src/record.dart' show Record;
export 'src/util.dart' show splitKey;
export 'src/validator.dart'
    show
        BetterRecordException,
        InvalidRecordTypeException,
        NamespacedValidator,
        Validator;
