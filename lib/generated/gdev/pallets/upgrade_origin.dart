// ignore_for_file: no_leading_underscores_for_library_prefixes
import '../types/gdev_runtime/runtime_call.dart' as _i1;
import '../types/pallet_upgrade_origin/pallet/call.dart' as _i2;
import '../types/sp_weights/weight_v2/weight.dart' as _i3;

class Txs {
  const Txs();

  /// Dispatches a function call from root origin.
  ///
  /// The weight of this call is defined by the caller.
  _i1.UpgradeOrigin dispatchAsRoot({required _i1.RuntimeCall call}) {
    return _i1.UpgradeOrigin(_i2.DispatchAsRoot(call: call));
  }

  /// Dispatches a function call from root origin.
  /// This function does not check the weight of the call, and instead allows the
  /// caller to specify the weight of the call.
  ///
  /// The weight of this call is defined by the caller.
  _i1.UpgradeOrigin dispatchAsRootUncheckedWeight({
    required _i1.RuntimeCall call,
    required _i3.Weight weight,
  }) {
    return _i1.UpgradeOrigin(_i2.DispatchAsRootUncheckedWeight(
      call: call,
      weight: weight,
    ));
  }
}
