/// Codec interfaces shared by IPLD encoders and decoders.
library;

export 'src/codec/api.dart'
    show BudgetExhaustedException, Decoder, Encoder, MapSortMode;
export 'src/codec/json/codec.dart' show decode, encode, JsonCodecException;
