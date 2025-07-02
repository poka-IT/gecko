import 'package:truncate/truncate.dart';

String getShortPubkey(String pubkey) {
  String pubkeyShort =
      truncate(pubkey, 7, omission: String.fromCharCode(0x2026), position: TruncatePosition.end) +
      truncate(pubkey, 6, omission: "", position: TruncatePosition.start);
  return pubkeyShort;
}
