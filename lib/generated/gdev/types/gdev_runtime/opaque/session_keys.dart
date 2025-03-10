// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i6;

import 'package:polkadart/scale_codec.dart' as _i1;
import 'package:quiver/collection.dart' as _i7;

import '../../pallet_im_online/sr25519/app_sr25519/public.dart' as _i4;
import '../../sp_authority_discovery/app/public.dart' as _i5;
import '../../sp_consensus_babe/app/public.dart' as _i3;
import '../../sp_consensus_grandpa/app/public.dart' as _i2;

class SessionKeys {
  const SessionKeys({
    required this.grandpa,
    required this.babe,
    required this.imOnline,
    required this.authorityDiscovery,
  });

  factory SessionKeys.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// <Grandpa as $crate::BoundToRuntimeAppPublic>::Public
  final _i2.Public grandpa;

  /// <Babe as $crate::BoundToRuntimeAppPublic>::Public
  final _i3.Public babe;

  /// <ImOnline as $crate::BoundToRuntimeAppPublic>::Public
  final _i4.Public imOnline;

  /// <AuthorityDiscovery as $crate::BoundToRuntimeAppPublic>::Public
  final _i5.Public authorityDiscovery;

  static const $SessionKeysCodec codec = $SessionKeysCodec();

  _i6.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, List<int>> toJson() => {
        'grandpa': grandpa.toList(),
        'babe': babe.toList(),
        'imOnline': imOnline.toList(),
        'authorityDiscovery': authorityDiscovery.toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is SessionKeys &&
          _i7.listsEqual(
            other.grandpa,
            grandpa,
          ) &&
          _i7.listsEqual(
            other.babe,
            babe,
          ) &&
          _i7.listsEqual(
            other.imOnline,
            imOnline,
          ) &&
          _i7.listsEqual(
            other.authorityDiscovery,
            authorityDiscovery,
          );

  @override
  int get hashCode => Object.hash(
        grandpa,
        babe,
        imOnline,
        authorityDiscovery,
      );
}

class $SessionKeysCodec with _i1.Codec<SessionKeys> {
  const $SessionKeysCodec();

  @override
  void encodeTo(
    SessionKeys obj,
    _i1.Output output,
  ) {
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.grandpa,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.babe,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.imOnline,
      output,
    );
    const _i1.U8ArrayCodec(32).encodeTo(
      obj.authorityDiscovery,
      output,
    );
  }

  @override
  SessionKeys decode(_i1.Input input) {
    return SessionKeys(
      grandpa: const _i1.U8ArrayCodec(32).decode(input),
      babe: const _i1.U8ArrayCodec(32).decode(input),
      imOnline: const _i1.U8ArrayCodec(32).decode(input),
      authorityDiscovery: const _i1.U8ArrayCodec(32).decode(input),
    );
  }

  @override
  int sizeHint(SessionKeys obj) {
    int size = 0;
    size = size + const _i2.PublicCodec().sizeHint(obj.grandpa);
    size = size + const _i3.PublicCodec().sizeHint(obj.babe);
    size = size + const _i4.PublicCodec().sizeHint(obj.imOnline);
    size = size + const _i5.PublicCodec().sizeHint(obj.authorityDiscovery);
    return size;
  }
}
