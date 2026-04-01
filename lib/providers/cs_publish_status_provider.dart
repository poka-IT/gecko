import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status of a CesiumPlus name publication attempt.
enum CsPublishStatus { idle, publishing, success, failed }

/// Tracks the CesiumPlus name publish status per wallet address.
/// Used to show retry indicator when upload fails.
final csPublishStatusProvider = StateProvider.family<CsPublishStatus, String>(
  (ref, address) => CsPublishStatus.idle,
);
