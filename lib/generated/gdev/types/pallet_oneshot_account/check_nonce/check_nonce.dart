// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:polkadart/scale_codec.dart' as _i2;

import '../../frame_system/extensions/check_nonce/check_nonce.dart' as _i1;

typedef CheckNonce = _i1.CheckNonce;

class CheckNonceCodec with _i2.Codec<CheckNonce> {
  const CheckNonceCodec();

  @override
  CheckNonce decode(_i2.Input input) {
    return _i2.CompactBigIntCodec.codec.decode(input);
  }

  @override
  void encodeTo(
    CheckNonce value,
    _i2.Output output,
  ) {
    _i2.CompactBigIntCodec.codec.encodeTo(
      value,
      output,
    );
  }

  @override
  int sizeHint(CheckNonce value) {
    return const _i1.CheckNonceCodec().sizeHint(value);
  }
}
