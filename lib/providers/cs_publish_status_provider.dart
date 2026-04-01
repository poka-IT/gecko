import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status of a CesiumPlus name publication attempt.
enum CsPublishStatus { idle, publishing, success, failed }

/// Notifier to track the CesiumPlus name publish status per wallet address.
class CsPublishStatusNotifier extends Notifier<CsPublishStatus> {
  @override
  CsPublishStatus build() => CsPublishStatus.idle;

  void setStatus(CsPublishStatus status) => state = status;
}

/// Tracks the CesiumPlus name publish status per wallet address.
/// Used to show retry indicator when upload fails.
final csPublishStatusProvider = NotifierProvider.family<CsPublishStatusNotifier, CsPublishStatus, String>(
  (_) => CsPublishStatusNotifier(),
);
