// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:typed_data' as _i2;

import 'package:polkadart/scale_codec.dart' as _i1;

class Parameters {
  const Parameters({
    required this.babeEpochDuration,
    required this.certPeriod,
    required this.certMaxByIssuer,
    required this.certMinReceivedCertToIssueCert,
    required this.certValidityPeriod,
    required this.idtyConfirmPeriod,
    required this.idtyCreationPeriod,
    required this.membershipPeriod,
    required this.membershipRenewalPeriod,
    required this.udCreationPeriod,
    required this.udReevalPeriod,
    required this.smithCertMaxByIssuer,
    required this.smithWotMinCertForMembership,
    required this.smithInactivityMaxDuration,
    required this.wotFirstCertIssuableOn,
    required this.wotMinCertForCreateIdtyRight,
    required this.wotMinCertForMembership,
  });

  factory Parameters.decode(_i1.Input input) {
    return codec.decode(input);
  }

  /// PeriodCount
  final BigInt babeEpochDuration;

  /// BlockNumber
  final int certPeriod;

  /// CertCount
  final int certMaxByIssuer;

  /// CertCount
  final int certMinReceivedCertToIssueCert;

  /// BlockNumber
  final int certValidityPeriod;

  /// BlockNumber
  final int idtyConfirmPeriod;

  /// BlockNumber
  final int idtyCreationPeriod;

  /// BlockNumber
  final int membershipPeriod;

  /// BlockNumber
  final int membershipRenewalPeriod;

  /// PeriodCount
  final BigInt udCreationPeriod;

  /// PeriodCount
  final BigInt udReevalPeriod;

  /// CertCount
  final int smithCertMaxByIssuer;

  /// CertCount
  final int smithWotMinCertForMembership;

  /// SessionCount
  final int smithInactivityMaxDuration;

  /// BlockNumber
  final int wotFirstCertIssuableOn;

  /// CertCount
  final int wotMinCertForCreateIdtyRight;

  /// CertCount
  final int wotMinCertForMembership;

  static const $ParametersCodec codec = $ParametersCodec();

  _i2.Uint8List encode() {
    return codec.encode(this);
  }

  Map<String, dynamic> toJson() => {
        'babeEpochDuration': babeEpochDuration,
        'certPeriod': certPeriod,
        'certMaxByIssuer': certMaxByIssuer,
        'certMinReceivedCertToIssueCert': certMinReceivedCertToIssueCert,
        'certValidityPeriod': certValidityPeriod,
        'idtyConfirmPeriod': idtyConfirmPeriod,
        'idtyCreationPeriod': idtyCreationPeriod,
        'membershipPeriod': membershipPeriod,
        'membershipRenewalPeriod': membershipRenewalPeriod,
        'udCreationPeriod': udCreationPeriod,
        'udReevalPeriod': udReevalPeriod,
        'smithCertMaxByIssuer': smithCertMaxByIssuer,
        'smithWotMinCertForMembership': smithWotMinCertForMembership,
        'smithInactivityMaxDuration': smithInactivityMaxDuration,
        'wotFirstCertIssuableOn': wotFirstCertIssuableOn,
        'wotMinCertForCreateIdtyRight': wotMinCertForCreateIdtyRight,
        'wotMinCertForMembership': wotMinCertForMembership,
      };

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is Parameters &&
          other.babeEpochDuration == babeEpochDuration &&
          other.certPeriod == certPeriod &&
          other.certMaxByIssuer == certMaxByIssuer &&
          other.certMinReceivedCertToIssueCert ==
              certMinReceivedCertToIssueCert &&
          other.certValidityPeriod == certValidityPeriod &&
          other.idtyConfirmPeriod == idtyConfirmPeriod &&
          other.idtyCreationPeriod == idtyCreationPeriod &&
          other.membershipPeriod == membershipPeriod &&
          other.membershipRenewalPeriod == membershipRenewalPeriod &&
          other.udCreationPeriod == udCreationPeriod &&
          other.udReevalPeriod == udReevalPeriod &&
          other.smithCertMaxByIssuer == smithCertMaxByIssuer &&
          other.smithWotMinCertForMembership == smithWotMinCertForMembership &&
          other.smithInactivityMaxDuration == smithInactivityMaxDuration &&
          other.wotFirstCertIssuableOn == wotFirstCertIssuableOn &&
          other.wotMinCertForCreateIdtyRight == wotMinCertForCreateIdtyRight &&
          other.wotMinCertForMembership == wotMinCertForMembership;

