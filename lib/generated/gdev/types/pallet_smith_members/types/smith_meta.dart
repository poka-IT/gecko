// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i3;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i4;

import '../smith_status.dart' as _i2;

class SmithMeta {
  const SmithMeta({
    required this.status,
    this.expiresOn,
    required this.issuedCerts,
    required this.receivedCerts,
  });

  factory SmithMeta.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// SmithStatus
  final _i2.SmithStatus status;

  /// Option<SessionIndex>
  final int? expiresOn;

  /// Vec<IdtyIndex>
  final List<int> issuedCerts;

  /// Vec<IdtyIndex>
  final List<int> receivedCerts;

  static const $SmithMetaCodec codec = $SmithMetaCodec();

  _i3.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'status': status.toJson(),
        'expiresOn': expiresOn,
        'issuedCerts': issuedCerts,
        'receivedCerts': receivedCerts,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SmithMeta &&
          other.status == status &&
          other.expiresOn == expiresOn &&
          _i4.listsEqual(
            other.issuedCerts,
            issuedCerts,
          ) &&
          _i4.listsEqual(
            other.receivedCerts,
            receivedCerts,
          );

  @override
  int get hashCode => Object.hash(
        status,
        expiresOn,
        issuedCerts,
        receivedCerts,
      );
}

class $SmithMetaCodec with _i1.Codec<SmithMeta> {
  const $SmithMetaCodec();

  @override
  void encodeTo(
    SmithMeta obj,
    _i1.Output output,
  ) {
    _i2.SmithStatus.codec.encodeTo(
      obj.status,
      output,
    );
    const _i1.OptionCodec<int>(_i1.U32Codec.codec).encodeTo(
      obj.expiresOn,
      output,
    );
    _i1.U32SequenceCodec.codec.encodeTo(
      obj.issuedCerts,
      output,
    );
    _i1.U32SequenceCodec.codec.encodeTo(
      obj.receivedCerts,
      output,
    );
  }

  @override
  SmithMeta decode(_i1.Input input) {
    return SmithMeta(
      status: _i2.SmithStatus.codec.decode(input),
      expiresOn: const _i1.OptionCodec<int>(_i1.U32Codec.codec).decode(input),
      issuedCerts: _i1.U32SequenceCodec.codec.decode(input),
      receivedCerts: _i1.U32SequenceCodec.codec.decode(input),
    );
  }

  @override
  int sizeHint(SmithMeta obj) {
    int size = 0;
    size = size + _i2.SmithStatus.codec.sizeHint(obj.status);
    size = size +
        const _i1.OptionCodec<int>(_i1.U32Codec.codec).sizeHint(obj.expiresOn);
    size = size + _i1.U32SequenceCodec.codec.sizeHint(obj.issuedCerts);
    size = size + _i1.U32SequenceCodec.codec.sizeHint(obj.receivedCerts);
    return size;
  }
}
