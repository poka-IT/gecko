// Add a class to store certification data
import 'package:hive_flutter/hive_flutter.dart';

part 'certification_data.g.dart';

@HiveType(typeId: 8)
class CertificationData {
  @HiveField(0)
  final int receivedCount;

  @HiveField(1)
  final int sentCount;

  CertificationData({required this.receivedCount, required this.sentCount});

  bool equals(CertificationData? other) {
    if (other == null) return false;
    return receivedCount == other.receivedCount && sentCount == other.sentCount;
  }

  bool get isEmpty => receivedCount == 0 && sentCount == 0;
}