  @override
  int get hashCode => Object.hash(
        babeEpochDuration,
        certPeriod,
        certMaxByIssuer,
        certMinReceivedCertToIssueCert,
        certValidityPeriod,
        idtyConfirmPeriod,
        idtyCreationPeriod,
        membershipPeriod,
        membershipRenewalPeriod,
        udCreationPeriod,
        udReevalPeriod,
        smithCertMaxByIssuer,
        smithWotMinCertForMembership,
        smithInactivityMaxDuration,
        wotFirstCertIssuableOn,
        wotMinCertForCreateIdtyRight,
        wotMinCertForMembership,
      );
}

class $ParametersCodec with _i1.Codec<Parameters> {
  const $ParametersCodec();

  @override
  void encodeTo(
    Parameters obj,
    _i1.Output output,
  ) {
    _i1.U64Codec.codec.encodeTo(
      obj.babeEpochDuration,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.certPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.certMaxByIssuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.certMinReceivedCertToIssueCert,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.certValidityPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.idtyConfirmPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.idtyCreationPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.membershipPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.membershipRenewalPeriod,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.udCreationPeriod,
      output,
    );
    _i1.U64Codec.codec.encodeTo(
      obj.udReevalPeriod,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.smithCertMaxByIssuer,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.smithWotMinCertForMembership,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.smithInactivityMaxDuration,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.wotFirstCertIssuableOn,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.wotMinCertForCreateIdtyRight,
      output,
    );
    _i1.U32Codec.codec.encodeTo(
      obj.wotMinCertForMembership,
      output,
    );
  }

  @override
  Parameters decode(_i1.Input input) {
    return Parameters(
      babeEpochDuration: _i1.U64Codec.codec.decode(input),
      certPeriod: _i1.U32Codec.codec.decode(input),
      certMaxByIssuer: _i1.U32Codec.codec.decode(input),
      certMinReceivedCertToIssueCert: _i1.U32Codec.codec.decode(input),
      certValidityPeriod: _i1.U32Codec.codec.decode(input),
      idtyConfirmPeriod: _i1.U32Codec.codec.decode(input),
      idtyCreationPeriod: _i1.U32Codec.codec.decode(input),
      membershipPeriod: _i1.U32Codec.codec.decode(input),
      membershipRenewalPeriod: _i1.U32Codec.codec.decode(input),
      udCreationPeriod: _i1.U64Codec.codec.decode(input),
      udReevalPeriod: _i1.U64Codec.codec.decode(input),
      smithCertMaxByIssuer: _i1.U32Codec.codec.decode(input),
      smithWotMinCertForMembership: _i1.U32Codec.codec.decode(input),
      smithInactivityMaxDuration: _i1.U32Codec.codec.decode(input),
      wotFirstCertIssuableOn: _i1.U32Codec.codec.decode(input),
      wotMinCertForCreateIdtyRight: _i1.U32Codec.codec.decode(input),
      wotMinCertForMembership: _i1.U32Codec.codec.decode(input),
    );
  }

  @override
  int sizeHint(Parameters obj) {
    int size = 0;
    size = size + _i1.U64Codec.codec.sizeHint(obj.babeEpochDuration);
    size = size + _i1.U32Codec.codec.sizeHint(obj.certPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.certMaxByIssuer);
    size =
        size + _i1.U32Codec.codec.sizeHint(obj.certMinReceivedCertToIssueCert);
    size = size + _i1.U32Codec.codec.sizeHint(obj.certValidityPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.idtyConfirmPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.idtyCreationPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.membershipPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.membershipRenewalPeriod);
    size = size + _i1.U64Codec.codec.sizeHint(obj.udCreationPeriod);
    size = size + _i1.U64Codec.codec.sizeHint(obj.udReevalPeriod);
    size = size + _i1.U32Codec.codec.sizeHint(obj.smithCertMaxByIssuer);
    size = size + _i1.U32Codec.codec.sizeHint(obj.smithWotMinCertForMembership);
    size = size + _i1.U32Codec.codec.sizeHint(obj.smithInactivityMaxDuration);
    size = size + _i1.U32Codec.codec.sizeHint(obj.wotFirstCertIssuableOn);
    size = size + _i1.U32Codec.codec.sizeHint(obj.wotMinCertForCreateIdtyRight);
    size = size + _i1.U32Codec.codec.sizeHint(obj.wotMinCertForMembership);
    return size;
  }
}
