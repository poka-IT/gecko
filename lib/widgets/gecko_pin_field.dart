import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Reusable PIN field widget with the modern Gecko theme.
///
/// Provides consistent styling across all PIN entry screens:
/// rounded corners (12px), thin borders (1.5px), filled dot character,
/// theme-aware colors, and responsive cell sizes.
class GeckoPinField extends StatelessWidget {
  const GeckoPinField({
    super.key,
    required this.pinController,
    this.onCompleted,
    this.onChanged,
    this.pinColor,
    this.enabled = true,
    this.autoFocus = true,
    this.autoDismissKeyboard = true,
    this.length = 4,
  });

  final PinInputController pinController;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final Color? pinColor;
  final bool enabled;
  final bool autoFocus;
  final bool autoDismissKeyboard;
  final int length;

  @override
  Widget build(BuildContext context) {
    final effectivePinColor = pinColor ?? const Color(0xFFA4B600);
    final fillColor = enabled ? context.colorScheme.surfaceContainer : Colors.grey[100]!;

    return Center(
      child: MaterialPinField(
        textCapitalization: TextCapitalization.none,
        pinController: pinController,
        autoFocus: autoFocus,
        autoDismissKeyboard: autoDismissKeyboard,
        enabled: enabled,
        length: length,
        obscureText: true,
        enableHapticFeedback: true,
        theme: MaterialPinTheme(
          shape: MaterialPinShape.outlined,
          borderRadius: BorderRadius.circular(12),
          cellSize: Size(scaleSize(50), scaleSize(50)),
          filledFillColor: fillColor,
          focusedFillColor: fillColor,
          fillColor: fillColor,
          filledBorderColor: enabled ? effectivePinColor : Colors.grey,
          focusedBorderColor: enabled ? context.colorScheme.primary : Colors.grey,
          borderColor: Colors.grey[300],
          borderWidth: 1.5,
          entryAnimation: MaterialPinAnimation.fade,
          animationDuration: const Duration(milliseconds: 150),
          obscuringCharacter: '●',
          showCursor: !kDebugMode,
          cursorColor: context.colorScheme.primary,
          cursorHeight: 25,
          textStyle: scaledTextStyle(fontSize: 24, height: 1.6, fontWeight: FontWeight.w600),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onCompleted: onCompleted,
        onChanged: onChanged,
      ),
    );
  }
}
