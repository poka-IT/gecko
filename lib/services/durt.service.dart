import 'package:durt2/durt2.dart' show Durt, Networks;

class DurtService {
  Future<void> init() async {
    await Durt().init(network: Networks.gdev);
  }
}
