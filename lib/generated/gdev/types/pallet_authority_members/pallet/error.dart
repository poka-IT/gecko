// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

/// The `Error` enum of this pallet.
enum Error {
  /// Member already incoming.
  alreadyIncoming('AlreadyIncoming', 0),

  /// Member already online.
  alreadyOnline('AlreadyOnline', 1),

  /// Member already outgoing.
  alreadyOutgoing('AlreadyOutgoing', 2),

  /// Owner key is invalid as a member.
  memberIdNotFound('MemberIdNotFound', 3),

  /// Member is blacklisted.
  memberBlacklisted('MemberBlacklisted', 4),

  /// Member is not blacklisted.
  memberNotBlacklisted('MemberNotBlacklisted', 5),

  /// Member not found.
  memberNotFound('MemberNotFound', 6),

  /// Neither online nor scheduled.
  notOnlineNorIncoming('NotOnlineNorIncoming', 7),

  /// Not member.
  notMember('NotMember', 8),

  /// Session keys not provided.
  sessionKeysNotProvided('SessionKeysNotProvided', 9),

  /// Too many authorities.
  tooManyAuthorities('TooManyAuthorities', 10);

  const Error(
    this.variantName,
    this.codecIndex,
  );

  factory Error.decode(_i1.Input input) {
    return codec.decode(input);
  }

  final String variantName;

  final int codecIndex;

  static const $ErrorCodec codec = $ErrorCodec();

  String toJson() => variantName;
  _i2.Uint8List encode() {
    return codec.encode(this);
  }
}

class $ErrorCodec with _i1.Codec<Error> {
  const $ErrorCodec();

  @override
  Error decode(_i1.Input input) {
    final index = _i1.U8Codec.codec.decode(input);
    switch (index) {
      case 0:
        return Error.alreadyIncoming;
      case 1:
        return Error.alreadyOnline;
      case 2:
        return Error.alreadyOutgoing;
      case 3:
        return Error.memberIdNotFound;
      case 4:
        return Error.memberBlacklisted;
      case 5:
        return Error.memberNotBlacklisted;
      case 6:
        return Error.memberNotFound;
      case 7:
        return Error.notOnlineNorIncoming;
      case 8:
        return Error.notMember;
      case 9:
        return Error.sessionKeysNotProvided;
      case 10:
        return Error.tooManyAuthorities;
      default:
        throw Exception('Error: Invalid variant index: "$index"');
    }
  }

  @override
  void encodeTo(
    Error value,
    _i1.Output output,
  ) {
    _i1.U8Codec.codec.encodeTo(
      value.codecIndex,
      output,
    );
  }
}
